// GLSL-версия BrooklynShaders.metal: вершинный поворот кубов и материал с окружением,
// туман и итоговая цветокоррекция (ACES, sRGB, яркость/контраст).
const PI = "3.14159265358979323846";

const TONE = `
vec3 rrtAndODTFit(vec3 v) {
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return a / b;
}
vec3 aces(vec3 color) {
  const mat3 inM = mat3(0.59719, 0.07600, 0.02840, 0.35458, 0.90834, 0.13383, 0.04823, 0.01566, 0.83777);
  const mat3 outM = mat3(1.60475, -0.10208, -0.00327, -0.53108, 1.10813, -0.07276, -0.07367, -0.00605, 1.07602);
  color *= 1.0 / 0.6;
  color = inM * color;
  color = rrtAndODTFit(color);
  return clamp(outM * color, 0.0, 1.0);
}
vec3 toSRGB(vec3 c) {
  return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, vec3(lessThanEqual(c, vec3(0.0031308))));
}
vec3 finish(vec3 linearColor, vec2 correction) {
  vec3 color = toSRGB(aces(linearColor));
  if (abs(correction.x) < 0.0001 && abs(correction.y) < 0.0001) return color;
  color += correction.x - 0.5;
  color = correction.y > 0.0 ? color / (1.0 - correction.y) : color * (1.0 + correction.y);
  return clamp(color + 0.5, 0.0, 1.0);
}`;

export const FOG_VERTEX = `#version 300 es
void main() {
  vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
  gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}`;

export const FOG_FRAGMENT = `#version 300 es
precision highp float;
uniform vec3 uFog;
uniform vec2 uCorrection;
out vec4 outColor;
${TONE}
void main() { outColor = vec4(finish(uFog, uCorrection), 1.0); }`;

export const BROOKLYN_VERTEX = `#version 300 es
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aUV;
layout(location = 3) in vec3 aCell;
uniform mat4 uProj;
uniform float uTime;
uniform float uSpacing;
uniform vec2 uHighlight;
out vec3 vWorld;
out vec3 vNormal;
out vec3 vGeometry;
out vec3 vMouse;
out vec2 vUV;
out float vDepth;
flat out float vHighlight;
const float PI = ${PI};
vec3 rotateX(vec3 p, float a) { float c = cos(a), s = sin(a); return vec3(p.x, c * p.y - s * p.z, s * p.y + c * p.z); }
vec3 rotateY(vec3 p, float a) { float c = cos(a), s = sin(a); return vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z); }
vec3 rotateZ(vec3 p, float a) { float c = cos(a), s = sin(a); return vec3(c * p.x - s * p.y, s * p.x + c * p.y, p.z); }
float easePowerInOut(float t, float e) {
  t = clamp(t, 0.0, 1.0);
  return t < 0.5 ? pow(t * 2.0, e) * 0.5 : 1.0 - pow((1.0 - t) * 2.0, e) * 0.5;
}
void main() {
  float seed = aCell.z;
  float delay = 0.2 + seed * 1.8;
  float duration = PI * 0.5 + seed * PI;
  float cycleDuration = delay + duration + 2.0 + seed;
  float cycle = floor(uTime / cycleDuration);
  float localTime = uTime - cycle * cycleDuration;
  float turn = (cycle + easePowerInOut((localTime - delay) / duration, 3.0 + floor(seed * 3.0))) * PI * 0.5;
  float scale = uSpacing * 0.9;
  float breath = uTime - delay;
  if (breath > 0.0 && breath < 4.0) {
    float pr = breath <= 2.0 ? breath * 0.5 : (4.0 - breath) * 0.5;
    scale += (seed * 0.05 - 0.05) * (0.5 - cos(PI * clamp(pr, 0.0, 1.0)) * 0.5);
  }
  vec3 lv = aPosition * scale;
  vec3 ln = aNormal;
  if (seed < 0.5) { lv = rotateX(lv, turn); ln = rotateX(ln, turn); }
  else { lv = rotateZ(lv, turn); ln = rotateZ(ln, turn); }
  vec3 local = vec3(aCell.x * uSpacing, 0.0, aCell.y * uSpacing) + lv;
  vec3 world = rotateX(rotateY(local, -PI * 0.25), PI * 0.2);
  vNormal = normalize(rotateX(rotateY(ln, -PI * 0.25), PI * 0.2));
  vWorld = world;
  vGeometry = aPosition;
  vMouse = -lv;
  vUV = aUV;
  vDepth = 5.0 - world.z;
  vHighlight = all(lessThan(abs(aCell.xy - uHighlight), vec2(0.01))) ? 1.0 : 0.0;
  gl_Position = uProj * vec4(world, 1.0);
}`;

export const BROOKLYN_FRAGMENT = `#version 300 es
precision highp float;
in vec3 vWorld;
in vec3 vNormal;
in vec3 vGeometry;
in vec3 vMouse;
in vec2 vUV;
in float vDepth;
flat in float vHighlight;
uniform float uTime;
uniform vec3 uBase;
uniform vec3 uFog;
uniform int uStyle;
uniform vec2 uCorrection;
uniform sampler2D uTex0;
uniform sampler2D uTex1;
uniform sampler2D uEnvSpec;
uniform sampler2D uEnvDiffuse;
out vec4 outColor;
const float PI = ${PI};
${TONE}
vec2 rotateUV(vec2 uv, float a, vec2 m) {
  float c = cos(a), s = sin(a);
  return vec2(c * (uv.x - m.x) + s * (uv.y - m.y) + m.x, c * (uv.y - m.y) - s * (uv.x - m.x) + m.y);
}
vec3 env(sampler2D t, vec3 d) {
  d = normalize(d);
  vec2 uv = vec2(atan(d.z, d.x) / (2.0 * PI) + 0.5, 0.5 - asin(clamp(d.y, -1.0, 1.0)) / PI);
  return texture(t, uv).rgb;
}
vec3 brdf(vec3 sc, float r, float nv) {
  const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
  const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
  vec4 rr = r * c0 + c1;
  float a004 = min(rr.x * rr.x, exp2(-9.28 * nv)) * rr.x + rr.y;
  vec2 ab = vec2(-1.04, 1.04) * a004 + rr.zw;
  return sc * ab.x + ab.y;
}
void main() {
  vec3 diffuse = vHighlight > 0.5 ? vec3(1.0) : uBase;
  vec2 st = vUV * 2.0 - 0.5;
  vec3 q = vGeometry;
  vec2 md = (vMouse - vWorld).xy;
  float isBottom = step(q.y, -0.45);
  float isBack = step(q.z, -0.45);
  vec2 puv = rotateUV(st, length(md) * PI, vec2(0.5));
  puv = rotateUV(puv, uTime * 0.15, vec2(0.5));
  vec4 c0 = texture(uTex0, puv);
  vec4 c1 = texture(uTex1, puv);
  vec4 lower = mix(c0, c1, isBottom);
  lower = mix(lower, c0, step(0.9, diffuse.g));
  vec4 line = mix(vec4(0.0), lower, min(isBottom + isBack, 1.0));
  float inv = 1.0 - smoothstep(0.2, 0.745, length(md));
  line.rgb = mix(line.rgb, 1.0 - line.rgb, inv);
  float white = 1.0 - smoothstep(0.0, 1.5, distance(abs(st), vec2(1.0, 0.5)));
  diffuse = mix(diffuse, vec3(1.2), white);
  diffuse = mix(diffuse, line.rgb * 2.0, pow(line.a, 4.0));
  diffuse = mix(diffuse, diffuse * 1.23, 1.0 - smoothstep(-0.2, 0.6, length(md)));
  vec3 n = normalize(vNormal);
  vec3 v = normalize(vec3(0.0, 0.0, 5.0) - vWorld);
  float nv = clamp(dot(n, v), 0.0, 1.0);
  float rough = uStyle == 0 ? 0.5 : 0.28;
  vec3 refl = normalize(mix(reflect(-v, n), n, rough * rough));
  vec3 irradiance = env(uEnvDiffuse, n);
  vec3 radiance = env(uEnvSpec, refl);
  vec3 color = (diffuse * irradiance + radiance * brdf(vec3(0.04), rough, nv)) * 0.24;
  if (uStyle == 1) {
    float rim = pow(1.0 - nv, 3.0);
    vec3 h = normalize(normalize(vec3(-0.45, 0.78, 0.62)) + v);
    color += radiance * brdf(vec3(0.08), rough, nv) * 0.22;
    color += rim * vec3(0.68, 0.15, 0.34) * 0.34;
    color += pow(max(dot(n, h), 0.0), 34.0) * vec3(1.15, 0.72, 0.92) * 0.48;
  }
  float fog = 1.0 - exp(-0.08 * 0.08 * vDepth * vDepth);
  color = mix(color, uFog, clamp(fog, 0.0, 1.0));
  outColor = vec4(finish(color, uCorrection), 1.0);
}`;
