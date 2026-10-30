// Экран «Рабочий список»: поиск и выбор уборщиц, карточки тележек с выбором здания
// и этажа, сетка номеров с замками занятых.
// Источник: Features/WorkSetup/WorkSetupScreen.swift, WorkSetupComponents.swift,
// WorkSetupTerritoryPicker.swift, WorkSetupRoomPickButton.swift, HousekeeperRosterPresentation.swift.
import { h, onHold } from "./dom.js";
import { icon } from "./icons.js";
import { compareRoomIDs } from "../domain/catalog.js";
import { paletteColor } from "../domain/housekeepers.js";
import { roomOwnerCart, roomsForCart, selectedCartNumbers, selectedRooms } from "../domain/selection.js";
import { tr } from "../i18n/i18n.js";

const view = { focusedCart: null, query: "", searchOpen: false };
const fold = (s) => s.trim().normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
const sortRoster = (list) => [...list].sort((a, b) => fold(a.displayName).localeCompare(fold(b.displayName)) || (a.id < b.id ? -1 : 1));

export function renderSetup(root, app) {
  const { store, settings, feedback } = app;
  const s = store.selection;
  const carts = selectedCartNumbers(s);
  if (!carts.includes(view.focusedCart)) view.focusedCart = carts[0] ?? null;
  const total = selectedRooms(s).size;
  const housekeepers = settings.get("housekeepers");
  const hkForCart = (cart) => settings.housekeeper(s.cartHousekeeperIDs[cart]);
  const focusedHK = hkForCart(view.focusedCart);

  const settingsButton = h("button", { class: "icon-button", "aria-label": tr("Открыть настройки") }, icon("gear", 26, 2.4));
  onHold(settingsButton, 460, () => app.openSettings());
  const start = h("button", { class: "start-button", disabled: total === 0 }, tr("Начать"));
  start.addEventListener("click", () => { if (total) { feedback.confirm(); store.lockWorkday(); } });

  const header = h("header", { class: "setup-header" },
    settingsButton,
    h("div", { class: "title-block" }, h("div", { class: "title setup-title" }, tr("Рабочий список")), h("div", { class: "subtitle" }, tr("Выбрано: {count}", { count: total }))),
    start
  );

  const activate = (hk) => {
    view.query = hk.displayName;
    view.searchOpen = false;
    const owned = store.cartForHousekeeper(hk.id);
    if (owned != null) {
      feedback.deselect();
      store.removeCart(owned);
      return;
    }
    const cart = store.addHousekeeper(hk.id);
    if (cart == null) return feedback.invalid();
    feedback.select();
    view.focusedCart = cart;
    app.render();
    requestAnimationFrame(() => document.getElementById(`cart-${cart}`)?.scrollIntoView({ behavior: "smooth", block: "start" }));
  };

  const body = h("div", { class: "setup-scroll" },
    housekeeperPicker(app, sortRoster(housekeepers), new Set(carts.map((c) => s.cartHousekeeperIDs[c]).filter(Boolean)), focusedHK?.id, activate),
    carts.length ? carts.map((cart) => cartCard(app, cart, hkForCart(cart))) : h("div", { class: "empty-hint", onclick: () => { view.searchOpen = false; app.render(); } }, tr("Выбери уборщицу сверху."))
  );
  root.replaceChildren(h("main", { class: "screen setup" }, header, body));
}

function housekeeperPicker(app, roster, selectedIDs, focusedID, activate) {
  const input = h("input", { class: "search-input", type: "text", placeholder: tr("Имя уборщицы"), autocapitalize: "words", autocomplete: "off", spellcheck: "false", "aria-label": tr("Поиск уборщицы по началу имени") });
  input.value = view.query;
  const suggestions = h("div", { class: "suggestions", "aria-label": tr("Подсказки уборщиц") });
  const renderSuggestions = () => {
    const prefix = fold(view.query);
    const list = prefix ? roster.filter((hk) => fold(hk.displayName).startsWith(prefix)) : [];
    suggestions.hidden = !view.searchOpen || !list.length;
    suggestions.replaceChildren(...list.map((hk) => h("button", {
      class: "suggestion", style: { "--hk": paletteColor(hk.palette), "--hk-soft": paletteColor(hk.palette, 0.18) },
      onmousedown: (e) => e.preventDefault(),
      onclick: () => {
        const cart = app.store.cartForHousekeeper(hk.id);
        if (cart != null) {
          view.query = hk.displayName;
          view.searchOpen = false;
          view.focusedCart = cart;
          app.feedback.select();
          app.render();
          requestAnimationFrame(() => document.getElementById(`cart-${cart}`)?.scrollIntoView({ behavior: "smooth", block: "start" }));
        } else activate(hk);
      }
    }, h("span", { class: "dot" }), h("span", { class: "suggestion-name" }, hk.displayName), focusedID === hk.id ? icon("checkCircle", 18, 2.6) : null)));
  };
  const clear = h("button", { class: "search-clear", "aria-label": tr("Очистить имя и закрыть подсказки"), hidden: !view.query }, icon("close", 16, 3));
  clear.addEventListener("click", () => { view.query = ""; view.searchOpen = false; input.value = ""; clear.hidden = true; renderSuggestions(); });
  input.addEventListener("focus", () => { view.searchOpen = true; field.classList.add("focused"); renderSuggestions(); });
  input.addEventListener("blur", () => { view.searchOpen = false; field.classList.remove("focused"); renderSuggestions(); });
  input.addEventListener("input", () => { view.query = input.value; clear.hidden = !input.value; renderSuggestions(); });
  input.addEventListener("keydown", (e) => { if (e.key === "Enter") input.blur(); });
  const field = h("div", { class: "search-field" }, icon("user", 20, 2.6), input, clear);
  renderSuggestions();

  const chips = h("div", { class: "hk-strip" }, roster.map((hk) => {
    const selected = selectedIDs.has(hk.id);
    return h("button", {
      class: `hk-chip${selected ? " selected" : ""}${focusedID === hk.id ? " focused" : ""}`,
      style: { "--hk": paletteColor(hk.palette), "--hk-soft": paletteColor(hk.palette, 0.34) },
      onclick: () => activate(hk)
    }, h("span", { class: "dot" }), h("span", {}, hk.displayName), selected ? icon("checkCircle", 18, 2.8) : null);
  }));
  return h("div", { class: "hk-picker" }, field, suggestions, chips);
}

function cartCard(app, cart, hk) {
  const { store, feedback } = app;
  const s = store.selection;
  const catalog = store.catalog;
  const territory = catalog.find((t) => t.id === s.cartBindings[cart]) ?? catalog[0];
  const color = hk ? paletteColor(hk.palette) : "var(--accent)";
  const mine = roomsForCart(s, cart);
  const focus = () => { if (view.focusedCart !== cart) { view.focusedCart = cart; app.render(); } };

  const buildings = [...new Set(catalog.map((t) => t.building))].sort();
  const floors = [...new Set(catalog.map((t) => t.floor))].sort((a, b) => a - b);
  const update = (building, floor) => {
    const next = catalog.find((t) => t.building === building && t.floor === floor);
    if (!next || next.id === territory.id) return;
    feedback.confirm();
    view.focusedCart = cart;
    store.setCartTerritory(cart, next.id);
  };
  const chip = (label, selected, onclick) => h("button", { class: `zone-chip${selected ? " selected" : ""}`, onclick }, label);
  const picker = h("div", { class: "zone-picker", style: { "--sel": color, "--sel-soft": hk ? paletteColor(hk.palette, 0.26) : "rgba(30,255,90,0.26)", "--sel-line": hk ? paletteColor(hk.palette, 0.48) : "rgba(30,255,90,0.48)" } },
    h("div", { class: "zone-row" }, h("span", { class: "zone-label" }, tr("Здание")), buildings.map((b) => chip(b.toUpperCase(), territory.building === b, () => update(b, territory.floor)))),
    h("div", { class: "zone-row" }, h("span", { class: "zone-label" }, tr("Этаж")), floors.map((f) => chip(String(f), territory.floor === f, () => update(territory.building, f))))
  );

  const groups = catalog.filter((t) => t.id !== territory.id)
    .map((t) => ({ label: t.label, rooms: t.rooms.filter((r) => mine.has(r)).sort(compareRoomIDs) }))
    .filter((g) => g.rooms.length);
  const summary = groups.length ? h("div", { class: "off-zones" },
    h("div", { class: "off-zones-title" }, tr("Уже выбрано в других зонах")),
    h("div", { class: "off-zones-row" }, groups.map((g) => h("div", { class: "off-zone" },
      h("span", { class: "off-zone-label" }, g.label),
      h("span", {}, g.rooms.slice(0, 3).join(", ") + (g.rooms.length > 3 ? ` +${g.rooms.length - 3}` : ""))
    )))) : null;

  const grid = h("div", { class: "pick-grid" }, territory.rooms.map((room) => {
    const owner = roomOwnerCart(s, room);
    const reserved = owner != null && owner !== cart;
    const ownerHK = reserved ? app.settings.housekeeper(s.cartHousekeeperIDs[owner]) : null;
    const selected = mine.has(room);
    return h("button", {
      class: `pick${selected ? " selected" : ""}${reserved ? " reserved" : ""}`,
      style: { "--sel": color, "--owner": ownerHK ? paletteColor(ownerHK.palette, 0.45) : "rgba(155,255,184,0.45)" },
      "aria-label": tr("Комната {room}", { room }),
      onclick: (event) => {
        event.stopPropagation();
        if (reserved) return feedback.invalid();
        view.focusedCart = cart;
        selected ? feedback.deselect() : feedback.select();
        store.toggleRoom(cart, room);
      }
    }, h("span", { class: "pick-number" }, room),
    reserved ? h("span", { class: "pick-owner" }, icon("lock", 11, 3), h("span", {}, ownerHK?.displayName ?? tr("Занято"))) : null);
  }));

  const remove = h("button", { class: "icon-button small", "aria-label": tr("Убрать уборщицу из смены") }, icon("close", 15, 3.2));
  remove.addEventListener("click", (e) => { e.stopPropagation(); feedback.deselect(); store.removeCart(cart); });

  return h("section", { class: `cart-card${view.focusedCart === cart ? " focused" : ""}`, id: `cart-${cart}`, onclick: focus },
    h("div", { class: "cart-head" },
      h("div", {}, h("div", { class: "cart-name" }, hk?.displayName ?? tr("Уборщица")), h("div", { class: "cart-zone" }, territory.label)),
      remove
    ),
    picker,
    summary,
    grid
  );
}
