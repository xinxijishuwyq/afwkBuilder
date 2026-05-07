#!/usr/bin/env bash
set -euo pipefail

MANIFEST_REPO="https://gitcode.com/openharmony/manifest.git"
: "${BASE_REF:=master}"
BUILD_COMMAND="bash build/prebuilts_config.sh && hb build audio_framework -i"
UT_BUILD_COMMAND="hb build audio_framework -t"
: "${SYNC_PROJECTS:=build}"
: "${AUDIO_FRAMEWORK_DIR:=}"

if [ ! -d .repo ]; then
  repo init -u "$MANIFEST_REPO" -b "$BASE_REF" --no-repo-verify
fi

repo sync -c ${SYNC_PROJECTS}

echo "Synced repositories with manifest: $MANIFEST_REPO @ $BASE_REF"

TARGET_DIR="foundation/multimedia/audio_framework"
if [ -n "$AUDIO_FRAMEWORK_DIR" ]; then
  if [ ! -d "$AUDIO_FRAMEWORK_DIR" ]; then
    echo "::error::AUDIO_FRAMEWORK_DIR does not exist: $AUDIO_FRAMEWORK_DIR"
    exit 1
  fi

  rm -rf "$TARGET_DIR"
  ln -s "$AUDIO_FRAMEWORK_DIR" "$TARGET_DIR"
  echo "Using external audio framework directory: $AUDIO_FRAMEWORK_DIR"
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "::error::audio_framework source not found at $TARGET_DIR. Please set AUDIO_FRAMEWORK_DIR to a mounted local path."
  exit 1
fi

cd "$TARGET_DIR"
bash -lc "$BUILD_COMMAND"
bash -lc "$UT_BUILD_COMMAND"
