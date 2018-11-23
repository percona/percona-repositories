#!/bin/bash
#
#
if [[ $(id -u) -gt 0 ]]; then
  echo "Please run $(basename ${0}) as root!"
  exit 1
fi
#
COMMANDS="list enable enable-only disable"
REPOSITORIES="percona ps-80 psmdb-40 tools"
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
function check_specified_repo {
  local found=NO
  [[ -z ${1} ]] && echo "ERROR: No repo specified!" && show_help && exit 2
  for _repo in all ${REPOSITORIES}; do
    [[ ${_repo} = ${1} ]] && found=YES
  done
  [[ ${found} = NO ]] && echo "ERROR: Unknown repository specification: ${1}" && show_help && exit 2
}
#
function check_specified_component {
  local message=""
  local found=NO
  [[ -z ${1} ]] && echo "<!> No component specified, assuming \"release\"" && return
  for _component in all ${COMPONENTS}; do
    [[ ${_component} = ${1} ]] && found=YES
  done
  [[ ${found} = NO ]] && message="ERROR: Unknown component specification: ${1}"
  [[ -n ${message} ]] && echo ${message} && show_help && exit 2
}
#
function show_message {
  echo "<*> All done!"
  if [[ ${MODIFIED} = YES ]] && [[ ${PKGTOOL} = apt ]]; then
    echo "==> Please run \"${PKGTOOL} update\" to apply changes"
  fi
}
#
function show_help {
  echo
  echo "Usage:    $(basename ${0}) list | enable | enable-only | disable (<REPO> | all) [COMPONENT | all]"
  echo "  Example: $(basename ${0}) list"
  echo "  Example: $(basename ${0}) enable all"
  echo "  Example: $(basename ${0}) enable all testing"
  echo "  Example: $(basename ${0}) enable ps-80 testing"
  echo "  Example: $(basename ${0}) enable-only percona testing"
  echo
  echo "Short specification:"
  echo "  Example: $(basename ${0}) enable  <REPO> IS EQUAL to enable  <REPO> release"
  echo "  Example: $(basename ${0}) disable <REPO> IS EQUAL to disable <REPO> all"
  echo
  echo "-> Available commands:     ${COMMANDS}"
  echo "-> Available repositories: ${REPOSITORIES}"
  echo "-> Available components:   ${COMPONENTS}"
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
  check_specified_component ${2}
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
  local _repo=${1}
  [[ ${_repo} != percona ]] && _repo=percona-${1}
  if [[ ${2} = all ]] || [[ -z ${2} ]]; then
    for _component in ${COMPONENTS}; do
      mv -f ${LOCATION}/${_repo}-${_component}.${EXT} ${LOCATION}/${_repo}-${_component}.${EXT}.bak 2>/dev/null
    done
  else
    check_specified_component ${2}
    mv -f ${LOCATION}/${_repo}-${2}.${EXT} ${LOCATION}/${_repo}-${2}.${EXT}.bak 2>/dev/null
  fi
}
#
function enable_repository {
  local _repos=${1}
  [[ ${1} = all ]] && _repos=${REPOSITORIES}
  check_specified_repo ${1}
  for _repository in ${_repos}; do
    enable_component ${_repository} ${2}
  done
  MODIFIED=YES
}
#
function disable_repository {
  local _repos=${1}
  [[ ${1} = all ]] && _repos=${REPOSITORIES}
  check_specified_repo ${1}
  for _repository in ${_repos}; do
    disable_component ${_repository} ${2}
  done
  MODIFIED=YES
}
#
if [[ ${COMMANDS} != *${1}* ]]; then
  echo "ERROR: Unknown action specified: ${1}"
  show_help
  exit 2
fi
#
case $1 in
  list )
    list_repositories
    exit
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
