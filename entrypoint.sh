#!/bin/bash
set -eu

GIT_USER_NAME=${1} # git-user-name
GIT_USER_EMAIL=${2} # git-user-email
PACKAGE_MANAGER=${3} # package-manager
TARGET_VERSION=${4} # target-version
MODULES_FILTER=${5} # modules-filter
REVIEWERS=${6} # reviewers
COMMIT_MSG_PREFIX=${7} # commit-message-prefix
PULL_REQUEST_LABELS=${8} # pull-request-labels
BUMP_VERSION=${9} # bump-version
NPM_SCOPE=${10} # npm-registry-scope
NPM_REGISTRY=${11} # npm-registry-url
PRE_COMMIT_SCRIPT=${12} # pre-commit-script



if [ -n "${NPM_SCOPE}" ] && [ -n "${NPM_REGISTRY}" ]; then
  NPM_REGISTRY_PATH=${NPM_REGISTRY#https:}
  
  echo "${NPM_SCOPE}:registry=${NPM_REGISTRY}" > .npmrc
  echo "${NPM_REGISTRY_PATH}:_authToken=${NPM_TOKEN}" >> .npmrc
  echo "${NPM_REGISTRY_PATH}:always-auth=true" >> .npmrc
fi

PACKAGES_FOR_UPDATE=$(npx npm-check-updates -u -f ${MODULES_FILTER} -t ${TARGET_VERSION})

if $(git diff-index --quiet HEAD); then
  echo 'No dependencies needed to be updated!'
  exit 0
fi

if [ "${PACKAGE_MANAGER}" == 'npm' ]; then
  npm i --package-lock-only
  elif [ "${PACKAGE_MANAGER}" == 'yarn' ]; then
  yarn install
else
  echo "Invalid package manager '${PACKAGE_MANAGER}'. Please set 'package-manager' to either 'npm' or 'yarn'."
  exit 1
fi

if [ -n "${BUMP_VERSION}" ]; then
  if [ "${PACKAGE_MANAGER}" == 'npm' ]; then
    npm version --no-git-tag-version ${BUMP_VERSION}
    elif [ "${PACKAGE_MANAGER}" == 'yarn' ]; then
    yarn version --no-git-tag-version "--${BUMP_VERSION}"
  fi
fi

RUN_LABEL="${GITHUB_WORKFLOW}@${GITHUB_RUN_NUMBER}"
RUN_ENDPOINT="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
UPDATED_PACKAGES=$(grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" <<< "${PACKAGES_FOR_UPDATE}")

COMMIT_MSG="${COMMIT_MSG_PREFIX}: update node deps ($(date -I))"  # this is also a PR title
PR_MSG=$(echo -e "## Updated packages\n${UPDATED_PACKAGES}\n\n_Generated by [${RUN_LABEL}](${RUN_ENDPOINT})._")
PR_BRANCH=chore/node-deps-$(date +%s)

git config user.name ${GIT_USER_NAME}
git config user.email ${GIT_USER_EMAIL}
git checkout -b ${PR_BRANCH}

if [ -n "${PRE_COMMIT_SCRIPT}" ]; then
  ${PRE_COMMIT_SCRIPT}
fi

git commit -am "${COMMIT_MSG}"
git push origin ${PR_BRANCH}

DEFAULT_BRANCH=$(curl --silent \
  --url https://api.github.com/repos/${GITHUB_REPOSITORY} \
  --header "authorization: Bearer ${GITHUB_TOKEN}" \
  --header 'content-type: application/json' \
--fail | jq -r .default_branch)

git fetch origin ${DEFAULT_BRANCH}

if [ -n "${REVIEWERS}" ]; then
  PR_NUMBER=$(hub pull-request -b ${DEFAULT_BRANCH} -r ${REVIEWERS} --no-edit | grep -o '[^/]*$')
else
  PR_NUMBER=$(hub pull-request -b ${DEFAULT_BRANCH} --no-edit | grep -o '[^/]*$')
fi

echo "Created pull request #${PR_NUMBER}."

hub issue update ${PR_NUMBER} -l ${PULL_REQUEST_LABELS} -m "${COMMIT_MSG}" -m "${PR_MSG}"
echo "Updated pull request #${PR_NUMBER} (labels: '${PULL_REQUEST_LABELS}')."
