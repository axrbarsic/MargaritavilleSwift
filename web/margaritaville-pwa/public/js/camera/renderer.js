// WebGL 2 рендер: копия кадра (с зеркалом для передней камеры) → подготовка
// («Матовый» — размытие, «Мультфильм» и «Таблица металлов» — медиана) →
// один проход эффекта на экран. Повторяет CameraBackgroundRenderer.swift.
import { VERTEX, COPY_FRAGMENT, BLUR_FRAGMENT, MEDIAN_FRAGMENT } from "./shaders-common.js";
import { EFFECT_FRAGMENT } from "./shaders-effects.js";
import { tr } from "../i18n/i18n.js";

const MAX_WORK_SIDE = 1280;

export class Renderer {
  constructor(canvas) {
    const gl = canvas.getContext("webgl2", { antialias: false, alpha: false, powerPreference: "high-performance" });
    if (!gl) throw new Error(tr("WebGL 2 недоступен"));
    this.gl = gl;
    this.canvas = canvas;
    this.vao = gl.createVertexArray();
    this.programs = {
      copy: this.makeProgram(COPY_FRAGMENT),
      blur: this.makeProgram(BLUR_FRAGMENT),
      median: this.makeProgram(MEDIAN_FRAGMENT),
      effect: this.makeProgram(EFFECT_FRAGMENT)
    };
    this.sourceTexture = this.makeTexture();
    this.targets = new Map();
  }

  makeProgram(fragmentSource) {
    const gl = this.gl;
    const compile = (type, source) => {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        throw new Error(tr("Ошибка шейдера: {log}", { log: gl.getShaderInfoLog(shader) }));
      }
      return shader;
    };
    const program = gl.createProgram();
    gl.attachShader(program, compile(gl.VERTEX_SHADER, VERTEX));
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, fragmentSource));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(tr("Ошибка сборки шейдера: {log}", { log: gl.getProgramInfoLog(program) }));
    }
    const locations = new Map();
    return {
      program,
      loc: (name) => {
        if (!locations.has(name)) locations.set(name, gl.getUniformLocation(program, name));
        return locations.get(name);
      }
    };
  }

  makeTexture() {
    const gl = this.gl;
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    return texture;
  }

  target(name, width, height) {
    const gl = this.gl;
    const existing = this.targets.get(name);
    if (existing && existing.width === width && existing.height === height) return existing;
    if (existing) {
      gl.deleteTexture(existing.texture);
      gl.deleteFramebuffer(existing.framebuffer);
    }
    const texture = this.makeTexture();
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    const framebuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
    const target = { texture, framebuffer, width, height };
    this.targets.set(name, target);
    return target;
  }

  pass(program, target, texture, setUniforms) {
    const gl = this.gl;
    gl.bindFramebuffer(gl.FRAMEBUFFER, target ? target.framebuffer : null);
    gl.viewport(0, 0, target ? target.width : this.canvas.width, target ? target.height : this.canvas.height);
    gl.useProgram(program.program);
    gl.bindVertexArray(this.vao);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.uniform1f(program.loc("uToScreen"), target ? 0 : 1);
    setUniforms(program);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
  }

  /// Рисует один кадр. source — video, img или canvas; settings — состояние эффекта.
  render(source, mirror, settings, timeSeconds) {
    const gl = this.gl;
    const sourceWidth = source.videoWidth || source.naturalWidth || source.width;
    const sourceHeight = source.videoHeight || source.naturalHeight || source.height;
    if (!sourceWidth || !sourceHeight) return false;

    gl.bindTexture(gl.TEXTURE_2D, this.sourceTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, source);

    const scale = Math.min(1, MAX_WORK_SIDE / Math.max(sourceWidth, sourceHeight));
    const workWidth = Math.max(2, Math.round(sourceWidth * scale));
    const workHeight = Math.max(2, Math.round(sourceHeight * scale));
    const base = this.target("base", workWidth, workHeight);
    this.pass(this.programs.copy, base, this.sourceTexture, (p) => {
      gl.uniform1i(p.loc("uSrc"), 0);
      gl.uniform1f(p.loc("uMirror"), mirror ? 1 : 0);
    });

    let cameraTexture = base.texture;
    if (settings.prefilter === "blur") {
      cameraTexture = this.blur(base);
    } else if (settings.prefilter === "median") {
      cameraTexture = this.median(base);
    }

    this.pass(this.programs.effect, null, cameraTexture, (p) => {
      const t = settings.tuning;
      gl.uniform1i(p.loc("uCam"), 0);
      gl.uniform2f(p.loc("uView"), this.canvas.width, this.canvas.height);
      gl.uniform2f(p.loc("uTex"), workWidth, workHeight);
      gl.uniform1f(p.loc("uTime"), timeSeconds);
      gl.uniform1i(p.loc("uEffect"), settings.shader);
      gl.uniform1f(p.loc("uAmount"), t.amount);
      gl.uniform1f(p.loc("uBrightness"), t.brightness);
      gl.uniform1f(p.loc("uReliefDepth"), t.reliefDepth);
      gl.uniform1f(p.loc("uLightAngle"), (t.lightAngle * Math.PI) / 180);
      gl.uniform1f(p.loc("uEdge"), t.edgeSensitivity);
      gl.uniform1f(p.loc("uDetail"), t.detailScale);
      gl.uniform1f(p.loc("uMetalHue"), t.metalHue / 360);
      gl.uniform1f(p.loc("uMetalSat"), t.metalSaturation);
      gl.uniform1f(p.loc("uLiveLight"), t.liveLight ? 1 : 0);
      gl.uniform1f(p.loc("uGlow"), t.glowAmount);
    });
    return true;
  }

  /// Сильное размытие на четверти разрешения (в приложении — MPS, сигма 22 на 1080p).
  blur(base) {
    const gl = this.gl;
    const width = Math.max(2, Math.round(base.width / 4));
    const height = Math.max(2, Math.round(base.height / 4));
    const a = this.target("blurA", width, height);
    const b = this.target("blurB", width, height);
    this.pass(this.programs.copy, a, base.texture, (p) => {
      gl.uniform1i(p.loc("uSrc"), 0);
      gl.uniform1f(p.loc("uMirror"), 0);
    });
    const sigma = (22 * base.width) / 1080 / 4;
    const run = (from, to, dx, dy) =>
      this.pass(this.programs.blur, to, from.texture, (p) => {
        gl.uniform1i(p.loc("uSrc"), 0);
        gl.uniform2f(p.loc("uDir"), dx, dy);
        gl.uniform1f(p.loc("uSigma"), sigma);
      });
    run(a, b, 1 / width, 0);
    run(b, a, 0, 1 / height);
    return a.texture;
  }

  /// Медиана на половине разрешения в два прохода — сглаживание с сохранением краёв.
  median(base) {
    const gl = this.gl;
    const width = Math.max(2, Math.round(base.width / 2));
    const height = Math.max(2, Math.round(base.height / 2));
    const a = this.target("medianA", width, height);
    const b = this.target("medianB", width, height);
    this.pass(this.programs.copy, a, base.texture, (p) => {
      gl.uniform1i(p.loc("uSrc"), 0);
      gl.uniform1f(p.loc("uMirror"), 0);
    });
    const run = (from, to) =>
      this.pass(this.programs.median, to, from.texture, (p) => {
        gl.uniform1i(p.loc("uSrc"), 0);
        gl.uniform2f(p.loc("uTexel"), 1 / width, 1 / height);
      });
    run(a, b);
    run(b, a);
    return a.texture;
  }
}
