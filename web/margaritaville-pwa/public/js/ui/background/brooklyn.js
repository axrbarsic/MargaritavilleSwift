// Brooklyn 3D: сетка 16×16 скруглённых кубов исходной сцены, каждый поворачивается по
// своему таймингу; материал с текстурами, HDR-окружением, туманом и ACES-тонмаппингом.
// Источник: Packages/BrooklynBackgroundKit (BrooklynShaders.metal, BrooklynDonorContract.swift,
// BrooklynGridLayout.swift, BrooklynSceneState.swift). Свечение (bloom) упрощено.
import { BROOKLYN_VERTEX, BROOKLYN_FRAGMENT, FOG_VERTEX, FOG_FRAGMENT } from "./brooklyn-shaders.js";

const GRID = 16;
const STEPS = 15;
const ZOOM = 600;
const CAMERA_Z = 5;
const BASE = [245, 17, 85].map((v) => v / 255);
const FOG = [248, 0, 168].map((v) => v / 255);
export const DONOR_HUE = 0.9502923976608187;

const rotX = ([x, y, z], a) => [x, Math.cos(a) * y - Math.sin(a) * z, Math.sin(a) * y + Math.cos(a) * z];
const rotY = ([x, y, z], a) => [Math.cos(a) * x + Math.sin(a) * z, y, -Math.sin(a) * x + Math.cos(a) * z];
const toWorld = (p) => rotX(rotY(p, -Math.PI / 4), Math.PI / 5);
const toLocal = (p) => rotY(rotX(p, -Math.PI / 5), Math.PI / 4);

function planeHit(sx, sy) {
  const o = toLocal([sx, sy, CAMERA_Z]);
  const d = toLocal([0, 0, -1]);
  if (Math.abs(d[1]) < 1e-4) return null;
  const t = -o[1] / d[1];
  return [o[0] + d[0] * t, 0, o[2] + d[2] * t];
}

function hueShift([r, g, b], hue) {
  if (hue === DONOR_HUE) return [r, g, b];
  const max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2;
  if (max === min) return [l, l, l];
  const d = max - min;
  const s = l <= 0.5 ? d / (max + min) : d / (2 - max - min);
  let hh = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
  hh = ((hh / 6 + hue - DONOR_HUE + 1) % 1);
  const q = l <= 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q;
  const ch = (t) => { t = (t + 1) % 1; return t < 1 / 6 ? p + (q - p) * 6 * t : t < 0.5 ? q : t < 2 / 3 ? p + (q - p) * (2 / 3 - t) * 6 : p; };
  return [ch(hh + 1 / 3), ch(hh), ch(hh - 1 / 3)];
}
const toLinear = (c) => c.map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));

export class Brooklyn {
  constructor(container, settings) {
    this.settings = settings;
    this.canvas = document.createElement("canvas");
    this.canvas.className = "bg-canvas";
    container.append(this.canvas);
    this.gl = this.canvas.getContext("webgl2", { antialias: true, alpha: false, powerPreference: "high-performance" });
    this.running = false;
    this.elapsed = 0;
    this.ready = this.gl ? this.load().catch(() => { this.failed = true; }) : Promise.resolve((this.failed = true));
  }

  program(vs, fs) {
    const gl = this.gl;
    const make = (type, src) => { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s); if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s)); return s; };
    const p = gl.createProgram();
    gl.attachShader(p, make(gl.VERTEX_SHADER, vs));
    gl.attachShader(p, make(gl.FRAGMENT_SHADER, fs));
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(p));
    const cache = new Map();
    return { p, u: (n) => { if (!cache.has(n)) cache.set(n, gl.getUniformLocation(p, n)); return cache.get(n); } };
  }

  async load() {
    const gl = this.gl;
    const [mesh, env, tex0, tex1] = await Promise.all([
      fetch("brooklyn/BrooklynDonorMesh.bin").then((r) => r.arrayBuffer()),
      fetch("brooklyn/environment.json").then((r) => r.json()),
      this.image("brooklyn/tex0.png"),
      this.image("brooklyn/tex1.png")
    ]);
    this.scene = this.program(BROOKLYN_VERTEX, BROOKLYN_FRAGMENT);
    this.fog = this.program(FOG_VERTEX, FOG_FRAGMENT);
    const view = new DataView(mesh);
    const vertexCount = view.getUint32(12, true);
    const indexCount = view.getUint32(16, true);
    this.indexCount = indexCount;
    this.vao = gl.createVertexArray();
    gl.bindVertexArray(this.vao);
    const vbo = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(mesh, 24, vertexCount * 8), gl.STATIC_DRAW);
    [[0, 3, 0], [1, 3, 12], [2, 2, 24]].forEach(([loc, size, offset]) => { gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc, size, gl.FLOAT, false, 32, offset); });
    const ibo = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(mesh, 24 + vertexCount * 32, indexCount), gl.STATIC_DRAW);
    this.instanceBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.instanceBuffer);
    gl.enableVertexAttribArray(3);
    gl.vertexAttribPointer(3, 3, gl.FLOAT, false, 12, 0);
    gl.vertexAttribDivisor(3, 1);
    gl.bindVertexArray(null);
    this.tex0 = this.texture(tex0, gl.RGBA, gl.UNSIGNED_BYTE, gl.REPEAT);
    this.tex1 = this.texture(tex1, gl.RGBA, gl.UNSIGNED_BYTE, gl.REPEAT);
    this.envSpec = this.envTexture(env.spec);
    this.envDiffuse = this.envTexture(env.diffuse);
    this.fogVao = gl.createVertexArray();
  }

  image(src) {
    return new Promise((resolve, reject) => { const img = new Image(); img.onload = () => resolve(img); img.onerror = reject; img.src = src; });
  }

  texture(source, format, type, wrap) {
    const gl = this.gl;
    const t = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, t);
    gl.texImage2D(gl.TEXTURE_2D, 0, format, format, type, source);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap);
    return t;
  }

  envTexture({ w, h, rgb }) {
    const gl = this.gl;
    const data = new Float32Array(w * h * 4);
    for (let i = 0; i < w * h; i += 1) data.set([rgb[i * 3], rgb[i * 3 + 1], rgb[i * 3 + 2], 1], i * 4);
    const t = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, t);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, w, h, 0, gl.RGBA, gl.FLOAT, data);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    return t;
  }

  /// Ячейки: исходные 16×16, при уменьшении — достройка видимых краёв (BrooklynGridLayout.cells).
  layout(width, height, cellScale) {
    const key = `${width}x${height}@${cellScale}`;
    if (key === this.layoutKey) return;
    this.layoutKey = key;
    const base = [width / ZOOM, height / ZOOM];
    const spacing = Math.max(4, Math.max(...base) * 1.1) / STEPS;
    const half = STEPS / 2;
    const cells = [];
    for (let i = 0; i < GRID * GRID; i += 1) cells.push(Math.floor(i / GRID) - half, (i % GRID) - half, (i * 0.618033988749895) % 1);
    if (cellScale < 1) {
      const hw = base[0] / (2 * cellScale), hh = base[1] / (2 * cellScale);
      let maxLocal = 0;
      for (const [x, y] of [[-hw, -hh], [-hw, hh], [hw, -hh], [hw, hh]]) {
        const p = planeHit(x, y);
        if (p) maxLocal = Math.max(maxLocal, Math.abs(p[0]), Math.abs(p[2]));
      }
      const limit = Math.ceil(maxLocal / spacing) + 2;
      const guard = spacing * 1.25;
      for (let xi = -limit; xi < limit; xi += 1) for (let zi = -limit; zi < limit; zi += 1) {
        const gx = xi + 0.5, gz = zi + 0.5;
        if (Math.abs(gx) <= half && Math.abs(gz) <= half) continue;
        const w = toWorld([gx * spacing, 0, gz * spacing]);
        if (Math.abs(w[0]) > hw + guard || Math.abs(w[1]) > hh + guard) continue;
        const v = Math.sin(gx * 12.9898 + gz * 78.233) * 43758.5453;
        cells.push(gx, gz, v - Math.floor(v));
      }
    }
    const target = planeHit((base[0] / cellScale / 2) * 0.4, (base[1] / cellScale / 2) * 0.4);
    this.highlight = target ? [Math.floor(target[0] / spacing) + 0.5, Math.floor(target[2] / spacing) + 0.5] : [1e9, 1e9];
    this.spacing = spacing;
    this.viewport = [base[0] / cellScale, base[1] / cellScale];
    this.instanceCount = cells.length / 3;
    const gl = this.gl;
    gl.bindBuffer(gl.ARRAY_BUFFER, this.instanceBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(cells), gl.STATIC_DRAW);
  }

  start() {
    if (this.running) return;
    this.running = true;
    this.last = null;
    const loop = (t) => {
      if (!this.running) return;
      if (this.last != null) this.elapsed += Math.min((t - this.last) / 1000, 0.1);
      this.last = t;
      if (this.vao) this.frame();
      this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  stop() {
    this.running = false;
    cancelAnimationFrame(this.raf);
  }

  frame() {
    const gl = this.gl;
    const s = this.settings;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const width = window.innerWidth, height = window.innerHeight;
    if (this.canvas.width !== Math.round(width * dpr) || this.canvas.height !== Math.round(height * dpr)) {
      this.canvas.width = Math.round(width * dpr);
      this.canvas.height = Math.round(height * dpr);
    }
    const cellScale = Math.min(Math.max(s.get("brooklynCellScale"), 0.45), 1.25);
    this.layout(width, height, cellScale);
    const hue = s.get("brooklynHue") ?? DONOR_HUE;
    const correction = [(s.get("brooklynBrightness") ?? 1) - 1, s.get("brooklynContrast") ?? 0];
    const fog = toLinear(hueShift(FOG, hue));
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    gl.disable(gl.DEPTH_TEST);
    gl.useProgram(this.fog.p);
    gl.bindVertexArray(this.fogVao);
    gl.uniform3fv(this.fog.u("uFog"), fog);
    gl.uniform2fv(this.fog.u("uCorrection"), correction);
    gl.drawArrays(gl.TRIANGLES, 0, 3);

    gl.enable(gl.DEPTH_TEST);
    gl.clear(gl.DEPTH_BUFFER_BIT);
    const [vw, vh] = this.viewport;
    const near = 0.1, far = 1000;
    // Ортографическая камера, сдвинутая на CAMERA_Z: ortho × translate(0, 0, −CAMERA_Z).
    const depth = far - near;
    const proj = new Float32Array([2 / vw, 0, 0, 0, 0, 2 / vh, 0, 0, 0, 0, -2 / depth, 0, 0, 0, (2 * CAMERA_Z) / depth - (far + near) / depth, 1]);
    const p = this.scene;
    gl.useProgram(p.p);
    gl.bindVertexArray(this.vao);
    gl.uniformMatrix4fv(p.u("uProj"), false, proj);
    gl.uniform1f(p.u("uTime"), this.elapsed);
    gl.uniform1f(p.u("uSpacing"), this.spacing);
    gl.uniform2fv(p.u("uHighlight"), this.highlight);
    gl.uniform3fv(p.u("uBase"), toLinear(hueShift(BASE, hue)));
    gl.uniform3fv(p.u("uFog"), fog);
    gl.uniform1i(p.u("uStyle"), s.get("brooklynSurfaceStyle") === "enhanced" ? 1 : 0);
    gl.uniform2fv(p.u("uCorrection"), correction);
    [[this.tex0, "uTex0"], [this.tex1, "uTex1"], [this.envSpec, "uEnvSpec"], [this.envDiffuse, "uEnvDiffuse"]].forEach(([t, name], i) => {
      gl.activeTexture(gl.TEXTURE0 + i);
      gl.bindTexture(gl.TEXTURE_2D, t);
      gl.uniform1i(p.u(name), i);
    });
    gl.drawElementsInstanced(gl.TRIANGLES, this.indexCount, gl.UNSIGNED_SHORT, 0, this.instanceCount);
  }

  destroy() {
    this.stop();
    this.canvas.remove();
    this.gl?.getExtension("WEBGL_lose_context")?.loseContext();
  }
}
