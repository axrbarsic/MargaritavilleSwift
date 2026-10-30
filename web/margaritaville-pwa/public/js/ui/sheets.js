// Нижние листы: меню действий комнаты и выбор времени открытия (барабаны час/мин/AM-PM).
// Источник: MargaritavilleRoomTile.confirmationDialog, RoomScheduleSheet.swift,
// Domain/RoomScheduleSelection.swift.
import { h } from "./dom.js";
import { icon } from "./icons.js";
import { roomStatus } from "../domain/room.js";
import { tr } from "../i18n/i18n.js";

const HOURS = [8, 9, 10, 11, 12, 1, 2, 3, 4];
const MINUTES = [0, 15, 30, 45];
const PERIODS = ["AM", "PM"];
const ROW = 36;

export function openSheet(content, { onClose } = {}) {
  const layer = h("div", { class: "sheet-layer" });
  const sheet = h("div", { class: "bottom-sheet" });
  layer.append(sheet);
  let closed = false;
  const close = () => {
    if (closed) return;
    closed = true;
    layer.classList.remove("shown");
    setTimeout(() => layer.remove(), 200);
    onClose?.();
  };
  layer.addEventListener("click", (event) => { if (event.target === layer) close(); });
  sheet.append(content(close));
  document.body.append(layer);
  requestAnimationFrame(() => layer.classList.add("shown"));
  return close;
}

/// Меню комнаты: Голос/медиа, VIP, Назначить время, Вернуть в жёлтый, Отмена.
export function openRoomActions(app, roomID, handlers) {
  const room = app.store.room(roomID);
  if (!room) return;
  app.feedback.play("actionMenuOpen");
  openSheet((close) => {
    const action = (label, name, onclick, cls = "") => h("button", { class: `action ${cls}`, onclick: () => { close(); onclick(); } }, icon(name, 20, 2.6), h("span", {}, label));
    return h("div", { class: "actions" },
      h("div", { class: "action-group" },
        h("div", { class: "action-title" }, tr("Комната {room}", { room: room.id })),
        action(tr("Голос/медиа"), "mic", () => { app.feedback.tap(); handlers.openDetails(roomID, "voice"); }),
        action(room.isVIP ? tr("VIP выключить") : tr("VIP включить"), "diamond", () => { app.feedback.confirm(); handlers.toggleVIP(roomID); }),
        action(tr("Назначить время"), "clock", () => { app.feedback.tap(); handlers.openSchedule(roomID); }),
        roomStatus(room) !== "pending" ? action(tr("Вернуть в жёлтый"), "reset", () => { app.feedback.deselect(); handlers.reset(roomID); }) : null
      ),
      h("button", { class: "action cancel", onclick: close }, tr("Отмена"))
    );
  });
}

function selectionFor(ms) {
  const date = new Date(ms);
  const hour24 = date.getHours();
  const minute = MINUTES.reduce((best, m) => (Math.abs(m - date.getMinutes()) < Math.abs(best - date.getMinutes()) ? m : best), 0);
  const hour12 = hour24 % 12 || 12;
  return { hour: HOURS.includes(hour12) ? hour12 : 11, minute, period: hour24 >= 12 ? "PM" : "AM" };
}

function defaultSelection() {
  const now = new Date();
  return selectionFor(now.getTime() + (15 - (now.getMinutes() % 15)) * 60000);
}

const label = (s) => `${s.hour}:${String(s.minute).padStart(2, "0")} ${s.period}`;

function todayAt(s) {
  const date = new Date();
  date.setHours((s.hour % 12) + (s.period === "PM" ? 12 : 0), s.minute, 0, 0);
  return date.getTime();
}

function wheel(values, format, value, onChange, feedback) {
  const list = h("div", { class: "wheel-list" }, h("div", { class: "wheel-pad" }), values.map((v) => h("div", { class: "wheel-item" }, format(v))), h("div", { class: "wheel-pad" }));
  let index = Math.max(0, values.indexOf(value));
  let settle = null;
  const mark = () => list.querySelectorAll(".wheel-item").forEach((el, i) => el.classList.toggle("current", i === index));
  list.addEventListener("scroll", () => {
    const next = Math.min(values.length - 1, Math.max(0, Math.round(list.scrollTop / ROW)));
    if (next !== index) { index = next; mark(); feedback.tap(); onChange(values[index]); }
    clearTimeout(settle);
    settle = setTimeout(() => list.scrollTo({ top: index * ROW, behavior: "smooth" }), 120);
  }, { passive: true });
  list.addEventListener("click", (e) => {
    const items = [...list.querySelectorAll(".wheel-item")];
    const i = items.indexOf(e.target.closest(".wheel-item"));
    if (i >= 0) list.scrollTo({ top: i * ROW, behavior: "smooth" });
  });
  requestAnimationFrame(() => { list.scrollTop = index * ROW; mark(); });
  return h("div", { class: "wheel" }, list, h("div", { class: "wheel-band" }));
}

/// Лист «Время открытия». onSet(time) / onClear().
export function openSchedule(app, roomID, { onSet, onClear, onDismiss }) {
  const room = app.store.room(roomID);
  if (!room) return;
  const choice = room.scheduledTime != null ? selectionFor(room.scheduledTime) : defaultSelection();
  let acted = false;
  openSheet((close) => {
    const pill = h("div", { class: "schedule-pill" }, label(choice));
    const changed = () => { pill.textContent = label(choice); };
    return h("div", { class: "schedule" },
      h("div", { class: "schedule-head" },
        h("div", {}, h("div", { class: "schedule-title" }, tr("Время открытия")), h("div", { class: "schedule-room" }, tr("Комната {room}", { room: room.id }))),
        pill),
      h("div", { class: "wheels" },
        wheel(HOURS, String, choice.hour, (v) => { choice.hour = v; changed(); }, app.feedback),
        wheel(MINUTES, (m) => String(m).padStart(2, "0"), choice.minute, (v) => { choice.minute = v; changed(); }, app.feedback),
        wheel(PERIODS, String, choice.period, (v) => { choice.period = v; changed(); }, app.feedback)),
      h("div", { class: "sheet-buttons" },
        h("button", { class: "action bordered", onclick: () => { acted = true; app.feedback.deselect(); close(); onClear(); } }, tr("Очистить")),
        h("button", { class: "action scheduled", onclick: () => { acted = true; app.feedback.confirm(); close(); onSet(todayAt(choice)); } }, tr("Установить")))
    );
  }, { onClose: () => { if (!acted) onDismiss?.(); } });
}
