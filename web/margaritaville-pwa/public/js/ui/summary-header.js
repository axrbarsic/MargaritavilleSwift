// Шапка сводки: меню настроек (удержание), счётчики всего/готово/осталось, фильтры
// по статусу и пазл справа — перетащить к меню, чтобы вернуться к выбору комнат.
// Источник: Features/Summary/SummaryHeader.swift, SummarySelectionPuzzleHandle.swift.
import { h, onHold } from "./dom.js";
import { icon } from "./icons.js";
import { roomStatus } from "../domain/room.js";

const CHIP_ORDER = ["open", "ready", "scheduled", "pending"];
const PAD = 18;
const BUTTON = 48;
const START_ZONE = 86;

export function summaryHeader(app, { counts, rooms, filter, onFilter }) {
  const { feedback } = app;
  const menu = h("button", { class: "header-menu", "aria-label": "Открыть настройки" }, icon("menu", 24, 3));
  onHold(menu, 460, () => { feedback.play("settingsOpen"); app.openSettings(); });

  const count = (value, color) => h("span", { class: "header-count", style: { color } }, String(value));
  const chips = CHIP_ORDER.map((status) => {
    const active = filter === status;
    return h("button", {
      class: `status-chip status-${status}${active ? " active" : ""}${filter && !active ? " dim" : ""}`,
      "aria-label": `Фильтр: ${status}`,
      onclick: () => { feedback.tap(); onFilter(active ? null : status); }
    }, String(rooms.filter((r) => roomStatus(r) === status).length));
  });

  const stats = h("div", { class: "header-stats" },
    count(counts.total, "var(--pending)"), count(counts.completed, "var(--ready)"), count(counts.remaining, "#ff3b30"), chips);

  // Как minimumScaleFactor: счётчики ужимаются, если не помещаются (на узких экранах сильнее, чем 0,58).
  requestAnimationFrame(() => {
    stats.style.setProperty("--hs", 1);
    const natural = [...stats.children].reduce((sum, el) => sum + el.offsetWidth, 0) + 7 * (stats.children.length - 1);
    const scale = Math.max(0.4, Math.min(1, stats.clientWidth / Math.max(natural, 1)));
    stats.style.setProperty("--hs", scale.toFixed(3));
  });
  const header = h("header", { class: "summary-header" }, menu, stats, h("span", { class: "header-spacer" }));
  header.append(puzzleHandle(app, header, menu));
  return header;
}

/// Пазл: тянуть влево от правого края до кнопки меню; на пороге — вибрация и выбор комнат.
function puzzleHandle(app, header, menu) {
  const { feedback } = app;
  const socket = h("div", { class: "puzzle-socket" }, icon("puzzle", 20, 2.4));
  const piece = h("div", { class: "puzzle-piece" }, icon("puzzle", 20, 2.6));
  const zone = h("div", { class: "puzzle-zone" });
  const hit = h("div", { class: "puzzle-hit", "aria-label": "Открыть выбор комнат", role: "button" });
  const layer = h("div", { class: "puzzle-layer" }, socket, piece, zone, hit);

  let startX = null;
  let drag = 0;
  let armed = false;
  let started = false;
  const metrics = () => {
    const width = header.clientWidth;
    const target = PAD + BUTTON / 2;
    const startCenter = width - PAD - START_ZONE / 2;
    return { target, startCenter, travel: Math.max(startCenter - target, 1) };
  };
  const paint = () => {
    const m = metrics();
    const p = Math.min(Math.max(drag / m.travel, 0), 1);
    piece.style.left = `${m.startCenter + (m.target - m.startCenter) * p}px`;
    piece.style.setProperty("--p", p);
    socket.style.left = `${m.target}px`;
    socket.style.opacity = p > 0.001 ? 0.4 + 0.6 * p : 0;
    zone.style.opacity = 1 - Math.min(p * 1.15, 0.82);
    menu.style.opacity = 1 - Math.min(p * 1.65, 1);
  };
  const reset = () => { drag = 0; armed = false; started = false; startX = null; paint(); };

  hit.addEventListener("pointerdown", (e) => { startX = e.clientX; hit.setPointerCapture(e.pointerId); });
  hit.addEventListener("pointermove", (e) => {
    if (startX == null) return;
    const m = metrics();
    const next = Math.min(Math.max(startX - e.clientX, 0), m.travel * 1.08);
    if (next > 2 && !started) { started = true; feedback.holdStart(); }
    const nextArmed = next >= m.travel;
    if (nextArmed && !armed) feedback.holdCommit();
    else if (!nextArmed && next > m.travel * 0.82 && drag <= m.travel * 0.82) feedback.holdWarning();
    drag = next;
    armed = nextArmed;
    paint();
  });
  const end = () => {
    if (startX == null) return;
    if (armed) {
      feedback.confirm();
      feedback.play("selectionOpen", { haptic: false });
      setTimeout(() => app.store.unlockWorkday(), 120);
    }
    reset();
  };
  hit.addEventListener("pointerup", end);
  hit.addEventListener("pointercancel", reset);
  requestAnimationFrame(paint);
  return layer;
}
