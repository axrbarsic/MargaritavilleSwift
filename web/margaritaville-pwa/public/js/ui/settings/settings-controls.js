// Элементы настроек: панель, информационная строка, ползунок со сбросом, переключатель,
// сегменты и выпадающий список. Источник: Features/Settings/SettingsControls.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { tr } from "../../i18n/i18n.js";

export function settingsPanel(title, subtitle, ...children) {
  return h("section", { class: "settings-panel" },
    h("div", { class: "settings-panel-head" }, h("div", { class: "settings-panel-title" }, title), h("div", { class: "settings-panel-subtitle" }, subtitle)),
    h("div", { class: "settings-panel-body" }, ...children));
}

export function infoRow({ title, value, iconName, subtitle, onclick, trailing }) {
  const content = [
    h("span", { class: "info-icon" }, icon(iconName, 18, 2.6)),
    h("span", { class: "info-text" }, h("span", { class: "info-title" }, title), subtitle ? h("span", { class: "info-subtitle" }, subtitle) : null),
    value != null ? h("span", { class: "info-value" }, value) : null,
    trailing ?? null
  ];
  return onclick ? h("button", { class: "info-row", onclick }, ...content) : h("div", { class: "info-row" }, ...content);
}

/// Ползунок: { title, label(value), iconName, min, max, step, defaultValue, value, onChange }.
export function sliderRow(opts) {
  const { title, label, iconName, min, max, step = 0.01, defaultValue, value, onChange } = opts;
  const valueLabel = h("span", { class: "info-value" }, label(value));
  const input = h("input", { type: "range", min, max, step, class: "slider" });
  input.value = value;
  const reset = h("button", { class: "slider-reset", "aria-label": tr("Сбросить") }, icon("reset", 16, 3));
  const sync = (v) => {
    valueLabel.textContent = label(v);
    reset.disabled = Math.abs(v - defaultValue) <= 0.001;
    input.style.setProperty("--fill", `${((v - min) / (max - min)) * 100}%`);
  };
  input.addEventListener("input", () => { const v = Number(input.value); sync(v); onChange(v); });
  reset.addEventListener("click", () => { input.value = defaultValue; sync(defaultValue); onChange(defaultValue); });
  sync(value);
  return h("div", { class: "slider-row" },
    h("div", { class: "slider-head" }, h("span", { class: "info-icon" }, icon(iconName, 18, 2.6)), h("span", { class: "info-title" }, title), valueLabel),
    h("div", { class: "slider-line" }, input, reset));
}

export function toggleRow({ title, iconName, subtitle, value, onLabel = tr("Вкл"), offLabel = tr("Выкл"), onChange, feedback }) {
  const input = h("input", { type: "checkbox", class: "switch", role: "switch" });
  input.checked = value;
  const valueLabel = h("span", { class: "info-value" }, value ? onLabel : offLabel);
  input.addEventListener("change", () => { valueLabel.textContent = input.checked ? onLabel : offLabel; feedback?.confirm(); onChange(input.checked); });
  return h("label", { class: "info-row toggle-row" },
    h("span", { class: "info-icon" }, icon(iconName, 18, 2.6)),
    h("span", { class: "info-text" }, h("span", { class: "info-title" }, title), subtitle ? h("span", { class: "info-subtitle" }, subtitle) : null),
    valueLabel, input);
}

/// Сегментированный выбор: options — [{ value, label }].
export function segmented(options, value, onChange, feedback) {
  const row = h("div", { class: "segmented", role: "radiogroup" });
  const paint = (current) => row.replaceChildren(...options.map((o) => h("button", {
    class: `segment${o.value === current ? " selected" : ""}`, role: "radio", "aria-checked": String(o.value === current),
    onclick: () => { if (o.value === current) return; feedback?.confirm(); paint(o.value); onChange(o.value); }
  }, o.label)));
  paint(value);
  return row;
}

export function selectMenu(options, value, onChange, label) {
  const select = h("select", { class: "settings-select", "aria-label": label });
  for (const o of options) {
    const option = h("option", { value: o.value }, o.label);
    if (o.value === value) option.selected = true;
    select.append(option);
  }
  select.addEventListener("change", () => onChange(select.value));
  return select;
}

export function textInputRow(placeholder, onAdd, { inputMode = "text", autocapitalize = "sentences" } = {}) {
  const input = h("input", { class: "settings-input", type: "text", placeholder, inputmode: inputMode, autocapitalize, autocomplete: "off" });
  const add = () => { onAdd(input.value, () => { input.value = ""; }); };
  input.addEventListener("keydown", (e) => { if (e.key === "Enter") add(); });
  return h("div", { class: "input-row" }, input, h("button", { class: "add-button", "aria-label": tr("Добавить"), onclick: add }, icon("plus", 18, 3.2)));
}

export function messageLine(text) {
  return h("div", { class: "settings-message" }, text);
}
