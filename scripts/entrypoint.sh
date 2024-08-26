#!/bin/bash
# shellcheck shell=bash
export PATH=${PATH}:/actions-runner

##### ENVVARS
# APP_ID ID of app used for registering and setting up runner
# AP_PRIVATE_KEY Private key for app (should be kept in a vault)
# REPO_URL Url to the repository. Example: https://github.com/tjololo/github-runner-keda
# RUNNER_NAME (optional) Name of the runner. Default: ${RUNNER_NAME_PREFIX}-<random-string>
# RUNNER_NAME_PREFIX (optional) The name will have random string add after the prefix. Default: github-runner
# RUNNER_WORKDIR (optional) Work dir for the runner. Default: /_work/${RUNNER_NAME}
# LABELS (optional) Runner labels. Default: default
# RUNNER_GROUP (optional) Name of runner group. Default: Default
# RUNNER_GROUP_ID (optional) Id of runner group. Default: 1
# JIT_RUNNER (optional) If this var is set the runner will be setup as a JIT runner.

# Un-export these, so that they must be passed explicitly to the environment of
# any command that needs them.  This may help prevent leaks.
export -n ACCESS_TOKEN
export -n RUNNER_TOKEN
export -n APP_ID
export -n APP_PRIVATE_KEY

_RUNNER_NAME=${RUNNER_NAME:-${RUNNER_NAME_PREFIX:-github-runner}-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')}
_RUNNER_WORKDIR=${RUNNER_WORKDIR:-/_work/${_RUNNER_NAME}}
_LABELS=${LABELS:-default}
_RUNNER_GROUP=${RUNNER_GROUP:-Default}
_RUNNER_GROUP_ID=${RUNNER_GROUP_ID:-1}

## Unset these, this may help prevent leaks
unset_env() {
  unset ACCESS_TOKEN
  unset RUNNER_TOKEN
  unset APP_ID
  unset APP_PRIVATE_KEY
}

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

if [[ -n "${JIT_RUNNER}" ]]; then
  ./config.sh \
    --url $REPO_URL \
    --token $RUNNER_TOKEN \
    --labels "${_LABELS}" \
    --work "${_RUNNER_WORKDIR}" \
    --name "${_RUNNER_NAME}" \
    --runnergroup "${_RUNNER_GROUP}" \
    --unattended \
    --replace \
    --ephemeral
  JIT_CONFIG=$(REPO_URL="${REPO_URL}" NAME="${_RUNNER_NAME}" LABELS="${_LABELS}" WORK_FOLDER="${_RUNNER_WORKDIR}" ACCESS_TOKEN="${ACCESS_TOKEN}" bash ./jit-config.sh)
  echo "Starting runner with JIT config ${JIT_CONFIG}"
  ENCODED_JIT_CONFIG=$(jq -r '.encoded_jit_config' <<< "${JIT_CONFIG}")
  unset_env
  ./run.sh --jitconfig "${ENCODED_JIT_CONFIG}"
else
  echo "Starting runner without JIT config"
  ./config.sh \
    --url $REPO_URL \
    --token $RUNNER_TOKEN \
    --labels "${_LABELS}" \
    --work "${_RUNNER_WORKDIR}" \
    --name "${_RUNNER_NAME}" \
    --runnergroup "${_RUNNER_GROUP}" \
    --unattended \
    --replace \
    --ephemeral
  unset_env
  ./run.sh
fi