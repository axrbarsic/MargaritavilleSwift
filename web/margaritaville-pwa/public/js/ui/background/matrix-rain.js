// Matrix Rain: 80 капель символов, голова яркая, хвост гаснет, символы мерцают.
// Источник: Effects/SpriteKit/MatrixRainSpriteScene.swift (те же скорости, прозрачности, шрифт).
const GLYPHS = [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃ日田大木本山川空海風火水金土月星"];
const DROPS = 80;
const FONT = 18;
const CHAR_H = FONT * 1.2;
const BG = "rgb(2, 8, 4)";

const glyph = () => GLYPHS[Math.floor(Math.random() * GLYPHS.length)];
const makeDrop = (startY) => ({
  x: Math.random(),
  y: startY,
  velocity: 0.3 + Math.random() * 1.2,
  opacity: 0.28 + Math.random() * 0.58,
  glyphs: Array.from({ length: 8 + Math.floor(Math.random() * 25) }, glyph)
});

export class MatrixRain {
  constructor(container, settings) {
    this.settings = settings;
    this.canvas = document.createElement("canvas");
    this.canvas.className = "bg-canvas";
    container.append(this.canvas);
    this.ctx = this.canvas.getContext("2d", { alpha: false });
    this.drops = Array.from({ length: DROPS }, () => makeDrop(-Math.random()));
    this.last = null;
    this.running = false;
    this.resize = () => this.fit();
    window.addEventListener("resize", this.resize);
    this.fit();
  }

  fit() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = Math.round(this.width * dpr);
    this.canvas.height = Math.round(this.height * dpr);
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    const g = this.ctx.createRadialGradient(this.width / 2, this.height / 2, 0, this.width / 2, this.height / 2, Math.hypot(this.width, this.height) / 2);
    g.addColorStop(0, "rgba(2,8,4,0)");
    g.addColorStop(1, "rgba(2,8,4,0.74)");
    this.vignette = g;
  }

  start() {
    if (this.running) return;
    this.running = true;
    this.last = null;
    const loop = (t) => {
      if (!this.running) return;
      this.frame(t);
      this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  stop() {
    this.running = false;
    cancelAnimationFrame(this.raf);
  }

  frame(time) {
    const step = this.last == null ? 1 / 60 : Math.min(Math.max(0, (time - this.last) / 1000), 1 / 30);
    this.last = time;
    const speed = Math.min(Math.max(this.settings.get("matrixSpeed"), 0.08), 3);
    const { ctx, width, height } = this;
    ctx.fillStyle = BG;
    ctx.fillRect(0, 0, width, height);
    ctx.font = `bold ${FONT}px Courier, "Courier New", monospace`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    for (let i = this.drops.length - 1; i >= 0; i -= 1) {
      const drop = this.drops[i];
      drop.y += drop.velocity * 0.5 * step * speed;
      if (drop.y > 1.3) {
        this.drops[i] = makeDrop(-0.3);
        continue;
      }
      if (Math.random() < 0.03) drop.glyphs[Math.floor(Math.random() * drop.glyphs.length)] = glyph();
      const px = drop.x * width;
      const head = drop.y * height;
      const count = drop.glyphs.length;
      for (let k = 0; k < count; k += 1) {
        const y = head - k * CHAR_H;
        if (y < -CHAR_H || y > height + CHAR_H) continue;
        const alpha = k === 0 ? drop.opacity : drop.opacity * (1 - k / count) * 0.7;
        const b = k < 3 ? 0.9 : 0.4;
        ctx.fillStyle = `rgba(${Math.round(130 * b)}, ${Math.round(255 * b)}, ${Math.round(100 * b)}, ${Math.min(Math.max(alpha, 0), 1)})`;
        if (k === 0) {
          ctx.shadowColor = `rgba(128, 255, 128, ${drop.opacity * 0.6})`;
          ctx.shadowBlur = 6;
        }
        ctx.fillText(drop.glyphs[k], px, y);
        if (k === 0) ctx.shadowBlur = 0;
      }
    }
    ctx.fillStyle = this.vignette;
    ctx.fillRect(0, 0, width, height);
  }

  destroy() {
    this.stop();
    window.removeEventListener("resize", this.resize);
    this.canvas.remove();
  }
}
