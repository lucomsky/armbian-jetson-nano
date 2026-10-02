#!/usr/bin/env bash
# Build the Armbian image for Jetson Nano (P3449-0000-B01).
# Usage: ./build.sh [config-name] [extra compile.sh args...]
#   config-name defaults to "jetson-nano-xfce" (userpatches/config-jetson-nano-xfce.conf)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${1:-jetson-nano-xfce}"
shift || true

if [[ ! -x "${ROOT}/armbian-build/compile.sh" ]]; then
	git -C "${ROOT}" submodule update --init armbian-build
fi

# Armbian (and its Docker container) only sees userpatches inside its own tree, so copy ours in.
rsync -a --delete "${ROOT}/userpatches/" "${ROOT}/armbian-build/userpatches/"

# Build the Docker build-container from debian:trixie (Docker Hub) instead of pulling the prebuilt
# ghcr.io/armbian/docker-armbian-build image: on this host the Docker daemon gets "denied" from ghcr.io.
# Set USE_GHCR_BUILD_IMAGE=yes to use the (faster) prebuilt image.
declare -a docker_args=()
[[ "${USE_GHCR_BUILD_IMAGE:-no}" == "yes" ]] || docker_args+=("DOCKERFILE_USE_ARMBIAN_IMAGE_AS_BASE=no")

cd "${ROOT}/armbian-build"
./compile.sh "${CONFIG}" "${docker_args[@]}" "$@"

echo
echo "Images:"
ls -lh "${ROOT}/armbian-build/output/images/" 2>/dev/null || true
