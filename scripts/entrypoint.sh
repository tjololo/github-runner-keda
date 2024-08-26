#!/bin/bash
# shellcheck shell=bash
export PATH=${PATH}:/actions-runner

##### ENVVARS
# APP_ID ID of app used for registering and setting up runner
# APP_PRIVATE_KEY Private key for app (should be kept in a vault)
# ORG_NAME Name of the org the runner should be added to (For repo runners please supply REPO_NAME as well)
# REPO_NAME (optional) Name of the repository to add this runner to. Leave unset for org runners
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
_BASE_HOST=${GITHUB_HOST:-"https://github.com"}

## Unset these, this may help prevent leaks
unset_env() {
  unset ACCESS_TOKEN
  unset RUNNER_TOKEN
  unset APP_ID
  unset APP_PRIVATE_KEY
}

[[ -z ${APP_ID} ]] && ( echo "APP_ID is required"; exit 1 )
[[ -z ${APP_PRIVATE_KEY} ]] && (echo "APP_PRIVATE_KEY is required"; exit 1)
[[ -z ${ORG_NAME} ]] && (echo "Atleast ORG_NAME is required, to define a Repo runner define REPO_NAME as well"; exit 1)

APP_LOGIN=${ORG_NAME}

if [[ -z ${REPO_NAME} ]]; then
  _SHORT_URL="${_BASE_HOST}/${ORG_NAME}"
  RUNNER_SCOPE="org"
else
  _SHORT_URL="${_BASE_HOST}/${ORG_NAME}/${REPO_NAME}"
  RUNNER_SCOPE="repo"
fi

echo "Obtaining access token for app_id ${APP_ID} and login ${APP_LOGIN}"

ACCESS_TOKEN=$(APP_ID="${APP_ID}" APP_PRIVATE_KEY="${APP_PRIVATE_KEY//\\n/${nl}}" APP_LOGIN="${APP_LOGIN}" bash ./app-token.sh)


# Retrieve a short lived runner registration token using the PAT
_TOKEN=$(ACCESS_TOKEN="${ACCESS_TOKEN}" bash ./token.sh)
RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)

if [[ -n "${JIT_RUNNER}" ]]; then
  ./config.sh \
    --url $_SHORT_URL \
    --token $RUNNER_TOKEN \
    --labels "${_LABELS}" \
    --work "${_RUNNER_WORKDIR}" \
    --name "${_RUNNER_NAME}" \
    --runnergroup "${_RUNNER_GROUP}" \
    --unattended \
    --replace \
    --ephemeral
  JIT_CONFIG=$(REPO_URL="${_SHORT_URL}" NAME="${_RUNNER_NAME}" LABELS="${_LABELS}" WORK_FOLDER="${_RUNNER_WORKDIR}" ACCESS_TOKEN="${ACCESS_TOKEN}" bash ./jit-config.sh)
  echo "Starting runner with JIT config ${JIT_CONFIG}"
  ENCODED_JIT_CONFIG=$(jq -r '.encoded_jit_config' <<< "${JIT_CONFIG}")
  unset_env
  ./run.sh --jitconfig "${ENCODED_JIT_CONFIG}"
else
  echo "Starting runner without JIT config"
  ./config.sh \
    --url $_SHORT_URL \
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