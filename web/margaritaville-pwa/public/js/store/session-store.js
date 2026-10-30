// Хранилище смены: выбор, тележки, каталог, история; сохранение с задержкой 0,28 с, как
// WorkSessionStore. После ошибки загрузки запись блокируется, чтобы не затереть данные.
// Источник: Features/WorkSession/WorkSessionStore*.swift.
import { loadSnapshot, saveSnapshot } from "./db.js";
import * as selection from "../domain/selection.js";
import * as roomOps from "../domain/room.js";
import { effectiveCatalog } from "../domain/catalog.js";
import { sessionCartMethods } from "./session-store-carts.js";
import { summaryCounts } from "../domain/summary-grouping.js";

const SAVE_DELAY = 280;
const HISTORY_LIMIT = 500;
const STATUS_LABEL = { pending: "жёлтый", open: "красный", ready: "зелёный", scheduled: "назначено" };
const MEDIA_LABEL = { photo: "фото", video: "видео", audio: "голос" };
const clone = (value) => JSON.parse(JSON.stringify(value));

export class SessionStore {
  constructor(settings) {
    this.settings = settings;
    this.selection = selection.emptySelection();
    this.carts = [];
    this.history = [];
    this.catalogOverrides = [];
    this.loaded = false;
    this.loadFailure = null;
    this.listeners = new Set();
    this.saveTimer = null;
  }

  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  emit() { this.listeners.forEach((listener) => listener()); }

  get catalog() { return effectiveCatalog(this.catalogOverrides); }
  get counts() { return summaryCounts(this.carts); }

  async load() {
    try {
      const snapshot = await loadSnapshot();
      if (snapshot) {
        this.selection = { ...selection.emptySelection(), ...snapshot.selection };
        this.carts = snapshot.carts ?? [];
        this.history = snapshot.history ?? [];
        this.catalogOverrides = snapshot.catalogOverrides ?? [];
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
    const save = () => {
      this.saveTimer = null;
      saveSnapshot({ selection: this.selection, carts: this.carts, history: this.history, catalogOverrides: this.catalogOverrides, updatedAt: Date.now() }).catch(() => {});
    };
    if (immediately) save();
    else this.saveTimer = setTimeout(save, SAVE_DELAY);
  }

  flush() { if (this.saveTimer) this.persist(true); }

  commit(immediately = false) {
    this.persist(immediately);
    this.emit();
  }

  /// Запись хронологии со снимком затронутых тележек (WorkSessionStore.appendHistory).
  record(kind, title, { roomID = null, cartID = null } = {}) {
    let carts = [];
    if (cartID != null) carts = this.carts.filter((c) => c.id === cartID);
    else if (roomID != null) carts = this.carts.filter((c) => c.rooms.some((r) => r.id === roomID));
    else if (kind === "workdayLocked" || kind === "workdayUnlocked") carts = this.carts;
    const snapshot = { carts: clone(carts).map((c) => ({ ...c, mediaAttachments: null })), counts: this.counts };
    this.history.unshift({ id: crypto.randomUUID(), happenedAt: Date.now(), kind, title, roomID, cartID, snapshot });
    if (this.history.length > HISTORY_LIMIT) this.history.length = HISTORY_LIMIT;
  }

  rebuildCarts() {
    this.carts = selection.makeCarts(this.selection, this.carts, Date.now(), this.catalog);
  }

  // ——— выбор смены ———
  cartForHousekeeper(housekeeperID) {
    return selection.selectedCartNumbers(this.selection).find((c) => this.selection.cartHousekeeperIDs[c] === housekeeperID) ?? null;
  }

  /// Добавляет уборщицу в смену первой свободной тележкой. Возвращает номер тележки.
  addHousekeeper(housekeeperID) {
    const cart = selection.firstAvailableCart(this.selection);
    if (cart == null || !selection.toggleCart(this.selection, cart)) return null;
    selection.setHousekeeper(this.selection, cart, housekeeperID);
    this.afterSelectionChange();
    return cart;
  }

  removeCart(cart) {
    if (!this.selection.cartBindings[cart] || !selection.toggleCart(this.selection, cart)) return;
    this.afterSelectionChange();
  }

  afterSelectionChange() {
    this.rebuildCarts();
    this.record("selectionChanged", "Выбор тележек изменён");
    this.commit();
  }

  setCartTerritory(cart, territoryID) {
    if (!selection.setCartTerritory(this.selection, cart, territoryID)) return;
    this.commit();
  }

  toggleRoom(cart, room) {
    const result = selection.toggleRoom(this.selection, cart, room);
    if (result !== "changed") return result;
    this.rebuildCarts();
    this.record("selectionChanged", `Тележка ${cart}: выбор комнат изменён`);
    this.commit();
    return result;
  }

  lockWorkday() {
    if (!selection.lockWorkday(this.selection, Date.now())) return;
    this.record("workdayLocked", "Рабочий день зафиксирован");
    this.commit(true);
  }

  unlockWorkday() {
    if (!selection.unlockWorkday(this.selection, Date.now())) return;
    this.record("workdayUnlocked", "Рабочий день открыт для редактирования");
    this.commit(true);
  }

  /// Полный сброс смены (тестовые данные и «Новый день»).
  replaceSession(nextSelection, carts) {
    this.selection = nextSelection;
    this.carts = carts;
    this.commit(true);
  }

  // ——— комнаты ———
  room(id) {
    for (const cart of this.carts) {
      const room = cart.rooms.find((r) => r.id === id);
      if (room) return room;
    }
    return null;
  }

  cart(id) { return this.carts.find((c) => c.id === id) ?? null; }

  mutateRoom(id, mutation, describe) {
    const room = this.room(id);
    if (!room) return;
    const before = clone(room);
    mutation(room, Date.now());
    const entry = describe ? describe(before, room) : null;
    if (entry) this.record(entry[0], entry[1], { roomID: room.id });
    this.commit();
  }

  statusEntry(before, after) {
    const a = roomOps.roomStatus(before);
    const b = roomOps.roomStatus(after);
    return a === b ? null : ["roomStatusChanged", `${after.id}: ${STATUS_LABEL[b]}`];
  }

  advance(id) { this.mutateRoom(id, roomOps.advance, (b, a) => this.statusEntry(b, a)); }
  setStatus(id, status) { this.mutateRoom(id, (room, now) => roomOps.setStatus(room, status, now), (b, a) => this.statusEntry(b, a)); }
  reset(id) { this.mutateRoom(id, roomOps.reset, (b, a) => this.statusEntry(b, a)); }
  toggleVIP(id) { this.mutateRoom(id, roomOps.toggleVIP, (b, a) => ["roomVIPChanged", `${a.id}: VIP ${a.isVIP ? "включён" : "выключен"}`]); }
  setSchedule(id, time) {
    this.mutateRoom(id, (room, now) => roomOps.setSchedule(room, time, now),
      (b, a) => ["roomScheduleChanged", `${a.id}: время ${time == null ? "снято" : "назначено"}`]);
  }

  updateTextNote(id, text) {
    this.mutateRoom(id, (room, now) => {
      const empty = !text.trim();
      room.textNote = empty ? null : text;
      room.textNoteUpdatedAt = empty ? null : now;
    }, (b, a) => ["roomTextNoteChanged", `${a.id}: текстовая заметка`]);
  }

  updateVoiceTranscript(id, text) {
    this.mutateRoom(id, (room, now) => {
      const empty = !text.trim();
      room.voiceTranscript = empty ? null : text;
      room.voiceTranscriptUpdatedAt = empty ? null : now;
    }, (b, a) => ["roomVoiceTranscriptChanged", `${a.id}: голосовая заметка`]);
  }

  addRoomMedia(id, attachment) {
    this.mutateRoom(id, (room) => { room.mediaAttachments = [attachment, ...(room.mediaAttachments ?? [])]; },
      (b, a) => ["roomMediaAdded", `${a.id}: добавлено ${MEDIA_LABEL[attachment.kind]}`]);
  }

  removeRoomMedia(id, attachment) {
    this.mutateRoom(id, (room) => {
      const rest = (room.mediaAttachments ?? []).filter((m) => m.id !== attachment.id);
      room.mediaAttachments = rest.length ? rest : null;
      if (attachment.kind === "audio" && room.voiceTranscript === attachment.transcript) {
        room.voiceTranscript = null;
        room.voiceTranscriptUpdatedAt = null;
      }
    }, (b, a) => ["roomMediaAdded", `${a.id}: удалено ${MEDIA_LABEL[attachment.kind]}`]);
  }

  /// Открывает комнаты, чьё назначенное время наступило. Возвращает открытые номера.
  advanceScheduledRooms() {
    const now = Date.now();
    const opened = [];
    let changed = false;
    for (const cart of this.carts) {
      for (const room of cart.rooms) {
        if (room.scheduledTime == null || room.scheduledTime > now) continue;
        changed = true;
        if (roomOps.advanceIfDue(room, now)) {
          opened.push(room.id);
          this.record("scheduledRoomAutoOpened", `${room.id}: открыта по времени`, { roomID: room.id });
        }
      }
    }
    if (changed) this.commit();
    return opened;
  }
}

Object.assign(SessionStore.prototype, sessionCartMethods);
