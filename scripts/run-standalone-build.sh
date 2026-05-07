#!/usr/bin/env bash
set -euo pipefail

MANIFEST_REPO="https://gitcode.com/openharmony/manifest.git"
: "${BASE_REF:=master}"
BUILD_COMMAND="bash build/prebuilts_config.sh && hb build audio_framework -i"
UT_BUILD_COMMAND="hb build audio_framework -t"
: "${AUDIO_FRAMEWORK_DIR:=}"

if [ ! -d .repo ]; then
  repo init -u "$MANIFEST_REPO" -b "$BASE_REF" --no-repo-verify
fi

repo sync -c build multimedia_audio_framework

echo "repo sync finished for: build multimedia_audio_framework"

echo "Synced repositories with manifest: $MANIFEST_REPO @ $BASE_REF"


WORKSPACE_DIR="$(pwd)"
TARGET_DIR="$WORKSPACE_DIR/foundation/multimedia/audio_framework"
TARGET_PARENT_DIR="$(dirname "$TARGET_DIR")"
if [ -n "$AUDIO_FRAMEWORK_DIR" ]; then
  if [ ! -d "$AUDIO_FRAMEWORK_DIR" ]; then
    echo "::error::AUDIO_FRAMEWORK_DIR does not exist: $AUDIO_FRAMEWORK_DIR"
    exit 1
  fi

  if [ -e "$TARGET_PARENT_DIR" ] && [ ! -d "$TARGET_PARENT_DIR" ]; then
    echo "::error::Target parent path exists but is not a directory: $TARGET_PARENT_DIR"
    exit 1
  fi

  mkdir -p "$TARGET_PARENT_DIR"
  rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_PARENT_DIR"
  ln -s "$AUDIO_FRAMEWORK_DIR" "$TARGET_DIR"

  if [ ! -L "$TARGET_DIR" ]; then
    echo "::error::Failed to create symlink: $TARGET_DIR"
    exit 1
  fi

  LINK_TARGET="$(readlink "$TARGET_DIR")"
  if [ "$LINK_TARGET" != "$AUDIO_FRAMEWORK_DIR" ]; then
    echo "::error::Symlink target mismatch: expected=$AUDIO_FRAMEWORK_DIR actual=$LINK_TARGET"
    exit 1
  fi

  echo "Using external audio framework directory: $AUDIO_FRAMEWORK_DIR"
  echo "Symlink verified: $TARGET_DIR -> $LINK_TARGET"
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "::error::audio_framework source not found at $TARGET_DIR. Please set AUDIO_FRAMEWORK_DIR to a mounted local path."
  echo "::error::Debug info: pwd=$PWD, target_parent_exists=$([ -d "$TARGET_PARENT_DIR" ] && echo yes || echo no)"
  exit 1
fi

cd "$WORKSPACE_DIR"

ensure_hb() {
  export PATH="$HOME/.local/bin:$PATH"
  if command -v hb >/dev/null 2>&1; then
    return
  fi

  echo "hb not found, install it with: python3 -m pip install --user build/hb"
  python3 -m pip install --user build/hb
  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v hb >/dev/null 2>&1; then
    echo "::error::hb installation finished but command is still unavailable."
    exit 1
  fi
}

ensure_python_deps() {
  # hb runtime imports build/hb modules with system Python; ensure required deps exist there.
  if ! python3 -c "import jinja2" >/dev/null 2>&1; then
    echo "Installing missing Python dependency: jinja2"
    python3 -m pip install --user jinja2
  fi
}


ensure_hb
ensure_python_deps
$BUILD_COMMAND
$UT_BUILD_COMMAND
