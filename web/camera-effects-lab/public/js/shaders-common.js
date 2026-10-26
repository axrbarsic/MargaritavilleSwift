// Общая часть шейдеров: вершинный шейдер, общие функции (CameraEffectsCommon.h)
// и проходы подготовки кадра (копия с зеркалом, размытие, медиана).

// Полноэкранный треугольник. Во всех текстурах ось v идёт сверху вниз, как в
// Metal: при записи во framebuffer (uToScreen = 0) строка v = 0 ложится в t = 0.
export const VERTEX = `#version 300 es
uniform float uToScreen;
out vec2 vUv;
void main() {
  vec2 p = vec2(gl_VertexID == 1 ? 3.0 : -1.0, gl_VertexID == 2 ? 3.0 : -1.0);
  vUv = vec2(p.x * 0.5 + 0.5, uToScreen > 0.5 ? 0.5 - p.y * 0.5 : 0.5 + p.y * 0.5);
  gl_Position = vec4(p, 0.0, 1.0);
}`;

export const HEADER = `#version 300 es
precision highp float;
precision highp int;
#define saturate(x) clamp(x, 0.0, 1.0)
in vec2 vUv;
out vec4 outColor;
`;

export const COMMON = `
uniform sampler2D uCam;
uniform vec2 uView;
uniform vec2 uTex;
uniform float uTime;
uniform int uEffect;
uniform float uAmount;
uniform float uBrightness;
uniform float uReliefDepth;
uniform float uLightAngle;
uniform float uEdge;
uniform float uDetail;
uniform float uMetalHue;
uniform float uMetalSat;
uniform float uLiveLight;
uniform float uGlow;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
vec2 aspectFill(vec2 uv, vec2 view, vec2 tex) {
  float viewAspect = view.x / view.y;
  float textureAspect = tex.x / tex.y;
  if (viewAspect < textureAspect) uv.x = 0.5 + (uv.x - 0.5) * viewAspect / textureAspect;
  else uv.y = 0.5 + (uv.y - 0.5) * textureAspect / viewAspect;
  return uv;
}
vec3 sampleCamera(vec2 uv) { return texture(uCam, uv).rgb; }
vec3 sampleScreen(vec2 pixel) { return sampleCamera(aspectFill(pixel / uView, uView, uTex)); }
float sobel(vec2 uv, vec2 texel, float gain) {
  float tl = luma(sampleCamera(uv + texel * vec2(-1.0, -1.0)));
  float t = luma(sampleCamera(uv + texel * vec2(0.0, -1.0)));
  float tr = luma(sampleCamera(uv + texel * vec2(1.0, -1.0)));
  float l = luma(sampleCamera(uv + texel * vec2(-1.0, 0.0)));
  float r = luma(sampleCamera(uv + texel * vec2(1.0, 0.0)));
  float bl = luma(sampleCamera(uv + texel * vec2(-1.0, 1.0)));
  float b = luma(sampleCamera(uv + texel * vec2(0.0, 1.0)));
  float br = luma(sampleCamera(uv + texel * vec2(1.0, 1.0)));
  float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
  float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
  return length(vec2(gx, gy)) * gain;
}
vec2 sobelVector(vec2 uv, vec2 texel) {
  float tl = luma(sampleCamera(uv + texel * vec2(-1.0, -1.0)));
  float t = luma(sampleCamera(uv + texel * vec2(0.0, -1.0)));
  float tr = luma(sampleCamera(uv + texel * vec2(1.0, -1.0)));
  float l = luma(sampleCamera(uv + texel * vec2(-1.0, 0.0)));
  float r = luma(sampleCamera(uv + texel * vec2(1.0, 0.0)));
  float bl = luma(sampleCamera(uv + texel * vec2(-1.0, 1.0)));
  float b = luma(sampleCamera(uv + texel * vec2(0.0, 1.0)));
  float br = luma(sampleCamera(uv + texel * vec2(1.0, 1.0)));
  return vec2(-tl - 2.0 * l - bl + tr + 2.0 * r + br, -tl - 2.0 * t - tr + bl + 2.0 * b + br);
}
float edgeMask(vec2 uv, vec2 texel, float radius, float low, float high, float gain) {
  return smoothstep(low, high, sobel(uv, texel * radius, gain));
}
vec3 hue(float h) { return saturate(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0); }
float bayer8(uvec2 p) {
  uint x = p.x & 7u;
  uint y = p.y & 7u;
  uint xy = x ^ y;
  uint value = ((xy & 1u) << 5) | ((y & 1u) << 4) | ((xy & 2u) << 2)
    | ((y & 2u) << 1) | ((xy & 4u) >> 1) | ((y & 4u) >> 2);
  return (float(value) + 0.5) / 64.0;
}
`;

// Копия кадра источника в рабочую текстуру; uMirror — зеркало для передней камеры.
export const COPY_FRAGMENT = `${HEADER}
uniform sampler2D uSrc;
uniform float uMirror;
void main() {
  vec2 uv = vec2(uMirror > 0.5 ? 1.0 - vUv.x : vUv.x, vUv.y);
  outColor = vec4(texture(uSrc, uv).rgb, 1.0);
}`;

// Отделимое гауссово размытие (для «Матового»): uDir — шаг в текселях по оси.
export const BLUR_FRAGMENT = `${HEADER}
uniform sampler2D uSrc;
uniform vec2 uDir;
uniform float uSigma;
void main() {
  vec3 sum = texture(uSrc, vUv).rgb;
  float total = 1.0;
  for (int i = 1; i <= 12; i++) {
    float w = exp(-float(i * i) / (2.0 * uSigma * uSigma));
    sum += (texture(uSrc, vUv + uDir * float(i)).rgb + texture(uSrc, vUv - uDir * float(i)).rgb) * w;
    total += 2.0 * w;
  }
  outColor = vec4(sum / total, 1.0);
}`;

// Медиана 3×3 по каналам (сеть сравнений); два прохода на уменьшенном кадре
// заменяют двойную медиану диаметра 9 из приложения.
export const MEDIAN_FRAGMENT = `${HEADER}
uniform sampler2D uSrc;
uniform vec2 uTexel;
#define s2(a, b) temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c) s2(a, b); s2(a, c);
#define mx3(a, b, c) s2(b, c); s2(a, c);
#define mnmx3(a, b, c) mx3(a, b, c); s2(a, b);
#define mnmx4(a, b, c, d) s2(a, b); s2(c, d); s2(a, c); s2(b, d);
#define mnmx5(a, b, c, d, e) s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f);
void main() {
  vec3 v[9];
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      v[(dx + 1) * 3 + (dy + 1)] = texture(uSrc, vUv + vec2(float(dx), float(dy)) * uTexel).rgb;
    }
  }
  vec3 temp;
  mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
  mnmx5(v[1], v[2], v[3], v[4], v[6]);
  mnmx4(v[2], v[3], v[4], v[7]);
  mnmx3(v[3], v[4], v[8]);
  outColor = vec4(v[4], 1.0);
}`;
