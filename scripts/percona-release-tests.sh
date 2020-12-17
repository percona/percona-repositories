#!/bin/bash
#
set -o xtrace
#
#          RH derivatives      and          Amazon Linux
if [[ -f /etc/redhat-release ]] || [[ -f /etc/system-release ]]; then
  LOCATION=/etc/yum.repos.d
  EXT=repo
elif [[ -f /etc/debian_version ]]; then
  LOCATION=/etc/apt/sources.list.d
  EXT=list
  CODENAME=$(lsb_release -sc)
else
  echo "==>> ERROR: Unsupported system"
  exit 1
fi
#
SCRIPT="percona-release.sh"
# this is linux-specific call
cd $(readlink -f $(dirname ${0}))
[[ ! -f ${SCRIPT} ]] && echo "* ${SCRIPT} is missing, exiting" && exit 1
#
TMPFILE=$(mktemp)
egrep '^ALIASES|^REPOSITORIES|^COMPONENTS|^P.*REPOS' ${SCRIPT} > ${TMPFILE}
source ${TMPFILE}
#
function cleanup_on_exit {
  ./percona-release.sh disable all all
  rm -fv ${LOCATION}/*.bak
  rm -fv ${TMPFILE}
}
trap cleanup_on_exit EXIT
#
function expect_repofile_created {
  set +x
  REPO=percona-${1}
  COMPONENT=${2}
  [[ ! -f ${LOCATION}/${REPO}-${COMPONENT}.${EXT} ]] && echo "* ERROR! Repo file for ${REPO}-${COMPONENT} has not been created!" && exit 1
  set -x
}
#
function expect_single_repo_enabled {
  set +x
  COUNT=$(ls -1 ${LOCATION}/percona-*.${EXT} 2>/dev/null | wc -l)
  [[ ${COUNT} -gt 1 ]] && echo "* ERROR! enable-only err: Additional repos are still enabled " && exit 1
  set -x
}
#
function expect_nothing_enabled {
  set +x
  for _repository in ${REPOSITORIES}; do
    for _component in ${COMPONENTS}; do
      REPO=percona-${_repository}
      COMPONENT=${_component}
      [[ -f ${LOCATION}/${REPO}-${COMPONENT}.${EXT} ]] && echo "* ERROR! Repo file exists for ${REPO}-${COMPONENT}" && exit 1
    done
  done
  set -x
}
#
function expect_repofile_deleted {
  REPO=percona-${1}
  COMPONENT=${2}
  [[ -f ${LOCATION}/${REPO}-${COMPONENT}.${EXT} ]] && echo "* ERROR! Repo file for ${REPO}-${COMPONENT} has not been disabled!" && exit 1
  [[ ! -f ${LOCATION}/${REPO}-${COMPONENT}.${EXT}.bak ]] && echo "* ERROR! Repo backup file for ${REPO}-${COMPONENT} has not been created!" && exit 1
}

function test_default_overrides {
    local -i file_exists=0
    local -r repo_url='https://repo.percona.com/test/'
    local -r repo_name="percona-original-release"
    local -r repo_file="${LOCATION}/${repo_name}.${EXT}"

    if [[ -f /etc/default/percona-release ]]; then
        file_exists=1
        mv -v /etc/default/percona-release /etc/default/percona-release.backupfortest
        printf 'URL="%s"\n' "${repo_url}" > /etc/default/percona-release
    fi

    ./${SCRIPT} enable-only original release
    if [[ "${file_exists}" -eq 1 ]]; then
        mv -v /etc/default/percona-release.backupfortest /etc/default/percona-release
    fi

    grep -Fq "${repo_url}" "${repo_file}" || {
        echo "* ERROR! Repo file for  ${repo_name} does not contain the override setting"
        exit 1
    }
}
####
###
##
# trying to test
##
###
####
#
./${SCRIPT} disable all all
expect_nothing_enabled
rm -fv ${LOCATION}/*.bak
#
for _repository in ${REPOSITORIES}; do
  for _component in ${COMPONENTS}; do
    ./${SCRIPT} enable ${_repository} ${_component}
    expect_repofile_created ${_repository} ${_component}
    ./${SCRIPT} disable ${_repository} ${_component}
    expect_repofile_deleted ${_repository} ${_component}
  done
done
#
./${SCRIPT} disable all all
rm -fv ${LOCATION}/*.bak
#
for _repository in ${REPOSITORIES}; do
  for _component in ${COMPONENTS}; do
    ./${SCRIPT} enable-only ${_repository} ${_component}
    expect_repofile_created ${_repository} ${_component}
    expect_single_repo_enabled
    ./${SCRIPT} disable ${_repository} ${_component}
    expect_repofile_deleted ${_repository} ${_component}
  done
done
#
./${SCRIPT} disable all all
rm -fv ${LOCATION}/*.bak
## Test for overrides
if [[ ! -d /etc/default ]]; then
    echo "WARNING: /etc/default does not exist"
else
    test_default_overrides
fi
./${SCRIPT} disable all all
rm -fv ${LOCATION}/*.bak
## End
#
for _alias in ${ALIASES}; do
  REPOS=""
  [[ ${_alias} = ps56 ]] && REPOS=${PS56REPOS:-}
  [[ ${_alias} = ps57 ]] && REPOS=${PS57REPOS:-}
  [[ ${_alias} = ps80 ]] && REPOS=${PS80REPOS:-}
  [[ ${_alias} = pxc56 ]] && REPOS=${PXC56REPOS:-}
  [[ ${_alias} = pxc57 ]] && REPOS=${PXC57REPOS:-}
  [[ ${_alias} = pxc80 ]] && REPOS=${PXC80REPOS:-}
  [[ ${_alias} = pxb24 ]] && REPOS=${PXB24REPOS:-}
  [[ ${_alias} = pxb80 ]] && REPOS=${PXB80REPOS:-}
  [[ ${_alias} = psmdb36 ]] && REPOS=${PSMDB36REPOS:-}
  [[ ${_alias} = psmdb40 ]] && REPOS=${PSMDB40REPOS:-}
  [[ ${_alias} = psmdb42 ]] && REPOS=${PSMDB42REPOS:-}
  [[ ${_alias} = ppg11 ]] && REPOS=${PPG11REPOS:-}
  [[ ${_alias} = ppg11.5 ]] && REPOS=${PPG11_5_REPOS:-}
  [[ ${_alias} = ppg11.6 ]] && REPOS=${PPG11_6_REPOS:-}
  [[ ${_alias} = ppg11.7 ]] && REPOS=${PPG11_7_REPOS:-}
  [[ ${_alias} = ppg11.8 ]] && REPOS=${PPG11_8_REPOS:-}
  [[ ${_alias} = pdmdb4.2.6 ]] && REPOS=${PDMDB_4_2_6_REPOS:-}
  [[ ${_alias} = pdmdb4.2.7 ]] && REPOS=${PDMDB_4_2_7_REPOS:-}
  [[ ${_alias} = pdmdb4.2.8 ]] && REPOS=${PDMDB_4_2_8_REPOS:-}
  [[ ${_alias} = pdmdb4.2 ]] && REPOS=${PDMDB_4_2_REPOS:-}
  [[ ${_alias} = ppg12 ]] && REPOS=${PPG12_REPOS:-}
  [[ ${_alias} = ppg12.2 ]] && REPOS=${PPG12_2_REPOS:-}
  [[ ${_alias} = ppg12.3 ]] && REPOS=${PPG12_3_REPOS:-}
  [[ ${_alias} = pdpxc8.0 ]] && REPOS=${PDPXC80_REPOS:-}
  [[ ${_alias} = pdpxc8.0.19 ]] && REPOS=${PDPXC80_19_REPOS:-}
  [[ ${_alias} = pdps8.0 ]] && REPOS=${PDPS80_REPOS:-}
  [[ ${_alias} = pdps8.0.19 ]] && REPOS=${PDPS80_19_REPOS:-}
  [[ ${_alias} = pdps8.0.20 ]] && REPOS=${PDPS80_20_REPOS:-}
  [[ ${_alias} = prel ]] && REPOS=${PREL_REPOS:-}
  [[ ${_alias} = proxysql ]] && REPOS=${PROXYSQL_REPOS:-}
  [[ ${_alias} = sysbench ]] && REPOS=${SYSBENCH_REPOS:-}
  [[ ${_alias} = pt ]] && REPOS=${PT_REPOS:-}
  [[ ${_alias} = pbm ]] && REPOS=${PBM_REPOS:-}
  [[ ${_alias} = mysqlshell ]] && REPOS=${MYSQL_SHELL_REPOS:-}
  [[ ${_alias} = pmmclient ]] && REPOS=${PMM_CLIENT_REPOS:-}
  [[ ${_alias} = pmm2client ]] && REPOS=${PMM2_CLIENT_REPOS:-}
  [[ -z ${REPOS} ]] && REPOS="original tools"
    ./${SCRIPT} setup ${_alias}
    for _repository in ${REPOS}; do
      expect_repofile_created ${_repository} release
    done
done

