// Каталог номеров Margaritaville и правила сравнения номеров.
// Источник: Domain/HotelProfile.swift (MargaritavilleRoomCatalog), Domain/RoomCatalog.swift.

const ids = (...values) => values.map(String);

function territory(floor, building, rooms) {
  const label = `${building.toUpperCase()}${floor}`;
  return { id: label, label, floor, building, rooms };
}

export const TERRITORIES = [
  territory(1, "a", ids(101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 114, 115, 116, 117, 118, 119, 120, 122, 123, 124, 125, 126, 127, 128, 129)),
  territory(1, "b", ids(142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170)),
  territory(2, "a", ids(201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232)),
  territory(2, "b", ids(239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270)),
  territory(3, "a", ids(301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328)),
  territory(3, "b", ids(330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370))
];

/// Порядок тележек по умолчанию (WorkSessionSelectionRules.margaritavillePreferredTerritoryByCart).
export const PREFERRED_TERRITORY_BY_CART = { 1: "A1", 2: "B1", 3: "A2", 4: "B2", 5: "A3", 6: "B3" };

export function territoryById(id) {
  return TERRITORIES.find((t) => t.id === id) ?? null;
}

export function territoryForRoom(room) {
  return TERRITORIES.find((t) => t.rooms.includes(room)) ?? null;
}

function parseRoomID(value) {
  const match = /^(\d+)([A-Z]*)$/.exec(value);
  return match ? { number: Number(match[1]), suffix: match[2] } : null;
}

export function compareRoomIDs(left, right) {
  const a = parseRoomID(left);
  const b = parseRoomID(right);
  if (!a || !b) return left < right ? -1 : left > right ? 1 : 0;
  if (a.number !== b.number) return a.number - b.number;
  return a.suffix < b.suffix ? -1 : a.suffix > b.suffix ? 1 : 0;
}

export function normalizeRoomID(value) {
  const trimmed = String(value ?? "").trim().toUpperCase();
  return trimmed || null;
}

function compareTerritoryLabels(left, right) {
  const a = territoryById(left);
  const b = territoryById(right);
  if (!a || !b) return left < right ? -1 : 1;
  if (a.building !== b.building) return a.building < b.building ? -1 : 1;
  return a.floor - b.floor;
}

/// Подпись зон для набора номеров, например «A1/B1» (territorySummaryLabel).
export function territorySummaryLabel(rooms, fallback) {
  const labels = [...new Set(rooms.map((room) => territoryForRoom(room)?.label).filter(Boolean))];
  if (!labels.length) return fallback;
  return labels.sort(compareTerritoryLabels).join("/");
}
