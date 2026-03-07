#!/usr/bin/env bash
set -euo pipefail

# Usage: ./img_to_jpg.sh /path/to/images
SRC_DIR="${1:-.}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Base parameters
QUALITY_START=88
QUALITY_MIN=60
SHARPEN="0x0.5"
DENSITY=300
SAMPLE_FACTOR="4:2:0"

# Target max sizes (in bytes)
INLINE_MAX_BYTES=$((150 * 1024))
HERO_MAX_BYTES=$((300 * 1024))

# Resize limits
INLINE_MAX_DIM="1000x1000>"
HERO_MAX_DIM="2000x2000>"

process_image() {
  local src="$1"
  local dst="$2"
  local resize_max="$3"
  local max_bytes="$4"

  if [[ -f "$dst" ]]; then
    echo "Skipping existing file: $dst"
    return
  fi

  local quality="$QUALITY_START"
  local tmp="$TMP_DIR/$(basename "$dst")"

  # Loop: reduce quality until under max_bytes or quality_min reached
  while :; do
    convert "$src" \
      -auto-orient \
      -colorspace sRGB \
      -resize "$resize_max" \
      -density "$DENSITY" \
      -unsharp "$SHARPEN" \
      -sampling-factor "$SAMPLE_FACTOR" \
      -quality "$quality" \
      -interlace Plane \
      -define jpeg:optimize-coding=true \
      -strip \
      "$tmp"

    actual_size=$(stat -c%s "$tmp")
    if [ "$actual_size" -le "$max_bytes" ] || [ "$quality" -le "$QUALITY_MIN" ]; then
      mv "$tmp" "$dst"
      echo "Saved $dst ($((actual_size / 1024)) KB, quality=$quality)"
      break
    fi

    # Reduce quality and retry
    quality=$((quality - 4))
  done
}

process_variants() {
  local src="$1"
  local base="${src%.*}"

  process_image "$src" "${base}.inline.jpg" "$INLINE_MAX_DIM" "$INLINE_MAX_BYTES"
  process_image "$src" "${base}.hero.jpg" "$HERO_MAX_DIM" "$HERO_MAX_BYTES"
}

# 1) Convert NEF / nef
find "$SRC_DIR" -type f -regextype posix-extended \
  -regex '.*\.(NEF|nef)$' -print0 |
  while IFS= read -r -d '' src; do
    process_variants "$src"
  done

# 2) Recompress JPEGs larger than 1 MB (skip temp files)
find "$SRC_DIR" -type f -regextype posix-extended \
  -regex '.*\.(jpg|JPG|jpeg|JPEG)$' \
  ! -name '*.inline.jpg' ! -name '*.hero.jpg' \
  -size +1M -print0 |
  while IFS= read -r -d '' src; do
    process_variants "$src"
  done
