#!/bin/bash
# shellcheck shell=bash
export PATH=${PATH}:/actions-runner

export -n ACCESS_TOKEN
export -n RUNNER_TOKEN
export -n APP_ID
export -n APP_PRIVATE_KEY

_RUNNER_NAME=${RUNNER_NAME:-${RUNNER_NAME_PREFIX:-github-runner}-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')}
_RUNNER_WORKDIR=${RUNNER_WORKDIR:-/_work/${_RUNNER_NAME}}
_LABELS=${LABELS:-default}
_RUNNER_GROUP=${RUNNER_GROUP:-Default}

[[ -z ${REPO_URL} ]] && ( echo "REPO_URL required for repo runners"; exit 1 )
_SHORT_URL=${REPO_URL}
RUNNER_SCOPE="repo"

if [[ -n "${APP_ID}" ]] && [[ -z "${APP_LOGIN}" ]]; then
  APP_LOGIN=${REPO_URL%/*}
  APP_LOGIN=${APP_LOGIN##*/}
fi

echo "Obtaining access token for app_id ${APP_ID} and login ${APP_LOGIN}"

ACCESS_TOKEN=$(APP_ID="${APP_ID}" APP_PRIVATE_KEY="${APP_PRIVATE_KEY//\\n/${nl}}" APP_LOGIN="${APP_LOGIN}" bash ./app-token.sh)



# Retrieve a short lived runner registration token using the PAT
_TOKEN=$(ACCESS_TOKEN="${ACCESS_TOKEN}" bash ./token.sh)
RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)

echo "Configuring"

if [[ -n "${JIT_RUNNER}" ]]; then
  JIT_CONFIG=$(REPO_URL="${REPO_URL}" NAME="${_RUNNER_NAME}" LABELS="${_LABELS}" WORK_FOLDER="${_RUNNER_WORKDIR}" ACCESS_TOKEN="${ACCESS_TOKEN}" bash ./jit-config.sh)
  echo -n "Starting runner with JIT config ${JIT_CONFIG}"
  ENCODED_JIT_CONFIG=$(echo -n "${JIT_CONFIG}" | jq -r '.encoded_jit_config')
  ./run.sh --jitconfig "${ENCODED_JIT_CONFIG}"
else
  echo "Starting runner without JIT config"
  ./config.sh \
    --url $REPO_URL \
    --token $RUNNER_TOKEN \
    --labels "${_LABELS}" \
    --work "${_RUNNER_WORKDIR}" \
    --name "${_RUNNER_NAME}" \
    --unattended \
    --ephemeral
  ./run.sh
fi
