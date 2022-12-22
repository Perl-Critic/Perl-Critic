#!/bin/bash

VER='v1.146'
TAG="ghcr.io/perl-critic/perl-critic:$VER"

# Any arguments passed to this script will be added to the docker build call.
# --network=host is necessary to get DNS resolving correctly for apt-get.
time docker build \
    --network=host \
    --no-cache \
    --label=built-by="$USER" \
    --label=build-on="$(date)" \
    . \
    -t $TAG \
    "$@"
