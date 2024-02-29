#!/bin/bash

if [[ -n "${APP_ID}" ]] && [[ -z "${APP_LOGIN}" ]]; then
  APP_LOGIN=${REPO_URL%/*}
  APP_LOGIN=${APP_LOGIN##*/}
fi

echo "Obtaining access token for app_id ${APP_ID} and login ${APP_LOGIN}"

ACCESS_TOKEN=$(APP_ID="${APP_ID}" APP_PRIVATE_KEY="${APP_PRIVATE_KEY}" APP_LOGIN="${APP_LOGIN}" bash ./app-token.sh)

# Retrieve a short lived runner registration token using the PAT
_TOKEN=$(ACCESS_TOKEN="${ACCESS_TOKEN}" bash ./token.sh)
RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)

echo "Configuring"

./config.sh --url $REPO_URL --token $RUNNER_TOKEN --unattended --ephemeral && ./run.sh