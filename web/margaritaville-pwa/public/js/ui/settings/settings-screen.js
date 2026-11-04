// Экран «Настройки»: короткий список групп в стиле iOS, каждая строка открывает свой экран.
// Источник: Features/Settings/SettingsScreen.swift, SettingsCategory*.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { openSettingsPage } from "./settings-page.js";
import { openSheet } from "../sheets.js";
import { BACKGROUND_MODES, effectiveMode } from "../background/app-background.js";
import { backgroundSection } from "./settings-background.js";
import { housekeepersEditor, consumablesEditor, catalogEditor } from "./settings-work.js";
import { cellsSections, soundSection } from "./settings-display.js";
import { developerSections } from "./settings-developer.js";
import { chooseLanguage } from "./settings-language.js";
import { openChangelog } from "./changelog-screen.js";
import { openShiftGame } from "../game/game-screen.js";
import { segmented } from "./settings-controls.js";
import { currentLanguage, tr } from "../../i18n/i18n.js";

function navRow({ title, iconName, tint, value, onclick, destructive = false }) {
  return h("button", { class: `menu-row${destructive ? " destructive" : ""}`, onclick },
    h("span", { class: "menu-icon", style: { "--tint": tint } }, icon(iconName, 17, 2.6)),
    h("span", { class: "menu-title" }, title),
    value != null ? h("span", { class: "menu-value" }, value) : null,
    destructive ? null : h("span", { class: "menu-chevron" }, icon("chevron", 16, 3)));
}

const menuGroup = (title, rows, footer) => h("section", { class: "menu-section" },
  title ? h("div", { class: "menu-caption" }, title) : null,
  h("div", { class: "menu-group" }, ...rows),
  footer ? h("div", { class: "menu-footer" }, footer) : null);

export function openSettings(app) {
  app.ui ??= {};
  app.feedback.play("settingsOpen", { haptic: false });
  const page = (title, build) => () => { app.feedback.tap(); openSettingsPage(app, title, build); };
  openSettingsPage(app, tr("Настройки"), () => {
    const { settings, store } = app;
    const rooms = store.catalog.reduce((sum, tower) => sum + tower.rooms.length, 0);
    const background = BACKGROUND_MODES.find((m) => m.id === effectiveMode(settings)) ?? BACKGROUND_MODES[0];
    const mode = segmented([{ value: "houseman", label: "Houseman" }, { value: "runner", label: "Runner" }], settings.get("workMode"),
      (value) => settings.set("workMode", value), app.feedback);
    return [
      menuGroup(tr("Режим"), [mode], tr("Houseman — утренняя работа с номерами. Runner — вечерний список уборщиц, которым готовят тележки на завтра.")),
      menuGroup(tr("Смена"), [
        navRow({ title: tr("Уборщицы"), iconName: "user", tint: "#30d158", value: String(settings.get("housekeepers").length), onclick: page(tr("Уборщицы"), (r) => housekeepersEditor(app, r)) }),
        navRow({ title: tr("Расходники"), iconName: "box", tint: "#ff9f0a", value: String(settings.get("cartConsumableCatalog").length), onclick: page(tr("Расходники"), (r) => consumablesEditor(app, r)) }),
        navRow({ title: tr("Номера отеля"), iconName: "door", tint: "#0a84ff", value: String(rooms), onclick: page(tr("Номера отеля"), (r) => catalogEditor(app, r)) })
      ]),
      menuGroup(tr("Экран"), [
        navRow({ title: tr("Ячейки"), iconName: "grid", tint: "#64d2ff", value: tr("{count} в ряду", { count: settings.get("gridColumnCount") }), onclick: page(tr("Ячейки"), (r) => cellsSections(app, r)) }),
        navRow({ title: tr("Фон"), iconName: "film", tint: "#bf5af2", value: background.title, onclick: page(tr("Фон"), (r) => backgroundSection(app, r)) }),
        navRow({ title: tr("Звуки"), iconName: "speaker", tint: "#ff375f", onclick: page(tr("Звуки"), (r) => [soundSection(app, r)]) }),
        navRow({ title: tr("Язык"), iconName: "globe", tint: "#5e5ce6", value: currentLanguage().name, onclick: () => { app.feedback.tap(); chooseLanguage(app); } })
      ]),
      menuGroup(tr("Игра"), [
        navRow({ title: tr("Смена"), iconName: "gamepad", tint: "#ff9f0a", value: tr("Играть"), onclick: () => { app.feedback.tap(); openShiftGame(app); } })
      ], tr("Раздавай номера уборщицам и успей к заезду гостей. Есть демо, где играет автопилот.")),
      menuGroup(tr("Приложение"), [
        navRow({ title: tr("Что нового"), iconName: "list", tint: "#8e8e93", value: `${app.version} (${app.build})`, onclick: () => { app.feedback.tap(); openChangelog(); } }),
        navRow({ title: tr("Для разработчика"), iconName: "hammer", tint: "#8e8e93", onclick: page(tr("Для разработчика"), (r) => developerSections(app, r)) }),
        navRow({ title: tr("Сбросить настройки"), iconName: "reset", tint: "#ff453a", destructive: true, onclick: () => confirmReset(app) })
      ], tr("Смена, фото, голос и настройки хранятся только на этом телефоне и никуда не отправляются."))
    ];
  });
}

function confirmReset(app) {
  app.feedback.tap();
  openSheet((close) => h("div", { class: "actions" },
    h("div", { class: "action-group" },
      h("div", { class: "action-title" }, tr("Сбросить настройки?")),
      h("div", { class: "action-message" }, tr("Ячейки, фон, звуки и режимы вернутся к значениям по умолчанию. Смена и язык не изменятся.")),
      h("button", { class: "action destructive", onclick: () => { app.feedback.confirm(); app.settings.resetToDefaults(); close(); } }, tr("Сбросить"))),
    h("button", { class: "action cancel", onclick: close }, tr("Отмена"))));
}
