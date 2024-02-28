#!/bin/sh -l
echo "Obtaining access token for app_id ${APP_ID} and login ${APP_LOGIN}"
nl="
"
#ACCESS_TOKEN=$(APP_ID="${APP_ID}" APP_PRIVATE_KEY="${APP_PRIVATE_KEY//\\n/${nl}}" APP_LOGIN="${APP_LOGIN}" bash ./app_token.sh)


# Retrieve a short lived runner registration token using the PAT
REGISTRATION_TOKEN="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$REGISTRATION_TOKEN_API_URL" \
  | jq -r '.token')"

./config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --unattended --ephemeral && ./run.sh