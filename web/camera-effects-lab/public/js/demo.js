// Встроенная анимированная демо-сцена: закат над заливом с яркими цветами,
// контурами и движением, чтобы эффекты было видно без камеры.

export function createDemoScene() {
  const canvas = document.createElement("canvas");
  canvas.width = 720;
  canvas.height = 1280;
  const ctx = canvas.getContext("2d");

  function draw(t) {
    const w = canvas.width;
    const h = canvas.height;
    const sky = ctx.createLinearGradient(0, 0, 0, h * 0.62);
    sky.addColorStop(0, "#1b2a6b");
    sky.addColorStop(0.55, "#e0567a");
    sky.addColorStop(1, "#ffc06b");
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, w, h);

    ctx.fillStyle = "#fff3c4";
    ctx.beginPath();
    ctx.arc(w * 0.62, h * 0.47 + Math.sin(t * 0.3) * 8, 110, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = "#3b1f4d";
    ctx.beginPath();
    ctx.moveTo(0, h * 0.6);
    ctx.lineTo(w * 0.18, h * 0.43);
    ctx.lineTo(w * 0.38, h * 0.58);
    ctx.lineTo(w * 0.55, h * 0.5);
    ctx.lineTo(w, h * 0.62);
    ctx.lineTo(w, h);
    ctx.lineTo(0, h);
    ctx.fill();

    const sea = ctx.createLinearGradient(0, h * 0.62, 0, h);
    sea.addColorStop(0, "#2b6f9e");
    sea.addColorStop(1, "#0b2236");
    ctx.fillStyle = sea;
    ctx.fillRect(0, h * 0.62, w, h * 0.38);

    ctx.strokeStyle = "rgba(255, 220, 170, 0.75)";
    ctx.lineWidth = 3;
    for (let i = 0; i < 14; i++) {
      const y = h * 0.64 + i * 32;
      ctx.beginPath();
      for (let x = 0; x <= w; x += 24) ctx.lineTo(x, y + Math.sin(x * 0.03 + t * 1.4 + i) * (3 + i * 0.6));
      ctx.stroke();
    }

    ctx.fillStyle = "#14101c";
    ctx.fillRect(w * 0.16, h * 0.7, 18, h * 0.3);
    for (let i = 0; i < 6; i++) {
      const a = -Math.PI / 2 + (i - 2.5) * 0.45 + Math.sin(t + i) * 0.05;
      ctx.beginPath();
      ctx.ellipse(w * 0.16 + 9 + Math.cos(a) * 70, h * 0.7 + Math.sin(a) * 40, 85, 16, a, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.fillStyle = "#f4f1ff";
    ctx.textAlign = "center";
    ctx.font = "800 64px system-ui, sans-serif";
    ctx.fillText("MARGARITAVILLE", w / 2, h * 0.2);
    ctx.font = "600 34px system-ui, sans-serif";
    ctx.fillText("комната 214 · готово", w / 2, h * 0.26);
  }

  return { canvas, draw };
}
