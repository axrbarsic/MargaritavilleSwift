// Ячейка комнаты сводки: номер 45 px black, время 12 px, высота 98, скругление 16.
// Стандартный режим — удержание 0,46 с меняет статус, свайп вправо открывает меню;
// расширенный — удержание 0,52 с увеличивает ячейку.
// Источник: Features/Summary/MargaritavilleSummarySection.swift (MargaritavilleRoomTile),
// RoomMediaIndicator.swift, SummarySwipeCommitPolicy.swift.
import { h, formatTime } from "./dom.js";
import { icon } from "./icons.js";
import { roomStatus } from "../domain/room.js";

const HOLD_STATUS_MS = 460;
const HOLD_ZOOM_MS = 520;

function mediaIndicator(room) {
  const list = room.mediaAttachments ?? [];
  if (!list.length) return null;
  const kind = list.some((a) => a.kind === "audio") ? "waveform" : list.some((a) => a.kind === "video") ? "video" : "photo";
  return h("span", { class: "media-flag", "aria-hidden": "true" },
    h("span", { class: "media-flag-icon" }, icon(kind, 12, 3)),
    list.length > 1 ? h("span", { class: "media-flag-count" }, String(list.length)) : null);
}

export function tileTime(room) {
  const status = roomStatus(room);
  return formatTime(status === "scheduled" ? room.scheduledTime : room.statusChangedAt ?? room.timeline?.selectedAt);
}

export function roomTile(app, room, { tileWidth, onAdvance, onZoom, onActions }) {
  const { settings, feedback } = app;
  const status = roomStatus(room);
  const zoomMode = settings.holdZoomEnabled;
  const vipJelly = room.isVIP && settings.get("developerVIPJellyEnabled");
  const vipHDR = room.isVIP && settings.get("developerVIPHDREnabled");
  const seed = [...room.id].reduce((a, c) => a + c.charCodeAt(0), 0) % 97;

  const element = h("div", {
    class: `tile status-${status}${vipJelly ? " vip-jelly" : ""}${vipHDR ? " vip-hdr" : ""}`,
    role: "button",
    tabindex: "0",
    "aria-label": `Комната ${room.id}`,
    "data-room": room.id,
    style: { "--seed": seed, "--jelly-speed": settings.get("developerVIPJellySpeed") }
  },
  h("span", { class: "tile-body" }),
  h("span", { class: "tile-number" }, room.id),
  h("span", { class: "tile-time" }, tileTime(room)),
  mediaIndicator(room));

  let timer = null;
  let start = null;
  let swipe = { armed: false, started: false };
  const threshold = Math.min(Math.max(tileWidth * 0.72, 58), 84);
  const cancelHold = () => { clearTimeout(timer); timer = null; element.classList.remove("holding"); };

  element.addEventListener("pointerdown", (e) => {
    start = { x: e.clientX, y: e.clientY, t: performance.now() };
    swipe = { armed: false, started: false };
    element.classList.add("holding");
    if (!zoomMode) feedback.hapticOnly("holdStart");
    timer = setTimeout(() => {
      cancelHold();
      if (zoomMode) {
        feedback.hapticOnly("holdCommit");
        onZoom(room);
      } else {
        onAdvance(room.id);
      }
    }, zoomMode ? HOLD_ZOOM_MS : HOLD_STATUS_MS);
  });
  element.addEventListener("pointermove", (e) => {
    if (!start) return;
    const dx = e.clientX - start.x;
    const dy = Math.abs(e.clientY - start.y);
    if (Math.hypot(dx, dy) > 8) cancelHold();
    if (zoomMode || dx <= 0 || dx < 38 || dx <= dy * 2.8) return;
    if (dx >= threshold * 0.86 && !swipe.started) { swipe.started = true; feedback.hapticOnly("holdStart"); }
    const armed = dx >= threshold;
    if (armed && !swipe.armed) feedback.hapticOnly("holdCommit");
    swipe.armed = armed;
  });
  element.addEventListener("pointerup", (e) => {
    cancelHold();
    if (!start || zoomMode) { start = null; return; }
    const dx = e.clientX - start.x;
    const dy = Math.abs(e.clientY - start.y);
    const velocity = dx / Math.max(performance.now() - start.t, 1);
    const predicted = dx + velocity * 120;
    start = null;
    if (dx > 0 && dx > dy * 2.5 && (swipe.armed || Math.max(dx, predicted * 0.78) >= threshold)) onActions(room.id);
  });
  element.addEventListener("pointercancel", () => { cancelHold(); start = null; });
  element.addEventListener("pointerleave", cancelHold);
  element.addEventListener("contextmenu", (e) => e.preventDefault());
  element.addEventListener("keydown", (e) => {
    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); zoomMode ? onZoom(room) : onAdvance(room.id); }
    if (e.key === "ArrowRight" && !zoomMode) onActions(room.id);
  });
  return element;
}

/// Ряды как в MargaritavilleRoomGrid: базовая ширина ячейки — четверть экрана, ряд из 3 масштабируется.
export function gridMetrics(containerWidth, columns) {
  const inset = 16;
  const gap = 8;
  const base = Math.max(0, containerWidth - 2 * inset - 3 * gap) / 4;
  const design = 2 * inset + columns * base + (columns - 1) * gap;
  return { base, scale: design > 0 ? containerWidth / design : 1, gap, inset };
}
