#!/usr/bin/env node

import { createHash } from 'node:crypto'
import { writeFileSync } from 'node:fs'
import { pathToFileURL } from 'node:url'

const [threeModulePath, outputPath] = process.argv.slice(2)

if (!threeModulePath || !outputPath) {
  console.error('usage: export-donor-mesh.mjs /path/to/three.module.js output.bin')
  process.exit(64)
}

const THREE = await import(pathToFileURL(threeModulePath))
const eps = 0.00001

function createShape(w, h, radius) {
  const shape = new THREE.Shape()
  const r = (radius - eps) * 1.5

  return shape
    .moveTo(r, 0)
    .lineTo(w - r, 0)
    .quadraticCurveTo(w, 0, w, r)
    .lineTo(w, h - r)
    .quadraticCurveTo(w, h, w - r, h)
    .lineTo(r, h)
    .quadraticCurveTo(0, h, 0, h - r)
    .lineTo(0, r)
    .quadraticCurveTo(0, 0, r, 0)
}

const geometry = new THREE.ExtrudeGeometry(createShape(1, 1, 0.175), {
  bevelEnabled: true,
  bevelSegments: 16,
  bevelSize: 0.15,
  curveSegments: 16,
  depth: 1 - 0.175 - eps
})
geometry.center()

const position = geometry.getAttribute('position')
const normal = geometry.getAttribute('normal')
const uv = geometry.getAttribute('uv')

if (position.count !== 13860 || normal.count !== position.count || uv.count !== position.count) {
  throw new Error(`unexpected Three r167 vertex contract: ${position.count}/${normal.count}/${uv.count}`)
}

const keyBuffer = Buffer.allocUnsafe(32)
const uniqueVertices = []
const indices = []
const lookup = new Map()

for (let i = 0; i < position.count; i += 1) {
  const values = [
    position.getX(i), position.getY(i), position.getZ(i),
    normal.getX(i), normal.getY(i), normal.getZ(i),
    uv.getX(i), uv.getY(i)
  ]

  values.forEach((value, component) => keyBuffer.writeFloatLE(value, component * 4))
  const key = keyBuffer.toString('hex')
  let index = lookup.get(key)

  if (index === undefined) {
    index = uniqueVertices.length
    if (index > 65535) throw new Error('mesh exceeds UInt16 index capacity')
    lookup.set(key, index)
    uniqueVertices.push(values)
  }

  indices.push(index)
}

const headerSize = 24
const vertexStride = 32
const output = Buffer.allocUnsafe(
  headerSize + uniqueVertices.length * vertexStride + indices.length * 2
)
output.write('BRKMESH1', 0, 'ascii')
output.writeUInt32LE(1, 8)
output.writeUInt32LE(uniqueVertices.length, 12)
output.writeUInt32LE(indices.length, 16)
output.writeUInt32LE(vertexStride, 20)

let offset = headerSize
for (const vertex of uniqueVertices) {
  vertex.forEach((value, component) => output.writeFloatLE(value, offset + component * 4))
  offset += vertexStride
}
for (const index of indices) {
  output.writeUInt16LE(index, offset)
  offset += 2
}

writeFileSync(outputPath, output)

geometry.computeBoundingBox()
const bounds = geometry.boundingBox
console.log(JSON.stringify({
  sourceVertexCount: position.count,
  triangleCount: position.count / 3,
  uniqueVertexCount: uniqueVertices.length,
  indexCount: indices.length,
  bounds: {
    min: bounds.min.toArray(),
    max: bounds.max.toArray()
  },
  sha256: createHash('sha256').update(output).digest('hex')
}, null, 2))
