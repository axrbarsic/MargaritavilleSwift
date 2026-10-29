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
