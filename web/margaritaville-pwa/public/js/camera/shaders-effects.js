// Эффекты фона «Камера», перенесённые один к одному из Metal:
// CameraEffectsRetro.h, CameraEffectsToy.h, CameraEffectsEdges.h, CameraEffectsRelief.h.
import { HEADER, COMMON } from "./shaders-common.js";
import { RELIEF_EFFECTS } from "./shaders-relief.js";

const EFFECT_FUNCTIONS = `
vec3 thermal(float value) {
  const vec3 stops[5] = vec3[5](vec3(0.0, 0.0, 0.08), vec3(0.30, 0.0, 0.62), vec3(0.92, 0.05, 0.32), vec3(1.0, 0.55, 0.0), vec3(1.0, 1.0, 0.65));
  float t = saturate(value) * 4.0;
  int index = min(int(floor(t)), 3);
  return mix(stops[index], stops[index + 1], t - float(index));
}
float asciiGlyph(int bits, vec2 p) {
  vec2 cell = floor(p * vec2(-4.0, -4.0) + 2.5);
  if (any(lessThan(cell, vec2(0.0))) || any(greaterThan(cell, vec2(4.0)))) return 0.0;
  int index = int(cell.x + 5.0 * cell.y);
  return float((bits >> index) & 1);
}
vec3 asciiArt(vec2 pixel) {
  float cellSize = uView.x / 56.0 * uDetail;
  vec2 cellOrigin = floor(pixel / cellSize) * cellSize;
  vec3 color = sampleScreen(cellOrigin + cellSize * 0.5);
  float gray = luma(color);
  int bits = 4096;
  if (gray > 0.2) bits = 65600;
  if (gray > 0.3) bits = 163153;
  if (gray > 0.4) bits = 15255086;
  if (gray > 0.5) bits = 13121101;
  if (gray > 0.6) bits = 15252014;
  if (gray > 0.7) bits = 13195790;
  if (gray > 0.8) bits = 11512810;
  vec2 p = fract(pixel / cellSize) * 2.0 - 1.0;
  return min(color * 1.3, vec3(1.0)) * asciiGlyph(bits, p);
}
vec3 dither1Bit(vec2 pixel) {
  float dotSize = 3.0 * uDetail;
  vec2 cell = floor(pixel / dotSize);
  float value = saturate((luma(sampleScreen((cell + 0.5) * dotSize)) - 0.5) * 1.35 + 0.5);
  return value > bayer8(uvec2(cell)) ? vec3(0.93, 0.91, 0.82) : vec3(0.08, 0.07, 0.11);
}
float halftoneDot(vec2 pixel, float angle, int channel, float cellSize) {
  mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
  vec2 rotated = rotation * pixel;
  vec2 center = (floor(rotated / cellSize) + 0.5) * cellSize;
  vec3 rgb = sampleScreen(transpose(rotation) * center);
  float key = 1.0 - max(rgb.r, max(rgb.g, rgb.b));
  vec4 cmyk = vec4((1.0 - rgb - key) / max(1.0 - key, 0.001), key);
  float radius = sqrt(saturate(cmyk[channel])) * cellSize * 0.62;
  return 1.0 - smoothstep(radius - 1.0, radius + 1.0, length(rotated - center));
}
vec3 halftone(vec2 pixel) {
  float cellSize = uView.x / 64.0 * uDetail;
  float c = halftoneDot(pixel, 0.2618, 0, cellSize);
  float m = halftoneDot(pixel, 1.3090, 1, cellSize);
  float y = halftoneDot(pixel, 0.0, 2, cellSize);
  float k = halftoneDot(pixel, 0.7854, 3, cellSize);
  return vec3(0.96, 0.94, 0.88) * (1.0 - vec3(c, m, y) * 0.92) * (1.0 - k * 0.9);
}
vec3 gameBoy(vec2 pixel) {
  float block = uView.x / 128.0 * uDetail;
  vec2 cell = floor(pixel / block);
  float value = saturate((luma(sampleScreen((cell + 0.5) * block)) - 0.5) * 1.2 + 0.5);
  float level = clamp(floor(value * 3.0 + (bayer8(uvec2(cell)) - 0.5) * 0.9 + 0.5), 0.0, 3.0);
  const vec3 palette[4] = vec3[4](vec3(0.06, 0.22, 0.06), vec3(0.19, 0.38, 0.19), vec3(0.55, 0.67, 0.06), vec3(0.61, 0.74, 0.06));
  vec2 inner = fract(pixel / block);
  return palette[int(level)] * (1.0 - step(0.85, max(inner.x, inner.y)) * 0.18);
}
vec3 crt(vec2 pixel) {
  vec2 centered = pixel / uView * 2.0 - 1.0;
  centered *= 1.0 + 0.06 * dot(centered, centered);
  if (any(greaterThan(abs(centered), vec2(1.0)))) return vec3(0.0);
  vec2 curved = centered * 0.5 + 0.5;
  float jitter = (hash(vec2(floor(uTime * 24.0), floor(curved.y * 90.0))) - 0.5) * 0.0015;
  vec2 base = curved + vec2(jitter, 0.0);
  const vec2 shift = vec2(0.0025, 0.0);
  vec3 color = vec3(sampleCamera(aspectFill(base + shift, uView, uTex)).r, sampleCamera(aspectFill(base, uView, uTex)).g, sampleCamera(aspectFill(base - shift, uView, uTex)).b);
  float scanline = 0.75 + 0.25 * cos(pixel.y * 2.0944);
  vec3 mask = vec3(0.85);
  mask[int(mod(pixel.x, 3.0))] = 1.15;
  float bandX = (fract(curved.y + uTime * 0.1) - 0.5) * 12.0;
  float band = exp(-bandX * bandX) * 0.08;
  float vignette = pow(16.0 * curved.x * curved.y * (1.0 - curved.x) * (1.0 - curved.y), 0.25);
  float noise = (hash(pixel + fract(uTime) * 97.0) - 0.5) * 0.04;
  return color * scanline * mask * vignette * 1.15 + band + noise;
}
float hatchLine(vec2 pixel, float spacing, float direction, float offset) {
  float coordinate = pixel.x + direction * pixel.y + offset;
  float distanceToLine = abs(fract(coordinate / spacing + 0.5) - 0.5) * spacing;
  return 1.0 - smoothstep(0.7, 1.5, distanceToLine);
}
vec3 sketch(vec2 uv, vec2 pixel) {
  float value = luma(sampleCamera(uv));
  float spacing = 9.0 * uDetail;
  float ink = 0.0;
  if (value < 0.85) ink = max(ink, hatchLine(pixel, spacing, 1.0, 0.0));
  if (value < 0.60) ink = max(ink, hatchLine(pixel, spacing, -1.0, 0.0));
  if (value < 0.40) ink = max(ink, hatchLine(pixel, spacing, 1.0, spacing * 0.5));
  if (value < 0.22) ink = max(ink, hatchLine(pixel, spacing, -1.0, spacing * 0.5));
  float edge = smoothstep(0.25, 0.7, sobel(uv, 1.5 / uTex, uEdge));
  return mix(vec3(0.95, 0.93, 0.87), vec3(0.16, 0.16, 0.20), max(ink * 0.85, edge));
}
vec3 kaleidoscope(vec2 pixel) {
  float scale = min(uView.x, uView.y);
  vec2 centered = (pixel - uView * 0.5) / scale;
  const float segment = 6.28318 / 8.0;
  float angle = mod(atan(centered.y, centered.x) + uTime * 0.15, segment);
  angle = abs(angle - segment * 0.5);
  vec2 mapped = vec2(cos(angle), sin(angle)) * length(centered);
  return sampleScreen(mapped * scale + uView * 0.5);
}
vec3 glitch(vec2 pixel) {
  vec2 screenUV = pixel / uView;
  float tick = floor(uTime * 7.0);
  float band = floor(screenUV.y * 24.0);
  float trigger = hash(vec2(band, tick));
  float shift = trigger > 0.82 ? (hash(vec2(tick, band + 7.0)) - 0.5) * 0.12 : 0.0;
  vec2 shifted = screenUV + vec2(shift, 0.0);
  float split = 0.004 + step(0.9, hash(vec2(tick, 3.0))) * 0.012;
  vec3 color = vec3(sampleCamera(aspectFill(shifted + vec2(split, 0.0), uView, uTex)).r, sampleCamera(aspectFill(shifted, uView, uTex)).g, sampleCamera(aspectFill(shifted - vec2(split, 0.0), uView, uTex)).b);
  if (trigger > 0.96) color = 1.0 - color;
  return color + step(0.995, hash(vec2(floor(pixel.y / 2.0), tick))) * 0.5;
}
vec3 cartoon(vec2 uv, vec2 texel) {
  vec3 color = sampleCamera(uv);
  float value = max(luma(color), 0.001);
  const float levels = 4.0;
  float nearest = floor(value * levels + 0.5) / levels;
  float quantized = nearest + tanh((value - nearest) * 60.0) / (2.0 * levels);
  color = saturate(color * (max(quantized, 0.08) / value));
  color = floor(color * 8.0 + 0.5) / 8.0;
  color = saturate(mix(vec3(luma(color)), color, 1.6));
  float edge = smoothstep(0.08, 0.22, sobel(uv, texel * 2.5, uEdge));
  return mix(color, vec3(0.04, 0.03, 0.05), edge);
}
vec3 legoColor(vec3 color) {
  const vec3 palette[16] = vec3[16](
    vec3(0.95, 0.95, 0.95), vec3(0.11, 0.16, 0.20), vec3(0.77, 0.16, 0.11), vec3(0.05, 0.41, 0.67),
    vec3(0.96, 0.80, 0.18), vec3(0.16, 0.50, 0.27), vec3(0.29, 0.59, 0.29), vec3(0.85, 0.52, 0.25),
    vec3(0.39, 0.37, 0.38), vec3(0.64, 0.64, 0.64), vec3(0.84, 0.77, 0.60), vec3(0.41, 0.25, 0.15),
    vec3(0.13, 0.23, 0.34), vec3(0.91, 0.73, 0.78), vec3(0.64, 0.74, 0.27), vec3(0.21, 0.68, 0.75));
  vec3 best = palette[0];
  float bestDistance = 1e9;
  for (int index = 0; index < 16; index++) {
    vec3 delta = (color - palette[index]) * vec3(0.30, 0.59, 0.11);
    float dist = dot(delta, delta);
    if (dist < bestDistance) { bestDistance = dist; best = palette[index]; }
  }
  return best;
}
vec3 lego(vec2 pixel) {
  float block = uView.x / 28.0 * uDetail;
  vec2 cell = floor(pixel / block);
  vec3 base = legoColor(sampleScreen((cell + 0.5) * block));
  vec2 local = fract(pixel / block) - 0.5;
  float edge = max(abs(local.x), abs(local.y));
  float bevel = smoothstep(0.40, 0.47, edge);
  float side = (abs(local.x) > abs(local.y) ? local.x : local.y) > 0.0 ? -0.28 : 0.16;
  vec3 color = base * (1.0 + bevel * side);
  color *= 1.0 - smoothstep(0.47, 0.5, edge) * 0.55;
  const float studRadius = 0.27;
  float shadow = 1.0 - smoothstep(studRadius - 0.03, studRadius + 0.03, length(local - vec2(0.06, 0.07)));
  color *= 1.0 - shadow * 0.32;
  float stud = 1.0 - smoothstep(studRadius - 0.015, studRadius + 0.015, length(local));
  float rim = smoothstep(studRadius - 0.07, studRadius, length(local)) * stud;
  float facing = dot(normalize(local + 1e-4), vec2(-0.707, -0.707));
  vec3 studColor = base * (1.06 + rim * facing * 0.35);
  studColor += (1.0 - smoothstep(0.0, 0.07, length(local - vec2(-0.1, -0.1)))) * 0.35;
  return mix(color, studColor, stud);
}
vec3 neonShadow(vec2 uv, vec2 texel) {
  float spread = 0.013 + 0.007 * sin(uTime * 1.3);
  float angle = uTime * 0.8;
  vec2 offsetA = vec2(cos(angle), sin(angle)) * spread;
  vec2 offsetB = vec2(cos(angle + 2.094), sin(angle + 2.094)) * spread;
  vec3 color = sampleCamera(uv) * 0.08;
  color += vec3(1.0, 0.15, 0.6) * edgeMask(uv + offsetA, texel, 1.6, 0.12, 0.5, uEdge);
  color += vec3(0.1, 0.9, 1.0) * edgeMask(uv + offsetB, texel, 1.6, 0.12, 0.5, uEdge);
  color += vec3(1.0, 0.95, 0.3) * edgeMask(uv, texel, 1.6, 0.12, 0.5, uEdge);
  return color;
}
vec3 neonGlow(vec2 uv, vec2 texel) {
  float core = edgeMask(uv, texel, 1.5, 0.12, 0.5, uEdge);
  float halo = (edgeMask(uv, texel, 5.0, 0.1, 0.6, uEdge) * 0.5 + edgeMask(uv, texel, 12.0, 0.1, 0.7, uEdge) * 0.3) * uGlow * 2.0;
  vec3 tint = hue(fract(uv.x * 0.4 + uv.y * 0.25 + uTime * 0.05));
  return tint * (core * 1.3 + halo) + vec3(1.0) * core * 0.35;
}
vec3 tron(vec2 uv, vec2 pixel, vec2 texel) {
  vec2 gradient = sobelVector(uv, texel * 1.5);
  float edge = smoothstep(0.12, 0.5, length(gradient) * uEdge);
  float horizontal = abs(gradient.y) / (abs(gradient.x) + abs(gradient.y) + 1e-4);
  vec3 lineColor = mix(vec3(0.1, 0.85, 1.0), vec3(1.0, 0.55, 0.1), step(0.6, horizontal));
  float cell = uView.x / 14.0;
  vec2 offset = abs(fract(pixel / cell + 0.5) - 0.5) * cell;
  float grid = (1.0 - smoothstep(0.0, 1.2, min(offset.x, offset.y))) * 0.12;
  float halo = edgeMask(uv, texel, 6.0, 0.1, 0.6, uEdge) * 0.35;
  return vec3(0.0, 0.02, 0.05) + vec3(0.1, 0.5, 0.7) * grid + lineColor * (edge * 1.2 + halo);
}
vec3 blueprint(vec2 uv, vec2 pixel, vec2 texel) {
  float edge = edgeMask(uv, texel, 1.4, 0.1, 0.35, uEdge);
  float fine = uView.x / 48.0 * uDetail;
  float coarse = fine * 6.0;
  vec2 fineOffset = abs(fract(pixel / fine + 0.5) - 0.5) * fine;
  vec2 coarseOffset = abs(fract(pixel / coarse + 0.5) - 0.5) * coarse;
  float grid = (1.0 - smoothstep(0.0, 1.0, min(fineOffset.x, fineOffset.y))) * 0.12 + (1.0 - smoothstep(0.0, 1.4, min(coarseOffset.x, coarseOffset.y))) * 0.22;
  return vec3(0.05, 0.22, 0.48) + vec3(0.85, 0.92, 1.0) * max(grid, edge * 0.95);
}
vec3 chalk(vec2 uv, vec2 pixel, vec2 texel) {
  float edge = edgeMask(uv, texel, 1.8, 0.12, 0.45, uEdge);
  float breakup = step(0.35, hash(floor(pixel / 2.0)));
  float dust = hash(floor(pixel / 3.0) + 17.0) * 0.06;
  return mix(vec3(0.13, 0.22, 0.18) + dust, vec3(0.93, 0.95, 0.9), edge * breakup * 0.95);
}
vec3 electric(vec2 uv, vec2 texel) {
  float tick = floor(uTime * 20.0);
  vec2 jitter = (vec2(hash(floor(uv * 60.0) + tick), hash(floor(uv * 60.0) + tick + 5.0)) - 0.5) * 0.004;
  float core = edgeMask(uv + jitter, texel, 1.4, 0.15, 0.45, uEdge);
  float halo = edgeMask(uv, texel, 6.0, 0.1, 0.6, uEdge);
  float flicker = 0.75 + 0.25 * hash(vec2(tick, 2.0));
  return (vec3(0.45, 0.25, 1.0) * halo * 0.7 + vec3(0.85, 0.9, 1.0) * core) * flicker;
}
`;

const MAIN = `
void main() {
  vec2 uv = aspectFill(vUv, uView, uTex);
  vec2 texel = 1.0 / uTex;
  vec2 pixel = vUv * uView;
  vec3 color;
  if (uEffect == 1) {
    color = sampleCamera(uv);
    color = mix(color, vec3(luma(color)), 0.15);
    color = mix(color, vec3(1.0), 0.14);
    color += (hash(pixel + fract(uTime) * 61.0) - 0.5) * 0.05;
  } else if (uEffect == 2) {
    color = sampleCamera(uv) * 0.82;
    float cell = uView.x / 12.0 * uDetail;
    vec2 offset = abs(fract(pixel / cell + 0.5) - 0.5) * cell;
    float distanceToLine = min(offset.x, offset.y);
    float lineMask = 1.0 - smoothstep(0.0, 1.6, distanceToLine);
    float glow = exp(-distanceToLine * 0.35) * 0.35;
    float scanY = fract(uTime * 0.25) * uView.y;
    float scan = exp(-abs(pixel.y - scanY) * 0.02) * 0.25;
    color += vec3(0.1, 1.0, 0.85) * (lineMask * 0.7 + glow * 0.6) + vec3(0.2, 1.0, 0.8) * scan;
  } else if (uEffect == 3) {
    float value = pow(saturate(luma(sampleCamera(uv)) * 1.9), 0.75);
    float noise = (hash(pixel + floor(uTime * 30.0)) - 0.5) * 0.18;
    float scanlines = 0.88 + 0.12 * sin(pixel.y * 1.6);
    float vignette = smoothstep(0.85, 0.25, length((vUv - 0.5) * vec2(1.0, 0.8)));
    color = vec3(0.18, 1.0, 0.28) * saturate(value + noise) * scanlines * vignette;
  } else if (uEffect == 4) {
    color = thermal(luma(sampleCamera(uv)));
  } else if (uEffect == 6) {
    vec3 base = floor(sampleCamera(uv) * 5.0 + 0.5) / 5.0;
    float edge = step(0.35, sobel(uv, texel * 1.8, uEdge));
    color = mix(base * 1.08, vec3(0.02), edge);
  } else if (uEffect == 7) {
    float block = uView.x / 40.0 * uDetail;
    color = sampleScreen((floor(pixel / block) + 0.5) * block);
    vec2 inner = fract(pixel / block);
    color *= 1.0 - step(0.92, max(inner.x, inner.y)) * 0.35;
  } else if (uEffect == 8) { color = asciiArt(pixel); }
  else if (uEffect == 9) { color = dither1Bit(pixel); }
  else if (uEffect == 10) { color = halftone(pixel); }
  else if (uEffect == 11) { color = gameBoy(pixel); }
  else if (uEffect == 12) { color = crt(pixel); }
  else if (uEffect == 13) { color = sketch(uv, pixel); }
  else if (uEffect == 14) { color = kaleidoscope(pixel); }
  else if (uEffect == 15) { color = glitch(pixel); }
  else if (uEffect == 16) { color = cartoon(uv, texel); }
  else if (uEffect == 17) { color = lego(pixel); }
  else if (uEffect == 18) { color = neonShadow(uv, texel); }
  else if (uEffect == 19) { color = neonGlow(uv, texel); }
  else if (uEffect == 20) { color = tron(uv, pixel, texel); }
  else if (uEffect == 21) { color = blueprint(uv, pixel, texel); }
  else if (uEffect == 22) { color = chalk(uv, pixel, texel); }
  else if (uEffect == 23) { color = electric(uv, texel); }
  else if (uEffect == 24) { color = emboss(uv, texel); }
  else if (uEffect == 25) { color = metalRelief(uv, texel); }
  else if (uEffect == 26) { color = periodicMetals(uv, texel); }
  else if (uEffect == 28) { color = stoneRelief(uv, pixel, texel); }
  else if (uEffect == 29) { color = paperRelief(uv, pixel, texel); }
  else if (uEffect == 30) { color = woodRelief(uv, pixel, texel); }
  else { color = sampleCamera(uv); }
  color = mix(sampleCamera(uv), color, saturate(uAmount)) * uBrightness;
  outColor = vec4(saturate(color), 1.0);
}
`;

export const EFFECT_FRAGMENT = HEADER + COMMON + EFFECT_FUNCTIONS + RELIEF_EFFECTS + MAIN;
