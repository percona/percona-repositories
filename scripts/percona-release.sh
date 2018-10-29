#!/bin/bash
#
#
if [[ $(id -u) -gt 0 ]]; then
  echo "Please run $(basename ${0}) as root!"
  exit 1
fi
#
COMMANDS="list enable enable-only disable"
REPOSITORIES="percona ps-80 tools"
COMPONENTS="release testing experimental"
URL="http://repo.percona.com"
#
MODIFIED=NO
REPOFILE=""
#
if [[ -f /etc/redhat-release ]]; then
  LOCATION=/etc/yum.repos.d
  EXT=repo
  PKGTOOL=yum
elif [[ -f /etc/debian_version ]]; then
  LOCATION=/etc/apt/sources.list.d
  EXT=list
  PKGTOOL=apt
  CODENAME=$(lsb_release -sc)
else
  echo "==>> ERROR: Unsupported system"
  exit 1
fi
#
function show_message {
  if [[ ${MODIFIED} = YES ]]; then
    echo "==> Please run \"${PKGTOOL} update\" to apply changes"
  fi
}
#
function show_help {
  echo " Usage:    $(basename ${0}) list | enable | enable-only | disable (<REPO> | all) [COMPONENT | all]"
  echo "  Example: $(basename ${0}) list"
  echo "  Example: $(basename ${0}) enable all"
  echo "  Example: $(basename ${0}) enable all testing"
  echo "  Example: $(basename ${0}) enable ps-80 testing"
  echo "  Example: $(basename ${0}) enable-only percona testing"
  echo " -> Available commands:     ${COMMANDS}"
  echo " -> Available repositories: ${REPOSITORIES}"
  echo " -> Available components:   ${COMPONENTS}"
  echo "=> Please see percona-release page for help: https://www.percona.com/doc/percona-repo-config/index.html"
}
#
function list_repositories {
  echo "Currently available repositories:"
  for _repository in ${REPOSITORIES}; do
    echo "<*> Repository [${_repository}] with components: ${COMPONENTS}"
    for _component in ${COMPONENTS}; do
      REPOFILE=${LOCATION}/${_repository}-${_component}.${EXT}
      if [[ -f ${REPOFILE} ]]; then
        STATUS="IS INSTALLED"
        PREFIX="+++"
      else
        STATUS="IS NOT INSTALLED"
        PREFIX="-"
      fi
      echo "${PREFIX} ${_repository}-${_component}: ${STATUS}"
    done
      echo
  done
}
#
function create_yum_repo {
  for _key in "\$basearch" noarch sources; do
    echo "[${1}-${2}-${_key}]" >> ${REPOFILE}
    echo "name = Percona ${2}-${_key} YUM repository for \$basearch" >> ${REPOFILE}
    if [[ ${_key} = sources ]]; then
      DIR=SRPMS
      rPATH=""
      ENABLE=0
    else
      DIR=RPMS
      rPATH="/${_key}"
      ENABLE=1
    fi
    echo "baseurl = ${URL}/${1}/yum/${2}/\$releasever/${DIR}${rPATH}" >> ${REPOFILE}
    echo "enable = ${ENABLE}" >> ${REPOFILE}
    echo "gpgcheck = 1" >> ${REPOFILE}
    echo "gpgkey = file:///etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY" >> ${REPOFILE}
    echo >> ${REPOFILE}
  done
}
#
function create_apt_repo {
  REPOURL="${URL}/${1}/apt ${CODENAME}"
  if [[ ${2} = release ]]; then
    _component=main
    echo "deb ${REPOURL} ${_component}" >> ${REPOFILE}
    echo "deb-src ${REPOURL} ${_component}" >> ${REPOFILE}
  else
    echo "deb ${REPOURL} ${_component}" >> ${REPOFILE}
  fi
}
#
function enable_component {
  local _repo=${1}
  [[ ${_repo} != percona ]] && _repo=percona-${1}
  if [[ ${2} = all ]]; then
    dCOMP=${COMPONENTS}
  elif [[ -z ${2} ]]; then
    dCOMP=release
  else
    dCOMP=${2}
  fi
#
  for _component in ${dCOMP}; do
    REPOFILE=${LOCATION}/${_repo}-${_component}.${EXT}
    echo "#" > ${REPOFILE}
    echo "# This repo is managed by \"$(basename ${0})\" utility, do not edit!" >> ${REPOFILE}
    echo "#" >> ${REPOFILE}
    if [[ ${PKGTOOL} = yum ]]; then
      create_yum_repo ${1} ${_component}
    elif [[ ${PKGTOOL} = apt ]]; then
      create_apt_repo ${1} ${_component}
    fi
  done
}
#
function disable_component {
  if [[ ${2} = all ]] || [[ -z ${2} ]]; then
    for _component in ${COMPONENTS}; do
      rm -f ${LOCATION}/${1}-${_component}.${EXT}
    done
  else
      rm -f ${LOCATION}/${1}-${2}.${EXT}
  fi
}
#
function enable_repository {
    if [[ ${1} = all ]]; then
    for _repository in ${REPOSITORIES}; do
      enable_component ${_repository} ${2}
    done
  else
      enable_component ${1} ${2}
  fi
  MODIFIED=YES
}
#
function disable_repository {
  if [[ ${1} = all ]]; then
    for _repository in ${REPOSITORIES}; do
      disable_component ${_repository} ${2}
    done
  else
      disable_component ${1} ${2}
  fi
  MODIFIED=YES
}
#
if [[ ${#} -lt 2 ]] || [[ ${#} -gt 3 ]]; then
  echo "ERROR: Wrong number of parameters: ${#}"
  show_help
  exit 2
fi
#
if [[ ${COMMANDS} != *${1}* ]]; then
  echo "ERROR: Unknown action specified: ${1}"
  show_help
  exit 2
fi
#
if [[ ${REPOSITORIES} != *${2}* ]] && [[ ${2} != all ]]; then
  echo "ERROR: Unknown repo specification: ${2}"
  show_help
  exit 2
fi
#
if [[ -n ${3} ]] && [[ ${COMPONENTS} != *${3}* ]] && [[ ${3} != all ]]; then
  echo "ERROR: Unknown component specification: ${3}"
  show_help
  exit 2
fi
#
case $1 in
  list )
    list_repositories
    ;;
  enable )
    shift
    enable_repository $@
    ;;
  enable-only )
    shift
    disable_repository all all
    enable_repository $@
    ;;
  disable )
    shift
    disable_repository $@
    ;;
  * )
    show_help
    exit 3
    ;;
esac
#
show_message
#
