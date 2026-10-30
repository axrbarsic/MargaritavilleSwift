// Выбор смены: тележки, их зоны, горничные и номера. Источник: Domain/WorkSessionSelection.swift.
import { PREFERRED_TERRITORY_BY_CART, TERRITORIES, compareRoomIDs, normalizeRoomID, territoryById, territorySummaryLabel } from "./catalog.js";

const CART_RANGE = Array.from({ length: 100 }, (_, i) => i + 1);
export const firstAvailableCart = (s) => CART_RANGE.find((c) => !s.cartBindings[c]) ?? null;
import { makeRoom } from "./room.js";

export function emptySelection() {
  return { cartBindings: {}, cartHousekeeperIDs: {}, cartRoomSelections: {}, workdayLocked: false, workdayLockUpdatedAt: null };
}

export const selectedCartNumbers = (s) => Object.keys(s.cartBindings).map(Number).sort((a, b) => a - b);
export const roomsForCart = (s, cart) => new Set(s.cartRoomSelections[cart] ?? []);
export const selectedRooms = (s) => new Set(Object.values(s.cartRoomSelections).flat());

export function roomOwnerCart(s, room) {
  const carts = Object.keys(s.cartRoomSelections).map(Number).sort((a, b) => a - b);
  return carts.find((cart) => s.cartRoomSelections[cart].includes(room)) ?? null;
}

function preferredTerritory(cart, bindings) {
  const preferred = territoryById(PREFERRED_TERRITORY_BY_CART[cart]);
  if (preferred) return preferred;
  const bound = new Set(Object.values(bindings));
  return TERRITORIES.find((t) => !bound.has(t.id)) ?? TERRITORIES[0];
}

/// Включает или выключает тележку. Возвращает true, если выбор изменился.
export function toggleCart(s, cart) {
  if (s.workdayLocked) return false;
  if (s.cartBindings[cart]) {
    delete s.cartBindings[cart];
    delete s.cartHousekeeperIDs[cart];
    delete s.cartRoomSelections[cart];
    return true;
  }
  s.cartBindings[cart] = preferredTerritory(cart, s.cartBindings).id;
  return true;
}

export function setCartTerritory(s, cart, territoryID) {
  if (s.workdayLocked || !s.cartBindings[cart]) return false;
  s.cartBindings[cart] = territoryID;
  return true;
}

export function setHousekeeper(s, cart, housekeeperID) {
  if (s.workdayLocked || !s.cartBindings[cart]) return false;
  if (housekeeperID) s.cartHousekeeperIDs[cart] = housekeeperID;
  else delete s.cartHousekeeperIDs[cart];
  return true;
}

/// Отмечает номер за тележкой; номер другой тележки не трогается ("blocked").
export function toggleRoom(s, cart, rawRoom) {
  if (s.workdayLocked) return "ignored";
  const room = normalizeRoomID(rawRoom);
  if (!room) return "ignored";
  const owner = roomOwnerCart(s, room);
  if (owner != null && owner !== cart) return "blocked";
  const rooms = new Set(s.cartRoomSelections[cart] ?? []);
  if (rooms.has(room)) rooms.delete(room);
  else rooms.add(room);
  if (rooms.size) s.cartRoomSelections[cart] = [...rooms].sort(compareRoomIDs);
  else delete s.cartRoomSelections[cart];
  return "changed";
}

export function lockWorkday(s, now) {
  if (s.workdayLocked || selectedRooms(s).size === 0) return false;
  s.workdayLocked = true;
  s.workdayLockUpdatedAt = now;
  return true;
}

export function unlockWorkday(s, now) {
  if (!s.workdayLocked) return false;
  s.workdayLocked = false;
  s.workdayLockUpdatedAt = now;
  return true;
}

/// Пересобирает тележки из выбора, сохраняя состояние комнат и данные тележек
/// (WorkSessionBuilder.makeCarts).
export function makeCarts(s, previousCarts, now, catalog = TERRITORIES) {
  const roomsByID = new Map();
  const cartsByID = new Map();
  for (const cart of previousCarts) {
    cartsByID.set(cart.id, cart);
    for (const room of cart.rooms) if (!roomsByID.has(room.id)) roomsByID.set(room.id, room);
  }
  return selectedCartNumbers(s).map((cartNumber) => {
    const rooms = [...roomsForCart(s, cartNumber)].sort(compareRoomIDs).map((id) => roomsByID.get(id) ?? makeRoom(id, now));
    const fallback = territoryById(s.cartBindings[cartNumber])?.label ?? "";
    const existing = cartsByID.get(cartNumber);
    return {
      id: cartNumber,
      building: territorySummaryLabel(rooms.map((r) => r.id), fallback, catalog),
      rooms,
      note: existing?.note ?? null,
      noteUpdatedAt: existing?.noteUpdatedAt ?? null,
      mediaAttachments: existing?.mediaAttachments ?? null,
      consumables: existing?.consumables ?? null
    };
  });
}
