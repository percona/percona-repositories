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

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

append_arg_to_args () {
  args="$args "$(shell_quote_string "$1")
}

parse_arguments() {
    pick_args=
    if test "$1" = PICK-ARGS-FROM-ARGV
    then
        pick_args=1
        shift
    fi

    for arg do
        val=$(echo "$arg" | sed -e 's;^--[^=]*=;;')
        case "$arg" in
            --user_name=*) USER_NAME="$val" ;;
            --repo_token=*) REPO_TOKEN="$val" ;;
            --help) show_help ;;
            *)
              if test -n "$pick_args"
              then
                  append_arg_to_args "$arg"
              fi
              ;;
        esac
    done
}

PRODUCTS_ABBREVIATIONS=("pdmdb" "pdps" "pdpxc" "pmm" "ppg11" "ppg12" "ppg13" "ppg14" "psmdb" "px")

function sort_array {
  ARRAY=$1
  local flagforabbr="pdmdb"
  PRODUCTS=()
  OTHER_PRODUCTS=()
  for element in ${ARRAY[@]}
    do
      counter=1
      for abbr in ${PRODUCTS_ABBREVIATIONS[@]}
        do
          if [[ "${element//-/}" =~ ^$abbr.*$ ]]; then
            if [[ $flagforabbr == $abbr ]]; then
              PRODUCTS+="$element "
            else
              flagforabbr=$abbr
              echo ${PRODUCTS}
              PRODUCTS=()
              PRODUCTS+="$element "
              break
            fi
          else
            if [[ $counter == ${#PRODUCTS_ABBREVIATIONS[@]} ]]; then
              OTHER_PRODUCTS+="$element "
            else
              counter=$((counter+1))
            fi
          fi
        done
    done
  echo -e ${PRODUCTS}
  echo -e ${OTHER_PRODUCTS}
}

function get_repos_from_site {
  if [ "${REPOSITORIES}" != "" ]; then
      return
  fi

  REPOSITORIES=$(curl -s ${URL} | tail -n +28  | grep href | grep -v https | awk -Fhref=\" '{print $2}' | awk -F\/ '{print $1}')
  if [ -z "$REPOSITORIES" ]; then
    REPOSITORIES="original ps-56 ps-57 ps-80 pxb-24 pxb-80 pxc-56 pxc-57 pxc-80 psmdb-36 psmdb-40 psmdb-42 tools ppg-11 ppg-11.5 ppg-11.6 ppg-11.7 ppg-11.8 ppg-12 ppg-12.2 ppg-12.3 pdmdb-4.2 pdmdb-4.2.6 pdmdb-4.2.7 pdmdb-4.2.8 pdps-8.0.19 pdpxc-8.0.19 pdps-8.0.20 pdps-8.0 pdpxc-8.0 prel telemetry proxysql sysbench pt mysql-shell pbm pmm-client pmm2-client pmm3-client pdmdb-4.4 pdmdb-4.4.0 psmdb-44"
  fi

  REPOSITORIES="${REPOSITORIES} ps-80-pro ps-84-pro psmdb-60-pro psmdb-70-pro ps-57-eol pxc-57-eol pxc-80-pro pxc-84-pro"
  REPOSITORIES="${REPOSITORIES/percona/original}"
  for repo in ${REPOSITORIES[@]}
    do
      if [[ ${repo} =~ ^mysql-shell$|^pmm-client$|^pmm2-client$|^pmm3-client$|^pmm2-components$ ]]; then
        ALIASES+="${repo} "
      else
        ALIASES+="${repo//-/} "
      fi
    done
  REPOSITORIES="${REPOSITORIES//$'\n'/ }"
}

COMMANDS="enable enable-silent enable-only setup disable show help"
COMPONENTS="release testing experimental"
REPOSITORIES=""
URL="http://repo.percona.com"
SUPPORTED_ARCHS="i386 noarch x86_64 aarch64 sources"

if [[ -f /etc/default/percona-release ]]; then
    source /etc/default/percona-release
fi

# Special proxy handling for cURL
CURL_PROXY=
CURL_EXEC=( /usr/bin/curl )
if [[ -n "${https_proxy}" ]] || [[ -n "${http_proxy}" ]] ||
   [[ -n "${HTTPS_PROXY}" ]] || [[ -n "${HTTP_PROXY}" ]]; then
    if [[ "${URL}" =~ ^https: ]]; then
        APT_PROXY_SCHEME=https
        CURL_PROXY="${https_proxy:-${HTTPS_PROXY}}"
    else
        APT_PROXY_SCHEME=http
        CURL_PROXY="${http_proxy:-${HTTP_PROXY}}"
    fi
    if [[ -n "${CURL_PROXY}" ]]; then
        CURL_EXEC=( /usr/bin/curl "--proxy" "${CURL_PROXY}" )
    fi
fi

#
DESCRIPTION=""
DEFAULT_REPO_DESC="Percona Packaging Repository"
PREL_DESC="Percona Release"
TELEMETRY_DESC="Percona Telemetry"
VALKEY_DESC="Percona Valkey"
PT_DESC="Percona Toolkit"
SYSBENCH_DESC="Sysbench"
PROXYSQL_DESC="Proxysql"
PBM_DESC="Percona Backup MongoDB"
MYSQL_SHELL_DESC="Percona MySQL Shell"
PMM_CLIENT_DESC="PMM Client"
PMM2_CLIENT_DESC="PMM2 Client"
PMM3_CLIENT_DESC="PMM3 Client"
PS56_DESC="Percona Server for MySQL 5.6"
PS57_DESC="Percona Server for MySQL 5.7"
PS80_DESC="Percona Server for MySQL 8.0"
PS80_PRO_DESC="Percona Server for MySQL 8.0 Pro"
PS57_EOL_DESC="Percona Server for MySQL 5.7 EOL"
PXC57_EOL_DESC="Percona XtraDB Cluster 5.7 EOL"
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
PDPS8X_INNOVATION_DESC="Percona Distribution for MySQL - PS 8x Innovation"
PS8X_INNOVATION_DESC="Percona Server for MySQL - PS 8x Innovation"
PXC8X_INNOVATION_DESC="Percona XtraDB Cluster 8x Innovation"
PDPXC8X_INNOVATION_DESC="Percona Distribution XtraDB Cluster 8x Innovation"
PXB8X_INNOVATION_DESC="Percona XtraBackup 8x Innovation"
PDPS9X_INNOVATION_DESC="Percona Distribution for MySQL - PS 9x Innovation"
PS9X_INNOVATION_DESC="Percona Server for MySQL - PS 9x Innovation"
PXC9X_INNOVATION_DESC="Percona XtraDB Cluster 9x Innovation"
PDPXC9X_INNOVATION_DESC="Percona Distribution XtraDB Cluster 9x Innovation"
PXB9X_INNOVATION_DESC="Percona XtraBackup 9x Innovation"
PS_DESC="Percona Server for MySQL - PS"
PDPXC_DESC="Percona Distribution for MySQL - PXC"
#
PS56REPOS="ps-56 tools"
PS57REPOS="ps-57 pxb-24"
PS80REPOS="ps-80 tools"
PS57EOLREPOS="ps-57-eol"
PXC57EOLREPOS="pxc-57-eol"
PS80PROREPOS="ps-80-pro"
PXC56REPOS="pxc-56 tools"
PXC57REPOS="pxc-57 pxb-24"
PXC80REPOS="pxc-80 tools"
PXB24REPOS="pxb-24"
PXB80REPOS="pxb-80"
PSMDB36REPOS="psmdb-36 pbm"
PSMDB40REPOS="psmdb-40 tools"
PSMDB42REPOS="psmdb-42 tools"
PSMDB60PROREPOS="psmdb-60-pro"
PSMDB70PROREPOS="psmdb-70-pro"
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
PDPS8X_INNOVATION_REPOS="pdps-8x-innovation"
PS8X_INNOVATION_REPOS="ps-8x-innovation"
PS84_LTS_REPOS="ps-84-lts"
PDPS84_LTS_REPOS="pdps-84-lts"
PXC8X_INNOVATION_REPOS="pxc-8x-innovation"
PXC84_LTS_REPOS="pxc-84-lts"
PDPXC8X_INNOVATION_REPOS="pdpxc-8x-innovation"
PDPXC84_LTS_REPOS="pdpxc-84-lts"
PXB8X_INNOVATION_REPOS="pxb-8x-innovation"
PXB84_LTS_REPOS="pxb-84-lts"
PDPS9X_INNOVATION_REPOS="pdps-9x-innovation"
PS9X_INNOVATION_REPOS="ps-9x-innovation"
PXC9X_INNOVATION_REPOS="pxc-9x-innovation"
PDPXC9X_INNOVATION_REPOS="pdpxc-9x-innovation"
PXB9X_INNOVATION_REPOS="pxb-9x-innovation"
PDPXC80_REPOS="pdpxc-8.0"
PDPS80_19_REPOS="pdps-8.0.19"
PDPS80_20_REPOS="pdps-8.0.20"
PDPXC80_19_REPOS="pdpxc-8.0.19"
PREL_REPOS="prel telemetry"
PROXYSQL_REPOS="proxysql"
SYSBENCH_REPOS="sysbench"
PT_REPOS="pt"
MYSQL_SHELL_REPOS="mysql-shell"
PBM_REPOS="PBM"
PMM_CLIENT_REPOS="pmm-client"
PMM2_CLIENT_REPOS="pmm2-client"
PMM3_CLIENT_REPOS="pmm3-client"
TOOLS_REPOS="tools"
ORIGINAL_REPOS="original"
#
AUTOUPDATE=NO
MODIFIED=NO
REPOFILE=""
#          RH derivatives      and          Amazon Linux
if [[ -f /etc/redhat-release ]] || [[ -f /etc/system-release ]]; then
  LOCATION=/etc/yum.repos.d
  EXT=repo
  PKGTOOL=dnf
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
    for line in $(dnf repolist enabled | egrep -ie "percona|sysbench|proxysql|pmm" | awk '{print $1}' | awk -F'/' '{print $1}' ); do
      count=$(grep -o '-' <<< $line | wc -l)
      if [[ $count = 3 ]]; then
        echo $line | awk -F '-' '{print $1"-"$2,"- "$3,"| "$4}'
      else
        echo $line | awk -F '-' '{print $1" - "$2" | " $3}'
      fi
    done
  elif [[ -f /etc/debian_version ]]; then
    grep -E '^deb\s' /etc/apt/sources.list /etc/apt/sources.list.d/*.list | cut -f2- -d: | grep "${URL/http*:\/\//}" | awk '{print $3$5}' | sed "s;${URL}/;;g" | sed 's;/apt; - ;g' | sed 's;percona;original;g' | sed 's;main;release;g'
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
    # Ignore alias in case of -pro repos
    [[ ${NAME} == *pro ]] && found=YES
    [[ ${NAME} == *eol ]] && found=YES
    [[ ${NAME} == *innovation ]] && found=YES
    [[ ${NAME} == *lts ]] && found=YES
    [[ ${_alias} = ${NAME} ]] && found=YES
  done
  if [[ ${found} = NO ]]; then
    echo "ERROR: Unknown alias specification: ${1}"
    echo "Available product aliases are: ${ALIASES}"
    exit 2
  fi
}

function read_credentials_from_config {

  config_file="${HOME}/.percona-private-repos.config"

  section_name=$1

  # Check if section_name is provided
  if [ -z "$section_name" ]; then
    echo "Usage: $0 <section_name>"
    exit 1
  fi

  # Check if the config file exists
  if [ ! -f "$config_file" ]; then
    echo "Config file not found: $config_file"
    exit 1
  fi

  # Read the specified section from the config file
  section_content=$(awk -v section="$section_name" '/^\[/{flag=0} /^\['"$section_name"'\]/{flag=1;next} flag' "$config_file")

  # Check if the section exists
  if [ -z "$section_content" ]; then
    echo "Section not found: [$section_name]"
    exit 1
  fi

  # Parse the section content and export variables
  while IFS= read -r line; do
    if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
        export "$line"
    fi
  done <<< "$section_content"
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

  if [[ "${REPO_NAME}" == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
    if [[ -z ${USER_NAME} ]] || [[ -z ${REPO_TOKEN} ]]; then
      echo -e "ERROR: ${REPO_NAME} requires user_name and repo_token for ${REPO_NAME} repository. Either pass credentials using --user_name and --repo_token switches or create file ${HOME}/.percona-private-repos.config with following values:\n\n[${REPO_NAME}]\nUSER_NAME=<Your PRO repository user name>\nREPO_TOKEN=<Your PRO repository token>" && exit 2
    fi
  fi
}

#
function check_os_support {
   REPO_NAME=$1
   COMPONENT=$2
   if [[ ${PKGTOOL} = dnf ]]; then
    if [ -f /etc/os-release ]; then
      OS_VER=$(grep VERSION_ID= /etc/os-release | awk -F'"' '{print $2}' | awk -F'.' '{print $1}')
    else
      OS_VER=$(cat /etc/system-release | awk '{print $(NF-1)}' | awk -F'.' '{print $1}')
    fi

    if [[ ${REPO_NAME} == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
      [[ -z ${USER_NAME} ]] && echo -e "ERROR: ${REPO_NAME} requires user_name for ${REPO_NAME} repository. Use --user_name switch to pass user name" && exit 2
      [[ -z ${REPO_TOKEN} ]] && echo -e "ERROR: ${REPO_NAME} requires repo_token for ${REPO_NAME} repository. Use --repo_token switch to pass repository token" && exit 2
    fi

    if [[ ${REPO_NAME} == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
      if [[ ${OS_VER} == 2023 ]]; then
        reply=$("${CURL_EXEC[@]}" -Is http://repo.percona.com/private/${USER_NAME}-${REPO_TOKEN}/${REPO_NAME}/yum/${COMPONENT}/${OS_VER}/ | head -n 1 | awk '{print $2}')
      else
        reply=$("${CURL_EXEC[@]}" -Is http://repo.percona.com/private/${USER_NAME}-${REPO_TOKEN}/${REPO_NAME}/yum/release/${OS_VER}/ | head -n 1 | awk '{print $2}')
      fi
    else
      if [[ ${OS_VER} == 2023 ]]; then
        reply=$("${CURL_EXEC[@]}" -Is http://repo.percona.com/${REPO_NAME}/yum/${COMPONENT}/${OS_VER}/ | head -n 1 | awk '{print $2}')
      else
        reply=$("${CURL_EXEC[@]}" -Is http://repo.percona.com/${REPO_NAME}/yum/release/${OS_VER}/ | head -n 1 | awk '{print $2}')
      fi
    fi
  elif [[ ${PKGTOOL} = "apt-get" ]]; then
    OS_VER=$(lsb_release -sc)
    if [[ ${REPO_NAME} == *-pro ]] || [[ ${REPO_NAME} == *-eol ]]; then
      reply=$("${CURL_EXEC[@]}" -Is http://repo.percona.com/private/${USER_NAME}-${REPO_TOKEN}/${REPO_NAME}/apt/dists/${OS_VER}/ | head -n 1 | awk '{print $2}')
    else
      reply=$("${CURL_EXEC[@]}" -Is http://repo.percona.com/${REPO_NAME}/apt/dists/${OS_VER}/ | head -n 1 | awk '{print $2}')
    fi
  fi
  if [[ ${reply} != 200 ]]; then
      if [[ ${REPO_NAME} == *-pro ]] || [[ ${REPO_NAME} == *-eol ]]; then
        echo "Specified repository ($REPO_NAME) is not supported for current operating system or check your credentials."
      else
        echo "Specified repository is not supported for current operating system!"
      fi
      exit 2
  fi
}
#
function check_repo_availability {
  if [[ "$2" == "-y" ]]; then
    REPO_NAME=${3}
    COMPONENT=${4}
  else
    REPO_NAME=${2}
    COMPONENT=${3}
  fi

  if [[ -z ${COMPONENT} ]] || [[ ${COMPONENT} == *"--user_name="* ]] || [[ ${COMPONENT} == *"--repo_token="* ]]; then
    COMPONENT="release"
  fi

  if [[ "${REPO_NAME}" == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
    if [ -f "${HOME}/.percona-private-repos.config" ]; then
      read_credentials_from_config ${REPO_NAME}
    else
      parse_arguments PICK-ARGS-FROM-ARGV "$@"
    fi
  fi

  if [[ "${REPO_NAME}" == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
        if [[ -z ${USER_NAME} ]] || [[ -z ${REPO_TOKEN} ]]; then
          echo -e "ERROR: ${REPO_NAME} requires user_name and repo_token for ${REPO_NAME} repository. Either pass credentials using --user_name and --repo_token switches or create file ${HOME}/.percona-private-repos.config with following values:\n\n[${REPO_NAME}]\nUSER_NAME=<Your PRO repository user name>\nREPO_TOKEN=<Your PRO repository token>" && exit 2
        fi
  fi

  if [[ -z ${COMPONENT} ]] || [[ ${COMPONENT} == *"user_name="* ]] || [[ ${COMPONENT} == *"repo_token="* ]]; then
     COMPONENT="release"
  fi
  [[ -z ${REPO_NAME} ]] && return 0
  [[ ${REPO_NAME} == "original" ]] && REPO_NAME=percona
  [[ ${REPO_NAME} == "all" ]] && return 0
  if ! [[ ${REPO_NAME} =~ ^mysql-shell$|^pmm-client$|^pmm2-client$|^pmm3-client$|^pmm2-components$ ]]; then
    REPO_NAME=$(echo ${REPO_NAME} | sed 's/-//' | sed 's/\([0-9]\)/-\1/')
  fi
  if [[ ${REPO_NAME} == *xinnovation ]]; then
    REPO_NAME=$(echo ${REPO_NAME} | sed 's/innovation/-innovation/' )
  fi
  if [[ ${REPO_NAME} == *4lts ]]; then
    REPO_NAME=$(echo ${REPO_NAME} | sed 's/lts/-lts/' )
  fi

  if [[ ${REPO_NAME} == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
    [[ -z ${USER_NAME} ]] && echo -e "ERROR: ${REPO_NAME} requires user_name for ${REPO_NAME} repository. Use --user_name switch to pass user name" && exit 2
    [[ -z ${REPO_TOKEN} ]] && echo -e "ERROR: ${REPO_NAME} requires repo_token for ${REPO_NAME} repository. Use --repo_token switch to pass repository token" && exit 2
    REPO_LINK="http://repo.percona.com/private/${USER_NAME}-${REPO_TOKEN}/${REPO_NAME}/"
  else
    REPO_LINK="http://repo.percona.com/${REPO_NAME}/"
  fi
  reply=$("${CURL_EXEC[@]}" -Is ${REPO_LINK} | head -n 1 | awk '{print $2}')
  if [[ ${reply} == 200 ]]; then
    if [[ ${REPOSITORIES} != "*${REPO_NAME}*" ]]; then
      REPO_ALIAS=$(echo ${REPO_NAME} | sed 's/-//')
      ALIASES="${REPOSITORIES} ${REPO_ALIAS}"
      REPOSITORIES="${REPOSITORIES} ${REPO_NAME}"
      check_os_support ${REPO_NAME} ${COMPONENT}
    fi
  else
    if [[ ${REPO_NAME} == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
      echo "Specified repository does not exist: ${REPO_LINK} or check your repository credentials"
    else
      echo "Specified repository does not exist: ${REPO_LINK}"
    fi
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
  echo "Usage:     $(basename ${0}) enable | enable-silent | enable-only | setup | disable (<REPO> | all) [COMPONENT] | show"
  echo "  Example: $(basename ${0}) enable tools release"
  echo "  Example: $(basename ${0}) enable-only ps-80 experimental"
  echo "  Example: $(basename ${0}) setup ps57 | ps-57"
  echo "  Example: $(basename ${0}) setup -y ps57 | setup -y ps-57"
  echo "  Example: $(basename ${0}) show"
  echo "  Example: $(basename ${0}) enable ps-80-pro release --user_name=<User Name> --repo_token=<Pro repository token>"
  echo "  Example: $(basename ${0}) enable-only ps-80 experimental --user_name=<User Name> --repo_token=<Pro repository token>"
  echo "  Example: $(basename ${0}) setup ps-80-pro --user_name=<User Name> --repo_token=<Pro repository token>"
  echo "  Example: $(basename ${0}) setup -y ps-80-pro --user_name=<User Name> --repo_token=<Pro repository token>"
  echo
  echo "Available commands:          ${COMMANDS}"
  echo
  echo "Available setup products:    "
  sort_array "${ALIASES} ps-80-pro psmdb-70-pro psmdb-60-pro"
  echo
  echo "Available repositories:      "
  sort_array "${REPOSITORIES} ps-80-pro psmdb-70-pro psmdb-60-pro"
  echo
  echo "Available components:        ${COMPONENTS}"
  echo
  echo "The \"-y\" option for the setup command automatically answers \"yes\" for all interactive questions."
  echo "The \"show\" command will list all enabled Percona repos on the system."
  echo "Please see percona-release page for help: https://docs.percona.com/percona-software-repositories/percona-release.html"
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
  if [ -f /etc/os-release ]; then
      OS_VER=$(grep VERSION_ID= /etc/os-release | awk -F'"' '{print $2}' | awk -F'.' '{print $1}')
  fi
  ARCH_LIST="${ARCH} sources"
  [[ ${1} = "original" ]] && _repo=percona && ARCH_LIST="${ARCH} noarch sources"
  [[ ${1} = "prel" ]] && ARCH_LIST="noarch"
  [[ ${1} = "telemetry" ]] && ARCH_LIST="${ARCH} sources"
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

    if [[ ${_repo} == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
      [[ -z ${USER_NAME} ]] && echo -e "ERROR: ${REPO_NAME} requires user_name for ${REPO_NAME} repository. Use --user_name switch to pass user name" && exit 2
      [[ -z ${REPO_TOKEN} ]] && echo -e "ERROR: ${REPO_NAME} requires repo_token for ${REPO_NAME} repository. Use --repo_token switch to pass repository token" && exit 2
      echo "baseurl = ${URL}/private/${USER_NAME}-${REPO_TOKEN}/${_repo}/yum/${2}/\$releasever/${DIR}${rPATH}" >> ${REPOFILE}
    else
      echo "baseurl = ${URL}/${_repo}/yum/${2}/\$releasever/${DIR}${rPATH}" >> ${REPOFILE}
    fi
    echo "enabled = ${ENABLE}" >> ${REPOFILE}
    echo "gpgcheck = 1" >> ${REPOFILE}
    if [[ ${OS_VER} == 2023 ]]; then
      sed -i 's/$releasever/2023/g' /etc/yum.repos.d/percona*.repo
    fi
    [[ -n "${CURL_PROXY}" ]] && echo "proxy = ${CURL_PROXY}" >> ${REPOFILE}
    echo "gpgkey = file:///etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY" >> ${REPOFILE}
    echo >> ${REPOFILE}
  done
}
#
function create_apt_repo {
  local _repo=${1}
  local _proxyline=

  [[ ${1} = "original" ]] && _repo=percona
  REPOURL="${URL}/${_repo}/apt ${CODENAME}"

  if [[ ${_repo} == *-pro ]] || [[ "${REPO_NAME}" == *-eol ]]; then
    [[ -z ${USER_NAME} ]] && echo -e "ERROR: ${REPO_NAME} requires user_name for ${REPO_NAME} repository. Use --user_name switch to pass user name" && exit 2
    [[ -z ${REPO_TOKEN} ]] && echo -e "ERROR: ${REPO_NAME} requires repo_token for ${REPO_NAME} repository. Use --repo_token switch to pass repository token" && exit 2
    REPOURL="${URL}/private/${USER_NAME}-${REPO_TOKEN}/${_repo}/apt ${CODENAME}"
  fi

  if [[ -n "${CURL_PROXY}" ]]; then
      _proxyline="Acquire::${APT_PROXY_SCHEME}::Proxy::${URL/${APT_PROXY_SCHEME}:\/\//} \"${CURL_PROXY}\";"

      if [[ ! -f /etc/apt/apt.conf.d/99-percona-release ]] || ( ! grep -Rq "${_proxyline}" /etc/ ); then
          echo "${_proxyline}" >> /etc/apt/apt.conf.d/99-percona-release
      fi
  fi
  if [[ ${2} = release ]]; then
    _component=main
    echo "deb [signed-by=/usr/share/keyrings/percona-keyring.gpg] ${REPOURL} ${_component}" >> ${REPOFILE}
    echo "deb-src [signed-by=/usr/share/keyrings/percona-keyring.gpg] ${REPOURL} ${_component}" >> ${REPOFILE}
  else
    echo "deb [signed-by=/usr/share/keyrings/percona-keyring.gpg] ${REPOURL} ${_component}" >> ${REPOFILE}
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
    if [[ ${PKGTOOL} = dnf ]]; then
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
    for REPO_FILE in $(find ${LOCATION} -type f -iname "percona*.${EXT}" -not -iname "*prel-release*" -not -iname "*telemetry-release*"); do
      mv -f ${REPO_FILE} ${REPO_FILE}.bak 2>/dev/null
    done
  elif [[ -z ${2} ]]; then
    for comp in testing experimental; do
      mv -f ${LOCATION}/${_repo}-${comp}.${EXT} ${LOCATION}/${_repo}-${comp}.${EXT}.bak 2>/dev/null
    done
    if [[ ${_repo} != *prel && ${_repo} != *telemetry ]]; then
      mv -f ${LOCATION}/${_repo}-release.${EXT} ${LOCATION}/${_repo}-release.${EXT}.bak 2>/dev/null
    fi
  else
    check_specified_component ${2}
    if [[ ${_repo} != *prel && ${_repo} != *telemetry ]]; then
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
  [[ ${1} = "ps-80-pro" ]]    && DESCRIPTION=${PS80_PRO_DESC}
  [[ ${1} = "ps-57-eol" ]]    && DESCRIPTION=${PS57_EOL_DESC}
  [[ ${1} = "pxc-57-eol" ]]    && DESCRIPTION=${PXC57_EOL_DESC}
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
  [[ ${1} = "pdps-8x-innovation" ]]    && DESCRIPTION=${PDPS8X_INNOVATION_DESC}
  [[ ${1} = "ps-8x-innovation" ]]    && DESCRIPTION=${PS8X_INNOVATION_DESC}
  [[ ${1} = "ps-84-lts" ]]    && DESCRIPTION=${PS84_LTS_DESC}
  [[ ${1} = "pxc-8x-innovation" ]]    && DESCRIPTION=${PXC8X_INNOVATION_DESC}
  [[ ${1} = "pxc-84-lts" ]]    && DESCRIPTION=${PXC84_LTS_DESC}
  [[ ${1} = "pdpxc-8x-innovation" ]]    && DESCRIPTION=${PDPXC8X_INNOVATION_DESC}
  [[ ${1} = "pxb-8x-innovation" ]]    && DESCRIPTION=${PXB8X_INNOVATION_DESC}
  [[ ${1} = "pxb-84-lts" ]]    && DESCRIPTION=${PXB84_LTS_DESC}
  [[ ${1} = "pdps-9x-innovation" ]]    && DESCRIPTION=${PDPS9X_INNOVATION_DESC}
  [[ ${1} = "ps-9x-innovation" ]]    && DESCRIPTION=${PS9X_INNOVATION_DESC}
  [[ ${1} = "pxc-9x-innovation" ]]    && DESCRIPTION=${PXC9X_INNOVATION_DESC}
  [[ ${1} = "pdpxc-9x-innovation" ]]    && DESCRIPTION=${PDPXC9X_INNOVATION_DESC}
  [[ ${1} = "pxb-9x-innovation" ]]    && DESCRIPTION=${PXB9X_INNOVATION_DESC}
  [[ ${1} = "prel" ]]    && DESCRIPTION=${PREL_DESC}
  [[ ${1} = "telemetry" ]]    && DESCRIPTION=${TELEMETRY_DESC}
  [[ ${1} = "valkey" ]]    && DESCRIPTION=${VALKEY_DESC}
  [[ ${1} = "proxysql" ]]    && DESCRIPTION=${PROXYSQL_DESC}
  [[ ${1} = "sysbench" ]]    && DESCRIPTION=${SYSBENCH_DESC}
  [[ ${1} = "pt" ]]    && DESCRIPTION=${PT_DESC}
  [[ ${1} = "pbm" ]]    && DESCRIPTION=${PBM_DESC}
  [[ ${1} = "mysql-shell" ]]    && DESCRIPTION=${MYSQL_SHELL_DESC}
  [[ ${1} = "pmm-client" ]]    && DESCRIPTION=${PMM_CLIENT_DESC}
  [[ ${1} = "pmm2-client" ]]    && DESCRIPTION=${PMM2_CLIENT_DESC}
  [[ ${1} = "pmm3-client" ]]    && DESCRIPTION=${PMM3_CLIENT_DESC}
  if [[ -z ${DESCRIPTION} ]]; then
    REPO_NAME=$(echo ${1} | sed 's/-//')
    name=$(echo ${REPO_NAME} | sed 's/[0-9].*//g')
    version=$(echo ${REPO_NAME} | sed 's/[a-z]*//g')
    if [[ $version != *.* && $name != "ppg" ]] ; then
      version=$(echo $version | sed -r ':A;s|([0-9])([0-9]){1}|\1.\2|g')
    fi
    [[ ${name} == ppg* ]]    && DESCRIPTION="${PPG_DESC} $version"
    [[ ${name} == pdmdb* ]]    && DESCRIPTION="${PDMDB_DESC} $version"
    [[ ${name} == ps* ]]    && DESCRIPTION="${PS_DESC} $version"
    [[ ${name} == psmdb* ]]    && DESCRIPTION="${PSMDB_DESC} $version"
    [[ ${name} == pdps* ]]    && DESCRIPTION="${PDPS_DESC} $version"
    [[ ${name} == pdpxc* ]]    && DESCRIPTION="${PDPXC_DESC} $version"
  fi
  [[ -z ${DESCRIPTION} ]] && DESCRIPTION=${DEFAULT_REPO_DESC}
  echo "* Enabling the ${DESCRIPTION} repository"

  if [[ -z ${2} ]] || [[ ${2} == *"--user_name="* ]] || [[ ${2} == *"--repo_token="* ]]; then
    COMPONENT="release"
  else
    COMPONENT=${2}
  fi
  enable_component ${1} ${COMPONENT}
  MODIFIED=YES
}
#
function disable_repository {
  local _repos=${1}
  if [[ ${1} = all ]]; then
    disable_component all
  else
    check_specified_repo ${1}
    if [[ ${1} != "prel" && ${1} != "telemetry" ]]; then
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
function update_rpm {
  if [[ -f /usr/bin/dnf ]]; then
    RHEL=$(rpm --eval %rhel)
    UPDATES=$(dnf check-update rpm)
    if [ $? -eq 100 ]; then
      if [[ -f /usr/bin/dnf && ${RHEL} = 8 ]]; then
        RHEL=$(rpm --eval %rhel)
        if [[ ${INTERACTIVE} = YES ]]; then
          echo "On Red Hat 8 systems it is recommended to update rpm package to install ${PRODUCT}"
          read -r -p "Do you want to update it? [y/N] " response
          if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
          then
            dnf -y update rpm
          else
            echo "Please note that using an old version of rpm package can cause dependency issues or conflicts with existing packages."
            echo "If in the future you decide to update rpm package please execute the next command:"
            echo "  dnf update rpm"
          fi
        else
          echo "On Red Hat 8 systems it is recommended to update rpm package to install ${PRODUCT}"
          dnf -y update rpm
        fi
      fi
    fi
  fi
}
#
function check_enabled_modules {
  MOD="${1} ${2}"
  if [[ -f /usr/bin/dnf ]]; then
    for element in ${MOD[@]}
    do
      check_command=$(dnf -q module list --enabled | awk '{print $1}' | grep ${element})
      if [[ -n ${check_command} ]]; then
        ENABLED_MODULES=YES
        return
      fi
    done
  fi
  ENABLED_MODULES=NO
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
  check_enabled_modules ${MODULE}
  if [[ -f /usr/bin/dnf && ${ENABLED_MODULES} = YES ]]; then
    if [[ ${INTERACTIVE} = YES ]]; then
      echo "On Red Hat 8 and 9 systems it is needed to disable the following DNF module(s): ${MODULE}  to install ${PRODUCT}"
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
      echo "On Red Hat 8 and 9 systems it is needed to disable the following DNF module(s): ${MODULE}  to install ${PRODUCT}"
      echo "Disabling DNF module..."
      dnf -y module disable ${MODULE}
      echo "DNF ${MODULE} module was disabled"
    fi
  fi
}
#
function enable_alias {
  local REPOS=""
  if [[ ${1} != *-pro ]] && [[ ${1} != *-innovation ]] && [[ ${1} != *-eol  ]] && [[ ${1} != *-lts  ]]; then
    local NAME=$( echo ${1} | sed 's/-//' )
  else
    local NAME=${1}
  fi
  check_specified_alias ${NAME}
  if [[ ${NAME} == *xinnovation ]]; then
    NAME=$( echo ${NAME} | sed 's/innovation/-innovation/' )
  fi
  if [[ ${NAME} == *4lts ]]; then
    NAME=$(echo ${NAME} | sed 's/lts/-lts/' )
  fi
  [[ ${NAME} = ps56 ]] && REPOS=${PS56REPOS:-}
  [[ ${NAME} = ps57 ]] && REPOS=${PS57REPOS:-}
  [[ ${NAME} = ps80 ]] && REPOS=${PS80REPOS:-}
  [[ ${NAME} = ps57-eol ]] && REPOS=${PS57EOLREPOS:-}
  [[ ${NAME} = pxc57-eol ]] && REPOS=${PXC57EOLREPOS:-}
  [[ ${NAME} = ps80-pro ]] && REPOS=${PS80PROREPOS:-}
  [[ ${NAME} = psmdb60-pro ]] && REPOS=${PSMDB60PROREPOS:-}
  [[ ${NAME} = psmdb70-pro ]] && REPOS=${PSMDB70PROREPOS:-}
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
  [[ ${NAME} = pdps8x-innovation ]] && REPOS=${PDPS8X_INNOVATION_REPOS:-}
  [[ ${NAME} = ps8x-innovation ]] && REPOS=${PS8X_INNOVATION_REPOS:-}
  [[ ${NAME} = ps84-lts ]] && REPOS=${PS84_LTS_REPOS:-}
  [[ ${NAME} = pxc8x-innovation ]] && REPOS=${PXC8X_INNOVATION_REPOS:-}
  [[ ${NAME} = pxc84-lts ]] && REPOS=${PXC84_LTS_REPOS:-}
  [[ ${NAME} = pdpxc8x-innovation ]] && REPOS=${PDPXC8X_INNOVATION_REPOS:-}
  [[ ${NAME} = pdpxc84-lts ]] && REPOS=${PDPXC84_LTS_REPOS:-}
  [[ ${NAME} = pxb8x-innovation ]] && REPOS=${PXB8X_INNOVATION_REPOS:-}
  [[ ${NAME} = pxb84-lts ]] && REPOS=${PXB84_LTS_REPOS:-}
  [[ ${NAME} = pdps84-lts ]] && REPOS=${PDPS84_LTS_REPOS:-}
  [[ ${NAME} = pdps9x-innovation ]] && REPOS=${PDPS9X_INNOVATION_REPOS:-}
  [[ ${NAME} = ps9x-innovation ]] && REPOS=${PS9X_INNOVATION_REPOS:-}
  [[ ${NAME} = pxc9x-innovation ]] && REPOS=${PXC9X_INNOVATION_REPOS:-}
  [[ ${NAME} = pdpxc9x-innovation ]] && REPOS=${PDPXC9X_INNOVATION_REPOS:-}
  [[ ${NAME} = pxb9x-innovation ]] && REPOS=${PXB9X_INNOVATION_REPOS:-}
  [[ ${NAME} = prel ]] && REPOS=${PREL_REPOS:-}
  [[ ${NAME} = telemetry ]] && REPOS=${PREL_REPOS:-}
  [[ ${NAME} = proxysql ]] && REPOS=${PROXYSQL_REPOS:-}
  [[ ${NAME} = sysbench ]] && REPOS=${SYSBENCH_REPOS:-}
  [[ ${NAME} = pt ]] && REPOS=${PT_REPOS:-}
  [[ ${NAME} = pbm ]] && REPOS=${PBM_REPOS:-}
  [[ ${NAME} = mysqlshell ]] && REPOS=${MYSQL_SHELL_REPOS:-}
  [[ ${NAME} = pmmclient ]] && REPOS=${PMM_CLIENT_REPOS:-}
  [[ ${NAME} = pmm2client ]] && REPOS=${PMM2_CLIENT_REPOS:-}
  [[ ${NAME} = pmm3client ]] && REPOS=${PMM3_CLIENT_REPOS:-}
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
  if [[ ${NAME} = ps80 ]] || [[ ${NAME} == ps80-pro ]] || [[ ${NAME} == psmdb70-pro ]] || [[ ${NAME} == psmdb60-pro ]] || [[ ${NAME} == pxc* ]] || [[ ${NAME} == ppg* ]] || [[ ${NAME} == pdps* ]] || [[ ${NAME} == pdpxc* ]] || [[ ${NAME} == *innovation ]] || [[ ${NAME} == *lts ]]; then
    disable_dnf_module ${NAME}
    update_rpm ${NAME}
  fi
  for _repo in ${REPOS}; do
    if [[ -z $(echo ${REPOSITORIES} | grep -o ${_repo}) ]]; then
      echo "ERROR: Selected product uses \"${REPOS}\" repositories. But the \"${_repo}\" repository is disabled"
      echo "Add \"${_repo}\" repository to REPOSITORIES=\"\" variable in /etc/default/percona-release file and re-run the script"
      exit 1
    fi
    enable_repository ${_repo} $2
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
get_repos_from_site
#
if [[ ${COMMANDS} != *$(echo ${1} | sed 's/^--//g')* ]]; then
  echo "ERROR: Unknown action specified: ${1}"
  show_help
  exit 2
fi
#
check_repo_availability $@
case $(echo ${1} | sed 's/^--//g') in
  enable )
    shift
    enable_repository $@
    run_update
    ;;
  enable-silent )
    shift
    enable_repository $@
    ;;
  enable-only )
    shift
    echo "* Disabling all Percona Repositories"
    disable_repository all all
    enable_repository $@
    run_update
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
    run_update
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

