#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

BUILD_TARGET=${BUILD_TARGET:-}
PG_VERSION=${PG_VERSION:-15.12}
ARCHIVE_ARCH=${ARCHIVE_ARCH:-}

if [[ -z "$ARCHIVE_ARCH" ]]; then
  ARCHIVE_ARCH=$(uname -m)
fi

[[ -n "$BUILD_TARGET" ]] || {
  echo "BUILD_TARGET must be set" >&2
  exit 1
}

STAGE_DIR="$REPO_ROOT/out/${BUILD_TARGET}/stage"
DIST_DIR="$REPO_ROOT/dist/${BUILD_TARGET}"
ARCHIVE_NAME="postgresql-${PG_VERSION}-${BUILD_TARGET}-${ARCHIVE_ARCH}.tar.gz"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"

[[ -d "$STAGE_DIR" ]] || {
  echo "Stage directory does not exist: $STAGE_DIR" >&2
  exit 1
}

mkdir -p "$DIST_DIR"
rm -f "$ARCHIVE_PATH" "$ARCHIVE_PATH.sha256"

tar -C "$STAGE_DIR" -czf "$ARCHIVE_PATH" .
sha256sum "$ARCHIVE_PATH" >"$ARCHIVE_PATH.sha256"

echo "Created:"
echo "  $ARCHIVE_PATH"
echo "  $ARCHIVE_PATH.sha256"
