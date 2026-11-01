// Экраны «Ячейки» и «Звуки»: вид и жесты ячеек главного экрана, назначения звуков.
// Источник: Features/Settings/SettingsCategoryAppearance.swift, SettingsSoundSection.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { openSheet } from "../sheets.js";
import { SETTINGS_EVENTS, SETTINGS_PALETTE, SOUND_ASSETS, assetFor } from "../../infra/feedback.js";
import { segmented, settingsPanel, toggleRow } from "./settings-controls.js";
import { tr } from "../../i18n/i18n.js";

export function cellsSections(app, rerender) {
  const { settings, feedback } = app;
  const toggle = (key, title, iconName, subtitle) => toggleRow({ title, iconName, subtitle, feedback, value: settings.get(key), onChange: (v) => settings.set(key, v) });
  const compact = settings.get("roomCellGeometry") === "compact";
  return [
    settingsPanel(tr("Ячеек в ряду"), tr("Меньше колонок — крупнее номера."),
      segmented([{ value: 3, label: "3" }, { value: 4, label: "4" }], settings.get("gridColumnCount"), (v) => settings.set("gridColumnCount", v), feedback)),
    settingsPanel(tr("Удержание ячейки"), compact ? tr("Удержание открывает ячейку почти на весь экран.") : tr("Удержание переключает статус комнаты."),
      segmented([{ value: "roomy", label: tr("Меняет статус") }, { value: "compact", label: tr("Увеличивает") }], settings.get("roomCellGeometry"), (v) => { settings.set("roomCellGeometry", v); rerender(); }, feedback)),
    settingsPanel(tr("Жесты"), null,
      toggle("roomTaskLongPress", tr("Долгий тап для S, L, B"), "hand", tr("Защищает задачи от случайных касаний во время прокрутки.")),
      toggle("summaryActionMenuAllowsMultiple", tr("Несколько меню сразу"), "list", tr("Можно держать открытыми меню нескольких ячеек."))),
    settingsPanel(tr("Цвета"), null,
      toggleRow({ title: tr("Сочная палитра"), iconName: "palette", feedback, value: settings.vividStatusPaletteEnabled,
        subtitle: tr("Более яркие цвета статусов."), onChange: (v) => settings.set("statusPaletteSaturation", v ? 1.65 : 1) }),
      toggle("transparentSurfacesEnabled", tr("Прозрачные панели"), "sliders", tr("Сквозь панели и карточки виден живой фон.")))
  ];
}

export function soundSection(app, rerender) {
  const { settings, feedback } = app;
  const rows = SETTINGS_EVENTS.map((event) => {
    const asset = assetFor(settings.get("soundAssignments"), event.id);
    const choose = () => openSheet((close) => h("div", { class: "actions" },
      h("div", { class: "action-group" },
        h("div", { class: "action-title" }, event.title),
        (SETTINGS_PALETTE.includes(asset) ? SETTINGS_PALETTE : [asset, ...SETTINGS_PALETTE]).map((candidate) => h("button", {
          class: "action", onclick: () => {
            const next = { ...settings.get("soundAssignments") };
            if (candidate === assetFor({}, event.id)) delete next[event.id];
            else next[event.id] = candidate;
            settings.set("soundAssignments", next);
            feedback.preview(candidate);
            close();
            rerender();
          }
        }, icon(candidate === asset ? "check" : "speaker", 18, 2.6), h("span", {}, SOUND_ASSETS[candidate].title)))),
      h("button", { class: "action cancel", onclick: close }, tr("Отмена"))));
    return h("div", { class: "sound-row" },
      h("button", { class: "info-row", onclick: choose },
        h("span", { class: "info-text" },
          h("span", { class: "info-title" }, event.title),
          h("span", { class: "sound-name" }, SOUND_ASSETS[asset].title),
          h("span", { class: "info-subtitle" }, event.subtitle))),
      h("button", { class: "play-button", "aria-label": tr("Прослушать {sound}", { sound: SOUND_ASSETS[asset].title }), onclick: () => feedback.preview(asset) }, icon("play", 16, 3)));
  });
  return settingsPanel(null, tr("Коснись строки, чтобы выбрать звук, или ▶, чтобы прослушать."), ...rows);
}
