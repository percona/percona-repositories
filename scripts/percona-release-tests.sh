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
#
for _alias in ${ALIASES}; do
  REPOS=""
  [[ ${_alias} = ps80 ]] && REPOS=${PS80REPOS:-}
  [[ ${_alias} = pxc80 ]] && REPOS=${PXC80REPOS:-}
  [[ ${_alias} = pxb80 ]] && REPOS=${PXB80REPOS:-}
  [[ ${_alias} = psmdb40 ]] && REPOS=${PSMDB40REPOS:-}
  [[ ${_alias} = psmdb42 ]] && REPOS=${PSMDB42REPOS:-}
  [[ ${_alias} = ppg11 ]] && REPOS=${PPG11REPOS:-}
  [[ ${_alias} = ppg11.5 ]] && REPOS=${PPG11_5_REPOS:-}
  [[ ${_alias} = ppg11.6 ]] && REPOS=${PPG11_6_REPOS:-}
  [[ ${_alias} = ppg11.7 ]] && REPOS=${PPG11_7_REPOS:-}
  [[ ${_alias} = ppg11.8 ]] && REPOS=${PPG11_8_REPOS:-}
  [[ ${_alias} = pdmdb4.2.6 ]] && REPOS=${PDMDB_4_2_6_REPOS:-}
  [[ ${_alias} = pdmdb4.2 ]] && REPOS=${PDMDB_4_2_REPOS:-}
  [[ ${_alias} = ppg12 ]] && REPOS=${PPG12_REPOS:-}
  [[ ${_alias} = ppg12.2 ]] && REPOS=${PPG12_2_REPOS:-}
  [[ ${_alias} = ppg12.3 ]] && REPOS=${PPG12_3_REPOS:-}
  [[ ${_alias} = pdmysql8.0 ]] && REPOS=${PDMYSQL80_REPOS:-}
  [[ ${_alias} = pdmysql8.0.18 ]] && REPOS=${PDMYSQL80_18_REPOS:-}
  [[ -z ${REPOS} ]] && REPOS="original tools"
    ./${SCRIPT} setup ${_alias}
    for _repository in ${REPOS}; do
      expect_repofile_created ${_repository} release
    done
done
