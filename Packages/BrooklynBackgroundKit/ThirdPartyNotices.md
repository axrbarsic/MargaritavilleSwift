# Third-party notices

## brooklyn.sh

The scene behavior, original `tex0.png` and `tex1.png`, and the visual material
contract are adapted from `brooklyn.sh` commit
`e56918190b97a0b3d3ce68792bfed887cff1bc06`:

https://github.com/OutThisLife/brooklyn.sh

The donor `package.json` declares the ISC license. The Swift and Metal runtime
implementation is original and does not bundle React, GSAP, React Three Fiber,
or a donor web bundle.

ISC License

Copyright (c) Brooklyn Nicholson and brooklyn.sh contributors

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

## Three.js r167

`BrooklynDonorMesh.bin` is a deterministic indexed export of the donor's
`ExtrudeGeometry` generated with Three.js r167. The exporter is retained in
`Tools/export-donor-mesh.mjs` and the output is pinned by a SHA-256 test.

https://github.com/mrdoob/three.js/tree/r167

The MIT License

Copyright (c) 2010-2024 three.js authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## Potsdamer Platz HDRI

`PotsdamerPlatzCityHDR.bin` is a half-float conversion of
`potsdamer_platz_1k.hdr`, the city preset selected by
`@react-three/drei` 9.109.2. The original HDRI is "Potsdamer Platz" by Greg
Zaal from Poly Haven and is released under CC0 1.0 Universal.

https://polyhaven.com/a/potsdamer_platz

https://creativecommons.org/publicdomain/zero/1.0/

The bundled conversion preserves the original 1024 by 512 pixel data and is
pinned by a SHA-256 test. CC0 does not require attribution; the source and
author are recorded here for provenance.
