// Раздел «Фон»: выбор заставки и её настройки — Matrix, TV, видео, Brooklyn, камера с эффектами.
// Источник: Features/Settings/SettingsBackgroundSection.swift, BrooklynAppearanceControls.swift,
// CameraEffectControls.swift, CameraEffectPicker.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { BACKGROUND_MODES, availableModes, effectiveMode } from "../background/app-background.js";
import { BACKGROUND_VIDEO_KEY } from "../background/media-backgrounds.js";
import { TV_VARIANTS } from "../background/tv-static.js";
import { DONOR_HUE } from "../background/brooklyn.js";
import { saveFile } from "../../store/db.js";
import { CATEGORIES, EFFECTS, TUNING_DEFAULTS, categoryOf } from "../../camera/effects.js";
import { renderControls } from "../../camera/controls.js";
import { choiceRow, infoRow, pickerRow, segmented, settingsPanel, sliderRow } from "./settings-controls.js";
import { tr } from "../../i18n/i18n.js";

const pct = (v) => `${Math.round(v * 100)}%`;
const SUBTITLE = {
  off: tr("Фон отключён, основной экран остаётся чёрным."),
  matrixRain: tr("Matrix Rain как основной живой фон."),
  tvStaticNoise: tr("Аналоговый телевизионный снег как основной фон."),
  video: tr("Видео хранится только локально на устройстве."),
  brooklyn: tr("3D-сцена Brooklyn с геометрией, материалом и анимацией исходника."),
  camera: tr("Вместо обоев видно изображение камеры. Камера выключается, когда приложение свёрнуто или поверх открыт другой экран.")
};

export function backgroundSection(app, rerender) {
  const { settings, feedback } = app;
  const mode = effectiveMode(settings);
  const slider = (key, title, iconName, min, max, def, label = pct) => sliderRow({ title, iconName, min, max, defaultValue: def, value: settings.get(key), label, onChange: (v) => settings.set(key, v) });
  const extra = [];
  let footer = null;
  let picker = null;
  if (mode === "matrixRain") extra.push(slider("matrixSpeed", tr("Скорость"), "bolt", 0.08, 3, 1, (v) => `${v.toFixed(2)}x`));
  if (mode === "tvStaticNoise") {
    const variant = TV_VARIANTS.find((v) => v.id === settings.get("tvStaticVariant")) ?? TV_VARIANTS[0];
    extra.push(
      pickerRow({ title: tr("Вариант шума"), iconName: "film", subtitle: variant.description,
        control: segmented(TV_VARIANTS.map((v) => ({ value: v.id, label: v.title })), variant.id, (v) => { settings.set("tvStaticVariant", v); rerender(); }, feedback) }),
      slider("tvStaticBrightness", tr("Яркость"), "sparkle", -1, 1, -0.08),
      slider("tvStaticGreenTint", tr("Зелёный"), "sparkle", 0, 1, 0));
  }
  if (mode === "video") {
    picker = h("input", { type: "file", accept: "video/*", hidden: true });
    picker.addEventListener("change", async () => {
      const file = picker.files?.[0];
      if (!file) return;
      try {
        await saveFile(BACKGROUND_VIDEO_KEY, file);
        settings.set("backgroundVideoName", file.name);
        app.background.reloadVideo();
        feedback.confirm();
        rerender();
      } catch {
        feedback.holdWarning();
      }
    });
    extra.push(
      infoRow({ title: tr("Видео фона"), value: settings.get("backgroundVideoName") ? tr("Выбрано") : tr("Выбрать"), iconName: "film", subtitle: tr("Видео из галереи хранится только на этом устройстве."), chevron: true, onclick: () => picker.click() }),
      slider("backgroundVideoBlur", tr("Матовость"), "sparkle", 0, 1, 0.28),
      slider("backgroundVideoBrightness", tr("Яркость"), "sparkle", -0.85, 0.85, 0.08),
      slider("backgroundVideoGreenTint", tr("Зелёный"), "sparkle", 0, 1, 0.34),
      slider("backgroundVideoGridIntensity", tr("Сетка"), "grid", 0, 1, 0));
  }
  if (mode === "brooklyn") {
    const style = settings.get("brooklynSurfaceStyle");
    extra.push(
      pickerRow({ title: tr("Материал Brooklyn"), iconName: "grid", subtitle: style === "donorExact" ? tr("Точный материал исходника с текстурами и городским HDR.") : tr("Та же сцена и анимация с усиленными бликами."),
        control: segmented([{ value: "donorExact", label: tr("Оригинал") }, { value: "enhanced", label: tr("Блики+") }], style, (v) => { settings.set("brooklynSurfaceStyle", v); rerender(); }, feedback) }),
      slider("brooklynCellScale", tr("Размер ячеек"), "grid", 0.45, 1.25, 1),
      slider("brooklynHue", tr("Оттенок"), "palette", 0, 1, DONOR_HUE, (v) => `${Math.round(v * 360)}°`),
      slider("brooklynBrightness", tr("Яркость"), "sparkle", 0.45, 1.55, 1),
      slider("brooklynContrast", tr("Контраст"), "sliders", -0.5, 0.5, 0, (v) => `${v >= 0 ? "+" : ""}${Math.round(v * 100)}%`));
    footer = tr("Размер, оттенок, яркость и контраст применяются к живой сцене сразу.");
  }

  const current = BACKGROUND_MODES.find((m) => m.id === mode) ?? BACKGROUND_MODES[0];
  const modes = settingsPanel(tr("Заставка"), SUBTITLE[mode], ...availableModes(settings).map((m) => choiceRow({
    title: m.title, subtitle: m.description === m.title ? null : m.description, selected: m.id === mode,
    onclick: () => { if (m.id === mode) return; feedback.confirm(); settings.set("appBackgroundMode", m.id); rerender(); }
  })));
  const options = extra.length ? settingsPanel(current.title, footer, ...extra) : null;
  if (picker) options.append(picker);
  return [modes, options, ...(mode === "camera" ? cameraSections(app, rerender) : [])];
}

function cameraSections(app, rerender) {
  const { settings, feedback } = app;
  const effectID = EFFECTS[settings.get("cameraEffect")] ? settings.get("cameraEffect") : "normal";
  const category = app.ui.cameraCategory ?? categoryOf(effectID).id;
  const tuningMap = settings.get("cameraTuning") ?? {};
  const tuning = { ...TUNING_DEFAULTS, ...(tuningMap[effectID] ?? {}) };

  const chips = h("div", { class: "chip-row" }, CATEGORIES.map((c) => h("button", {
    class: `chip${c.id === category ? " selected" : ""}`,
    onclick: () => { feedback.tap(); app.ui.cameraCategory = c.id; rerender(); }
  }, c.title)));
  const grid = h("div", { class: "effect-grid" }, CATEGORIES.find((c) => c.id === category).effects.map((id) => h("button", {
    class: `effect-card${id === effectID ? " selected" : ""}`,
    onclick: () => { feedback.confirm(); settings.set("cameraEffect", id); rerender(); }
  }, EFFECTS[id].title)));
  const controls = h("div", { class: "camera-tuning" });
  renderControls(controls, effectID, tuning, (key, value, rebuild) => {
    tuning[key] = value;
    settings.set("cameraTuning", { ...settings.get("cameraTuning"), [effectID]: { ...tuning } });
    if (rebuild) rerender();
  });
  const reset = h("button", { class: "info-row center", onclick: () => {
    feedback.tap();
    const next = { ...settings.get("cameraTuning") };
    delete next[effectID];
    settings.set("cameraTuning", next);
    rerender();
  } }, icon("reset", 16, 3), h("span", {}, tr("Сбросить настройки эффекта")));

  return [
    settingsPanel(tr("Камера"), null,
      segmented([{ value: "environment", label: tr("Задняя") }, { value: "user", label: tr("Передняя") }], settings.get("cameraFacing"), (v) => settings.set("cameraFacing", v), feedback)),
    settingsPanel(tr("Эффект камеры"), EFFECTS[effectID].subtitle, h("div", { class: "effect-picker" }, chips, grid)),
    settingsPanel(EFFECTS[effectID].title, null, controls, reset)
  ];
}
