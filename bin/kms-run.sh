#!/usr/bin/env bash

#/ Run Kurento Media Server.
#/
#/ This shell script runs KMS with default options if
#/ already built.
#/
#/
#/
#/ Arguments
#/ ---------
#/
#/ --gdb
#/
#/   Run KMS in a GDB session. Useful to set break points and get backtraces.
#/
#/   Optional. Default: Disabled.
#/



# Shell setup
# -----------

BASEPATH="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"  # Absolute canonical path
# shellcheck source=bash.conf.sh
source "$BASEPATH/bash.conf.sh" || exit 1



BUILD_DIR="build-RelWithDebInfo-clang-docker"

# Prepare run environment
# -----------------------

RUN_VARS="GST_DEBUG='3,Kurento*:4,kms*:4,sdp*:4,webrtc*:4,*rtpendpoint:4,rtp*handler:4,rtpsynchronizer:4,agnosticbin:4'"



# Run Kurento Media Server
# ------------------------

pushd "$BUILD_DIR"  # Enter $BUILD_DIR

# Always run `make`: if any source file changed, it needs building; if nothing
# changed since last time, it is a "no-op" anyway
make -j"$(nproc)"

# System limits: Set maximum open file descriptors
# Maximum limit value allowed by Ubuntu: 2^20 = 1048576
ulimit -n 1048576

# System limits: Enable kernel core dump
ulimit -c unlimited

# System config: Set path for Kernel core dump files
# NOTE: Requires root (runs with `sudo`)
#KERNEL_CORE_PATH="${PWD}/core_%e_%p_%u_%t"
#log "Set kernel core dump path: $KERNEL_CORE_PATH"
#echo "$KERNEL_CORE_PATH" | sudo tee /proc/sys/kernel/core_pattern >/dev/null

# Prepare the final command
COMMAND="$RUN_VARS"

# NOTE: "--gst-disable-registry-fork" is used to prevent GStreamer from
# spawning a helper process that loads plugins, which can cause confusing
# results from analysis tools such as Valgrind.

COMMAND="$COMMAND kurento-media-server/server/kurento-media-server \
    --conf-file='$PWD/config/kurento.conf.json' \
    --modules-config-path='$PWD/config' \
    --modules-path='$PWD:/usr/lib/x86_64-linux-gnu/kurento/modules' \
    --gst-plugin-path='$PWD' \
    --gst-disable-registry-fork \
    --gst-disable-registry-update"

log "Run command: $COMMAND"
eval "$COMMAND" "$@"

popd  # Exit $BUILD_DIR
