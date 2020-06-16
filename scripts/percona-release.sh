#!/bin/bash
#
#
#If you want to make script non-interactive please change this variable to NO
INTERACTIVE=YES
#
if [[ $(id -u) -gt 0 ]]; then
  echo "Please run $(basename ${0}) as root!"
  exit 1
fi
#
ALIASES="ps56 ps57 ps80 psmdb34 psmdb36 psmdb40 psmdb42 pxb80 pxc56 pxc57 pxc80 ppg11 ppg11.5 ppg11.6 ppg11.7 ppg11.8 ppg12 ppg12.2 ppg12.3 pdmdb4.2 pdmdb4.2.6 pdmdb4.2.7 pdmysql8.0.18 pdmysql8.0"
COMMANDS="enable enable-only setup disable"
REPOSITORIES="original ps-80 pxc-80 psmdb-40 psmdb-42 tools ppg-11 ppg-11.5 ppg-11.6 ppg-11.7 ppg-11.8 ppg-12 ppg-12.2 ppg-12.3 pdmdb-4.2 pdmdb-4.2.6 pdmdb-4.2.7 pdmysql-8.0 pdmysql-8.0.18"
COMPONENTS="release testing experimental"
URL="http://repo.percona.com"

#
DESCRIPTION=""
DEFAULT_REPO_DESC="Percona Original"
PS80_DESC="Percona Server 8.0"
PXB80_DESC="Percona XtraBackup 8.0"
PXC80_DESC="Percona XtraDB Cluster 8.0"
PSMDB40_DESC="Percona Server for MongoDB 4.0"
PSMDB42_DESC="Percona Server for MongoDB 4.2"
TOOLS_DESC="Percona Tools"
PPG11_DESC="Percona Distribution for PostgreSQL 11"
PPG11_5_DESC="Percona Distribution for PostgreSQL 11.5"
PPG11_6_DESC="Percona Distribution for PostgreSQL 11.6"
PPG11_7_DESC="Percona Distribution for PostgreSQL 11.7"
PPG11_8_DESC="Percona Distribution for PostgreSQL 11.8"
PDMDB4_2_DESC="Percona Distribution for MongoDB 4.2"
PDMDB4_2_6_DESC="Percona Distribution for MongoDB 4.2.6"
PDMDB4_2_7_DESC="Percona Distribution for MongoDB 4.2.7"
PPG12_DESC="Percona Distribution for PostgreSQL 12"
PPG12_2_DESC="Percona Distribution for PostgreSQL 12.2"
PPG12_3_DESC="Percona Distribution for PostgreSQL 12.3"
PDMYSQL80_DESC="Percona Distribution for MySQL 8.0"
PDMYSQL80_18_DESC="Percona Distribution for MySQL 8.0.18"
PPG_DESC="Percona Distribution for PostgreSQL"
PDMDB_DESC="Percona Distribution for MongoDB"
PDPS_DESC="Percona Distribution for MySQL - PS"
PDPXC_DESC="Percona Distribution for MySQL - PXC"

#
PS80REPOS="ps-80 tools"
PXC80REPOS="pxc-80 tools"
PXB80REPOS="tools"
PSMDB40REPOS="psmdb-40 tools"
PSMDB42REPOS="psmdb-42 tools"
PPG11REPOS="ppg-11"
PPG11_5_REPOS="ppg-11.5"
PPG11_6_REPOS="ppg-11.6"
PPG11_7_REPOS="ppg-11.7"
PPG11_8_REPOS="ppg-11.8"
PDMDB4_2_6_REPOS="pdmdb-4.2.6"
PDMDB4_2_7_REPOS="pdmdb-4.2.7"
PDMDB4_2_REPOS="pdmdb-4.2"
PPG12_REPOS="ppg-12"
PPG12_2_REPOS="ppg-12.2"
PPG12_3_REPOS="ppg-12.3"
PDMYSQL80_REPOS="pdmysql-8.0"
PDMYSQL80_18_REPOS="pdmysql-8.0.18"
#
AUTOUPDATE=NO
MODIFIED=NO
REPOFILE=""
#          RH derivatives      and          Amazon Linux
if [[ -f /etc/redhat-release ]] || [[ -f /etc/system-release ]]; then
  LOCATION=/etc/yum.repos.d
  EXT=repo
  PKGTOOL=yum
  ARCH=$(rpm --eval %_arch)
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
    NAME=$(echo ${1} | sed 's/-//' )
    [[ ${_alias} = ${NAME} ]] && found=YES
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
  for _repo in ${REPOSITORIES}; do
    [[ ${_repo} = ${1} ]] && found=YES
  done
  if [[ ${found} = NO ]]; then
    echo "ERROR: Unknown repository: ${1}"
    echo "Available repositories are: ${REPOSITORIES}"
    exit 2
  fi
}
#
function check_repo_availability {
  if [[ "$2" == "-y" ]]; then
    REPO_NAME=${3}
  else
    REPO_NAME=${2}
  fi
  reply=$(curl -Is http://repo.percona.com/${REPO_NAME}/ | head -n 1 | awk '{print $2}')
  if [[ ${reply} == 200 ]]; then
    if [[ ${REPOSITORIES} != "*${REPONAME}*" ]]; then
      REPO_ALIAS=$(echo ${REPO_NAME} | sed 's/-//')
      ALIASES="${REPOSITORIES} ${REPO_ALIAS}"
      REPOSITORIES="${REPOSITORIES} ${REPO_NAME}"
    fi
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
  echo "Usage:     $(basename ${0}) enable | enable-only | setup | disable (<REPO> | all) [COMPONENT]"
  echo "  Example: $(basename ${0}) enable tools release"
  echo "  Example: $(basename ${0}) enable-only ps-80 experimental"
  echo "  Example: $(basename ${0}) setup ps57"
  echo "  Example: $(basename ${0}) setup -y ps57"
  echo
  echo "-> Available commands:       ${COMMANDS}"
  echo "-> Available setup products: ${ALIASES}"
  echo "-> Available repositories:   ${REPOSITORIES}"
  echo "-> Available components:     ${COMPONENTS}"
  echo "=> The \"-y\" option for the setup command automatically answers \"yes\" for all interactive questions."
  echo "=> Please see percona-release page for help: https://www.percona.com/doc/percona-repo-config/percona-release.html"
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
  local _repo=${1}
  [[ ${1} = "original" ]] && _repo=percona
  for _key in "${ARCH}" noarch sources; do
    echo "[${_repo}-${2}-${_key}]" >> ${REPOFILE}
    echo "name = ${DESCRIPTION} ${2}/${_key} YUM repository" >> ${REPOFILE}
    if [[ ${_key} = sources ]]; then
      DIR=SRPMS
      rPATH=""
      ENABLE=0
    else
      DIR=RPMS
      rPATH="/${_key}"
      ENABLE=1
    fi
    echo "baseurl = ${URL}/${_repo}/yum/${2}/\$releasever/${DIR}${rPATH}" >> ${REPOFILE}
    echo "enabled = ${ENABLE}" >> ${REPOFILE}
    echo "gpgcheck = 1" >> ${REPOFILE}
    echo "gpgkey = file:///etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY" >> ${REPOFILE}
    echo >> ${REPOFILE}
  done
}
#
function create_apt_repo {
  local _repo=${1}
  [[ ${1} = "original" ]] && _repo=percona
  REPOURL="${URL}/${_repo}/apt ${CODENAME}"
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
  local _repo=percona-${1}
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
  local _repo=percona-${1}
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
  check_specified_repo ${1}
  [[ ${1} = "ps-80" ]]    && DESCRIPTION=${PS80_DESC}
  [[ ${1} = "pxc-80" ]]   && DESCRIPTION=${PXC80_DESC}
  [[ ${1} = "pxb-80" ]]   && DESCRIPTION=${PXB80_DESC}
  [[ ${1} = "psmdb-40" ]]  && DESCRIPTION=${PSMDB40_DESC}
  [[ ${1} = "psmdb-42" ]]  && DESCRIPTION=${PSMDB42_DESC}
  [[ ${1} = "tools" ]]    && DESCRIPTION=${TOOLS_DESC}
  [[ ${1} = "ppg-11" ]]    && DESCRIPTION=${PPG11_DESC}
  [[ ${1} = "ppg-11.5" ]]    && DESCRIPTION=${PPG11_5_DESC}
  [[ ${1} = "ppg-11.6" ]]    && DESCRIPTION=${PPG11_6_DESC}
  [[ ${1} = "ppg-11.7" ]]    && DESCRIPTION=${PPG11_7_DESC}
  [[ ${1} = "ppg-11.8" ]]    && DESCRIPTION=${PPG11_8_DESC}
  [[ ${1} = "pdmdb-4.2" ]]    && DESCRIPTION=${PDMDB4_2_DESC}
  [[ ${1} = "pdmdb-4.2.6" ]]    && DESCRIPTION=${PDMDB4_2_6_DESC}
  [[ ${1} = "pdmdb-4.2.7" ]]    && DESCRIPTION=${PDMDB4_2_7_DESC}
  [[ ${1} = "ppg-12" ]]    && DESCRIPTION=${PPG12_DESC}
  [[ ${1} = "ppg-12.2" ]]    && DESCRIPTION=${PPG12_2_DESC}
  [[ ${1} = "ppg-12.3" ]]    && DESCRIPTION=${PPG12_3_DESC}
  [[ ${1} = "pdmysql-8.0" ]]    && DESCRIPTION=${PDMYSQL80_DESC}
  [[ ${1} = "pdmysql-8.0.18" ]]    && DESCRIPTION=${PDMYSQL80_18_DESC}
  if [[ -z ${DESCRIPTION} ]]; then
    REPO_NAME=$(echo ${1} | sed 's/-//')
    name=$(echo ${REPO_NAME} | sed 's/[0-9].*//g')
    version=$(echo ${REPO_NAME} | sed 's/[a-z]*//g')
    [[ ${name} == ppg* ]]    && DESCRIPTION="${PPG_DESC} $version"
    [[ ${name} == pdmdb* ]]    && DESCRIPTION="${PDMDB_DESC} $version"
    [[ ${name} == pdps* ]]    && DESCRIPTION="${PDPS_DESC} $version"
    [[ ${name} == pdpxc* ]]    && DESCRIPTION="${PDPXC_DESC} $version"
  fi
  [[ -z ${DESCRIPTION} ]] && DESCRIPTION=${DEFAULT_REPO_DESC}
  echo "* Enabling the ${DESCRIPTION} repository"
  enable_component ${1} ${2}
  MODIFIED=YES
}
#
function disable_repository {
  local _repos=${1}
  if [[ ${1} = all ]]; then
    _repos=${REPOSITORIES}
    for _repository in ${_repos}; do
      disable_component ${_repository} ${2}
    done
  else
    check_specified_repo ${1}
    disable_component ${1} ${2}
  fi
  MODIFIED=YES
}
#
function disable_dnf_module {
  REPO_NAME=${1}
  MODULE="mysql"
  PRODUCT="Percona-Server"
  if [[ ${REPO_NAME} == ppg* ]]; then
    MODULE="postgresql"
    PRODUCT="Percona PostgreSQL Distribution"
  fi
  if [[ ${REPO_NAME} == pdps* ]]; then
    MODULE="mysql"
    PRODUCT="Percona Distribution for MySQL - PS"
  fi
  if [[ ${REPO_NAME} == pdpxc* ]]; then
    MODULE="mysql"
    PRODUCT="Percona Distribution for MySQL - PXC"
  fi
  if [[ ${REPO_NAME} = pxc* ]];  then
    MODULE="mysql"
    PRODUCT="Percona XtraDB Cluster"
  fi
  if [[ -f /usr/bin/dnf ]]; then
    if [[ ${INTERACTIVE} = YES ]]; then
      echo "On RedHat 8 systems it is needed to disable dnf ${MODULE} module to install ${PRODUCT}"
      read -r -p "Do you want to disable it? [y/N] " response
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
      then
        echo "Disabling dnf module..."
        dnf -y module disable ${MODULE}
        echo "dnf ${MODULE} module was disabled"
      else
        echo "Please note that some packages might be unavailable"
        echo "If in future you decide to disable module please execute the next command:"
        echo "  dnf module disable ${MODULE}"
      fi
    else
      echo "On RedHat 8 systems it is needed to disable dnf ${MODULE} module to install ${PRODUCT}"
      echo "Disabling dnf module..."
      dnf -y module disable ${MODULE}
      echo "dnf ${MODULE} module was disabled"
    fi
  fi
}
#
function enable_alias {
  local REPOS=""
  local NAME=$( echo ${1} | sed 's/-//' )
  check_specified_alias ${NAME}
  [[ ${NAME} = ps80 ]] && REPOS=${PS80REPOS:-}
  [[ ${NAME} = pxc80 ]] && REPOS=${PXC80REPOS:-}
  [[ ${NAME} = pxb80 ]] && REPOS=${PXB80REPOS:-}
  [[ ${NAME} = psmdb40 ]] && REPOS=${PSMDB40REPOS:-}
  [[ ${NAME} = psmdb42 ]] && REPOS=${PSMDB42REPOS:-}
  [[ ${NAME} = ppg11 ]] && REPOS=${PPG11REPOS:-}
  [[ ${NAME} = ppg11.5 ]] && REPOS=${PPG11_5_REPOS:-}
  [[ ${NAME} = ppg11.6 ]] && REPOS=${PPG11_6_REPOS:-}
  [[ ${NAME} = ppg11.7 ]] && REPOS=${PPG11_7_REPOS:-}
  [[ ${NAME} = ppg11.8 ]] && REPOS=${PPG11_8_REPOS:-}
  [[ ${NAME} = pdmdb4.2 ]] && REPOS=${PDMDB4_2_REPOS:-}
  [[ ${NAME} = pdmdb4.2.6 ]] && REPOS=${PDMDB4_2_6_REPOS:-}
  [[ ${NAME} = pdmdb4.2.7 ]] && REPOS=${PDMDB4_2_7_REPOS:-}
  [[ ${NAME} = ppg12 ]] && REPOS=${PPG12_REPOS:-}
  [[ ${NAME} = ppg12.2 ]] && REPOS=${PPG12_2_REPOS:-}
  [[ ${NAME} = ppg12.3 ]] && REPOS=${PPG12_3_REPOS:-}
  if [ -z "${REPOS}" ]; then
    name=$(echo ${NAME} | sed 's/[0-9].*//g')
    version=$(echo ${NAME} | sed 's/[a-z]*//g')
    [[ ${name} = "ppg" ]] && REPOS="$name-$version"
    [[ ${name} = "pdmdb" ]] && REPOS="$name-$version"
    [[ ${name} = "pdps" ]] && REPOS="$name-$version"
    [[ ${name} = "pdpxc" ]] && REPOS="$name-$version"
  fi
  if [[ ${NAME} = ps80 ]] || [[ ${NAME} == pxc* ]] || [[ ${NAME} == ppg* ]] || [[ ${NAME} == pdps* ]] || [[ ${NAME} == pdpxc* ]]; then
    disable_dnf_module ${NAME}
  fi
  for _repo in ${REPOS}; do
    enable_repository ${_repo}
  done
  run_update
}
#
function check_setup_command {
  if [[ "$1" == "-y" || "${!#}" == "-y" ]]; then
      export INTERACTIVE=no
  elif [[ -n ${2} ]]; then
    echo "* \"setup\" command supports only \"-y\""
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
check_repo_availability $@
case $1 in
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
    enable_alias ${@##-*}
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
