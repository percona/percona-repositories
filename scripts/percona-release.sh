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
ALIASES="ps56 ps57 ps80 psmdb34 psmdb36 psmdb40 psmdb42 pxb24 pxb80 pxc56 pxc57 pxc80 ppg11 ppg11.5 ppg11.6 ppg11.7 ppg11.8 ppg12 ppg12.2 ppg12.3 pdmdb4.2 pdmdb4.2.6 pdmdb4.2.7 pdmdb4.2.8 pdps8.0.19 pdps8.0.20 pdpxc8.0.19 pdps8.0 pdpxc8.0 prel proxysql sysbench pt pmm-client pmm2-client mysql-shell pbm pdmdb4.4 pdmdb4.4.0 psmdb44"
COMMANDS="enable enable-only setup disable show"
REPOSITORIES="original ps-56 ps-57 ps-80 pxc-56 pxc-57 pxc-80 psmdb-36 psmdb-40 psmdb-42 pxb-24 pxb-80 tools ppg-11 ppg-11.5 ppg-11.6 ppg-11.7 ppg-11.8 ppg-12 ppg-12.2 ppg-12.3 pdmdb-4.2 pdmdb-4.2.6 pdmdb-4.2.7 pdmdb-4.2.8 pdps-8.0.19 pdpxc-8.0.19 pdps-8.0.20 pdps-8.0 pdpxc-8.0 prel proxysql sysbench pt mysql-shell pbm pmm-client pmm2-client pdmdb-4.4 pdmdb-4.4.0 psmdb-44"
COMPONENTS="release testing experimental"
URL="http://repo.percona.com"
SUPPORTED_ARCHS="i386 noarch x86_64 sources"

if [[ -f /etc/default/percona-release ]]; then
    source /etc/default/percona-release
fi

#
DESCRIPTION=""
DEFAULT_REPO_DESC="Percona Original"
PREL_DESC="Percona Release"
PT_DESC="Percona Toolkit"
SYSBENCH_DESC="Sysbench"
PROXYSQL_DESC="Proxysql"
PBM_DESC="Percona Backup MongoDB"
MYSQL_SHELL_DESC="Percona MySQL Shell"
PMM_CLIENT_DESC="PMM Client"
PMM2_CLIENT_DESC="PMM2 Client"
PS56_DESC="Percona Server for MySQL 5.6"
PS57_DESC="Percona Server for MySQL 5.7"
PS80_DESC="Percona Server for MySQL 8.0"
PXB24_DESC="Percona XtraBackup 2.4"
PXB80_DESC="Percona XtraBackup 8.0"
PXC56_DESC="Percona XtraDB Cluster 5.6"
PXC57_DESC="Percona XtraDB Cluster 5.7"
PXC80_DESC="Percona XtraDB Cluster 8.0"
PSMDB36_DESC="Percona Server for MongoDB 3.6"
PSMDB40_DESC="Percona Server for MongoDB 4.0"
PSMDB42_DESC="Percona Server for MongoDB 4.2"
PSMDB_DESC="Percona Server for MongoDB"
TOOLS_DESC="Percona Tools"
PPG11_DESC="Percona Distribution for PostgreSQL 11"
PPG11_5_DESC="Percona Distribution for PostgreSQL 11.5"
PPG11_6_DESC="Percona Distribution for PostgreSQL 11.6"
PPG11_7_DESC="Percona Distribution for PostgreSQL 11.7"
PPG11_8_DESC="Percona Distribution for PostgreSQL 11.8"
PDMDB4_2_DESC="Percona Distribution for MongoDB 4.2"
PDMDB4_2_6_DESC="Percona Distribution for MongoDB 4.2.6"
PDMDB4_2_7_DESC="Percona Distribution for MongoDB 4.2.7"
PDMDB4_2_8_DESC="Percona Distribution for MongoDB 4.2.8"
PPG12_DESC="Percona Distribution for PostgreSQL 12"
PPG12_2_DESC="Percona Distribution for PostgreSQL 12.2"
PPG12_3_DESC="Percona Distribution for PostgreSQL 12.3"
PDPXC80_19_DESC="Percona Distribution for MySQL 8.0.19 - PXC"
PDPS80_19_DESC="Percona Distribution for MySQL 8.0.19 - PS"
PDPS80_20_DESC="Percona Distribution for MySQL 8.0.20 - PS"
PDPS80_DESC="Percona Distribution for MySQL 8.0 - PS"
PDPXC80_DESC="Percona Distribution for MySQL 8.0 - PXC"
PPG_DESC="Percona Distribution for PostgreSQL"
PDMDB_DESC="Percona Distribution for MongoDB"
PDPS_DESC="Percona Distribution for MySQL - PS"
PDPXC_DESC="Percona Distribution for MySQL - PXC"
#
PS56REPOS="ps-56 tools"
PS57REPOS="ps-57 pxb-24"
PS80REPOS="ps-80 tools"
PXC56REPOS="pxc-56 tools"
PXC57REPOS="pxc-57 pxb-24"
PXC80REPOS="pxc-80 tools"
PXB24REPOS="pxb-24"
PXB80REPOS="pxb-80"
PSMDB36REPOS="psmdb-36 pbm"
PSMDB40REPOS="psmdb-40 tools"
PSMDB42REPOS="psmdb-42 tools"
PPG11REPOS="ppg-11"
PPG11_5_REPOS="ppg-11.5"
PPG11_6_REPOS="ppg-11.6"
PPG11_7_REPOS="ppg-11.7"
PPG11_8_REPOS="ppg-11.8"
PDMDB4_2_6_REPOS="pdmdb-4.2.6"
PDMDB4_2_7_REPOS="pdmdb-4.2.7"
PDMDB4_2_8_REPOS="pdmdb-4.2.8"
PDMDB4_2_REPOS="pdmdb-4.2"
PPG12_REPOS="ppg-12"
PPG12_2_REPOS="ppg-12.2"
PPG12_3_REPOS="ppg-12.3"
PDPS80_REPOS="pdps-8.0"
PDPXC80_REPOS="pdpxc-8.0"
PDPS80_19_REPOS="pdps-8.0.19"
PDPS80_20_REPOS="pdps-8.0.20"
PDPXC80_19_REPOS="pdpxc-8.0.19"
PREL_REPOS="prel"
PROXYSQL_REPOS="proxysql"
SYSBENCH_REPOS="sysbench"
PT_REPOS="pt"
MYSQL_SHELL_REPOS="mysql-shell"
PBM_REPOS="PBM"
PMM_CLIENT_REPOS="pmm-client"
PMM2_CLIENT_REPOS="pmm2-client"
TOOLS_REPOS="tools"
ORIGINAL_REPO="original"
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
  echo "==>> ERROR: Unsupported operating system"
  exit 1
fi
#
function show_enabled {
  echo "The following repositories are enabled on your system:"
  if [[ -f /etc/redhat-release ]] || [[ -f /etc/system-release ]]; then
    for line in $(yum repolist enabled | egrep -ie "percona|sysbench|proxysql|pmm" | awk '{print $1}' | awk -F'/' '{print $1}' ); do 
      count=$(grep -o '-' <<< $line | wc -l)
      if [[ $count = 3 ]]; then
        echo $line | awk -F '-' '{print $1"-"$2,"- "$3,"| "$4}'
      else
        echo $line | awk -F '-' '{print $1" - "$2" | " $3}'
      fi
    done
  elif [[ -f /etc/debian_version ]]; then
    grep -E '^deb\s' /etc/apt/sources.list /etc/apt/sources.list.d/*.list | cut -f2- -d: | grep percona | awk '{print $2$4}' | sed 's;http://repo.percona.com/;;g' | sed 's;/apt; - ;g' | sed 's;percona;original;g' | sed 's;main;release;g'
  else
    echo "==>> ERROR: Unsupported operating system"
    exit 1
  fi
}
#
function is_supported_arch {
  local arch=$1

  for _arch in ${SUPPORTED_ARCHS}; do
        [[ ${_arch} = ${arch} ]] && return
  done
  return 1
}

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
  [[ -z ${1} ]] && echo "ERROR: No repository specified!" && show_help && exit 2
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
function check_os_support {
   REPO_NAME=$1
   if [[ ${PKGTOOL} = yum ]]; then
    if [ -f /etc/os-release ]; then
      OS_VER=$(grep VERSION_ID= /etc/os-release | awk -F'"' '{print $2}' | awk -F'.' '{print $1}')
    else
      OS_VER=$(cat /etc/system-release | awk '{print $(NF-1)}' | awk -F'.' '{print $1}')
    fi
    reply=$(curl -Is http://repo.percona.com/${REPO_NAME}/yum/release/${OS_VER}/ | head -n 1 | awk '{print $2}')
  elif [[ ${PKGTOOL} = "apt-get" ]]; then
    OS_VER=$(lsb_release -sc)
    reply=$(curl -Is http://repo.percona.com/${REPO_NAME}/apt/dists/${OS_VER}/ | head -n 1 | awk '{print $2}')
  fi
  if [[ ${reply} != 200 ]]; then
      echo "Specified repository is not supported for current operating system!"
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
  [[ -z ${REPO_NAME} ]] && return 0
  [[ ${REPO_NAME} == "original" ]] && REPO_NAME=percona
  [[ ${REPO_NAME} == "all" ]] && return 0
  if [ ${REPO_NAME} != "mysql-shell" -a ${REPO_NAME} != "pmm-client" -a ${REPO_NAME} != "pmm2-client" -a ${REPO_NAME} != "pmm2-components" ]; then
    REPO_NAME=$(echo ${REPO_NAME} | sed 's/-//' | sed 's/\([0-9]\)/-\1/')
  fi
  REPO_LINK="http://repo.percona.com/${REPO_NAME}/"
  reply=$(curl -Is ${REPO_LINK} | head -n 1 | awk '{print $2}')
  if [[ ${reply} == 200 ]]; then
    if [[ ${REPOSITORIES} != "*${REPONAME}*" ]]; then
      REPO_ALIAS=$(echo ${REPO_NAME} | sed 's/-//')
      ALIASES="${REPOSITORIES} ${REPO_ALIAS}"
      REPOSITORIES="${REPOSITORIES} ${REPO_NAME}"
      check_os_support ${REPO_NAME}
    fi
  else
    echo "Specified repository does not exist: ${REPO_LINK}"
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
  echo "Usage:     $(basename ${0}) enable | enable-only | setup | disable (<REPO> | all) [COMPONENT] | show"
  echo "  Example: $(basename ${0}) enable tools release"
  echo "  Example: $(basename ${0}) enable-only ps-80 experimental"
  echo "  Example: $(basename ${0}) setup ps57 | setup-57"
  echo "  Example: $(basename ${0}) setup -y ps57 | setup -y ps-57"
  echo "  Example: $(basename ${0}) show"
  echo
  echo "-> Available commands:       ${COMMANDS}"
  echo "-> Available setup products: ${ALIASES}"
  echo "-> Available repositories:   ${REPOSITORIES}"
  echo "-> Available components:     ${COMPONENTS}"
  echo "=> The \"-y\" option for the setup command automatically answers \"yes\" for all interactive questions."
  echo "=> The \"show\" command will list all enabled Percona repos on the system."
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
  ARCH_LIST="${ARCH} sources"
  [[ ${1} = "original" ]] && _repo=percona && ARCH_LIST="${ARCH} noarch sources"
  [[ ${1} = "prel" ]] && ARCH_LIST="noarch"
  for _key in ${ARCH_LIST}; do
    if ! is_supported_arch "$_key"; then
      echo "WARNING: Skipping ${_key} architecture, as it's not supported"
      continue
    fi

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
    if [[ ${_repo} = percona-original ]]; then
      [[ -f ${LOCATION}/percona-percona-${_component}.${EXT} ]] && _repo="percona-percona"
    elif [[  ${_repo} = percona-percona ]]; then
      [[ -f ${LOCATION}/percona-original-${_component}.${EXT} ]] && _repo="percona-original"
    fi
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
  if [[ ${1} = all ]]; then
    for REPO_FILE in $(find ${LOCATION} -type f -iname "percona*.${EXT}" -not -iname "*prel-release*"); do
      mv -f ${REPO_FILE} ${REPO_FILE}.bak 2>/dev/null
    done
  elif [[ -z ${2} ]]; then
    for comp in testing experimental; do
      mv -f ${LOCATION}/${_repo}-${comp}.${EXT} ${LOCATION}/${_repo}-${comp}.${EXT}.bak 2>/dev/null
    done
    if [[ ${_repo} != *prel ]]; then
      mv -f ${LOCATION}/${_repo}-release.${EXT} ${LOCATION}/${_repo}-release.${EXT}.bak 2>/dev/null
    fi
  else
    check_specified_component ${2}
    if [[ ${_repo} != *prel ]]; then
      mv -f ${LOCATION}/${_repo}-${2}.${EXT} ${LOCATION}/${_repo}-${2}.${EXT}.bak 2>/dev/null
    else
      if [[ ${2} != "release" ]]; then
        mv -f ${LOCATION}/${_repo}-${2}.${EXT} ${LOCATION}/${_repo}-${2}.${EXT}.bak 2>/dev/null
      fi
    fi
  fi
}
#
function enable_repository {
  check_specified_repo ${1}
  [[ ${1} = "ps-56" ]]    && DESCRIPTION=${PS56_DESC}
  [[ ${1} = "ps-57" ]]    && DESCRIPTION=${PS57_DESC}
  [[ ${1} = "ps-80" ]]    && DESCRIPTION=${PS80_DESC}
  [[ ${1} = "pxc-56" ]]   && DESCRIPTION=${PXC56_DESC}
  [[ ${1} = "pxc-57" ]]   && DESCRIPTION=${PXC57_DESC}
  [[ ${1} = "pxc-80" ]]   && DESCRIPTION=${PXC80_DESC}
  [[ ${1} = "pxb-24" ]]   && DESCRIPTION=${PXB24_DESC}
  [[ ${1} = "pxb-80" ]]   && DESCRIPTION=${PXB80_DESC}
  [[ ${1} = "psmdb-36" ]]  && DESCRIPTION=${PSMDB36_DESC}
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
  [[ ${1} = "pdmdb-4.2.8" ]]    && DESCRIPTION=${PDMDB4_2_8_DESC}
  [[ ${1} = "ppg-12" ]]    && DESCRIPTION=${PPG12_DESC}
  [[ ${1} = "ppg-12.2" ]]    && DESCRIPTION=${PPG12_2_DESC}
  [[ ${1} = "ppg-12.3" ]]    && DESCRIPTION=${PPG12_3_DESC}
  [[ ${1} = "pdps-8.0" ]]    && DESCRIPTION=${PDPS80_DESC}
  [[ ${1} = "pdpxc-8.0" ]]    && DESCRIPTION=${PDPXC80_DESC}
  [[ ${1} = "pdps-8.0.19" ]]    && DESCRIPTION=${PDMYSQL80_19_DESC}
  [[ ${1} = "pdps-8.0.20" ]]    && DESCRIPTION=${PDMYSQL80_20_DESC}
  [[ ${1} = "pdpxc-8.0.19" ]]    && DESCRIPTION=${PDPXC80_19_DESC}
  [[ ${1} = "prel" ]]    && DESCRIPTION=${PREL_DESC}
  [[ ${1} = "proxysql" ]]    && DESCRIPTION=${PROXYSQL_DESC}
  [[ ${1} = "sysbench" ]]    && DESCRIPTION=${SYSBENCH_DESC}
  [[ ${1} = "pt" ]]    && DESCRIPTION=${PT_DESC}
  [[ ${1} = "pbm" ]]    && DESCRIPTION=${PBM_DESC}
  [[ ${1} = "mysql-shell" ]]    && DESCRIPTION=${MYSQL_SHELL_DESC}
  [[ ${1} = "pmm-client" ]]    && DESCRIPTION=${PMM_CLIENT_DESC}
  [[ ${1} = "pmm2-client" ]]    && DESCRIPTION=${PMM2_CLIENT_DESC}
  if [[ -z ${DESCRIPTION} ]]; then
    REPO_NAME=$(echo ${1} | sed 's/-//')
    name=$(echo ${REPO_NAME} | sed 's/[0-9].*//g')
    version=$(echo ${REPO_NAME} | sed 's/[a-z]*//g')
    if [[ $version != *.* ]] ; then
      version=$(echo $version | sed -r ':A;s|([0-9])([0-9]){1}|\1.\2|g')
    fi
    [[ ${name} == ppg* ]]    && DESCRIPTION="${PPG_DESC} $version"
    [[ ${name} == pdmdb* ]]    && DESCRIPTION="${PDMDB_DESC} $version"
    [[ ${name} == psmdb* ]]    && DESCRIPTION="${PSMDB_DESC} $version"
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
    disable_component all
  else
    check_specified_repo ${1}
    if [[ ${1} != "prel" ]]; then
      disable_component ${1} ${2}
    else
      if [[ ${2} != "release" ]]; then
        disable_component ${1} ${2}
      fi
    fi
  fi
  MODIFIED=YES
}
#
function disable_dnf_module {
  REPO_NAME=${1}
  MODULE="mysql"
  PRODUCT="Percona-Server"
  if [[ ${REPO_NAME} == ppg* ]]; then
    MODULE="postgresql llvm-toolset"
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
      echo "On Red Hat 8 systems it is needed to disable the following DNF module(s): ${MODULE}  to install ${PRODUCT}"
      read -r -p "Do you want to disable it? [y/N] " response
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
      then
        echo "Disabling dnf module..."
        dnf -y module disable ${MODULE}
        echo "DNF ${MODULE} module was disabled"
      else
        echo "Please note that some packages might be unavailable as packages that aren't included into DNF module are filtered"
        echo "If in the future you decide to disable module(s) please execute the next command:"
        echo "  dnf module disable ${MODULE}"
      fi
    else
      echo "On Red Hat 8 systems it is needed to disable the following DNF module(s): ${MODULE}  to install ${PRODUCT}"
      echo "Disabling DNF module..."
      dnf -y module disable ${MODULE}
      echo "DNF ${MODULE} module was disabled"
    fi
  fi
}
#
function enable_alias {
  local REPOS=""
  local NAME=$( echo ${1} | sed 's/-//' )
  check_specified_alias ${NAME}
  [[ ${NAME} = ps56 ]] && REPOS=${PS56REPOS:-}
  [[ ${NAME} = ps57 ]] && REPOS=${PS57REPOS:-}
  [[ ${NAME} = ps80 ]] && REPOS=${PS80REPOS:-}
  [[ ${NAME} = pxc56 ]] && REPOS=${PXC56REPOS:-}
  [[ ${NAME} = pxc57 ]] && REPOS=${PXC57REPOS:-}
  [[ ${NAME} = pxc80 ]] && REPOS=${PXC80REPOS:-}
  [[ ${NAME} = pxb24 ]] && REPOS=${PXB24REPOS:-}
  [[ ${NAME} = pxb80 ]] && REPOS=${PXB80REPOS:-}
  [[ ${NAME} = psmdb36 ]] && REPOS=${PSMDB36REPOS:-}
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
  [[ ${NAME} = pdmdb4.2.8 ]] && REPOS=${PDMDB4_2_8_REPOS:-}
  [[ ${NAME} = ppg12 ]] && REPOS=${PPG12_REPOS:-}
  [[ ${NAME} = ppg12.2 ]] && REPOS=${PPG12_2_REPOS:-}
  [[ ${NAME} = ppg12.3 ]] && REPOS=${PPG12_3_REPOS:-}
  [[ ${NAME} = pdps8.0 ]] && REPOS=${PDPS80_REPOS:-}
  [[ ${NAME} = pdps8.0.19 ]] && REPOS=${PDPS80_19_REPOS:-}
  [[ ${NAME} = pdps8.0.20 ]] && REPOS=${PDPS80_20_REPOS:-}
  [[ ${NAME} = pdpxc8.0 ]] && REPOS=${PDPXC80_REPOS:-}
  [[ ${NAME} = pdpxc8.0.19 ]] && REPOS=${PDPXC80_19_REPOS:-}
  [[ ${NAME} = prel ]] && REPOS=${PREL_REPOS:-}
  [[ ${NAME} = proxysql ]] && REPOS=${PROXYSQL_REPOS:-}
  [[ ${NAME} = sysbench ]] && REPOS=${SYSBENCH_REPOS:-}
  [[ ${NAME} = pt ]] && REPOS=${PT_REPOS:-}
  [[ ${NAME} = pbm ]] && REPOS=${PBM_REPOS:-}
  [[ ${NAME} = mysqlshell ]] && REPOS=${MYSQL_SHELL_REPOS:-}
  [[ ${NAME} = pmmclient ]] && REPOS=${PMM_CLIENT_REPOS:-}
  [[ ${NAME} = pmm2client ]] && REPOS=${PMM2_CLIENT_REPOS:-}
  [[ ${NAME} = tools ]] && REPOS=${TOOLS_REPOS:-}
  [[ ${NAME} = original ]] && REPOS=${ORIGINAL_REPOS:-}
  [[ ${NAME} = percona ]] && REPOS=${ORIGINAL_REPOS:-}
  if [[ -z ${DESCRIPTION} ]]; then
    if [[ -z "${REPOS}" ]]; then
      name=$(echo ${NAME} | sed 's/[0-9].*//g')
      version=$(echo ${NAME} | sed 's/[a-z]*//g')
      [[ ${name} = "ppg" ]] && REPOS="$name-$version"
      [[ ${name} = "pdmdb" ]] && REPOS="$name-$version"
      [[ ${name} = "psmdb" ]] && REPOS="$name-$version"
      [[ ${name} = "pdps" ]] && REPOS="$name-$version"
      [[ ${name} = "pdpxc" ]] && REPOS="$name-$version"
    fi
  fi
  if [[ ${NAME} = ps80 ]] || [[ ${NAME} == pxc* ]] || [[ ${NAME} == ppg* ]] || [[ ${NAME} == pdps* ]] || [[ ${NAME} == pdpxc* ]]; then
    disable_dnf_module ${NAME}
  fi
  for _repo in ${REPOS}; do
    if [[ -z $(echo ${REPOSITORIES} | grep -o ${_repo}) ]]; then
      echo "ERROR: Selected product uses \"${REPOS}\" repositories. But the \"${_repo}\" repository is disabled"
      echo "Add \"${_repo}\" repository to REPOSITORIES=\"\" variable in /etc/default/percona-release file and re-run the script"
      exit 1
    fi
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
    check_specified_alias ${@##-*}
    echo "* Disabling all Percona Repositories"
    disable_repository all all
    enable_alias ${@##-*}
    ;;
  disable )
    shift
    disable_repository $@
    ;;
  show )
    shift
    show_enabled
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
