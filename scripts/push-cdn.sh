#!/bin/bash

set -eu

basename="$(dirname "$0")"
repoRoot="${basename}/.."
cdnDir="${repoRoot}/cdn"

rclone sync --progress ${cdnDir} b2-cdn:assets-bckr-me/
