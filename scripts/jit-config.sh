#!/bin/bash

#######
# Input variables:
# REPO_URL url to github repo (https://github.com/owner/repo)
# ACCESS_TOKEN access token
# NAME name of the runner
# LABELS runner labels
# WORK_FOLDER work folder for the runner

echo "Fetching JIT config"

API_VERSION=v3
ACCEPT_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"
VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"

REPO=$(basename "$REPO_URL" ".${REPO_URL##*.}")
url_without_repo=$(echo "${REPO_URL/$REPO/}")
OWNER=$(basename "$url_without_repo" ".${url_without_repo##.}")
FULL_API_URL="https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/generate-jitconfig"

JSON_LABELS=$(jq -c -n --arg str "${LABELS}" '$str|split(",")')
REQUEST_BODY="{\"name\":\"${NAME}\",\"runner_group_id\":1,\"labels\":${JSON_LABELS},\"work_folder\":\"${WORK_FOLDER}\"}"

echo JIT request body: ${REQUEST_BODY}

JIT_CONFIG="$(curl -sSL -XPOST \
    -H "${ACCEPT_HEADER}" \
    -H "${AUTH_HEADER}" \
    -H "${VERSION_HEADER}" \
    "${FULL_API_URL}" \
    -d "${REQUEST_BODY}")"
#echo JIT config respons: ${JIT_CONFIG}
echo "${JIT_CONFIG}"