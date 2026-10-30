// Раздел «Фон»: выбор заставки и её настройки — Matrix, TV, видео, Brooklyn, камера с эффектами.
// Источник: Features/Settings/SettingsBackgroundSection.swift, BrooklynAppearanceControls.swift,
// CameraEffectControls.swift, CameraEffectPicker.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { BACKGROUND_MODES } from "../background/app-background.js";
import { BACKGROUND_VIDEO_KEY } from "../background/media-backgrounds.js";
import { TV_VARIANTS } from "../background/tv-static.js";
import { DONOR_HUE } from "../background/brooklyn.js";
import { saveFile } from "../../store/db.js";
import { CATEGORIES, EFFECTS, TUNING_DEFAULTS, categoryOf } from "../../camera/effects.js";
import { renderControls } from "../../camera/controls.js";
import { infoRow, segmented, selectMenu, settingsPanel, sliderRow } from "./settings-controls.js";

const pct = (v) => `${Math.round(v * 100)}%`;
const SUBTITLE = {
  off: "Фон отключён, основной экран остаётся чёрным.",
  matrixRain: "Matrix Rain как основной живой фон.",
  tvStaticNoise: "Аналоговый телевизионный снег как основной фон.",
  video: "Видео хранится только локально на устройстве.",
  brooklyn: "3D-сцена Brooklyn с геометрией, материалом и анимацией исходника.",
  camera: "Вместо обоев видно изображение камеры. Камера выключается, когда приложение свёрнуто или поверх открыт другой экран."
};

export function backgroundSection(app, rerender) {
  const { settings, feedback } = app;
  const mode = settings.get("appBackgroundMode");
  const slider = (key, title, iconName, min, max, def, label = pct) => sliderRow({ title, iconName, min, max, defaultValue: def, value: settings.get(key), label, onChange: (v) => settings.set(key, v) });
  const extra = [];
  if (mode === "matrixRain") extra.push(slider("matrixSpeed", "Скорость", "bolt", 0.08, 3, 1, (v) => `${v.toFixed(2)}x`));
  if (mode === "tvStaticNoise") {
    const variant = TV_VARIANTS.find((v) => v.id === settings.get("tvStaticVariant")) ?? TV_VARIANTS[0];
    extra.push(
      infoRow({ title: "Вариант шума", value: variant.title, iconName: "film", subtitle: variant.description }),
      segmented(TV_VARIANTS.map((v) => ({ value: v.id, label: v.title })), variant.id, (v) => { settings.set("tvStaticVariant", v); rerender(); }, feedback),
      slider("tvStaticBrightness", "Яркость", "sparkle", -1, 1, -0.08),
      slider("tvStaticGreenTint", "Зелёный", "sparkle", 0, 1, 0));
  }
  if (mode === "video") {
    const picker = h("input", { type: "file", accept: "video/*", hidden: true });
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
    extra.push(picker,
      infoRow({ title: "Видео фона", value: settings.get("backgroundVideoName") ? "Выбрано" : "Выбрать", iconName: "film", subtitle: "Видео из галереи хранится только на этом устройстве.", onclick: () => picker.click() }),
      slider("backgroundVideoBlur", "Матовость", "sparkle", 0, 1, 0.28),
      slider("backgroundVideoBrightness", "Яркость", "sparkle", -0.85, 0.85, 0.08),
      slider("backgroundVideoGreenTint", "Зелёный", "sparkle", 0, 1, 0.34),
      slider("backgroundVideoGridIntensity", "Сетка", "grid", 0, 1, 0));
  }
  if (mode === "brooklyn") {
    const style = settings.get("brooklynSurfaceStyle");
    extra.push(
      segmented([{ value: "donorExact", label: "Оригинал" }, { value: "enhanced", label: "Блики+" }], style, (v) => { settings.set("brooklynSurfaceStyle", v); rerender(); }, feedback),
      infoRow({ title: "Материал Brooklyn", value: style === "donorExact" ? "Оригинал" : "Блики+", iconName: "grid", subtitle: style === "donorExact" ? "Точный материал исходника с текстурами и городским HDR." : "Та же сцена и анимация с усиленными бликами." }),
      settingsPanel("Вид Brooklyn", "Размер, оттенок, яркость и контраст применяются к живой сцене сразу.",
        slider("brooklynCellScale", "Размер ячеек", "grid", 0.45, 1.25, 1),
        slider("brooklynHue", "Оттенок", "palette", 0, 1, DONOR_HUE, (v) => `${Math.round(v * 360)}°`),
        slider("brooklynBrightness", "Яркость", "sparkle", 0.45, 1.55, 1),
        slider("brooklynContrast", "Контраст", "sliders", -0.5, 0.5, 0, (v) => `${v >= 0 ? "+" : ""}${Math.round(v * 100)}%`)));
  }
  if (mode === "camera") extra.push(cameraControls(app, rerender));

  const current = BACKGROUND_MODES.find((m) => m.id === mode) ?? BACKGROUND_MODES[0];
  return settingsPanel("Фон приложения", "Живые Matrix, TV, Video, Brooklyn и камера как фон для всех экранов приложения.",
    selectMenu(BACKGROUND_MODES.map((m) => ({ value: m.id, label: m.title })), mode, (v) => { feedback.confirm(); settings.set("appBackgroundMode", v); rerender(); }, "Заставка"),
    infoRow({ title: "Заставка", value: current.description, iconName: "grid", subtitle: SUBTITLE[mode] }),
    ...extra);
}

function cameraControls(app, rerender) {
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
  } }, icon("reset", 16, 3), h("span", {}, "Сбросить настройки эффекта"));

  return h("div", { class: "detail-stack" },
    segmented([{ value: "environment", label: "Задняя" }, { value: "user", label: "Передняя" }], settings.get("cameraFacing"), (v) => settings.set("cameraFacing", v), feedback),
    chips, grid,
    infoRow({ title: "Эффект камеры", value: EFFECTS[effectID].title, iconName: "camera", subtitle: EFFECTS[effectID].subtitle }),
    controls, reset);
}
