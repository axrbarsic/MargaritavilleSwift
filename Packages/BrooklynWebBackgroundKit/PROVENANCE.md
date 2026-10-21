# Brooklyn Web provenance

The runtime is a local, canvas-only adaptation of `brooklyn.sh` pinned at:

`e56918190b97a0b3d3ce68792bfed887cff1bc06`

The exact clean source snapshot and `pnpm-lock.yaml` are stored under
`Vendor/brooklyn.sh`. The local analysis checkout used for this checkpoint had
the remote `https://github.com/axrbarsic/brooklyn.sh.git`; the original public
project is `https://github.com/OutThisLife/brooklyn.sh`.

`Patches/canvas-background.patch` removes portfolio UI, controls, analytics,
external navigation, code text, custom cursor, click/hide/poof behavior and
live pointer input. It also adds lifecycle and bounded telemetry bridges and
switches the Vite output to relative local URLs.

`Tools/build-web-dist.sh` applies that patch in a disposable directory, uses
pnpm 9.6.0 with `--frozen-lockfile`, type-checks, builds with Vite 5.3.5 and
copies only the three runtime assets into the final WebDist. Neither
`node_modules` nor pnpm store data is retained.

Runtime asset hashes:

| Asset | SHA-256 |
| --- | --- |
| `tex0.png` | `8eeecc01de0196b20eb3c74038eac28ccf58c63edd88b8c4db35c10023516ad2` |
| `tex1.png` | `7a99f66974d77abed24f12bce7553b6295f9fc03b11405baefa21724d962184e` |
| `potsdamer_platz_1k.hdr` | `7afe4c2f9700ee78c7477c53fa355463d7dda1fdede401432d6b5f9ff0a95696` |

The HDRI is the exact `city` preset file named by `@react-three/drei` 9.109.2,
retrieved from the pinned `drei-assets` commit
`456060a26bbeb8fdf79326f224b6d99b8bcce736`.
