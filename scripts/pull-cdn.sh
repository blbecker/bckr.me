#!/bin/bash

set -eu

basename="$(dirname "$0")"
repoRoot="${basename}/.."
cdnDir="${repoRoot}/cdn"
mkdir -p "${cdnDir}"

rclone copy --progress b2-cdn:assets-bckr-me/ "${cdnDir}"
