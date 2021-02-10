#!/bin/sh
echo "Building site.."

TRANSPORT="${GIT_TRANSPORT:-HTTP}"

SCHEMA="https"
if [ "${GIT_HTTP_INSECURE:-FALSE}" = "TRUE" ]; then
  SCHEMA="http"
fi
ERASE=0

cd `dirname ${GIT_CLONE_DEST}`

gitcommand (){
  if [ ! -d $2/.git ]; then
    git clone --depth 1 $1 $2
  else
    cd $2 && git pull --ff-only origin ${GIT_REPO_BRANCH} && cd - 
  fi
}

CONTENT_DIR=`basename ${GIT_CLONE_DEST}`

echo "Working directory: ${CONTENT_DIR}"
mkdir -p ${CONTENT_DIR}

case "$TRANSPORT" in

 SSH)
  GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no -i ${GIT_SSH_ID_FILE}" git clone ${GIT_REPO_URL} ${CONTENT_DIR}
  ;;
 HTTP)
   case "$GIT_PROVIDER" in
     GITHUB)
     gitcommand ${SCHEMA}://$GIT_TOKEN:x-oauth-basic@${GIT_REPO_URL} ${CONTENT_DIR}
     ;;
     GITEA|GITLAB)
     gitcommand ${SCHEMA}://${GIT_USERNAME}:$GIT_TOKEN@${GIT_REPO_URL} ${CONTENT_DIR}
     ;;
     *)
     echo "Cloning/updating a public repo.."
     gitcommand ${SCHEMA}://${GIT_REPO_URL} ${CONTENT_DIR}
     ;;
    esac
  ;;
  *)
  echo "Unsupported transport!"
  exit -1
  ;;
esac

mkdir -p ${HUGO_TARGET_DIR}
cd ${CONTENT_DIR}/${GIT_REPO_CONTENT_PATH} && hugo --destination ${HUGO_TARGET_DIR} ${HUGO_PARAMS}
cd `dirname ${GIT_CLONE_DEST}`
if [ "${GIT_PRESERVE_SRC:-FALSE}" = "FALSE" ]; then
  rm -rf ${CONTENT_DIR}
fi