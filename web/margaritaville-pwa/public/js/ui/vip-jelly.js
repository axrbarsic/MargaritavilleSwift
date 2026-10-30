// VIP-желе: живой контур VIP-ячейки — края волнуются (до 18 px), тело слегка дышит.
// Один общий цикл анимации на все VIP-ячейки; гаснет, когда их нет или приложение скрыто.
// Источник: Features/Summary/VIPJellyEffects.swift (VIPJellyCellShape, vipJellyUnifiedLayer).

const PAD = 20; // запас вокруг ячейки, куда может выйти волна
const tiles = new Set();
let raf = null;

function jellyOffset(seed, edge, unit, time, amplitude) {
  const edgeSeed = seed * 19.37 + edge * 0.731;
  const tau = Math.PI * 2;
  const slow = Math.sin((unit * (1.7 + (edgeSeed % 1.9)) + time * (0.31 + edgeSeed * 0.017) + edgeSeed) * tau);
  const medium = Math.sin((unit * (3.1 + (edgeSeed % 2.4)) - time * (0.47 + seed * 0.09) + edgeSeed * 1.41) * tau);
  const fast = Math.sin((unit * (4.6 + seed * 1.7) + time * (0.61 + edge * 0.017) + edgeSeed * 2.17) * tau);
  const drift = Math.sin((time * 0.113 + seed * 8 + edge) * tau);
  return (slow * 0.52 + medium * 0.31 + fast * 0.11 + drift * 0.06) * amplitude;
}

const f = (v) => v.toFixed(1);

/// Сглаженная ломаная (Catmull-Rom → кривые Безье), как addSmoothEdge.
function smoothEdge(points) {
  let d = "";
  for (let i = 0; i < points.length - 1; i += 1) {
    const p = points[Math.max(i - 1, 0)], c = points[i], n = points[i + 1], a = points[Math.min(i + 2, points.length - 1)];
    d += ` C${f(c[0] + (n[0] - p[0]) / 6)},${f(c[1] + (n[1] - p[1]) / 6)} ${f(n[0] - (a[0] - c[0]) / 6)},${f(n[1] - (a[1] - c[1]) / 6)} ${f(n[0])},${f(n[1])}`;
  }
  return d;
}

function jellyPath(w, h, seed, t, cornerRadius) {
  const amp = Math.min(h * 0.22, 18);
  const L = PAD, R = PAD + w, T = PAD, B = PAD + h;
  const r = Math.min(cornerRadius, h * 0.46, w * 0.12);
  const off = (edge, unit, a = amp) => jellyOffset(seed, edge, unit, t, a);
  const horizontal = (y, x0, x1, edge) => Array.from({ length: 29 }, (_, i) => [x0 + (x1 - x0) * (i / 28), y + off(edge, i / 28)]);
  const vertical = (x, y0, y1, edge) => Array.from({ length: 13 }, (_, i) => [x + off(edge, i / 12, amp * 0.55), y0 + (y1 - y0) * (i / 12)]);
  let d = `M${f(L + r)},${f(T + off(0, 0))}`;
  d += smoothEdge(horizontal(T, L + r, R - r, 0));
  d += ` Q${f(R + off(4, 0.25, amp * 0.55))},${f(T)} ${f(R)},${f(T + r)}`;
  d += smoothEdge(vertical(R, T + r, B - r, 1));
  d += ` Q${f(R)},${f(B + off(5, 0.75, amp * 0.55))} ${f(R - r)},${f(B)}`;
  d += smoothEdge(horizontal(B, R - r, L + r, 2));
  d += ` Q${f(L + off(6, 0.35, amp * 0.55))},${f(B)} ${f(L)},${f(B - r)}`;
  d += smoothEdge(vertical(L, B - r, T + r, 3));
  d += ` Q${f(L)},${f(T + off(7, 0.9, amp * 0.55))} ${f(L + r)},${f(T)} Z`;
  return `path("${d}")`;
}

function frame(now) {
  raf = null;
  for (const entry of tiles) {
    if (!entry.element.isConnected) tiles.delete(entry);
  }
  if (!tiles.size || document.hidden) return;
  for (const { element, body, seed, speed } of tiles) {
    const w = element.offsetWidth, h = element.offsetHeight;
    if (!w || !h) continue;
    const s = Math.min(Math.max(speed(), 0.2), 2.5);
    const t = (now / 1000) * s;
    const u = t + seed * 11;
    body.style.clipPath = jellyPath(w, h, seed, t, 16 * (h / 98));
    body.style.transform = `translate(${f(1.2 * Math.sin(u * 1.1))}px, ${f(0.8 * Math.cos(u * 1.3))}px) scale(${(1 + 0.012 * Math.sin(u * 1.7)).toFixed(4)}, ${(1 + 0.018 * Math.cos(u * 1.4)).toFixed(4)})`;
  }
  raf = requestAnimationFrame(frame);
}

function ensureRunning() {
  if (raf == null && tiles.size && !document.hidden) raf = requestAnimationFrame(frame);
}

document.addEventListener("visibilitychange", ensureRunning);

/// Подключить желе к ячейке. speed() читает текущую скорость из настроек.
export function attachVIPJelly(element, seed, speed) {
  const body = element.querySelector(".tile-body");
  if (!body) return;
  element.classList.add("vip-jelly");
  tiles.add({ element, body, seed, speed });
  ensureRunning();
}
