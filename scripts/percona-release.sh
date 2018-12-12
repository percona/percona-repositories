#!/bin/bash
#
#
if [[ $(id -u) -gt 0 ]]; then
  echo "Please run $(basename ${0}) as root!"
  exit 1
fi
#
ALIASES="ps56 ps57 ps80 psmdb34 psmdb36 psmdb40 pxb80 pxc56 pxc57 pxc80"
COMMANDS="list enable enable-only setup disable"
REPOSITORIES="percona ps-80 psmdb-40 tools"
COMPONENTS="release testing experimental"
URL="http://repo.percona.com"
#
PS80REPOS="ps-80 tools"
PXC80REPOS="pxc-80 tools"
PXB80REPOS="tools"
PSMDB40REPOS="psmdb-40 tools"
#
AUTOUPDATE=NO
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
  PKGTOOL="apt-get"
  CODENAME=$(lsb_release -sc)
else
  echo "==>> ERROR: Unsupported system"
  exit 1
fi
#
function check_specified_alias {
  local found=NO
  [[ -z ${1} ]] && echo "ERROR: No product alias specified!" && show_help && exit 2
  for _alias in ${ALIASES}; do
    [[ ${_alias} = ${1} ]] && found=YES
  done
  if [[ ${found} = NO ]]; then
    echo "ERROR: Unknown alias specification: ${1}"
    echo "Available product aliases are: ${ALIASES}"
    exit 2
  fi
}

function check_specified_repo {
  local found=NO
  [[ -z ${1} ]] && echo "ERROR: No repo specified!" && show_help && exit 2
  for _repo in all ${REPOSITORIES}; do
    [[ ${_repo} = ${1} ]] && found=YES
  done
  if [[ ${found} = NO ]]; then
    echo "ERROR: Unknown repository: ${1}"
    echo "Available repositories are: ${REPOSITORIES}"
    exit 2
  fi
}
#
function check_specified_component {
  local message=""
  local found=NO
  for _component in all ${COMPONENTS}; do
    [[ ${_component} = ${1} ]] && found=YES
  done
  [[ ${found} = NO ]] && message="ERROR: Unknown component specification: ${1}"
  [[ -n ${message} ]] && echo ${message} && show_help && exit 2
}
#
function show_message {
  echo "<*> All done!"
  if [[ ${MODIFIED} = YES ]] && [[ ${PKGTOOL} = "apt-get" ]]; then
    echo "==> Please run \"${PKGTOOL} update\" to apply changes"
  fi
}
#
function show_help {
  echo
  echo "Usage:    $(basename ${0}) list | enable | enable-only | setup | disable (<REPO> | all) [COMPONENT | all]"
  echo "  Example: $(basename ${0}) list"
  echo "  Example: $(basename ${0}) enable all"
  echo "  Example: $(basename ${0}) enable tools release"
  echo "  Example: $(basename ${0}) enable-only ps-80 experimental"
  echo "  Example: $(basename ${0}) setup ps57"
  echo
  echo "-> Available commands:       ${COMMANDS}"
  echo "-> Available setup products: ${ALIASES}"
  echo "-> Available repositories:   ${REPOSITORIES}"
  echo "-> Available components:     ${COMPONENTS}"
  echo "=> Please see percona-release page for help: https://www.percona.com/doc/percona-repo-config/percona-release.html"
}
#
function list_repositories {
  echo "Currently available repositories:"
  for _repository in ${REPOSITORIES}; do
    _repo=${_repository}
    [[ ${_repository} != percona ]] && _repo=percona-${_repository}
    echo "<*> Repository [${_repo}] with components: ${COMPONENTS}"
    for _component in ${COMPONENTS}; do
      REPOFILE=${LOCATION}/${_repo}-${_component}.${EXT}
      if [[ -f ${REPOFILE} ]]; then
        STATUS="IS ENABLED"
        PREFIX="+++"
      else
        STATUS="IS DISABLED"
        PREFIX="-"
      fi
      echo "${PREFIX} ${_repo}-${_component}: ${STATUS}"
    done
      echo
  done
}
#
function run_update {
  if [[ ${PKGTOOL} = "apt-get" ]]; then
    AUTOUPDATE="YES"
    ${PKGTOOL} update
  fi
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
  [[ -n ${2} ]] && check_specified_component ${2}
  if [[ ${2} = all ]]; then
    dCOMP=${COMPONENTS}
  elif [[ -z ${2} ]]; then
    dCOMP=release
  else
    dCOMP=${2}
  fi
#
  for _component in ${dCOMP}; do
    echo "* Enabling the ${1} ${_component} repository"
    REPOFILE=${LOCATION}/${_repo}-${_component}.${EXT}
    echo "#" > ${REPOFILE}
    echo "# This repo is managed by \"$(basename ${0})\" utility, do not edit!" >> ${REPOFILE}
    echo "#" >> ${REPOFILE}
    if [[ ${PKGTOOL} = yum ]]; then
      create_yum_repo ${1} ${_component}
    elif [[ ${PKGTOOL} = "apt-get" ]]; then
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
function enable_alias {
  local REPOS=""
  check_specified_alias ${1}
  [[ ${1} = ps80 ]] && REPOS=${PS80REPOS:-}
  [[ ${1} = pxc80 ]] && REPOS=${PXC80REPOS:-}
  [[ ${1} = pxb80 ]] && REPOS=${PXB80REPOS:-}
  [[ ${1} = psmdb40 ]] && REPOS=${PSMDB40REPOS:-}
  [[ -z ${REPOS} ]] && REPOS="percona tools"
  for _repo in ${REPOS}; do
    enable_repository ${_repo}
  done
  run_update
}
#
function check_setup_command {
  if [[ -n ${2} ]]; then
    echo "* \"setup\" command does not accept additional options!"
    show_help
    exit 2
  fi
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
    echo "* Disabling all Percona Repositories"
    disable_repository all all
    enable_repository $@
    ;;
  setup )
    shift
    check_setup_command $@
    echo "* Disabling all Percona Repositories"
    disable_repository all all
    enable_alias $@
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
if [[ ${AUTOUPDATE} = NO ]]; then
  show_message
fi
#
