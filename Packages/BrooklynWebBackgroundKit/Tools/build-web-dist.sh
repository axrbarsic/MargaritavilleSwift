#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PACKAGE_DIR="${SCRIPT_DIR:h}"
SOURCE_DIR="${PACKAGE_DIR}/Vendor/brooklyn.sh"
PATCH_FILE="${PACKAGE_DIR}/Patches/canvas-background.patch"
HDR_FILE="${PACKAGE_DIR}/Assets/potsdamer_platz_1k.hdr"
OUTPUT_DIR="${PACKAGE_DIR}/Sources/BrooklynWebBackgroundKit/Resources/WebDist"
WORK_DIR="$(mktemp -d /private/tmp/brooklyn-web-dist.XXXXXX)"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

rsync -a "${SOURCE_DIR}/" "${WORK_DIR}/"
patch -d "${WORK_DIR}" -p2 < "${PATCH_FILE}"
cp "${HDR_FILE}" "${WORK_DIR}/public/potsdamer_platz_1k.hdr"

(
  cd "${WORK_DIR}"
  npx --yes pnpm@9.6.0 install --frozen-lockfile
  ./node_modules/.bin/tsc --noEmit
  ./node_modules/.bin/vite build
  cp index.html dist/index.html
  cp public/tex0.png public/tex1.png public/potsdamer_platz_1k.hdr dist/
)

mkdir -p "${OUTPUT_DIR}"
rsync -a --delete "${WORK_DIR}/dist/" "${OUTPUT_DIR}/"

if [[ ! -f "${OUTPUT_DIR}/assets/brooklyn.js" ]] ||
   [[ "$(find "${OUTPUT_DIR}/assets" -type f | wc -l | tr -d ' ')" != "1" ]]
then
  echo "WebDist must contain one classic runtime bundle" >&2
  exit 1
fi

if rg -i 'type="module"|crossorigin|<link[^>]+stylesheet' "${OUTPUT_DIR}/index.html"
then
  echo "file-origin-incompatible module or cross-origin boundary found" >&2
  exit 1
fi

if rg 'process\.env|(^|[^[:alnum:]_])eval\(|new[[:space:]]+Function\(' \
  "${OUTPUT_DIR}/assets/brooklyn.js"
then
  echo "browser runtime contains an unsupported Node or dynamic-code path" >&2
  exit 1
fi

if rg 'window\.location\.href|new URL\([^)]*(tex0|tex1|potsdamer_platz)' \
  "${OUTPUT_DIR}/assets/brooklyn.js"
then
  echo "runtime asset still depends on a file-origin fetch URL" >&2
  exit 1
fi

if rg -i \
  'cdn\.segment\.com|window\.open|mailto:|resume\.pdf|tex2\.png|Code Opacity|I am a full stack|brooklyn\.bb|imbabybrooklyn|linkedin\.com|github\.com/outthislife|\bleva\b|\bpoof\b' \
  "${OUTPUT_DIR}"
then
  echo "forbidden donor UI, interaction, or network path found in WebDist" >&2
  exit 1
fi

find "${OUTPUT_DIR}" -maxdepth 2 -type f -print | sort
