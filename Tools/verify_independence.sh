#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

fail() {
  printf 'Independence guard failed: %s\n' "$1" >&2
  failures=$((failures + 1))
}

expect_fixed() {
  local pattern="$1"
  local path="$2"
  if ! rg --fixed-strings --quiet "$pattern" "$path"; then
    fail "missing '$pattern' in $path"
  fi
}

reject_fixed() {
  local pattern="$1"
  shift
  local matches
  if matches="$(rg --fixed-strings --line-number "$pattern" "$@" 2>/dev/null)"; then
    printf '%s\n' "$matches" >&2
    fail "forbidden '$pattern'"
  fi
}

reject_regex() {
  local pattern="$1"
  shift
  local matches
  if matches="$(rg --line-number "$pattern" "$@" 2>/dev/null)"; then
    printf '%s\n' "$matches" >&2
    fail "forbidden regex '$pattern'"
  fi
}

runtime_paths=(
  project.yml
  MargaritavilleSwift
  MargaritavilleSwiftTests
)

runtime_globs=(
  --glob '!MargaritavilleSwift/App/BuildChangelogEntries*.swift'
)

expect_fixed "PRODUCT_BUNDLE_IDENTIFIER: com.alex.margaritaville.swift" project.yml
expect_fixed "CFBundleDisplayName: Margaritaville" project.yml
expect_fixed "iCloud.com.alex.margaritaville.swift" MargaritavilleSwift/MargaritavilleSwift.entitlements

reject_fixed "com.alex.oceankey.swift" "${runtime_paths[@]}" "${runtime_globs[@]}"
reject_fixed "iCloud.com.alex.oceankey.swift" "${runtime_paths[@]}" "${runtime_globs[@]}"
reject_fixed "AXR.OCEANKEY" "${runtime_paths[@]}" "${runtime_globs[@]}"
reject_fixed "com.alex.oceankey.presetbackup" "${runtime_paths[@]}" "${runtime_globs[@]}"
reject_fixed "OceanKey-Presets" "${runtime_paths[@]}" "${runtime_globs[@]}"
reject_fixed "oceankey.room.schedule" "${runtime_paths[@]}" "${runtime_globs[@]}"
reject_regex 'appendingPathComponent\("OceanKeySwift"' MargaritavilleSwift --glob '!MargaritavilleSwift/App/AppIdentity.swift'

shared_root="/Users/alex/Developer/OceanKeySharedFoundation/Sources"
if [[ -d "$shared_root" ]]; then
  reject_regex 'import (OceanKeySwift|MargaritavilleSwift)\b' "$shared_root"
  reject_fixed "com.alex.oceankey" "$shared_root"
  reject_fixed "com.alex.margaritaville" "$shared_root"
  reject_fixed "iCloud.com.alex" "$shared_root"
  reject_fixed "AXR.OCEANKEY" "$shared_root"
fi

if (( failures > 0 )); then
  exit 1
fi

printf 'Independence guard passed.\n'
