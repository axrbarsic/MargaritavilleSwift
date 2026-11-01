// Экран «Для разработчика»: экспериментальные эффекты ячеек, стенд типографики, тестовые данные.
// Источник: Features/Settings/SettingsCategoryDeveloper.swift, SettingsTestDataSection.swift.
import { h } from "../dom.js";
import { infoRow, settingsPanel, sliderRow, toggleRow } from "./settings-controls.js";
import { openTypographyLab } from "./typography-lab.js";
import { tr } from "../../i18n/i18n.js";

export function developerSections(app, rerender) {
  return [effectsSection(app, rerender), testDataSection(app, rerender)];
}

function effectsSection(app, rerender) {
  const { settings, feedback } = app;
  const toggle = (key, title, iconName, subtitle) => toggleRow({ title, iconName, subtitle, feedback, value: settings.get(key), onChange: (v) => { settings.set(key, v); rerender(); } });
  const slider = (key, title, min, max, def, label) => sliderRow({ title, iconName: "bolt", min, max, defaultValue: def, value: settings.get(key), label, onChange: (v) => settings.set(key, v) });
  return settingsPanel(tr("Эффекты ячеек"), tr("Экспериментальные режимы, которые видно на главном экране."),
    toggle("developerLive3DCellsEnabled", tr("Живые 3D-ячейки"), "grid", tr("Объёмное тело ячеек с бликом. Текст и все действия остаются обычным интерфейсом.")),
    toggle("developerCellPhysicsEnabled", tr("Живые ячейки"), "waveform", tr("Пружинящий отклик ячеек на изменения статуса, задач и VIP.")),
    settings.get("developerCellPhysicsEnabled") ? slider("developerCellSpringIntensity", tr("Сила пружины"), 0, 1, 0.72, (v) => `${Math.round(v * 100)}%`) : null,
    settings.get("developerCellPhysicsEnabled") ? slider("developerCellSpringSpeed", tr("Скорость пружины"), 0.2, 1.6, 0.82, (v) => `${v.toFixed(2)}x`) : null,
    toggle("developerVIPJellyEnabled", tr("VIP-желе"), "waveform", tr("Живая форма VIP-ячейки: двигается сам контур, а не внутренняя линия.")),
    settings.get("developerVIPJellyEnabled") ? slider("developerVIPJellySpeed", tr("Скорость желе"), 0.2, 2.5, 0.75, (v) => `${v.toFixed(2)}x`) : null,
    toggle("developerVIPHDREnabled", tr("VIP HDR-свет"), "sparkle", tr("VIP-ячейка светится отдельно от общей яркости интерфейса.")),
    toggle("developerStatusHDRPulseEnabled", tr("HDR-всплеск статуса"), "bolt", tr("После смены статуса ячейка разгорается и две секунды плавно остывает из максимальной яркости нового цвета.")),
    infoRow({ title: tr("Типографика ячеек"), value: tr("Стенд"), iconName: "note", subtitle: tr("Живой preview ячеек с отдельными настройками номера и времени."), chevron: true, onclick: () => { feedback.tap(); openTypographyLab(app); } }));
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
