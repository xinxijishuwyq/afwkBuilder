#!/usr/bin/env bash
set -euo pipefail

MANIFEST_REPO="https://gitcode.com/openharmony/manifest.git"
: "${BASE_REF:=master}"
: "${AUDIO_FRAMEWORK_DIR:=}"

HB_BUILD_COMMAND="${HB_BUILD_COMMAND:-}"
WARMUP_BUILD_COMMAND="${WARMUP_BUILD_COMMAND:-hb build audio_framework -i}"

if [ "$#" -gt 0 ]; then
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'USAGE'
Usage: run-standalone-build.sh [hb build command...]

Examples:
  run-standalone-build.sh hb build audio_framework -i
  run-standalone-build.sh hb build audio_framework -t
  run-standalone-build.sh "hb build audio_framework -i && hb build audio_framework -t"

You can also pass the command by env var:
  HB_BUILD_COMMAND="hb build audio_framework -i" run-standalone-build.sh

Notes:
  - bash build/prebuilts_config.sh is always executed before your hb command.
  - If both argv command and HB_BUILD_COMMAND are provided, argv command wins.
USAGE
    exit 0
  fi

  HB_BUILD_COMMAND="$*"
fi

if [ -z "$HB_BUILD_COMMAND" ]; then
  echo "::error::No hb build command provided."
  echo "::error::Pass command arguments, or set HB_BUILD_COMMAND env."
  exit 1
fi

WORKSPACE_DIR="$(pwd)"
TARGET_DIR="$WORKSPACE_DIR/foundation/multimedia/audio_framework"
TARGET_PARENT_DIR="$(dirname "$TARGET_DIR")"

if [ ! -d .repo ]; then
  GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-repo}" \
  GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-repo@localhost}" \
  GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-$GIT_COMMITTER_NAME}" \
  GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-$GIT_COMMITTER_EMAIL}" \
    repo init -u "$MANIFEST_REPO" -b "$BASE_REF" --no-repo-verify
fi

# On reused /work volumes, a previous run may have replaced the project path
# with a symlink to an external directory. This breaks `repo sync` checkout.
if [ -L "$TARGET_DIR" ]; then
  echo "Found existing symlink at $TARGET_DIR; removing before repo sync"
  rm -f "$TARGET_DIR"
fi

if [ -z "${SYNC_PROJECTS:-}" ]; then
  SYNC_PROJECTS="build"
fi
read -r -a SYNC_PROJECT_LIST <<< "$SYNC_PROJECTS"
repo sync -c "${SYNC_PROJECT_LIST[@]}"

echo "repo sync finished for: $SYNC_PROJECTS"

echo "Synced repositories with manifest: $MANIFEST_REPO @ $BASE_REF"


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
  mkdir -p "$TARGET_DIR"
  rsync -a --delete "$AUDIO_FRAMEWORK_DIR"/ "$TARGET_DIR"/
  echo "Using external audio framework directory via rsync: $AUDIO_FRAMEWORK_DIR -> $TARGET_DIR"
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "::error::audio_framework source not found at $TARGET_DIR. Please set AUDIO_FRAMEWORK_DIR to a mounted local path."
  echo "::error::Debug info: pwd=$PWD, target_parent_exists=$([ -d "$TARGET_PARENT_DIR" ] && echo yes || echo no)"
  exit 1
fi

cd "$WORKSPACE_DIR"


ensure_python_cmd() {
  if command -v python >/dev/null 2>&1; then
    return
  fi

  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v python3)" "$HOME/.local/bin/python"
  export PATH="$HOME/.local/bin:$PATH"

  if ! command -v python >/dev/null 2>&1; then
    echo "::error::python command is unavailable and could not be shimmed to python3"
    exit 1
  fi
}

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
ensure_python_cmd
ensure_python_deps

bash build/prebuilts_config.sh

if [ -n "$WARMUP_BUILD_COMMAND" ] && [ "$WARMUP_BUILD_COMMAND" != ":" ]; then
  echo "Executing warm-up build command for cache: $WARMUP_BUILD_COMMAND"
  bash -lc "$WARMUP_BUILD_COMMAND"
else
  echo "Skipping warm-up build command (WARMUP_BUILD_COMMAND=$WARMUP_BUILD_COMMAND)"
fi

echo "Executing external build command: $HB_BUILD_COMMAND"
bash -lc "$HB_BUILD_COMMAND"
