// Расходники тележки: каталог по умолчанию, слияние с сохранёнными количествами,
// сводка по уборщицам. Источник: Domain/CartConsumables.swift,
// Features/Summary/SummaryConsumablesReport.swift.

export const MAX_QUANTITY = 10;

export const DEFAULT_CONSUMABLE_CATALOG = [
  ["bath_towel", "Полотенца банные"],
  ["hand_towel", "Полотенца ручные"],
  ["washcloth", "Салфетки"],
  ["bath_mat", "Коврики"],
  ["sheet", "Простыни"],
  ["pillowcase", "Наволочки"]
].map(([id, title]) => ({ id, title }));

export const clampQuantity = (value) => Math.min(Math.max(0, Math.round(value)), MAX_QUANTITY);

function stableID(title) {
  const folded = title.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
  const collapsed = folded.replace(/[^\p{L}\p{N}]+/gu, "-").replace(/^-+|-+$/g, "");
  return collapsed || "consumable";
}

function uniqueID(preferred, used) {
  let id = preferred;
  for (let suffix = 2; used.has(id); suffix += 1) id = `${preferred}-${suffix}`;
  used.add(id);
  return id;
}

export function normalizedCatalog(items) {
  const used = new Set();
  return items.flatMap((item) => {
    const title = String(item.title ?? "").trim();
    if (!title) return [];
    const preferred = String(item.id ?? "").trim() || stableID(title);
    return [{ id: uniqueID(preferred, used), title }];
  });
}

export function makeCatalogItem(title, existing) {
  const trimmed = String(title ?? "").trim();
  if (!trimmed) return null;
  return { id: uniqueID(stableID(trimmed), new Set(existing.map((i) => i.id))), title: trimmed };
}

/// Позиции каталога в его порядке с сохранёнными количествами (CartConsumableCatalog.merged).
export function mergedConsumables(stored, catalog = DEFAULT_CONSUMABLE_CATALOG) {
  const byID = new Map((stored ?? []).map((item) => [item.id, item]));
  return normalizedCatalog(catalog).map((entry) => ({
    ...(byID.get(entry.id) ?? { id: entry.id, quantity: 0, updatedAt: null, completedAt: null }),
    title: entry.title
  }));
}

export function setQuantity(cart, itemID, title, quantity, catalog, now) {
  const items = mergedConsumables(cart.consumables, catalog);
  let item = items.find((i) => i.id === itemID);
  if (!item && title?.trim()) {
    item = { id: itemID, title: title.trim(), quantity: 0, updatedAt: null, completedAt: null };
    items.push(item);
  }
  if (!item) return null;
  item.quantity = clampQuantity(quantity);
  item.updatedAt = now;
  if (item.quantity === 0) item.completedAt = null;
  cart.consumables = items;
  return item;
}

export function toggleCompletion(cart, itemID, title, catalog, now) {
  const items = mergedConsumables(cart.consumables, catalog);
  let item = items.find((i) => i.id === itemID);
  if (!item && title?.trim()) {
    item = { id: itemID, title: title.trim(), quantity: 0, updatedAt: null, completedAt: null };
    items.push(item);
  }
  if (!item) return null;
  item.completedAt = item.completedAt == null ? now : null;
  item.updatedAt = now;
  cart.consumables = items;
  return item;
}

function compareLines(a, b) {
  if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
  return a.title.localeCompare(b.title, "ru", { numeric: true });
}

/// Нужные расходники по уборщицам и итог (SummaryConsumablesAggregator.makeReport).
export function consumablesReport(sections, carts, housekeepers, catalog) {
  const cartsByID = new Map(carts.map((c) => [c.id, c]));
  const order = new Map(catalog.map((item, index) => [item.id, index]));
  const totals = new Map();
  const rows = [];
  for (const section of sections) {
    const counts = new Map();
    for (const cartID of section.cartIDs) {
      const cart = cartsByID.get(cartID);
      if (!cart) continue;
      for (const item of mergedConsumables(cart.consumables, catalog)) {
        if (item.quantity <= 0 || item.completedAt != null) continue;
        const line = counts.get(item.id) ?? { id: item.id, title: item.title, quantity: 0, sortOrder: order.get(item.id) ?? catalog.length + 100 };
        line.quantity += item.quantity;
        counts.set(item.id, line);
      }
    }
    const items = [...counts.values()].sort(compareLines);
    if (!items.length) continue;
    for (const item of items) {
      const total = totals.get(item.id) ?? { ...item, quantity: 0 };
      total.quantity += item.quantity;
      totals.set(item.id, total);
    }
    const hk = housekeepers.find((h) => h.id === section.housekeeperID);
    rows.push({
      id: section.id,
      displayName: hk?.displayName ?? "Уборщица",
      palette: hk?.palette ?? null,
      locationLabel: section.locationLabel,
      items,
      tickerText: items.map((i) => `${i.title} ${i.quantity}`).join("  •  ")
    });
  }
  return { totals: [...totals.values()].sort(compareLines), housekeepers: rows };
}
