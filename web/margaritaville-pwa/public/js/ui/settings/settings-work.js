// Раздел «Работа»: хранение, уборщицы, расходники тележки, каталог номеров, мульти-меню.
// Источник: Features/Settings/SettingsWorkSection.swift, HousekeeperCatalogEditorSection.swift,
// CartConsumableCatalogEditorSection.swift, MargaritavilleCatalogEditorSection.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { PALETTE_RGB, paletteColor, makeHousekeeper, canonicalHousekeepers, DEFAULT_HOUSEKEEPERS } from "../../domain/housekeepers.js";
import { makeCatalogItem, normalizedCatalog, DEFAULT_CONSUMABLE_CATALOG } from "../../domain/consumables.js";
import { normalizeRoomID } from "../../domain/catalog.js";
import { infoRow, messageLine, settingsPanel, textInputRow, toggleRow } from "./settings-controls.js";
import { tr } from "../../i18n/i18n.js";

export function workSection(app, rerender) {
  const { settings, feedback } = app;
  return settingsPanel(tr("Работа"), tr("Поведение раздвижного меню ячейки и рабочие жесты на основном экране."),
    infoRow({ title: tr("Хранение"), value: tr("Только телефон"), iconName: "box", subtitle: tr("Смена, медиа и настройки хранятся на этом устройстве и никуда не отправляются.") }),
    housekeepersEditor(app, rerender),
    consumablesEditor(app, rerender),
    catalogEditor(app, rerender),
    toggleRow({
      title: tr("Мульти-меню"), iconName: "list", feedback,
      subtitle: tr("По умолчанию открыто только одно меню ячейки; этот режим разрешает несколько."),
      value: settings.get("summaryActionMenuAllowsMultiple"), onLabel: tr("Несколько"), offLabel: tr("Одно"),
      onChange: (v) => settings.set("summaryActionMenuAllowsMultiple", v)
    })
  );
}

function housekeepersEditor(app, rerender) {
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
    return h("div", { class: "editor-row", style: { "--hk-line": paletteColor(hk.palette, 0.34) } }, palette, name, remove);
  });

  return settingsPanel(tr("Уборщицы"), tr("Имена, цвета и назначения тележек для первого экрана Margaritaville."),
    textInputRow(tr("Имя"), (value, clear) => {
      const hk = makeHousekeeper(value, settings.get("housekeepers"));
      if (!hk) { feedback.holdWarning(); say(tr("Напиши имя перед добавлением.")); return; }
      save([...settings.get("housekeepers"), hk]);
      feedback.confirm();
      say(tr("{name} добавлена.", { name: hk.displayName }));
      clear();
      rerender();
    }, { autocapitalize: "words" }),
    message, ...rows);
}

function consumablesEditor(app, rerender) {
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
  return settingsPanel(tr("Расходники тележки"), tr("Добавляй, удаляй и переименовывай позиции для меню уборщицы."),
    textInputRow(tr("Название"), (value, clear) => {
      const item = makeCatalogItem(value, settings.get("cartConsumableCatalog"));
      if (!item) { feedback.holdWarning(); say(tr("Напиши название перед добавлением.")); return; }
      settings.set("cartConsumableCatalog", [...settings.get("cartConsumableCatalog"), item]);
      feedback.confirm();
      say(tr("{name} добавлено.", { name: item.title }));
      clear();
      rerender();
    }),
    message, ...rows);
}

function catalogEditor(app, rerender) {
  const { store, feedback } = app;
  const message = messageLine(app.ui.catalogMessage ?? tr("Добавь номер, и корпус/этаж определятся автоматически."));
  const say = (text) => { app.ui.catalogMessage = text; message.textContent = text; };
  const cards = store.catalog.map((t) => h("div", { class: "catalog-card" },
    h("div", { class: "catalog-head" }, h("span", {}, t.label), h("span", {}, String(t.rooms.length))),
    h("div", { class: "catalog-rooms" }, t.rooms.map((room) => h("button", { class: "catalog-room", onclick: () => {
      const result = store.removeCatalogRoom(room);
      if (result === "changed") { feedback.confirm(); say(tr("{room} удалён из каталога.", { room })); rerender(); }
      else { feedback.holdWarning(); say(result === "blockedActiveRoom" ? tr("{room} сейчас в активной смене, удалить нельзя.", { room }) : tr("Номер {room} не найден в каталоге.", { room })); }
    } }, room, icon("close", 9, 3.4))))));
  return settingsPanel(tr("Каталог Margaritaville"), tr("Добавление и удаление номеров хранится в отдельной базе этого отеля."),
    textInputRow(tr("Номер"), (value, clear) => {
      const result = store.addCatalogRoom(value);
      const messages = { duplicate: tr("Этот номер уже есть в каталоге."), invalidRoom: tr("Не могу определить корпус/этаж для этого номера."), blockedActiveRoom: tr("Этот номер сейчас используется в смене.") };
      if (result === "changed") { feedback.confirm(); say(tr("{room} добавлен.", { room: normalizeRoomID(value) ?? value })); clear(); rerender(); }
      else { feedback.holdWarning(); say(messages[result]); }
    }, { inputMode: "text", autocapitalize: "characters" }),
    message, ...cards);
}
