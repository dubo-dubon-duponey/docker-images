#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)"

# --no-cache \

buildctl \
 --addr tcp://buildkit.local:443 \
 build \
 --progress auto \
 --opt hostname=cake.duponey.cloud \
 --opt image-resolve-mode=default \
 --opt force-network-mode=sandbox \
 --local dockerfile="$root" \
 --frontend dockerfile.v0 \
 --opt filename=Dockerfile.tools \
 --local context="$root" \
 --opt platform=linux/amd64 \
 --opt add-hosts=snapshot.debian.org=10.0.4.107,apt-proxy.local=10.0.4.99,apt-front.local=10.0.4.107
