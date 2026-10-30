// Ползунки эффекта: показываются только те, что меняют выбранный эффект
// (правила из CameraEffectControls.swift).
import { RANGES, TUNING_DEFAULTS, metalName, uses } from "./effects.js";
import { tr } from "../i18n/i18n.js";

const percent = (v) => `${Math.round(v * 100)}%`;
const times = (v) => `${v.toFixed(2)}×`;

/// Описание ползунков для эффекта: [ключ, подпись, формат, шаг].
function slidersFor(effectId, tuning) {
  const list = [];
  if (uses.amount(effectId)) list.push(["amount", tr("Сила эффекта"), percent, 0.01]);
  list.push(["brightness", tr("Яркость"), percent, 0.01]);
  if (uses.metalColor(effectId)) {
    list.push(["metalHue", tr("Цвет металла"), (v) => `${metalName(v, tuning.metalSaturation)} · ${Math.round(v)}°`, 1]);
    list.push(["metalSaturation", tr("Насыщенность металла"), (v) => (v < 0.12 ? tr("серебро") : percent(v)), 0.01]);
  }
  if (uses.relief(effectId)) list.push(["reliefDepth", tr("Глубина рельефа"), times, 0.01]);
  if (uses.edges(effectId)) list.push(["edgeSensitivity", tr("Чувствительность контуров"), times, 0.01]);
  if (uses.detail(effectId)) list.push(["detailScale", tr("Размер элементов"), times, 0.01]);
  if (uses.glow(effectId)) list.push(["glowAmount", tr("Ореол"), percent, 0.01]);
  return list;
}

export function renderControls(container, effectId, tuning, onChange) {
  container.replaceChildren();
  const addSlider = ([key, label, format, step]) => {
    const [min, max] = RANGES[key];
    const wrap = document.createElement("label");
    wrap.className = "control";
    const head = document.createElement("span");
    head.className = "control-head";
    const name = document.createElement("span");
    name.textContent = label;
    const value = document.createElement("output");
    value.textContent = format(tuning[key]);
    head.append(name, value);
    const input = document.createElement("input");
    input.type = "range";
    input.id = `tuning-${key}`;
    input.min = String(min);
    input.max = String(max);
    input.step = String(step);
    input.value = String(tuning[key]);
    input.addEventListener("input", () => {
      onChange(key, Number(input.value));
      value.textContent = format(tuning[key]);
      if (key === "metalSaturation") {
        const hueOutput = container.querySelector("#tuning-metalHue")?.parentElement?.querySelector("output");
        if (hueOutput) hueOutput.textContent = `${metalName(tuning.metalHue, tuning.metalSaturation)} · ${Math.round(tuning.metalHue)}°`;
      }
    });
    wrap.append(head, input);
    container.append(wrap);
  };

  slidersFor(effectId, tuning).forEach(addSlider);

  if (uses.relief(effectId)) {
    const toggle = document.createElement("label");
    toggle.className = "toggle";
    const text = document.createElement("span");
    text.textContent = tr("Свет по кругу");
    const input = document.createElement("input");
    input.type = "checkbox";
    input.id = "tuning-liveLight";
    input.checked = tuning.liveLight;
    input.addEventListener("change", () => onChange("liveLight", input.checked, true));
    toggle.append(text, input);
    container.append(toggle);
    if (!tuning.liveLight) {
      addSlider(["lightAngle", tr("Направление света"), (v) => `${Math.round(v)}°`, 1]);
    }
  }
}

export function isDefaultTuning(tuning) {
  return Object.keys(TUNING_DEFAULTS).every((key) => tuning[key] === TUNING_DEFAULTS[key]);
}
