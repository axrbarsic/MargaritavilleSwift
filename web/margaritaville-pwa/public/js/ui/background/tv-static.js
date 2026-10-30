// Сломанный телевизор: аналоговый снег пятью вариантами, яркость, зелёный оттенок,
// строки развёртки. Источник: App/TVStaticNoiseBackgroundView.swift (те же коэффициенты).
export const TV_VARIANTS = [
  { id: "classicAnalog", title: "Analog", description: "Классический серый аналоговый снег.", renderScale: 1, contrast: 1.9, bScale: 1.25, bBias: 0, rgb: [1, 1, 1] },
  { id: "fineSnow", title: "Fine", description: "Более мелкое плотное зерно.", renderScale: 1.75, contrast: 2.18, bScale: 1.05, bBias: -0.04, rgb: [1, 1, 1] },
  { id: "horizontalTear", title: "Tear", description: "Горизонтальные срывы и полосы.", renderScale: 1.15, contrast: 2.45, bScale: 1.2, bBias: -0.06, rgb: [1, 1, 1], tear: true },
  { id: "greenTerminal", title: "Green", description: "Зелёный цифровой шум.", renderScale: 1.35, contrast: 2.05, bScale: 1.1, bBias: -0.1, rgb: [0.3, 1.45, 0.22], green: 0.72 },
  { id: "highContrast", title: "Hard", description: "Жёсткий контрастный снег.", renderScale: 0.82, contrast: 3.15, bScale: 1.45, bBias: -0.02, rgb: [1.08, 1.08, 1.08] }
];

export class TVStatic {
  constructor(container, settings) {
    this.settings = settings;
    this.canvas = document.createElement("canvas");
    this.canvas.className = "bg-canvas pixelated";
    this.lines = document.createElement("div");
    this.lines.className = "bg-scanlines";
    container.append(this.canvas, this.lines);
    this.ctx = this.canvas.getContext("2d", { alpha: false });
    this.running = false;
  }

  variant() {
    return TV_VARIANTS.find((v) => v.id === this.settings.get("tvStaticVariant")) ?? TV_VARIANTS[0];
  }

  fitSize(v) {
    const aspect = window.innerHeight / Math.max(window.innerWidth, 1);
    const particle = Math.max(this.settings.get("tvStaticParticleSize") ?? 1, 0.5);
    const width = Math.round(Math.min(420, Math.max(80, (180 * v.renderScale) / particle)));
    const height = Math.round(Math.max(240, width * aspect));
    if (this.canvas.width !== width || this.canvas.height !== height) {
      this.canvas.width = width;
      this.canvas.height = height;
      this.image = this.ctx.createImageData(width, height);
    }
  }

  start() {
    if (this.running) return;
    this.running = true;
    let phase = 0;
    const loop = () => {
      if (!this.running) return;
      phase += Math.max(this.settings.get("tvStaticSpeed") ?? 1, 0.05);
      // Шум меняется каждый кадр; при скорости < 1 часть кадров пропускается.
      if (phase >= 1) { phase %= 1; this.frame(); }
      this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  stop() {
    this.running = false;
    cancelAnimationFrame(this.raf);
  }

  frame() {
    const v = this.variant();
    this.fitSize(v);
    const data = this.image.data;
    const green = Math.min(1, Math.min(Math.max(this.settings.get("tvStaticGreenTint"), 0), 1) + (v.green ?? 0));
    const brightness = Math.min(Math.max(this.settings.get("tvStaticBrightness") * v.bScale + v.bBias, -1), 1);
    const contrast = v.contrast + 0.45 * green;
    const r = Math.max(0, 1 - 0.97 * green) * v.rgb[0];
    const g = (1 + 0.55 * green) * v.rgb[1];
    const b = Math.max(0, 1 - 0.92 * green) * v.rgb[2];
    const width = this.canvas.width;
    let tearValue = 0;
    for (let i = 0, p = 0; i < data.length; i += 4, p += 1) {
      let n = Math.random();
      if (v.tear) {
        // Размытие по горизонтали: соседние точки строки похожи.
        tearValue = p % width === 0 ? n : tearValue * 0.7 + n * 0.3;
        n = tearValue;
      }
      const value = Math.min(Math.max((n - 0.5) * contrast + 0.5 + brightness, 0), 1) * 255;
      data[i] = value * r;
      data[i + 1] = value * g;
      data[i + 2] = value * b;
      data[i + 3] = 255;
    }
    this.ctx.putImageData(this.image, 0, 0);
  }

  destroy() {
    this.stop();
    this.canvas.remove();
    this.lines.remove();
  }
}
