#!/bin/bash

# RELEASE_SLUG (required): specific module release to be downloaded and evaulated
# EVALUATION_CMD (required): command to run from the module root, this command must generate JSON output to STDOUT
# RESPONSE_TOKEN (required): OAuth Bearer token to use when PUTing results
# Optional overrides
# DOWNLOAD_URL: allows you to override the default URL from which to download the release
# RESPONSE_URL: allows you to override the default URL to which the results will sent back via PATCH request

# Check for required env vars
: "${RELEASE_SLUG:?Need to set RELEASE_SLUG}"
: "${EVALUATION_CMD:?Need to set EVALUATION_CMD}"
: "${RESPONSE_TOKEN:?Need to set RESPONSE_TOKEN}"

# Check for custom download URI or use default
if [[ -z "${DOWNLOAD_URL}" ]]; then
  # TODO: write this to stderr
  #echo "DEBUG: DOWNLOAD_URL not set, using default..."
  download_uri="https://forgeapi.puppet.com/v3/files/${RELEASE_SLUG}.tar.gz"
else
  download_uri=${DOWNLOAD_URL}
fi

# Check for custom URL for response or use default
if [[ -z "${RESPONSE_URL}" ]]; then
  # TODO: write this to stderr
  #echo "DEBUG: RESPONSE_URL not set, using default..."
  # download_uri="https://forgeapi.puppet.com/private/evaluations"
  response_uri="http://localhost:4567/private/evaluations"
else
  response_uri=${RESPONSE_URL}
fi

# TODO: create a workspace dir in the Dockerfile via `RUN mkdir workspace` ?
# pushd workspace > /dev/null || exit

# Download and extract module release
# FIXME: curl command not found, so remove uninstall line? Or use another utility to download the tarball?
curl -sS -O "${download_uri}"

# TODO: check if URL existed/download succeeded

tar -xzf "${RELEASE_SLUG}.tar.gz"

# Change to the module root by finding the first instance of metadata.json
pushd -- "$(find . -name "metadata.json" -type f -printf '%h' -quit)" > /dev/null || exit

${EVALUATION_CMD}

# Post results back to specified URI
curl \
  --fail \
  --progress-bar \
  -X PATCH \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${RESPONSE_TOKEN}" \
  -d@response.json \
  "${response_uri}"
