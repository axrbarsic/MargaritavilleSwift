// Экран «Рабочий список»: выбор уборщиц, зон и номеров на смену.
// Источник: Features/WorkSetup/WorkSetupScreen.swift, WorkSetupComponents.swift.
import { h } from "./dom.js";
import { TERRITORIES, territoryById } from "../domain/catalog.js";
import { DEFAULT_HOUSEKEEPERS, housekeeperById, paletteColor } from "../domain/housekeepers.js";
import { roomOwnerCart, roomsForCart, selectedCartNumbers, selectedRooms } from "../domain/selection.js";

export function renderSetup(root, store, ui) {
  const s = store.selection;
  const carts = selectedCartNumbers(s);
  const total = selectedRooms(s).size;
  const usedHousekeepers = new Set(carts.map((c) => s.cartHousekeeperIDs[c]).filter(Boolean));

  const header = h("header", { class: "setup-header" },
    h("button", { class: "icon-button", "aria-label": "Открыть настройки", onclick: ui.openSettings }, "⚙︎"),
    h("div", { class: "title-block" }, h("div", { class: "title" }, "Рабочий список"), h("div", { class: "subtitle" }, `Выбрано: ${total}`)),
    h("button", { class: "start-button", disabled: total === 0, onclick: () => { navigator.vibrate?.(10); store.lockWorkday(); } }, "Начать")
  );

  const picker = h("div", { class: "housekeeper-picker" },
    DEFAULT_HOUSEKEEPERS.map((hk) => h("button", {
      class: `hk-chip${usedHousekeepers.has(hk.id) ? " selected" : ""}`,
      style: { "--hk": paletteColor(hk.palette), "--hk-soft": paletteColor(hk.palette, 0.2) },
      onclick: () => { navigator.vibrate?.(8); store.toggleCartForHousekeeper(hk.id); }
    }, hk.displayName))
  );

  const cards = carts.map((cart) => cartCard(store, cart));
  const body = h("div", { class: "setup-scroll" }, picker, cards.length ? cards : h("div", { class: "empty-hint" }, "Выбери уборщицу сверху."));
  root.replaceChildren(h("main", { class: "screen setup" }, header, body));
}

function cartCard(store, cart) {
  const s = store.selection;
  const territory = territoryById(s.cartBindings[cart]) ?? TERRITORIES[0];
  const hk = housekeeperById(s.cartHousekeeperIDs[cart]);
  const color = hk ? paletteColor(hk.palette) : "var(--accent)";
  const mine = roomsForCart(s, cart);
  const offTerritory = [...mine].filter((room) => !territory.rooms.includes(room));

  const territoryPicker = h("div", { class: "territory-picker" },
    TERRITORIES.map((t) => h("button", {
      class: `territory${t.id === territory.id ? " selected" : ""}`,
      style: { "--sel": color },
      onclick: () => store.setCartTerritory(cart, t.id)
    }, t.label))
  );

  const grid = h("div", { class: "pick-grid" },
    territory.rooms.map((room) => {
      const owner = roomOwnerCart(s, room);
      const reserved = owner != null && owner !== cart;
      const ownerHK = reserved ? housekeeperById(s.cartHousekeeperIDs[owner]) : null;
      return h("button", {
        class: `pick${mine.has(room) ? " selected" : ""}${reserved ? " reserved" : ""}`,
        style: { "--sel": color, "--owner": ownerHK ? paletteColor(ownerHK.palette) : "rgba(155,255,184,0.6)" },
        onclick: () => {
          const result = store.toggleRoom(cart, room);
          navigator.vibrate?.(result === "blocked" ? [20, 40, 20] : 6);
        }
      }, h("span", { class: "pick-number" }, room), reserved ? h("span", { class: "pick-owner" }, ownerHK?.displayName ?? "Занято") : null);
    })
  );

  return h("section", { class: "cart-card" },
    h("div", { class: "cart-head" },
      h("div", {}, h("div", { class: "cart-name" }, hk?.displayName ?? "Уборщица"), h("div", { class: "cart-zone" }, territory.label)),
      h("button", { class: "icon-button small", "aria-label": "Убрать уборщицу из смены", onclick: () => hk && store.toggleCartForHousekeeper(hk.id) }, "✕")
    ),
    territoryPicker,
    offTerritory.length ? h("div", { class: "off-territory" }, "Уже выбрано в других зонах: ", offTerritory.join(", ")) : null,
    grid
  );
}
