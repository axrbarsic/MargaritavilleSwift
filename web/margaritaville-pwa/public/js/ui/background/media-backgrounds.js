// Видео-фон и камера-фон.
// Видео: своё видео с матовостью, яркостью, зелёным оттенком и сеткой (LoopingVideoBackgroundView.swift).
// Камера: задняя или передняя камера через эффекты из лаборатории (CameraBackgroundView.swift,
// CameraBackgroundRenderer.swift). Камера выключается, когда приложение скрыто или поверх открыт экран.
import { loadFile } from "../../store/db.js";
import { Renderer } from "../../camera/renderer.js";
import { EFFECTS, TUNING_DEFAULTS } from "../../camera/effects.js";

export const BACKGROUND_VIDEO_KEY = "backgroundVideo";

export class VideoBackground {
  constructor(container, settings) {
    this.settings = settings;
    this.video = Object.assign(document.createElement("video"), { muted: true, loop: true, playsInline: true, autoplay: true });
    this.video.setAttribute("playsinline", "");
    this.video.className = "bg-video";
    this.tint = Object.assign(document.createElement("div"), { className: "bg-video-tint" });
    this.dim = Object.assign(document.createElement("div"), { className: "bg-video-dim" });
    this.grid = Object.assign(document.createElement("div"), { className: "bg-video-grid" });
    container.append(this.video, this.tint, this.dim, this.grid);
    this.loadVideo();
  }

  async loadVideo() {
    const blob = await loadFile(BACKGROUND_VIDEO_KEY).catch(() => null);
    if (this.url) URL.revokeObjectURL(this.url);
    this.url = blob ? URL.createObjectURL(blob) : null;
    if (this.url) { this.video.src = this.url; this.start(); }
  }

  apply() {
    const s = this.settings;
    const blur = Math.min(Math.max(s.get("backgroundVideoBlur"), 0), 1);
    const green = Math.min(Math.max(s.get("backgroundVideoGreenTint"), 0), 1);
    const brightness = Math.min(Math.max(s.get("backgroundVideoBrightness"), -0.85), 0.85);
    const grid = Math.min(Math.max(s.get("backgroundVideoGridIntensity"), 0), 1);
    this.video.style.filter = `blur(${(blur * 24).toFixed(1)}px) brightness(${1 + Math.max(0, brightness) * 0.35})`;
    this.tint.style.opacity = green <= 0.01 ? 0 : 0.04 + green * 0.76;
    this.dim.style.opacity = brightness < 0 ? Math.abs(brightness) * 0.82 : 0;
    this.grid.style.opacity = grid;
    this.grid.style.setProperty("--minor", 0.1 + grid * 0.24);
    this.grid.style.setProperty("--major", 0.05 + grid * 0.13);
  }

  start() { this.apply(); this.video.play().catch(() => {}); }
  stop() { this.video.pause(); }
  destroy() {
    this.stop();
    if (this.url) URL.revokeObjectURL(this.url);
    [this.video, this.tint, this.dim, this.grid].forEach((el) => el.remove());
  }
}

export class CameraBackground {
  constructor(container, settings) {
    this.settings = settings;
    this.canvas = Object.assign(document.createElement("canvas"), { className: "bg-canvas" });
    this.status = Object.assign(document.createElement("div"), { className: "bg-status", hidden: true });
    container.append(this.canvas, this.status);
    this.video = Object.assign(document.createElement("video"), { muted: true, playsInline: true });
    this.video.setAttribute("playsinline", "");
    try {
      this.renderer = new Renderer(this.canvas);
    } catch {
      this.say("Эффекты камеры требуют WebGL 2, а он недоступен.");
    }
    this.running = false;
    this.started = performance.now();
  }

  say(text) { this.status.hidden = !text; this.status.textContent = text ?? ""; }

  async openCamera() {
    const facing = this.settings.get("cameraFacing");
    if (this.stream && this.facing === facing) return;
    this.closeCamera();
    this.facing = facing;
    if (!navigator.mediaDevices?.getUserMedia) return this.say("Браузер не даёт доступ к камере.");
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: false, video: { facingMode: { ideal: facing }, width: { ideal: 1280 }, height: { ideal: 720 } } });
      if (!this.running) return this.closeCamera();
      // Пользователь остановил камеру через значок iOS (Dynamic Island) или система забрала её:
      // помечаем поток мёртвым и включаем снова на следующем касании экрана.
      const stream = this.stream;
      stream.getVideoTracks().forEach((track) => track.addEventListener("ended", () => this.cameraLost(stream)));
      this.video.srcObject = this.stream;
      await this.video.play();
      this.say(null);
    } catch (error) {
      const denied = error?.name === "NotAllowedError" || error?.name === "SecurityError";
      this.say(denied ? "Нет доступа к камере. Коснитесь экрана, чтобы попробовать снова, или разрешите камеру в настройках." : "Камера не запустилась. Коснитесь экрана, чтобы попробовать снова.");
      this.stream = null;
      if (this.running) this.waitForTouch();
    }
  }

  cameraLost(stream) {
    if (this.stream !== stream) return;
    this.stream = null;
    this.video.srcObject = null;
    if (!this.running) return;
    this.say("Камера остановлена. Коснитесь экрана, чтобы включить её снова.");
    this.waitForTouch();
  }

  /// Перезапуск камеры по касанию: iOS разрешает доступ к камере только после жеста.
  waitForTouch() {
    if (this.touchWaiter) return;
    this.touchWaiter = () => {
      window.removeEventListener("pointerdown", this.touchWaiter, true);
      this.touchWaiter = null;
      if (this.running && !this.stream) this.openCamera();
    };
    window.addEventListener("pointerdown", this.touchWaiter, true);
  }

  closeCamera() {
    this.stream?.getTracks().forEach((t) => t.stop());
    this.stream = null;
  }

  effectSettings() {
    const id = EFFECTS[this.settings.get("cameraEffect")] ? this.settings.get("cameraEffect") : "normal";
    const effect = EFFECTS[id];
    return { shader: effect.shader, prefilter: effect.prefilter ?? null, tuning: { ...TUNING_DEFAULTS, ...(this.settings.get("cameraTuning")?.[id] ?? {}) } };
  }

  start() {
    if (this.running || !this.renderer) return;
    this.running = true;
    this.openCamera();
    const loop = (t) => {
      if (!this.running) return;
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const w = Math.round(window.innerWidth * dpr), h = Math.round(window.innerHeight * dpr);
      if (this.canvas.width !== w || this.canvas.height !== h) { this.canvas.width = w; this.canvas.height = h; }
      // Подстраховка: Safari не всегда шлёт «ended», поэтому проверяем состояние дорожки каждый кадр.
      if (this.stream && this.stream.getVideoTracks().every((track) => track.readyState === "ended")) this.cameraLost(this.stream);
      if (this.stream && this.video.paused) this.video.play().catch(() => {});
      if (this.video.readyState >= 2 && this.stream) this.renderer.render(this.video, this.facing === "user", this.effectSettings(), (t - this.started) / 1000);
      this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  stop() {
    this.running = false;
    cancelAnimationFrame(this.raf);
    this.closeCamera();
  }

  apply() { if (this.running) this.openCamera(); }

  destroy() {
    this.stop();
    this.canvas.remove();
    this.status.remove();
  }
}
