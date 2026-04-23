#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

PG_VERSION=${PG_VERSION:-15.12}
PREFIX=${PREFIX:-/data/postgresql/pgsql-15}
IMAGE_NAMESPACE=${IMAGE_NAMESPACE:-local}
SOURCE_TARBALL_URL=${SOURCE_TARBALL_URL:-"https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.bz2"}
SOURCE_TARBALL_PATH=${SOURCE_TARBALL_PATH:-}
SKIP_PACKAGE=${SKIP_PACKAGE:-0}
BUILD_TARGET=${BUILD_TARGET:-}
EXTRA_CONFIGURE_FLAGS=${EXTRA_CONFIGURE_FLAGS:-}

DEFAULT_CONFIGURE_FLAGS=(
  "--prefix=${PREFIX}"
  "--with-uuid=e2fs"
  "--with-openssl"
  "--with-libxml"
  "--with-libxslt"
  "--with-python"
  "--with-perl"
  "--with-tcl"
  "--enable-nls"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/build.sh <target>
  scripts/build.sh all
  scripts/build.sh --inside

Targets:
  ubuntu22
  ubuntu24
  el8
  el9
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

safe_rm_rf() {
  local path=$1
  case "$path" in
    "$REPO_ROOT"/*) rm -rf "$path" ;;
    /workspace/*) rm -rf "$path" ;;
    *)
      echo "Refusing to remove unexpected path: $path" >&2
      exit 1
      ;;
  esac
}

join_by() {
  local delim=$1
  shift
  local first=1
  for item in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf '%s' "$item"
      first=0
    else
      printf '%s%s' "$delim" "$item"
    fi
  done
}

build_image() {
  local target=$1
  local dockerfile="$REPO_ROOT/docker/${target}/Dockerfile"
  local image_tag="${IMAGE_NAMESPACE}/postgresql-build:${target}"

  [[ -f "$dockerfile" ]] || {
    echo "Missing Dockerfile for target: $target" >&2
    exit 1
  }

  require_cmd docker
  docker build -f "$dockerfile" -t "$image_tag" "$REPO_ROOT"
}

run_container_build() {
  local target=$1
  local image_tag="${IMAGE_NAMESPACE}/postgresql-build:${target}"

  require_cmd docker

  docker run --rm \
    -e BUILD_TARGET="$target" \
    -e PG_VERSION="$PG_VERSION" \
    -e PREFIX="$PREFIX" \
    -e SOURCE_TARBALL_URL="$SOURCE_TARBALL_URL" \
    -e SOURCE_TARBALL_PATH="$SOURCE_TARBALL_PATH" \
    -e SKIP_PACKAGE="$SKIP_PACKAGE" \
    -e EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS" \
    -v "$REPO_ROOT:/workspace" \
    "$image_tag" \
    bash /workspace/scripts/build.sh --inside
}

prepare_source_tarball() {
  local cache_dir=$1
  local tarball="$cache_dir/postgresql-${PG_VERSION}.tar.bz2"

  mkdir -p "$cache_dir"

  if [[ -n "$SOURCE_TARBALL_PATH" ]]; then
    cp "$SOURCE_TARBALL_PATH" "$tarball"
    echo "$tarball"
    return
  fi

  if [[ ! -f "$tarball" ]]; then
    require_cmd curl
    curl -fsSL "$SOURCE_TARBALL_URL" -o "$tarball"
  fi

  echo "$tarball"
}

configure_flags() {
  local flags=("${DEFAULT_CONFIGURE_FLAGS[@]}")
  if [[ -n "$EXTRA_CONFIGURE_FLAGS" ]]; then
    # shellcheck disable=SC2206
    local extra=( $EXTRA_CONFIGURE_FLAGS )
    flags+=("${extra[@]}")
  fi
  printf '%s\n' "${flags[@]}"
}

build_inside_container() {
  [[ -n "$BUILD_TARGET" ]] || {
    echo "BUILD_TARGET must be set when running with --inside" >&2
    exit 1
  }

  local workspace=/workspace
  local cache_dir="$workspace/.cache"
  local out_root="$workspace/out/${BUILD_TARGET}"
  local build_root="$workspace/build/${BUILD_TARGET}"
  local source_root="$build_root/src"
  local source_dir="$source_root/postgresql-${PG_VERSION}"
  local stage_dir="$out_root/stage"
  local tarball
  local make_jobs
  local -a flags=()

  tarball=$(prepare_source_tarball "$cache_dir")
  make_jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc || echo 2)

  mkdir -p "$out_root" "$build_root" "$source_root"
  safe_rm_rf "$source_dir"
  safe_rm_rf "$stage_dir"

  tar -xf "$tarball" -C "$source_root"

  while IFS= read -r line; do
    flags+=("$line")
  done < <(configure_flags)

  (
    cd "$source_dir"
    ./configure "${flags[@]}"
    make -j"$make_jobs"
    make -j"$make_jobs" -C src/pl
    make -j"$make_jobs" -C contrib
    make install DESTDIR="$stage_dir"
    make -C src/pl install DESTDIR="$stage_dir"
    make -C contrib install DESTDIR="$stage_dir"
  )

  cat >"$out_root/BUILD-INFO.txt" <<EOF
target=${BUILD_TARGET}
pg_version=${PG_VERSION}
prefix=${PREFIX}
configure_flags=$(join_by ' ' "${flags[@]}")
source_tarball=$(basename "$tarball")
built_at_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  mkdir -p "$stage_dir"
  cp "$out_root/BUILD-INFO.txt" "$stage_dir/BUILD-INFO.txt"

  if [[ "$SKIP_PACKAGE" != "1" ]]; then
    BUILD_TARGET="$BUILD_TARGET" \
      PG_VERSION="$PG_VERSION" \
      PREFIX="$PREFIX" \
      "$workspace/scripts/package.sh"
  fi
}

main() {
  local mode=${1:-}

  case "$mode" in
    ubuntu22|ubuntu24|el8|el9)
      build_image "$mode"
      run_container_build "$mode"
      ;;
    all)
      for target in ubuntu22 ubuntu24 el8 el9; do
        build_image "$target"
        run_container_build "$target"
      done
      ;;
    --inside)
      build_inside_container
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
