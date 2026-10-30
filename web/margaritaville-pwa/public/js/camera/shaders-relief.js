// Рельефные эффекты (CameraEffectsRelief.h и тиснение из CameraEffectsEdges.h):
// яркость — высота, нормаль по разностям, освещение Блинна — Фонга, материал.

export const RELIEF_EFFECTS = `
vec3 emboss(vec2 uv, vec2 texel) {
  vec2 offset = -vec2(cos(uLightAngle), sin(uLightAngle)) * texel * 2.83;
  float relief = luma(sampleCamera(uv - offset)) - luma(sampleCamera(uv + offset));
  float value = saturate(0.5 + relief * 2.5 * uReliefDepth);
  return vec3(value) * vec3(0.92, 0.9, 0.86);
}
vec3 reliefNormal(vec2 uv, vec2 texel, float strength) {
  vec2 o = texel * 2.0;
  float left = luma(sampleCamera(uv - vec2(o.x, 0.0)));
  float right = luma(sampleCamera(uv + vec2(o.x, 0.0)));
  float top = luma(sampleCamera(uv - vec2(0.0, o.y)));
  float bottom = luma(sampleCamera(uv + vec2(0.0, o.y)));
  return normalize(vec3((left - right) * strength, (top - bottom) * strength, 1.0));
}
vec3 reliefLight(vec3 normal, vec3 lightDirection, vec3 base, vec3 specular, float shininess, float specularStrength) {
  vec3 light = normalize(lightDirection);
  float diffuse = saturate(dot(normal, light));
  vec3 halfVector = normalize(light + vec3(0.0, 0.0, 1.0));
  float highlight = pow(saturate(dot(normal, halfVector)), shininess) * specularStrength;
  return base * (0.3 + 0.8 * diffuse) + specular * highlight;
}
vec3 reliefLightFrom() {
  float angle = uLiveLight > 0.5 ? uTime * 0.9 : uLightAngle;
  return vec3(cos(angle) * 0.78, sin(angle) * 0.78, 0.65);
}
vec3 metalRelief(vec2 uv, vec2 texel) {
  float saturation = saturate(uMetalSat);
  vec3 n = reliefNormal(uv, texel, mix(11.0, 9.0, saturation) * uReliefDepth);
  vec3 tint = hue(fract(uMetalHue));
  vec3 dark = mix(vec3(0.5, 0.52, 0.56), tint * 0.45 + 0.05, saturation);
  vec3 light = mix(vec3(0.78, 0.8, 0.84), mix(tint, vec3(1.0), 0.35), saturation);
  vec3 base = mix(dark, light, luma(sampleCamera(uv)));
  vec3 specular = mix(vec3(1.0), mix(tint, vec3(1.0), 0.6), saturation);
  return reliefLight(n, reliefLightFrom(), base, specular, mix(60.0, 34.0, saturation), mix(1.0, 0.85, saturation));
}
vec3 stoneRelief(vec2 uv, vec2 pixel, vec2 texel) {
  vec3 n = reliefNormal(uv, texel, 7.0 * uReliefDepth);
  float grain = hash(floor(pixel / 2.0)) * 0.12 + hash(floor(pixel / 7.0) + 3.0) * 0.1;
  return reliefLight(n, reliefLightFrom(), vec3(0.62, 0.58, 0.52) * (0.85 + grain), vec3(0.3), 12.0, 0.25);
}
vec3 paperRelief(vec2 uv, vec2 pixel, vec2 texel) {
  vec3 n = reliefNormal(uv, texel, 5.0 * uReliefDepth);
  float fiber = hash(floor(pixel / 1.5)) * 0.03;
  return reliefLight(n, reliefLightFrom(), vec3(0.92, 0.91, 0.87) + fiber, vec3(0.25), 16.0, 0.2);
}
vec3 woodRelief(vec2 uv, vec2 pixel, vec2 texel) {
  vec3 n = reliefNormal(uv, texel, 8.0 * uReliefDepth);
  float rings = sin(uv.y * 140.0 + sin(uv.x * 9.0) * 3.0 + hash(vec2(floor(uv.y * 40.0), 1.0)) * 2.0);
  vec3 base = mix(vec3(0.42, 0.25, 0.12), vec3(0.66, 0.44, 0.24), 0.5 + 0.25 * rings);
  return reliefLight(n, reliefLightFrom(), base, vec3(0.5, 0.4, 0.3), 20.0, 0.3);
}
vec3 rgbToHsv(vec3 c) {
  vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
vec3 periodicMetals(vec2 uv, vec2 texel) {
  vec3 color = sampleCamera(uv);
  vec3 hsv = rgbToHsv(color);
  vec3 n = reliefNormal(uv, texel, 9.0 * uReliefDepth);
  const float centers[9] = float[9](15.0, 32.0, 48.0, 70.0, 140.0, 182.0, 220.0, 280.0, 340.0);
  const vec3 bases[9] = vec3[9](
    vec3(0.85, 0.45, 0.30), vec3(0.70, 0.48, 0.25), vec3(0.95, 0.75, 0.30),
    vec3(0.82, 0.75, 0.38), vec3(0.35, 0.62, 0.50), vec3(0.5, 0.5, 0.5),
    vec3(0.30, 0.45, 0.80), vec3(0.55, 0.35, 0.75), vec3(0.90, 0.55, 0.55));
  const vec3 speculars[9] = vec3[9](
    vec3(1.0, 0.75, 0.6), vec3(1.0, 0.85, 0.6), vec3(1.0, 0.93, 0.65),
    vec3(1.0, 0.97, 0.7), vec3(0.8, 1.0, 0.9), vec3(1.0),
    vec3(0.8, 0.9, 1.0), vec3(0.9, 0.85, 1.0), vec3(1.0, 0.85, 0.85));
  float hueDegrees = hsv.x * 360.0;
  vec3 colorBase = vec3(0.0);
  vec3 colorSpecular = vec3(0.0);
  float weightSum = 0.0;
  for (int index = 0; index < 9; index++) {
    float hueGap = abs(hueDegrees - centers[index]);
    hueGap = min(hueGap, 360.0 - hueGap);
    float scaled = hueGap / 22.0;
    float weight = exp(-scaled * scaled);
    vec3 base = bases[index];
    if (index == 5) base = hue(fract(dot(n.xy, vec2(0.6, 0.4)) * 1.5 + 0.55)) * 0.75 + 0.18;
    colorBase += base * weight;
    colorSpecular += speculars[index] * weight;
    weightSum += weight;
  }
  colorBase /= max(weightSum, 1e-4);
  colorSpecular /= max(weightSum, 1e-4);
  const vec3 bandBases[6] = vec3[6](
    vec3(0.30, 0.31, 0.34), vec3(0.28, 0.42, 0.72), vec3(0.80, 0.42, 0.28),
    vec3(0.72, 0.52, 0.26), vec3(0.95, 0.76, 0.30), vec3(0.84, 0.85, 0.88));
  const vec3 bandSpeculars[6] = vec3[6](
    vec3(0.7), vec3(0.8, 0.9, 1.0), vec3(1.0, 0.75, 0.6),
    vec3(1.0, 0.85, 0.6), vec3(1.0, 0.93, 0.65), vec3(1.0));
  const float bandShininess[6] = float[6](18.0, 40.0, 34.0, 34.0, 38.0, 70.0);
  float level = saturate(luma(color)) * 5.0;
  int lower = min(int(floor(level)), 4);
  float blend = smoothstep(0.35, 0.65, level - float(lower));
  vec3 bandBase = mix(bandBases[lower], bandBases[lower + 1], blend);
  vec3 bandSpecular = mix(bandSpeculars[lower], bandSpeculars[lower + 1], blend);
  float bandShine = mix(bandShininess[lower], bandShininess[lower + 1], blend);
  float colored = smoothstep(0.38, 0.6, hsv.y) * smoothstep(0.12, 0.25, hsv.z);
  vec3 base = mix(bandBase, colorBase, colored) * (0.75 + 0.4 * luma(color));
  vec3 specular = mix(bandSpecular, colorSpecular, colored);
  float shininess = mix(bandShine, 38.0, colored);
  return reliefLight(n, reliefLightFrom(), base, specular, shininess, 0.9);
}
`;
