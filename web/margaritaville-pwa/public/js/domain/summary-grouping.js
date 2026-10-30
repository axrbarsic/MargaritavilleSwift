// Секции сводки по уборщицам с фильтром статуса и подписью зон.
// Источник: Features/Summary/MargaritavilleSummaryRoomGrouping.swift.
import { compareRoomIDs } from "./catalog.js";
import { isReady, roomStatus } from "./room.js";

export function housekeeperSections(carts, selection, catalog, statusFilter) {
  const territoryOrder = new Map(catalog.map((t, index) => [t.id, index]));
  const territoryOfRoom = (room) => catalog.find((t) => t.rooms.includes(room)) ?? null;
  const buckets = new Map();

  for (const cart of carts) {
    const hkID = selection.cartHousekeeperIDs[cart.id] ?? null;
    const key = hkID ? `housekeeper-${hkID}` : `cart-${cart.id}`;
    const rooms = statusFilter ? cart.rooms.filter((r) => roomStatus(r) === statusFilter) : cart.rooms;
    if (!rooms.length) continue;

    const bucket = buckets.get(key) ?? { id: key, firstCartID: cart.id, housekeeperID: hkID, cartIDs: [], rooms: [], locations: new Map() };
    bucket.cartIDs.push(cart.id);
    bucket.rooms.push(...rooms);
    let found = false;
    for (const room of rooms) {
      const territory = territoryOfRoom(room.id);
      if (!territory) continue;
      bucket.locations.set(territory.label, territoryOrder.get(territory.id) ?? Number.MAX_SAFE_INTEGER);
      found = true;
    }
    if (!found) {
      const fallback = catalog.find((t) => t.id === selection.cartBindings[cart.id])?.label ?? cart.building ?? "";
      for (const label of fallback.split("/").filter(Boolean)) {
        bucket.locations.set(label, territoryOrder.get(label) ?? Number.MAX_SAFE_INTEGER);
      }
    }
    buckets.set(key, bucket);
  }

  return [...buckets.values()]
    .sort((a, b) => a.firstCartID - b.firstCartID)
    .map((bucket) => ({
      id: bucket.id,
      cartIDs: bucket.cartIDs.sort((a, b) => a - b),
      primaryCartID: Math.min(...bucket.cartIDs),
      housekeeperID: bucket.housekeeperID,
      locationLabel: [...bucket.locations.entries()]
        .sort((a, b) => (a[1] !== b[1] ? a[1] - b[1] : a[0] < b[0] ? -1 : 1))
        .map(([label]) => label)
        .join(" "),
      rooms: bucket.rooms.sort((x, y) => compareRoomIDs(x.id, y.id))
    }));
}

/// Счётчики шапки: всего, готово, осталось (WorkSessionStore.counts).
export function summaryCounts(carts) {
  const rooms = carts.flatMap((c) => c.rooms);
  const completed = rooms.filter(isReady).length;
  return { total: rooms.length, completed, remaining: rooms.length - completed };
}
