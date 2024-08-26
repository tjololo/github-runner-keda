#!/bin/bash

#######
# Input variables:
# REPO_URL url to github repo (https://github.com/owner/repo)
# ACCESS_TOKEN access token
# NAME name of the runner
# LABELS runner labels
# WORK_FOLDER work folder for the runner
# RUNNER_GROUP_ID id of the runner group this runner belongs to

_GITHUB_HOST=${GITHUB_HOST:-"github.com"}
# If URL is not github.com then use the enterprise api endpoint
if [[ ${_GITHUB_HOST} = "github.com" ]]; then
  URI="https://api.${_GITHUB_HOST}"
else
  URI="https://${_GITHUB_HOST}/api/v3"
fi

API_VERSION=v3
ACCEPT_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"
VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"

case ${RUNNER_SCOPE} in
  org*)
    _FULL_URL="${URI}/orgs/${ORG_NAME}/actions/runners/registration-token"
    ;;

  ent*)
    _FULL_URL="${URI}/enterprises/${ENTERPRISE_NAME}/actions/runners/registration-token"
    ;;

  *)
    _FULL_URL="${URI}/repos/${ORG_NAME}/${REPO_NAME}/actions/runners/registration-token"
    ;;
esac

JSON_LABELS=$(jq -c -n --arg str "${LABELS}" '$str|split(",")')
REQUEST_BODY="{\"name\":\"${NAME}\",\"runner_group_id\":${RUNNER_GROUP_ID},\"labels\":${JSON_LABELS},\"work_folder\":\"${WORK_FOLDER}\"}"

JIT_CONFIG="$(curl -fsSL -XPOST \
    -H "${ACCEPT_HEADER}" \
    -H "${AUTH_HEADER}" \
    -H "${VERSION_HEADER}" \
    "${_FULL_URL}" \
    -d "${REQUEST_BODY}")"
echo "${JIT_CONFIG}"