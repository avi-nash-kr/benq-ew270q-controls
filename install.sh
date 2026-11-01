#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/avi-nash-kr/benq-ew270q-controls"

if ! command -v omarchy >/dev/null 2>&1; then
  echo "This installer requires Omarchy." >&2
  exit 1
fi

if ! command -v ddcutil >/dev/null 2>&1; then
  echo "ddcutil is required. Install it with your distribution's package manager, then rerun this script." >&2
  exit 1
fi

omarchy plugin add "$repo_url" --enable
