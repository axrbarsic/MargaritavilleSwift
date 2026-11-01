// Экраны смены: уборщицы, расходники тележки, каталог номеров.
// Источник: Features/Settings/SettingsWorkSection.swift, HousekeeperCatalogEditorSection.swift,
// CartConsumableCatalogEditorSection.swift, MargaritavilleCatalogEditorSection.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { PALETTE_RGB, paletteColor, makeHousekeeper, canonicalHousekeepers, DEFAULT_HOUSEKEEPERS } from "../../domain/housekeepers.js";
import { makeCatalogItem, normalizedCatalog, DEFAULT_CONSUMABLE_CATALOG } from "../../domain/consumables.js";
import { normalizeRoomID } from "../../domain/catalog.js";
import { messageLine, settingsPanel, textInputRow } from "./settings-controls.js";
import { tr } from "../../i18n/i18n.js";

export function housekeepersEditor(app, rerender) {
  const { settings, store, feedback } = app;
  const message = messageLine(app.ui.hkMessage ?? tr("Имена идут из свежих листов; список можно менять под смену."));
  const say = (text) => { app.ui.hkMessage = text; message.textContent = text; };
  const save = (list) => settings.set("housekeepers", canonicalHousekeepers(list));

  const rows = settings.get("housekeepers").map((hk) => {
    const palette = h("select", { class: "palette-select", "aria-label": tr("Цвет"), style: { "--hk": paletteColor(hk.palette) } },
      Object.keys(PALETTE_RGB).map((p) => { const o = h("option", { value: p }, p[0].toUpperCase() + p.slice(1)); if (p === hk.palette) o.selected = true; return o; }));
    palette.addEventListener("change", () => {
      feedback.tap();
      save(settings.get("housekeepers").map((x) => (x.id === hk.id ? { ...x, palette: palette.value } : x)));
      rerender();
    });
    const name = h("input", { class: "settings-input compact", value: hk.displayName, autocapitalize: "words", "aria-label": tr("Имя") });
    name.addEventListener("change", () => {
      const trimmed = name.value.trim();
      if (!trimmed) { name.value = hk.displayName; return; }
      save(settings.get("housekeepers").map((x) => (x.id === hk.id ? { ...x, displayName: trimmed } : x)));
      say(tr("{name} сохранена.", { name: trimmed }));
    });
    const remove = h("button", { class: "trash-button", "aria-label": tr("Удалить"), onclick: () => {
      feedback.deselect();
      const rest = settings.get("housekeepers").filter((x) => x.id !== hk.id);
      settings.set("housekeepers", rest.length ? canonicalHousekeepers(rest) : DEFAULT_HOUSEKEEPERS);
      store.removeHousekeeperAssignments(hk.id);
      say(tr("{name} удалена из списка.", { name: hk.displayName }));
      rerender();
    } }, icon("trash", 15, 2.8));
    return h("div", { class: "editor-row" }, palette, name, remove);
  });

  return [
    settingsPanel(tr("Добавить"), message, textInputRow(tr("Имя"), (value, clear) => {
      const hk = makeHousekeeper(value, settings.get("housekeepers"));
      if (!hk) { feedback.holdWarning(); say(tr("Напиши имя перед добавлением.")); return; }
      save([...settings.get("housekeepers"), hk]);
      feedback.confirm();
      say(tr("{name} добавлена.", { name: hk.displayName }));
      clear();
      rerender();
    }, { autocapitalize: "words" })),
    settingsPanel(tr("Уборщицы"), tr("Кружок слева меняет цвет, корзина удаляет уборщицу из списка."), ...rows)
  ];
}

export function consumablesEditor(app, rerender) {
  const { settings, feedback } = app;
  const message = messageLine(app.ui.consumableMessage ?? tr("Этот список используется в меню уборщицы для быстрого запроса на тележку."));
  const say = (text) => { app.ui.consumableMessage = text; message.textContent = text; };
  const catalog = settings.get("cartConsumableCatalog");
  const rows = catalog.map((item) => {
    const name = h("input", { class: "settings-input compact", value: item.title, "aria-label": tr("Название") });
    name.addEventListener("change", () => {
      const trimmed = name.value.trim();
      if (!trimmed) { name.value = item.title; return; }
      settings.set("cartConsumableCatalog", normalizedCatalog(settings.get("cartConsumableCatalog").map((x) => (x.id === item.id ? { ...x, title: trimmed } : x))));
      say(tr("{name} сохранено.", { name: trimmed }));
    });
    const remove = h("button", { class: "trash-button", "aria-label": tr("Удалить"), onclick: () => {
      feedback.deselect();
      const rest = settings.get("cartConsumableCatalog").filter((x) => x.id !== item.id);
      settings.set("cartConsumableCatalog", rest.length ? rest : DEFAULT_CONSUMABLE_CATALOG);
      say(tr("{name} удалено.", { name: item.title }));
      rerender();
    } }, icon("trash", 15, 2.8));
    return h("div", { class: "editor-row" }, h("span", { class: "info-icon" }, icon("box", 18, 2.6)), name, remove);
  });
  return [
    settingsPanel(tr("Добавить"), message, textInputRow(tr("Название"), (value, clear) => {
      const item = makeCatalogItem(value, settings.get("cartConsumableCatalog"));
      if (!item) { feedback.holdWarning(); say(tr("Напиши название перед добавлением.")); return; }
      settings.set("cartConsumableCatalog", [...settings.get("cartConsumableCatalog"), item]);
      feedback.confirm();
      say(tr("{name} добавлено.", { name: item.title }));
      clear();
      rerender();
    })),
    settingsPanel(tr("Расходники"), tr("Добавляй, удаляй и переименовывай позиции для меню уборщицы."), ...rows)
  ];
}

export function catalogEditor(app, rerender) {
  const { store, feedback } = app;
  const message = messageLine(app.ui.catalogMessage ?? tr("Добавь номер, и корпус/этаж определятся автоматически."));
  const say = (text) => { app.ui.catalogMessage = text; message.textContent = text; };
  const towers = store.catalog.map((t, index) => settingsPanel(`${t.label} · ${t.rooms.length}`, index === 0 ? tr("Коснись номера, чтобы удалить его из каталога.") : null,
    h("div", { class: "catalog-rooms" }, t.rooms.map((room) => h("button", { class: "catalog-room", onclick: () => {
      const result = store.removeCatalogRoom(room);
      if (result === "changed") { feedback.confirm(); say(tr("{room} удалён из каталога.", { room })); rerender(); }
      else { feedback.holdWarning(); say(result === "blockedActiveRoom" ? tr("{room} сейчас в активной смене, удалить нельзя.", { room }) : tr("Номер {room} не найден в каталоге.", { room })); }
    } }, room, icon("close", 9, 3.4))))));
  return [
    settingsPanel(tr("Добавить"), message, textInputRow(tr("Номер"), (value, clear) => {
      const result = store.addCatalogRoom(value);
      const messages = { duplicate: tr("Этот номер уже есть в каталоге."), invalidRoom: tr("Не могу определить корпус/этаж для этого номера."), blockedActiveRoom: tr("Этот номер сейчас используется в смене.") };
      if (result === "changed") { feedback.confirm(); say(tr("{room} добавлен.", { room: normalizeRoomID(value) ?? value })); clear(); rerender(); }
      else { feedback.holdWarning(); say(messages[result]); }
    }, { inputMode: "text", autocapitalize: "characters" })),
    ...towers
  ];
}
