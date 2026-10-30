// Стенд «Типографика ячеек»: живой preview ячеек во всех статусах и эффектах с отдельными
// настройками номера и времени; пресет хранится только для стенда.
// Источник: Features/Settings/CellTypographyLabScreen.swift, CellTypographyLabPreview.swift,
// CellTypographyPresetStore.swift, SavedCellTypographyPresetPanel.swift.
import { h } from "../dom.js";
import { backButton, pushScreen } from "../screen-stack.js";
import { segmented, settingsPanel, sliderRow, infoRow } from "./settings-controls.js";
import { attachVIPJelly } from "../vip-jelly.js";

const KEY = "margaritaville.typographyPreset.v1";
const PRODUCTION = { roomNumberSize: 45, roomNumberWeight: 900, roomNumberOffset: 7, timeSize: 12, timeWeight: 400, timeOffset: 1 };
const WEIGHTS = [{ value: 400, label: "Regular" }, { value: 500, label: "Medium" }, { value: 600, label: "Semi" }, { value: 700, label: "Bold" }, { value: 900, label: "Black" }];
const SAMPLES = [["pending", "101"], ["open", "142"], ["ready", "203"], ["scheduled", "330"]];

function loadPreset() {
  try { return JSON.parse(localStorage.getItem(KEY) ?? "null"); } catch { return null; }
}

export function openTypographyLab(app) {
  pushScreen((close) => {
    const saved = loadPreset();
    const t = { ...PRODUCTION, ...(saved?.typography ?? {}) };
    const preview = h("div", { class: "lab-preview" });
    const savedBox = h("div");
    const columns = app.settings.get("gridColumnCount");

    const tile = (status, number, extra = "") => {
      const element = makeTile(status, number, extra.replace("vip-jelly", ""));
      if (extra.includes("vip-jelly")) attachVIPJelly(element, (Number(number) % 97) / 97, () => app.settings.get("developerVIPJellySpeed"));
      return element;
    };
    const makeTile = (status, number, extra) => h("div", {
      class: `tile lab-tile status-${status} ${extra}`,
      style: {
        "--number-size": `${t.roomNumberSize}px`, "--number-weight": t.roomNumberWeight, "--number-offset": `${t.roomNumberOffset}px`,
        "--time-size": `${t.timeSize}px`, "--time-weight": t.timeWeight, "--time-offset": `${t.timeOffset}px`, "--seed": Number(number) % 97, "--jelly-speed": app.settings.get("developerVIPJellySpeed")
      }
    }, h("span", { class: "tile-body" }), h("span", { class: "tile-number" }, number), h("span", { class: "tile-time" }, "9:41 AM"));
    const group = (title, extra) => h("div", { class: "lab-group" }, h("div", { class: "lab-group-title" }, title),
      h("div", { class: "lab-row", style: { "--cols": columns } }, SAMPLES.slice(0, columns).map(([s, n]) => tile(s, n, extra))));
    const paint = () => preview.replaceChildren(
      h("div", { class: "lab-heading" }, "Production-ячейки"),
      h("div", { class: "info-subtitle" }, "То же выбранное число колонок, размеры и геометрия, что на главном экране."),
      group("Обычные статусы", ""), group("HDR-всплеск + rubber", "hdr-pulse lab-loop"), group("VIP-желе", "vip-jelly"),
      group("VIP HDR", "vip-hdr"), group("VIP-желе + HDR", "vip-jelly vip-hdr"));

    const paintSaved = () => {
      const p = loadPreset();
      savedBox.replaceChildren(p ? settingsPanel("Сохранённый пресет", `Сохранено ${new Date(p.savedAt).toLocaleString("ru-RU")}`,
        infoRow({ title: "Основной номер", iconName: "note", value: `${p.typography.roomNumberSize} · ${p.typography.roomNumberWeight} · ${p.typography.roomNumberOffset}` }),
        infoRow({ title: "Время активации", iconName: "clock", value: `${p.typography.timeSize} · ${p.typography.timeWeight} · ${p.typography.timeOffset}` }),
        h("button", { class: "info-row center destructive", onclick: () => { localStorage.removeItem(KEY); app.feedback.deselect(); paintSaved(); } }, "Удалить пресет")) : "");
    };

    const controls = (title, prefix) => settingsPanel(title, "Все значения применяются ко всем preview-ячейкам сразу.",
      sliderRow({ title: "Размер", iconName: "note", min: prefix === "roomNumber" ? 36 : 12, max: prefix === "roomNumber" ? 48 : 18, step: 1, defaultValue: PRODUCTION[`${prefix}Size`], value: t[`${prefix}Size`], label: (v) => `${v}`, onChange: (v) => { t[`${prefix}Size`] = v; paint(); } }),
      sliderRow({ title: "Смещение по Y", iconName: "sliders", min: -8, max: 8, step: 1, defaultValue: PRODUCTION[`${prefix}Offset`], value: t[`${prefix}Offset`], label: (v) => `${v}`, onChange: (v) => { t[`${prefix}Offset`] = v; paint(); } }),
      h("div", { class: "info-title" }, "Толщина"),
      segmented(WEIGHTS, t[`${prefix}Weight`], (v) => { t[`${prefix}Weight`] = v; paint(); }, app.feedback));

    paint();
    paintSaved();
    return h("main", { class: "detail-screen" },
      h("div", { class: "detail-scroll" },
        h("header", { class: "detail-header inline" }, backButton(close), h("div", {}, h("div", { class: "detail-big-title" }, "Типографика ячеек"), h("div", { class: "detail-cart-subtitle" }, "Только preview — основной экран не меняется"))),
        preview,
        controls("Основной номер", "roomNumber"),
        controls("Время активации", "time"),
        settingsPanel("Сохранение", "Пресет хранится только для стенда и не меняет ячейки основного экрана.",
          h("button", { class: "info-row center", onclick: () => {
            localStorage.setItem(KEY, JSON.stringify({ typography: { ...t }, savedAt: Date.now() }));
            app.feedback.confirm();
            paintSaved();
          } }, "Сохранить пресет")),
        savedBox));
  });
}
