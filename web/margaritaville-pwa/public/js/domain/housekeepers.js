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

export const DEFAULT_HOUSEKEEPERS = [
  ["kerlange", "Kerlange", "slate"], ["anazline", "Ana", "aqua"], ["bebitha", "Bebita", "amber"],
  ["denise", "Denise", "coral"], ["fabiola", "Fabiola", "orchid"], ["francia", "Francia", "sky"],
  ["gurline", "Gurlene", "mint"], ["ketty", "Ketty", "ruby"], ["luisa", "Luisa", "violet"],
  ["marie", "Marie", "lime"], ["marie-pierre", "Marie Pierre", "slate"], ["nadia", "Nadia", "aqua"],
  ["nadia-m-dc", "Nadia M (DC)", "amber"], ["nidia", "Nidia", "coral"], ["omelene-pm", "Omelene PM", "orchid"],
  ["ritza", "Ritza", "sky"], ["rosalie", "Rosaire", "mint"], ["simone", "Simone", "ruby"],
  ["vida", "Vida", "violet"], ["wonderline", "Wonderline", "lime"]
].map(([id, displayName, palette]) => ({ id, displayName, palette }));

export function housekeeperById(id, list = DEFAULT_HOUSEKEEPERS) {
  return id ? list.find((h) => h.id === id) ?? null : null;
}

// ——— редактирование списка (MargaritavilleHousekeeperCatalog) ———
const PALETTES = Object.keys(PALETTE_RGB);
const DUPLICATE_GROUPS = [
  ["ana", "anazine", "anazline"], ["bebita", "bebitha"], ["gurlene", "gurline"],
  ["kerlange", "kerlande"], ["milodene", "omelenepm"], ["rosaire", "rosalie", "rosario"]
];
const NAME_BY_ID = { anazline: "Ana", bebitha: "Bebita", gurline: "Gurlene", "omelene-pm": "Omelene PM", rosalie: "Rosaire" };
const NAME_BY_KEY = { "ana|anazine|anazline": "Ana", "bebita|bebitha": "Bebita", "gurlene|gurline": "Gurlene", "kerlande|kerlange": "Kerlange", "milodene|omelenepm": "Omelene PM", "rosaire|rosalie|rosario": "Rosaire" };

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
