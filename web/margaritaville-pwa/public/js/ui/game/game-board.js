// Поле игры «Смена»: карточки уборщиц с тележками и сетка номеров в цветах статусов
// приложения. Каждый кадр меняет только то, что изменилось, и полосу прогресса уборки.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { paletteColor } from "../../domain/housekeepers.js";
import { CART_CAPACITY, clockMinutes, crewActivity } from "../../game/shift-state.js";
import { tr } from "../../i18n/i18n.js";

const URGENT_SECONDS = 12;

/// Время смены для шапки; short — без AM/PM, чтобы подпись влезала в узкую ячейку.
export function clockLabel(seconds, { short = false } = {}) {
  const total = Math.floor(clockMinutes(seconds));
  const hours = Math.floor(total / 60) % 24;
  const time = `${((hours + 11) % 12) + 1}:${String(total % 60).padStart(2, "0")}`;
  return short ? time : `${time} ${hours < 12 ? "AM" : "PM"}`;
}

/// Цвет ячейки: занят гостем (серый, подпись — время выезда), ждёт уборки (розовый — к сроку), убирается, готов.
function roomClass(room) {
  if (room.status === "occupied") return "occupied";
  if (room.status === "cleaning") return "open";
  if (room.status === "ready") return "ready";
  return room.deadline != null ? "scheduled" : "pending";
}

function roomSub(state, room, crewName) {
  if (room.status === "occupied") return clockLabel(room.checkoutAt, { short: true });
  if (room.status === "cleaning") return crewName(room.hk);
  if (room.status === "ready") return tr("Готов");
  return room.deadline != null ? tr("К {time}", { time: clockLabel(room.deadline, { short: true }) }) : tr("Грязный");
}

function crewStatus(hk) {
  const room = hk.current ?? hk.queue[0];
  switch (crewActivity(hk)) {
    case "restocking": return tr("Пополняет тележку");
    case "walking": return tr("Идёт в {room}", { room });
    case "cleaning": return tr("Убирает {room}", { room });
    case "empty": return tr("Нет расходников!");
    default: return tr("Свободна");
  }
}

export function createBoard(state, { onRoom, onCrew, onRestock }) {
  const crewViews = new Map();
  const roomViews = new Map();
  const names = new Map(state.crew.map((hk) => [hk.id, hk.name]));
  const crewName = (id) => names.get(id) ?? "";

  const crew = h("div", { class: "game-crew" }, state.crew.map((hk) => {
    const view = {
      status: h("span", { class: "crew-status" }),
      queue: h("span", { class: "crew-queue" }),
      pips: Array.from({ length: CART_CAPACITY }, () => h("i")),
      cart: h("button", { class: "crew-cart", "aria-label": tr("Пополнить тележку"), onclick: (e) => { e.stopPropagation(); onRestock(hk.id); } }, icon("box", 18, 2.6)),
      glow: h("span", { class: "game-glow" }),
      sig: ""
    };
    view.card = h("div", { class: "crew-card", role: "button", tabindex: "0", style: { "--hk": paletteColor(hk.palette), "--hk-soft": paletteColor(hk.palette, 0.24) }, onclick: () => onCrew(hk.id) },
      h("span", { class: "crew-text" },
        h("span", { class: "crew-head" }, h("span", { class: "crew-name" }, hk.name), view.queue),
        view.status,
        h("span", { class: "crew-pips" }, view.pips)),
      view.cart, view.glow);
    crewViews.set(hk.id, view);
    return view.card;
  }));

  const rooms = h("div", { class: "game-rooms" }, state.rooms.map((room) => {
    const view = {
      sub: h("span", { class: "game-room-sub" }),
      owner: h("span", { class: "game-room-owner" }),
      bar: h("span", { class: "game-room-bar" }),
      glow: h("span", { class: "game-glow" }),
      sig: "", progress: -1
    };
    view.tile = h("button", { class: "game-room", "data-room": room.id, onclick: () => onRoom(room.id) },
      h("span", { class: "game-room-badge" }, "VIP"),
      h("span", { class: "game-room-number" }, room.id),
      view.sub, view.owner, view.bar, view.glow);
    roomViews.set(room.id, view);
    return view.tile;
  }));

  function updateRooms(state) {
    const owners = new Map(state.crew.map((hk) => [hk.id, hk.palette]));
    for (const room of state.rooms) {
      const view = roomViews.get(room.id);
      const urgent = room.deadline != null && room.status !== "ready" && room.status !== "occupied" && room.deadline - state.time < URGENT_SECONDS;
      const sig = `${room.status}|${room.hk}|${room.vip}|${room.deadline}|${room.missed}|${urgent}|${room.checkoutAt}`;
      if (sig !== view.sig) {
        view.sig = sig;
        const queued = room.status === "dirty" && room.hk;
        view.tile.className = `game-room status-${roomClass(room)}${room.vip ? " vip" : ""}${room.missed ? " missed" : ""}${urgent ? " urgent" : ""}${queued ? " queued" : ""}${room.hk ? " has-owner" : ""}`;
        view.sub.textContent = roomSub(state, room, crewName);
        if (room.hk) view.owner.style.setProperty("--owner", paletteColor(owners.get(room.hk)));
      }
      const progress = room.status === "cleaning" ? Math.round(room.progress * 100) / 100 : 0;
      if (progress !== view.progress) { view.progress = progress; view.bar.style.setProperty("--p", progress); }
    }
  }

  function updateCrew(state, selected) {
    for (const hk of state.crew) {
      const view = crewViews.get(hk.id);
      const activity = crewActivity(hk);
      const sig = `${activity}|${hk.current}|${hk.queue.join()}|${hk.supplies}|${hk.pendingRestock}|${selected === hk.id}`;
      if (sig === view.sig) continue;
      view.sig = sig;
      view.card.className = `crew-card${selected === hk.id ? " selected" : ""}${activity === "empty" ? " empty" : ""}${activity === "restocking" ? " restocking" : ""}`;
      view.status.textContent = crewStatus(hk);
      view.queue.textContent = hk.queue.length ? `+${hk.queue.length}` : "";
      view.pips.forEach((pip, index) => pip.classList.toggle("on", index < hk.supplies));
      view.cart.disabled = hk.supplies >= CART_CAPACITY || hk.restock > 0 || hk.pendingRestock;
    }
  }

  /// Короткая вспышка цветом уборщицы — так видно решения автопилота.
  function flash(glow, color) {
    glow.style.setProperty("--flash", color);
    glow.classList.remove("on");
    void glow.offsetWidth;
    glow.classList.add("on");
  }

  return {
    crew, rooms,
    update(state, selected) { updateRooms(state); updateCrew(state, selected); },
    flashRoom(roomId, hkId) {
      const palette = state.crew.find((hk) => hk.id === hkId)?.palette;
      flash(roomViews.get(roomId).glow, paletteColor(palette));
      flash(crewViews.get(hkId).glow, paletteColor(palette));
    },
    flashCrew(hkId) { const view = crewViews.get(hkId); if (view) flash(view.glow, "rgba(255, 255, 255, 0.9)"); },
    floatText(roomId, text) {
      const tile = roomViews.get(roomId)?.tile;
      if (!tile) return;
      const label = h("span", { class: "game-float" }, text);
      tile.append(label);
      label.addEventListener("animationend", () => label.remove());
    }
  };
}
