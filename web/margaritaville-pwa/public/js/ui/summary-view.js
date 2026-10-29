// Главный экран: секции по уборщицам, сетка комнат цвета статуса.
// Удержание — следующий статус, свайп вправо — меню действий.
// Источник: Features/Summary/SummaryScreen.swift, MargaritavilleSummarySection.swift,
// MargaritavilleSummaryRoomGrouping.swift.
import { h, onHold, onSwipeRight, formatTime } from "./dom.js";
import { compareRoomIDs, territoryById, territorySummaryLabel } from "../domain/catalog.js";
import { housekeeperById, paletteColor } from "../domain/housekeepers.js";
import { roomStatus } from "../domain/room.js";

export function renderSummary(root, store, ui) {
  const rooms = store.carts.flatMap((cart) => cart.rooms);
  const ready = rooms.filter((room) => roomStatus(room) === "ready").length;

  const header = h("header", { class: "summary-header" },
    h("button", { class: "icon-button", "aria-label": "Открыть настройки", onclick: ui.openSettings }, "⚙︎"),
    h("div", { class: "title-block" },
      h("div", { class: "title" }, `${ready} / ${rooms.length}`),
      h("div", { class: "subtitle" }, `Осталось: ${rooms.length - ready}`)
    ),
    h("button", { class: "ghost-button", onclick: () => { navigator.vibrate?.(8); store.unlockWorkday(); } }, "Выбор")
  );

  const sections = housekeeperSections(store).map((section) => sectionView(store, ui, section));
  root.replaceChildren(h("main", { class: "screen summary" }, header, h("div", { class: "summary-scroll" }, sections)));
}

/// Секции по уборщицам (MargaritavilleSummaryRoomGrouping.housekeeperSections).
function housekeeperSections(store) {
  const s = store.selection;
  const buckets = new Map();
  for (const cart of store.carts) {
    if (!cart.rooms.length) continue;
    const hkID = s.cartHousekeeperIDs[cart.id] ?? null;
    const key = hkID ? `hk-${hkID}` : `cart-${cart.id}`;
    const bucket = buckets.get(key) ?? { key, firstCart: cart.id, hkID, rooms: [], fallback: territoryById(s.cartBindings[cart.id])?.label ?? cart.building };
    bucket.rooms.push(...cart.rooms);
    buckets.set(key, bucket);
  }
  return [...buckets.values()]
    .sort((a, b) => a.firstCart - b.firstCart)
    .map((b) => ({ ...b, rooms: b.rooms.sort((x, y) => compareRoomIDs(x.id, y.id)), label: territorySummaryLabel(b.rooms.map((r) => r.id), b.fallback) }));
}

function sectionView(store, ui, section) {
  const hk = housekeeperById(section.hkID);
  const color = hk ? paletteColor(hk.palette) : "var(--accent)";
  return h("section", { class: "summary-section" },
    h("div", { class: "section-head" },
      h("span", { class: "hk-name", style: { "--hk": color, "--hk-soft": hk ? paletteColor(hk.palette, 0.2) : "rgba(30,255,90,0.2)" } }, hk?.displayName ?? "Уборщица"),
      h("span", { class: "section-zone" }, section.label)
    ),
    h("div", { class: "room-grid" }, section.rooms.map((room) => tile(store, ui, room)))
  );
}

function tile(store, ui, room) {
  const status = roomStatus(room);
  const time = status === "scheduled" ? room.scheduledTime : room.statusChangedAt ?? room.timeline.selectedAt;
  const element = h("button", { class: `tile status-${status}${room.isVIP ? " vip" : ""}`, "aria-label": `Комната ${room.id}` },
    h("span", { class: "tile-number" }, room.id),
    h("span", { class: "tile-time" }, formatTime(time)),
    room.textNote ? h("span", { class: "tile-note", "aria-hidden": "true" }) : null
  );
  onHold(element, 520, () => store.advance(room.id));
  onSwipeRight(element, 38, () => ui.openRoomActions(room.id));
  return element;
}
