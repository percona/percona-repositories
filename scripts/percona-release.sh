#!/bin/bash
#
if [[ $(id -u) -gt 0 ]]; then
  echo "Please run $(basename ${0}) as root!"
  exit 1
fi
#
COMMANDS="list enable disable"
REPOSITORIES="percona ps8x pmm-client"
COMPONENTS="release testing experimental"
URL="http://repo.percona.com"
#
MODIFIED=NO
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
  echo " Usage:    $(basename ${0}) list | enable | disable (<REPO> | all) [COMPONENT | all]"
  echo "  Example: $(basename ${0}) list"
  echo "  Example: $(basename ${0}) enable all"
  echo "  Example: $(basename ${0}) enable ps8x testing"
  echo " -> Available commands:     ${COMMANDS}"
  echo " -> Available repositories: ${REPOSITORIES}"
  echo " -> Available components:   ${COMPONENTS}"
  echo "=> Please see percona-release page for complete help: https://percona.com/percona-release"
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
        PREFIX="(+)"
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
  echo create_yum_repo
}
#
function create_apt_repo {
  REPOFILE=${LOCATION}/${1}-${2}.${EXT}
  REPOURL="${URL}/${1}/apt ${CODENAME}"
  if [[ ${2} = release ]]; then
    _component=main
    echo "deb ${REPOURL} ${_component}" > ${REPOFILE}
    echo "deb-src ${REPOURL} ${_component}" >> ${REPOFILE}
  else
    echo "deb ${REPOURL} ${_component}" > ${REPOFILE}
  fi
}
#
function enable_component {
  if [[ -z ${2} ]]; then
    _component=release
  else
    _component=${2}
  fi
#
  if [[ ${PKGTOOL} = yum ]]; then
    create_yum_repo ${1} ${_component}
  elif [[ ${PKGTOOL} = apt ]]; then
    create_apt_repo ${1} ${_component}
  fi
}
#
function disable_component {
  if [[ ${2} = all ]] || [[ -z ${2} ]]; then
    for _component in ${COMPONENTS}; do
      rm -fv ${LOCATION}/${1}-${_component}.${EXT}
    done
  else
      rm -fv ${LOCATION}/${1}-${2}.${EXT}
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
if [[ ${#} -lt 1 ]] || [[ ${#} -gt 3 ]]; then
  echo "ERROR: Wrong number of parameters: ${#}"
  show_help
  exit 2
fi
#
if [[ ${COMMANDS} != *${1}* ]]; then
  echo "ERROR: Unknown action: ${1}"
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
