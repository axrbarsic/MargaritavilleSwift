// Горничные и их цвета. Источник: Domain/HousekeeperCatalog.swift,
// Design/HousekeeperPalette+Color.swift.

export const PALETTE_RGB = {
  aqua: [0.0, 0.78, 0.82],
  amber: [1.0, 0.68, 0.18],
  coral: [1.0, 0.38, 0.3],
  orchid: [0.78, 0.36, 0.92],
  sky: [0.22, 0.58, 1.0],
  mint: [0.32, 0.86, 0.55],
  ruby: [0.94, 0.18, 0.36],
  violet: [0.5, 0.42, 1.0],
  lime: [0.72, 0.92, 0.22],
  slate: [0.58, 0.66, 0.76]
};

export function paletteColor(palette, alpha = 1) {
  const [r, g, b] = PALETTE_RGB[palette] ?? PALETTE_RGB.mint;
  return `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)}, ${alpha})`;
}

// Состав по графику и листам комнат на 30–31 октября 2026. Старые id сохранены,
// чтобы назначения тележек не потерялись.
export const DEFAULT_HOUSEKEEPERS = [
  ["ritza", "Ritza", "sky"], ["denise", "Denise", "coral"], ["nadia", "Nadia", "aqua"],
  ["wonderline", "Wonderline", "lime"], ["kerlange", "Kerlange", "slate"], ["miolene", "Miolene", "amber"],
  ["gurline", "Gurlene", "mint"], ["anazline", "Anazine", "orchid"], ["marie", "Marie", "ruby"],
  ["vida", "Vida", "violet"], ["fabiola", "Fabiola", "coral"], ["luisa", "Luisa", "sky"],
  ["francia", "Francia", "lime"], ["ketty", "Kettia", "aqua"], ["miguerline", "Miguerline", "amber"],
  ["amenda", "Amenda", "orchid"]
].map(([id, displayName, palette]) => ({ id, displayName, palette }));

/// Версия встроенного состава: при её росте сохранённый на телефоне список заменяется новым.
export const ROSTER_VERSION = 2;
const PREVIOUS_DEFAULT_IDS = new Set(["kerlange", "anazline", "bebitha", "denise", "fabiola", "francia", "gurline", "ketty", "luisa",
  "marie", "marie-pierre", "nadia", "nadia-m-dc", "nidia", "omelene-pm", "ritza", "rosalie", "simone", "vida", "wonderline"]);

/// Переход на новый состав: встроенные имена — из свежего графика (цвет, выбранный вручную, остаётся),
/// добавленные вручную уборщицы сохраняются в конце списка.
export function migrateRoster(saved) {
  const list = Array.isArray(saved) ? saved : [];
  const palettes = new Map(list.map((h) => [h.id, h.palette]));
  const fresh = DEFAULT_HOUSEKEEPERS.map((h) => ({ ...h, palette: palettes.get(h.id) ?? h.palette }));
  const custom = list.filter((h) => !PREVIOUS_DEFAULT_IDS.has(h.id) && !fresh.some((f) => f.id === h.id));
  return canonicalHousekeepers([...fresh, ...custom]);
}

export function housekeeperById(id, list = DEFAULT_HOUSEKEEPERS) {
  return id ? list.find((h) => h.id === id) ?? null : null;
}

// ——— редактирование списка (MargaritavilleHousekeeperCatalog) ———
const PALETTES = Object.keys(PALETTE_RGB);
const DUPLICATE_GROUPS = [
  ["ana", "anazine", "anazline"], ["bebita", "bebitha"], ["gurlene", "gurline"], ["kettia", "ketty"],
  ["kerlange", "kerlande"], ["miguerlene", "miguerline"], ["milodene", "omelenepm"], ["rosaire", "rosalie", "rosario"]
];
const NAME_BY_ID = { anazline: "Anazine", bebitha: "Bebita", gurline: "Gurlene", ketty: "Kettia", "omelene-pm": "Omelene PM", rosalie: "Rosaire" };
const NAME_BY_KEY = { "ana|anazine|anazline": "Anazine", "bebita|bebitha": "Bebita", "gurlene|gurline": "Gurlene", "kettia|ketty": "Kettia", "kerlande|kerlange": "Kerlange", "miguerlene|miguerline": "Miguerline", "milodene|omelenepm": "Omelene PM", "rosaire|rosalie|rosario": "Rosaire" };

const fold = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
const token = (name) => fold(name).replace(/[^\p{L}\p{N}]/gu, "");
const candidates = (name) => { const t = token(name); return (t.endsWith("pm") ? [t, t.slice(0, -2)] : [t]).filter(Boolean); };
function duplicateKey(name) {
  const set = new Set(candidates(name));
  const group = DUPLICATE_GROUPS.find((g) => g.some((x) => set.has(x)));
  return group ? [...group].sort().join("|") : [...set].sort()[0] ?? token(name);
}
const stableID = (name) => fold(name).replace(/[^\p{L}\p{N}]+/gu, "-").replace(/^-+|-+$/g, "") || "housekeeper";
function uniqueID(preferred, used) {
  let id = preferred;
  for (let n = 2; used.has(id); n += 1) id = `${preferred}-${n}`;
  used.add(id);
  return id;
}

export function makeHousekeeper(displayName, existing) {
  const name = String(displayName ?? "").trim();
  if (!name) return null;
  const id = uniqueID(stableID(name), new Set(existing.map((h) => h.id)));
  return { id, displayName: name, palette: PALETTES[existing.length % PALETTES.length] };
}

/// Нормализация как в canonicalHousekeepers: печатные имена, без дублей листа, Kerlange всегда есть.
export function canonicalHousekeepers(list) {
  const used = new Set();
  let canonical = list.flatMap((h) => {
    const name = String(h.displayName ?? "").trim();
    if (!name) return [];
    const id = uniqueID(String(h.id ?? "").trim() || stableID(name), used);
    return [{ id, displayName: NAME_BY_ID[id] ?? NAME_BY_KEY[duplicateKey(name)] ?? name, palette: h.palette }];
  });
  if (!canonical.length) return DEFAULT_HOUSEKEEPERS;
  const seen = new Set();
  canonical = canonical.filter((h) => { const key = duplicateKey(h.displayName); if (seen.has(key)) return false; seen.add(key); return true; });
  const hasKerlange = canonical.some((h) => candidates(h.displayName).some((c) => ["kerlange"].includes(c)));
  if (!hasKerlange) {
    const k = makeHousekeeper("Kerlange", canonical);
    if (k) canonical.unshift(k);
  }
  return canonical;
}
