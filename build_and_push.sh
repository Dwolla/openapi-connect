#!/usr/bin/env bash

GIT_COMMIT_MSG="Build and publish Redocly documentation"
REDOCLY_GIT_BRANCH=redocly-build
REDOCLY_NPM_PKG=@redocly/cli
REDOCLY_OUTPUT_DIR=docs

console_log () {
  local COLOR_BLUE="\033[0;34m"
  local COLOR_OFF="\033[0m"
  echo -e "${COLOR_BLUE}[Build & Push]:${COLOR_OFF} $1"
}

# If $REDOCLY_GIT_BRANCH doesn't exist, create it
if git rev-parse --verify $REDOCLY_GIT_BRANCH > /dev/null; then
  console_log "Branch $REDOCLY_GIT_BRANCH found, attempting to check out..."

  if [[ $(git rev-parse --abbrev-ref HEAD) != "$REDOCLY_GIT_BRANCH" ]]; then
    if [[ $(git checkout $REDOCLY_GIT_BRANCH; echo $?) == 1 ]]; then
      console_log "Failed to checkout $REDOCLY_GIT_BRANCH branch, exiting..."
      exit 1
    fi
  else
    console_log "Branch $REDOCLY_GIT_BRANCH is already checked out, skipping..."
  fi
else
  console_log "Branch $REDOCLY_GIT_BRANCH doesn't exist, attempting to create..."
  git checkout -b $REDOCLY_GIT_BRANCH
fi

# Install $REDOCLY_NPM_PKG CLI if it doesn't exist
if [[ $(pnpm list --depth 0 -g | grep -q $REDOCLY_NPM_PKG; echo $?) == 1 ]]; then
  console_log "Package $REDOCLY_NPM_PKG not found, attempting to install it..."
  pnpm add -g $REDOCLY_NPM_PKG
fi

console_log "Deleting and recreating $REDOCLY_OUTPUT_DIR"
rm -r $REDOCLY_OUTPUT_DIR && mkdir $REDOCLY_OUTPUT_DIR

console_log "Bundling and building Redocly documentation..."
redocly bundle spec.json --ext=json -o $REDOCLY_OUTPUT_DIR/bundled.json
redocly build-docs $REDOCLY_OUTPUT_DIR/bundled.json -o $REDOCLY_OUTPUT_DIR/index.html

# Remove bundled JSON since it's no longer needed
rm $REDOCLY_OUTPUT_DIR/bundled.json

# Commit & push changes to GitHub
git add $REDOCLY_OUTPUT_DIR
git commit --allow-empty -m "$GIT_COMMIT_MSG"
git push -u origin $REDOCLY_GIT_BRANCH
