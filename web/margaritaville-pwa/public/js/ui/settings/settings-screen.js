// Экран «Настройки» с четырьмя категориями: Внешний вид, Фон, Работа, Разработчик.
// Источник: Features/Settings/SettingsScreen.swift, SettingsCategory*.swift, SettingsSoundSection.swift,
// SettingsTestDataSection.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { backButton, pushScreen } from "../screen-stack.js";
import { SETTINGS_EVENTS, SETTINGS_PALETTE, SOUND_ASSETS, assetFor } from "../../infra/feedback.js";
import { infoRow, segmented, settingsPanel, sliderRow, toggleRow } from "./settings-controls.js";
import { backgroundSection } from "./settings-background.js";
import { workSection } from "./settings-work.js";
import { openChangelog } from "./changelog-screen.js";
import { openTypographyLab } from "./typography-lab.js";
import { openSheet } from "../sheets.js";
import { languageSection } from "./settings-language.js";
import { tr } from "../../i18n/i18n.js";

const CATEGORIES = [
  { id: "appearance", title: tr("Внешний вид"), icon: "palette" },
  { id: "background", title: tr("Фон"), icon: "film" },
  { id: "workflow", title: tr("Работа"), icon: "hand" },
  { id: "developer", title: tr("Разработчик"), icon: "hammer" }
];

export function openSettings(app) {
  app.ui ??= {};
  app.ui.settingsCategory ??= "appearance";
  app.feedback.play("settingsOpen", { haptic: false });
  pushScreen((close, setRefresh) => {
    const content = h("div", { class: "settings-content" });
    const selector = h("div", { class: "category-grid" });
    const rerender = () => {
      const scroll = content.parentElement?.scrollTop ?? 0;
      selector.replaceChildren(...CATEGORIES.map((c) => h("button", {
        class: `category${c.id === app.ui.settingsCategory ? " selected" : ""}`,
        onclick: () => { app.feedback.tap(); app.ui.settingsCategory = c.id; rerender(); }
      }, icon(c.icon, 18, 2.6), h("span", {}, c.title))));
      content.replaceChildren(...sections(app, rerender));
      if (content.parentElement) content.parentElement.scrollTop = scroll;
    };
    setRefresh(() => {
      // Перерисовка только при изменении данных смены (каталог) — не во время ввода текста.
      if (!content.contains(document.activeElement) || document.activeElement === document.body) rerender();
    });
    rerender();
    return h("main", { class: "detail-screen" },
      h("div", { class: "detail-scroll" },
        h("header", { class: "detail-header inline" }, backButton(close), h("div", { class: "detail-big-title" }, tr("Настройки"))),
        selector, content));
  });
}

function sections(app, rerender) {
  switch (app.ui.settingsCategory) {
    case "background": return [backgroundSection(app, rerender)];
    case "workflow": return [workSection(app, rerender)];
    case "developer": return [experimentalSection(app, rerender), testDataSection(app, rerender), developerSection(app)];
    default: return [languageSection(app), appearanceSection(app), soundSection(app, rerender), resetSection(app, rerender)];
  }
}

function appearanceSection(app) {
  const { settings, feedback } = app;
  const geometry = settings.get("roomCellGeometry");
  const description = h("span", { class: "info-value" }, geometry === "compact" ? tr("Зум удержанием") : tr("Статус удержанием"));
  return settingsPanel(tr("Внешний вид"), tr("Размер ячеек, палитра статусов и жесты задач на основном экране."),
    segmented([{ value: "roomy", label: tr("Стандартные") }, { value: "compact", label: tr("Расширенные") }], geometry, (v) => {
      settings.set("roomCellGeometry", v);
      description.textContent = v === "compact" ? tr("Зум удержанием") : tr("Статус удержанием");
    }, feedback),
    infoRow({ title: tr("Ячейки"), iconName: "grid", subtitle: tr("Стандартный режим меняет статус удержанием, расширенный увеличивает комнату почти на весь экран."), trailing: description }),
    h("div", { class: "info-block" },
      h("div", { class: "info-block-head" }, h("span", { class: "info-title" }, tr("Ячеек в ряду")), h("span", { class: "info-value" }, String(settings.get("gridColumnCount")))),
      segmented([{ value: 3, label: "3" }, { value: 4, label: "4" }], settings.get("gridColumnCount"), (v) => settings.set("gridColumnCount", v), feedback),
      h("div", { class: "info-subtitle" }, tr("Меняет только число ячеек в строке главного экрана и стенда."))),
    toggleRow({ title: tr("Прозрачные панели"), iconName: "sliders", feedback, value: settings.get("transparentSurfacesEnabled"), onLabel: "AWS26", offLabel: tr("Обычные"),
      subtitle: tr("Ослабляет плотный чёрный фон у общих панелей, карточек и окон поверх живого фона."), onChange: (v) => settings.set("transparentSurfacesEnabled", v) }),
    toggleRow({ title: tr("Сочная палитра"), iconName: "palette", feedback, value: settings.vividStatusPaletteEnabled, onLabel: tr("Скриншот"), offLabel: tr("Обычная"),
      subtitle: tr("Второй режим фиксирует яркие цвета ячеек как на твоём скриншоте."), onChange: (v) => settings.set("statusPaletteSaturation", v ? 1.65 : 1) }),
    toggleRow({ title: tr("Долгий тап"), iconName: "hand", feedback, value: settings.get("roomTaskLongPress"), onLabel: tr("Включен"), offLabel: tr("Быстрый"),
      subtitle: tr("Защищает S, L, B от случайных касаний во время скролла."), onChange: (v) => settings.set("roomTaskLongPress", v) }));
}

function soundSection(app, rerender) {
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
      infoRow({ title: event.title, value: SOUND_ASSETS[asset].title, iconName: "speaker", subtitle: event.subtitle, onclick: choose }),
      h("button", { class: "play-button", "aria-label": tr("Прослушать {sound}", { sound: SOUND_ASSETS[asset].title }), onclick: () => feedback.preview(asset) }, icon("play", 16, 3)));
  });
  return settingsPanel(tr("Звуки"), tr("Три назначения: общий интерфейс, ячейка и финальная зелёная ячейка."), ...rows);
}

function resetSection(app, rerender) {
  return settingsPanel(tr("Сброс"), tr("Вернуть визуальные и рабочие параметры к значениям по умолчанию."),
    infoRow({ title: tr("Сброс настроек"), value: tr("По умолчанию"), iconName: "reset", subtitle: tr("Не удаляет рабочую смену, но сбрасывает внешний вид и режимы."), onclick: () => {
      app.feedback.tap();
      openSheet((close) => h("div", { class: "actions" },
        h("div", { class: "action-group" },
          h("div", { class: "action-title" }, tr("Сбросить настройки?")),
          h("div", { class: "action-message" }, tr("Размер ячеек, режимы меню, палитра и Matrix-настройки вернутся к значениям по умолчанию.")),
          h("button", { class: "action destructive", onclick: () => { app.feedback.confirm(); app.settings.resetToDefaults(); close(); rerender(); } }, tr("Сбросить"))),
        h("button", { class: "action cancel", onclick: close }, tr("Отмена"))));
    } }));
}

function experimentalSection(app, rerender) {
  const { settings, feedback } = app;
  const toggle = (key, title, iconName, subtitle) => toggleRow({ title, iconName, subtitle, feedback, value: settings.get(key), onChange: (v) => { settings.set(key, v); rerender(); } });
  const slider = (key, title, min, max, def, label) => sliderRow({ title, iconName: "bolt", min, max, defaultValue: def, value: settings.get(key), label, onChange: (v) => settings.set(key, v) });
  return settingsPanel(tr("Экспериментальное"), tr("Только активные режимы, которые можно реально оценить на основном экране."),
    toggle("developerLive3DCellsEnabled", tr("Живые 3D-ячейки"), "grid", tr("Объёмное тело ячеек с бликом. Текст и все действия остаются обычным интерфейсом.")),
    toggle("developerCellPhysicsEnabled", tr("Живые ячейки"), "waveform", tr("Пружинящий отклик ячеек на изменения статуса, задач и VIP.")),
    settings.get("developerCellPhysicsEnabled") ? slider("developerCellSpringIntensity", tr("Сила пружины"), 0, 1, 0.72, (v) => `${Math.round(v * 100)}%`) : null,
    settings.get("developerCellPhysicsEnabled") ? slider("developerCellSpringSpeed", tr("Скорость пружины"), 0.2, 1.6, 0.82, (v) => `${v.toFixed(2)}x`) : null,
    infoRow({ title: tr("Типографика ячеек"), value: tr("Стенд"), iconName: "note", subtitle: tr("Живой preview ячеек с отдельными настройками номера и времени."), onclick: () => { feedback.tap(); openTypographyLab(app); } }),
    toggle("developerVIPJellyEnabled", tr("VIP-желе"), "waveform", tr("Живая форма VIP-ячейки: двигается сам контур, а не внутренняя линия.")),
    settings.get("developerVIPJellyEnabled") ? slider("developerVIPJellySpeed", tr("Скорость желе"), 0.2, 2.5, 0.75, (v) => `${v.toFixed(2)}x`) : null,
    toggle("developerVIPHDREnabled", tr("VIP HDR-свет"), "sparkle", tr("VIP-ячейка светится отдельно от общей яркости интерфейса.")),
    toggle("developerStatusHDRPulseEnabled", tr("HDR-всплеск статуса"), "bolt", tr("После смены статуса ячейка разгорается и две секунды плавно остывает из максимальной яркости нового цвета.")));
}

function testDataSection(app, rerender) {
  const label = h("span", { class: "info-value" }, app.ui.testSummary ?? tr("Запустить"));
  return settingsPanel(tr("Тестовые данные"), tr("Быстро заполняет рабочий экран полным набором номеров."),
    infoRow({ title: tr("Распределить весь отель"), iconName: "grid", subtitle: tr("Случайно и равномерно назначает все номера всем уборщицам из списка."), trailing: label, onclick: () => {
      const summary = app.store.assignAllRoomsForTesting(app.settings.get("housekeepers"));
      if (!summary) return app.feedback.invalid();
      app.ui.testSummary = `${summary.housekeeperCount} / ${summary.roomCount}`;
      label.textContent = app.ui.testSummary;
      app.feedback.confirm();
      rerender();
    } }));
}

function developerSection(app) {
  return settingsPanel(tr("Разработчик"), tr("Только служебный журнал сборок. Остальная диагностика не смешивается с настройками."),
    infoRow({ title: tr("Версия PWA {version} ({build})", { version: app.version, build: app.build }), value: tr("Изменения"), iconName: "list", subtitle: tr("Короткая выжимка по последним сборкам."), onclick: () => { app.feedback.tap(); openChangelog(); } }));
}
