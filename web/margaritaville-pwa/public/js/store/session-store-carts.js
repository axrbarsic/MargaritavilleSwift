// Операции тележек (заметки, медиа, расходники), каталога номеров и тестовых данных
// для SessionStore. Источник: WorkSessionStore+NotesMedia/+Consumables/+Catalog/+Selection.swift.
import * as selection from "../domain/selection.js";
import * as consumables from "../domain/consumables.js";
import { compareRoomIDs, inferredTerritory, normalizeRoomID } from "../domain/catalog.js";
import { tr } from "../i18n/i18n.js";

const MEDIA_LABEL = { photo: tr("фото"), video: tr("видео"), audio: tr("голос") };

export const sessionCartMethods = {
  // ——— тележки ———
  mutateCart(id, mutation, describe) {
    const cart = this.cart(id);
    if (!cart) return;
    const result = mutation(cart, Date.now());
    const entry = describe?.(cart, result);
    if (entry) this.record(entry[0], entry[1], { cartID: cart.id });
    this.commit();
  },

  updateCartNote(id, text) {
    this.mutateCart(id, (cart, now) => {
      const empty = !text.trim();
      cart.note = empty ? null : text;
      cart.noteUpdatedAt = empty ? null : now;
    }, (cart) => ["cartNoteChanged", tr("Тележка {cart}: заметка", { cart: cart.id })]);
  },

  addCartMedia(id, attachment) {
    this.mutateCart(id, (cart) => { cart.mediaAttachments = [attachment, ...(cart.mediaAttachments ?? [])]; },
      (cart) => ["cartMediaAdded", tr("Тележка {cart}: добавлено {media}", { cart: cart.id, media: MEDIA_LABEL[attachment.kind] })]);
  },

  removeCartMedia(id, attachment) {
    this.mutateCart(id, (cart) => {
      const rest = (cart.mediaAttachments ?? []).filter((m) => m.id !== attachment.id);
      cart.mediaAttachments = rest.length ? rest : null;
      if (attachment.kind === "audio" && cart.note === attachment.transcript) {
        cart.note = null;
        cart.noteUpdatedAt = null;
      }
    }, (cart) => ["cartMediaAdded", tr("Тележка {cart}: удалено {media}", { cart: cart.id, media: MEDIA_LABEL[attachment.kind] })]);
  },

  setConsumableQuantity(cartID, itemID, title, quantity) {
    const catalog = this.settings.get("cartConsumableCatalog");
    this.mutateCart(cartID, (cart, now) => consumables.setQuantity(cart, itemID, title, quantity, catalog, now),
      (cart, item) => ["cartConsumablesChanged", tr("Тележка {cart}: {item} {count}", { cart: cart.id, item: tr(item?.title ?? title ?? "Расходник"), count: consumables.clampQuantity(quantity) })]);
  },

  toggleConsumableCompletion(cartID, itemID, title) {
    const catalog = this.settings.get("cartConsumableCatalog");
    this.mutateCart(cartID, (cart, now) => consumables.toggleCompletion(cart, itemID, title, catalog, now),
      (cart, item) => ["cartConsumablesChanged", tr(item?.completedAt != null ? "Тележка {cart}: {item} выполнено" : "Тележка {cart}: {item} снова в работе", { cart: cart.id, item: tr(item?.title ?? title ?? "Расходник") })]);
  },

  // ——— каталог номеров ———
  addCatalogRoom(raw) {
    const roomID = normalizeRoomID(raw);
    const territory = roomID ? inferredTerritory(roomID) : null;
    if (!territory) return "invalidRoom";
    const existing = this.catalogOverrides.find((o) => o.roomID === roomID);
    const inCatalog = this.catalog.some((t) => t.rooms.includes(roomID));
    if (existing && !existing.isRemoved) return inCatalog ? "duplicate" : "changed";
    if (!existing && inCatalog) return "duplicate";
    if (existing) Object.assign(existing, { territoryID: territory.id, isRemoved: false, updatedAt: Date.now() });
    else this.catalogOverrides.push({ roomID, territoryID: territory.id, isRemoved: false, updatedAt: Date.now() });
    this.commit();
    return "changed";
  },

  removeCatalogRoom(raw) {
    const roomID = normalizeRoomID(raw);
    const territory = roomID ? inferredTerritory(roomID) : null;
    if (!territory) return "invalidRoom";
    if (selection.selectedRooms(this.selection).has(roomID) || this.room(roomID)) return "blockedActiveRoom";
    const index = this.catalogOverrides.findIndex((o) => o.roomID === roomID);
    if (index >= 0) {
      const o = this.catalogOverrides[index];
      if (!o.isRemoved && !territory.rooms.includes(roomID)) this.catalogOverrides.splice(index, 1);
      else Object.assign(o, { territoryID: territory.id, isRemoved: true, updatedAt: Date.now() });
    } else {
      if (!this.catalog.some((t) => t.rooms.includes(roomID))) return "invalidRoom";
      this.catalogOverrides.push({ roomID, territoryID: territory.id, isRemoved: true, updatedAt: Date.now() });
    }
    this.commit();
    return "changed";
  },

  /// Уборщица удалена из списка: снимаем её с тележек (тележки и номера остаются).
  removeHousekeeperAssignments(housekeeperID) {
    if (this.selection.workdayLocked) return;
    const carts = Object.keys(this.selection.cartHousekeeperIDs).filter((c) => this.selection.cartHousekeeperIDs[c] === housekeeperID);
    if (!carts.length) return;
    carts.forEach((c) => delete this.selection.cartHousekeeperIDs[c]);
    this.rebuildCarts();
    this.record("selectionChanged", tr("Уборщица удалена из назначений"));
    this.commit();
  },

  /// Тест: все номера каталога случайно и поровну раздаются уборщицам.
  assignAllRoomsForTesting(housekeepers) {
    const rooms = [...new Set(this.catalog.flatMap((t) => t.rooms))];
    const ids = [...new Set(housekeepers.map((h) => h.id).filter(Boolean))];
    if (!rooms.length || !ids.length) return null;
    const shuffle = (list) => { for (let i = list.length - 1; i > 0; i -= 1) { const j = Math.floor(Math.random() * (i + 1)); [list[i], list[j]] = [list[j], list[i]]; } return list; };
    shuffle(rooms);
    const active = shuffle(ids).slice(0, Math.min(rooms.length, 100));
    const buckets = active.map(() => []);
    rooms.forEach((room, i) => buckets[i % active.length].push(room));
    const next = { ...selection.emptySelection(), workdayLocked: this.selection.workdayLocked, workdayLockUpdatedAt: this.selection.workdayLockUpdatedAt };
    active.forEach((id, i) => {
      const cart = i + 1;
      const sorted = buckets[i].sort(compareRoomIDs);
      next.cartBindings[cart] = this.catalog.find((t) => t.rooms.includes(sorted[0]))?.id;
      next.cartHousekeeperIDs[cart] = id;
      next.cartRoomSelections[cart] = sorted;
    });
    this.selection = next;
    this.rebuildCarts();
    this.record("selectionChanged", tr("Тест: все номера случайно распределены"));
    this.commit(true);
    return { housekeeperCount: active.length, roomCount: rooms.length };
  }
};
