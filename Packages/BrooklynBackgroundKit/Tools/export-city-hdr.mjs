#!/usr/bin/env node

import { createHash } from 'node:crypto'
import { readFileSync, writeFileSync } from 'node:fs'
import { pathToFileURL } from 'node:url'

const [rgbeLoaderPath, inputPath, outputPath] = process.argv.slice(2)

if (!rgbeLoaderPath || !inputPath || !outputPath) {
  console.error('usage: export-city-hdr.mjs /path/to/RGBELoader.js input.hdr output.bin')
  process.exit(64)
}

const endianProbe = new Uint8Array(new Uint16Array([0x0102]).buffer)
if (endianProbe[0] !== 0x02) throw new Error('little-endian host required')

const { RGBELoader } = await import(pathToFileURL(rgbeLoaderPath))
const source = readFileSync(inputPath)
const arrayBuffer = source.buffer.slice(source.byteOffset, source.byteOffset + source.byteLength)
const parsed = new RGBELoader().parse(arrayBuffer)

if (!(parsed.data instanceof Uint16Array) || parsed.width !== 1024 || parsed.height !== 512) {
  throw new Error(`unexpected city HDR contract: ${parsed.width}x${parsed.height}`)
}

const header = Buffer.alloc(24)
header.write('BRKHDR01', 0, 'ascii')
header.writeUInt32LE(1, 8)
header.writeUInt32LE(parsed.width, 12)
header.writeUInt32LE(parsed.height, 16)
header.writeUInt16LE(4, 20)
header.writeUInt16LE(2, 22)

const pixels = Buffer.from(parsed.data.buffer, parsed.data.byteOffset, parsed.data.byteLength)
const output = Buffer.concat([header, pixels])
writeFileSync(outputPath, output)

console.log(JSON.stringify({
  width: parsed.width,
  height: parsed.height,
  sourceSha256: createHash('sha256').update(source).digest('hex'),
  outputSha256: createHash('sha256').update(output).digest('hex')
}, null, 2))
