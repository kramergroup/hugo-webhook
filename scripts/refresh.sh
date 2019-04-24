#!/bin/sh
echo "Refresh started"

CONTENT_DIR=$(mktemp -d -t ci-XXXXXXXXXX)

echo "Working directory: ${CONTENT_DIR}"
mkdir -p ${CONTENT_DIR}
GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no -i ${GIT_SSH_ID_FILE}" git clone ${GIT_REPO_URL} ${CONTENT_DIR}
mkdir -p ${TARGET_DIR}
cd ${CONTENT_DIR}/${GIT_REPO_CONTENT_PATH} && hugo --destination ${TARGET_DIR} ${HUGO_PARAMS}
rm -rf ${CONTENT_DIR}