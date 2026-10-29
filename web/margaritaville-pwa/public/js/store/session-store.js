// Хранилище смены: выбор, тележки, история; сохранение с задержкой 0,28 с, как
// WorkSessionStore. После ошибки загрузки запись блокируется, чтобы не затереть данные.
import { loadSnapshot, saveSnapshot } from "./db.js";
import * as selection from "../domain/selection.js";
import * as roomOps from "../domain/room.js";

const SAVE_DELAY = 280;
const STATUS_LABEL = { pending: "жёлтый", open: "красный", ready: "зелёный", scheduled: "назначено" };

export class SessionStore {
  constructor() {
    this.selection = selection.emptySelection();
    this.carts = [];
    this.history = [];
    this.loaded = false;
    this.loadFailure = null;
    this.listeners = new Set();
    this.saveTimer = null;
  }

  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  emit() {
    this.listeners.forEach((listener) => listener());
  }

  async load() {
    try {
      const snapshot = await loadSnapshot();
      if (snapshot) {
        this.selection = { ...selection.emptySelection(), ...snapshot.selection };
        this.carts = snapshot.carts ?? [];
        this.history = snapshot.history ?? [];
      }
      this.loadFailure = null;
    } catch (error) {
      this.loadFailure = error?.message || "Хранилище недоступно";
    }
    this.loaded = true;
    this.emit();
  }

  persist(immediately = false) {
    if (this.loadFailure) return;
    clearTimeout(this.saveTimer);
    const save = () => saveSnapshot({ selection: this.selection, carts: this.carts, history: this.history, updatedAt: Date.now() }).catch(() => {});
    if (immediately) save();
    else this.saveTimer = setTimeout(save, SAVE_DELAY);
  }

  flush() {
    if (this.saveTimer) this.persist(true);
  }

  record(kind, title, extra = {}) {
    this.history.unshift({ id: crypto.randomUUID(), happenedAt: Date.now(), kind, title, ...extra });
    if (this.history.length > 500) this.history.length = 500;
  }

  rebuildCarts() {
    this.carts = selection.makeCarts(this.selection, this.carts, Date.now());
  }

  // ——— выбор смены ———
  toggleCartForHousekeeper(housekeeperID) {
    const owned = selection.selectedCartNumbers(this.selection).find((c) => this.selection.cartHousekeeperIDs[c] === housekeeperID);
    if (owned != null) {
      selection.toggleCart(this.selection, owned);
    } else {
      const used = new Set(selection.selectedCartNumbers(this.selection));
      let cart = 1;
      while (used.has(cart)) cart += 1;
      selection.toggleCart(this.selection, cart);
      selection.setHousekeeper(this.selection, cart, housekeeperID);
    }
    this.rebuildCarts();
    this.record("selectionChanged", "Выбор тележек изменён");
    this.persist();
    this.emit();
  }

  setCartTerritory(cart, territoryID) {
    if (!selection.setCartTerritory(this.selection, cart, territoryID)) return;
    this.persist();
    this.emit();
  }

  toggleRoom(cart, room) {
    const result = selection.toggleRoom(this.selection, cart, room);
    if (result !== "changed") return result;
    this.rebuildCarts();
    this.persist();
    this.emit();
    return result;
  }

  lockWorkday() {
    if (!selection.lockWorkday(this.selection, Date.now())) return;
    this.record("workdayLocked", "Рабочий день зафиксирован");
    this.persist(true);
    this.emit();
  }

  unlockWorkday() {
    if (!selection.unlockWorkday(this.selection, Date.now())) return;
    this.record("workdayUnlocked", "Рабочий день открыт для редактирования");
    this.persist(true);
    this.emit();
  }

  // ——— комнаты ———
  room(id) {
    for (const cart of this.carts) {
      const room = cart.rooms.find((r) => r.id === id);
      if (room) return room;
    }
    return null;
  }

  mutateRoom(id, mutation, describe) {
    const room = this.room(id);
    if (!room) return;
    const before = roomOps.roomStatus(room);
    mutation(room, Date.now());
    const after = roomOps.roomStatus(room);
    const title = describe ? describe(room) : before !== after ? `${room.id}: ${STATUS_LABEL[after]}` : null;
    if (title) this.record("roomChanged", title, { roomID: room.id });
    this.persist();
    this.emit();
  }

  advance(id) { this.mutateRoom(id, roomOps.advance); }
  setStatus(id, status) { this.mutateRoom(id, (room, now) => roomOps.setStatus(room, status, now)); }
  reset(id) { this.mutateRoom(id, roomOps.reset); }
  toggleVIP(id) { this.mutateRoom(id, roomOps.toggleVIP, (room) => `${room.id}: VIP ${room.isVIP ? "включен" : "выключен"}`); }
  setSchedule(id, time) {
    this.mutateRoom(id, (room, now) => roomOps.setSchedule(room, time, now), (room) => `${room.id}: время ${time == null ? "снято" : "установлено"}`);
  }
  setNote(id, text) {
    this.mutateRoom(id, (room, now) => {
      room.textNote = text.trim() ? text : null;
      room.textNoteUpdatedAt = now;
    }, (room) => `${room.id}: заметка`);
  }

  /// Открывает комнаты, чьё назначенное время наступило.
  advanceScheduledRooms() {
    const now = Date.now();
    let changed = false;
    for (const cart of this.carts) {
      for (const room of cart.rooms) {
        if (room.scheduledTime == null || room.scheduledTime > now) continue;
        changed = true;
        if (roomOps.advanceIfDue(room, now)) this.record("scheduledRoomAutoOpened", `${room.id}: открыта по времени`, { roomID: room.id });
      }
    }
    if (changed) {
      this.persist();
      this.emit();
    }
  }
}
