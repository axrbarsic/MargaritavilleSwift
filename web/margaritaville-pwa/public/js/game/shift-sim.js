// Игра «Смена»: ход времени и действия. Игрок и автопилот меняют смену только через
// applyAction, поэтому в любой момент можно перехватить управление у демо.
import { CART_CAPACITY, MAX_RATING, RESTOCK_SECONDS, crewById, planStay, roomById, walkSeconds } from "./shift-state.js";

const STEP = 0.1;
const emit = (state, type, data = {}) => state.events.push({ type, time: state.time, ...data });

/// Действие: { type: "assign" | "unassign" | "restock", hk, room?, by: "player" | "ai" }.
export function applyAction(state, action) {
  if (state.over) return false;
  const hk = crewById(state, action.hk);
  if (!hk) return false;
  if (action.type === "assign") {
    const room = roomById(state, action.room);
    if (!room || room.status !== "dirty" || room.hk) return false;
    room.hk = hk.id;
    hk.queue.push(room.id);
    emit(state, "assign", { hk: hk.id, room: room.id, by: action.by });
    return true;
  }
  if (action.type === "unassign") {
    const index = hk.queue.indexOf(action.room);
    if (index < 0) return false;
    hk.queue.splice(index, 1);
    roomById(state, action.room).hk = null;
    emit(state, "unassign", { hk: hk.id, room: action.room, by: action.by });
    return true;
  }
  if (action.type === "restock") {
    if (hk.restock > 0 || hk.pendingRestock || hk.supplies >= CART_CAPACITY) return false;
    if (hk.current) hk.pendingRestock = true;
    else startRestock(hk);
    emit(state, "restockOrdered", { hk: hk.id, by: action.by });
    return true;
  }
  return false;
}

function startRestock(hk) {
  hk.restock = RESTOCK_SECONDS;
  hk.pendingRestock = false;
  hk.outOfSupplies = false;
}

/// Продвигает смену на dt секунд мелкими шагами, чтобы ускорение не ломало правила.
export function tick(state, dt) {
  let left = Math.min(dt, 1);
  while (left > 1e-6 && !state.over) {
    const step = Math.min(STEP, left);
    advance(state, step);
    left -= step;
  }
}

function advance(state, dt) {
  state.time += dt;
  for (const room of state.rooms) advanceRoom(state, room);
  for (const hk of state.crew) advanceCrew(state, hk, dt);
  if (state.rating <= 0) finish(state, "rating");
  else if (state.time >= state.duration) finish(state, "time");
}

function advanceRoom(state, room) {
  if (room.status === "occupied" && state.time >= room.checkoutAt) {
    room.status = "dirty";
    emit(state, "checkout", { room: room.id, vip: room.vip, deadline: room.deadline });
  }
  if (room.status === "ready" && room.arrivalAt != null && state.time >= room.arrivalAt) {
    planStay(room, state);
    emit(state, "arrival", { room: room.id });
  }
  const waiting = room.status === "dirty" || room.status === "cleaning";
  if (waiting && room.deadline != null && !room.missed && state.time > room.deadline) {
    room.missed = true;
    state.rating = Math.max(0, state.rating - 1);
    state.combo = 0;
    state.missed += 1;
    emit(state, "missed", { room: room.id, vip: room.vip });
  }
}

function advanceCrew(state, hk, dt) {
  if (hk.restock > 0) {
    hk.restock -= dt;
    if (hk.restock <= 0) {
      hk.restock = 0;
      hk.supplies = CART_CAPACITY;
      emit(state, "restocked", { hk: hk.id });
    }
    return;
  }
  if (hk.current) {
    const room = roomById(state, hk.current);
    if (hk.walk > 0) {
      hk.walk -= dt;
      if (hk.walk <= 0) { hk.walk = 0; room.status = "cleaning"; emit(state, "cleaningStarted", { hk: hk.id, room: room.id }); }
      return;
    }
    room.progress = Math.min(1, room.progress + (dt * hk.speed) / room.work);
    if (room.progress >= 1) completeRoom(state, hk, room);
    return;
  }
  if (hk.pendingRestock) { startRestock(hk); return; }
  if (!hk.queue.length) return;
  if (hk.supplies <= 0) {
    if (!hk.outOfSupplies) { hk.outOfSupplies = true; emit(state, "outOfSupplies", { hk: hk.id }); }
    return;
  }
  const room = roomById(state, hk.queue.shift());
  hk.supplies -= 1;
  hk.current = room.id;
  hk.walk = walkSeconds(hk.at ? roomById(state, hk.at) : null, room);
}

function completeRoom(state, hk, room) {
  hk.current = null;
  hk.at = room.id;
  room.status = "ready";
  room.hk = null;
  const late = room.deadline != null && state.time > room.deadline;
  let points = room.vip ? 200 : 100;
  if (late) {
    points = Math.round(points * 0.3);
    state.combo = 0;
  } else {
    if (room.deadline != null) points += Math.min(60, Math.round((room.deadline - state.time) * 3));
    state.combo += 1;
    state.onTime += 1;
    state.bestCombo = Math.max(state.bestCombo, state.combo);
    points = Math.round(points * (1 + Math.min(state.combo - 1, 5) * 0.1));
    // Каждая пятёрка вовремя подряд возвращает одну потерянную звезду.
    if (state.combo % 5 === 0 && state.rating < MAX_RATING) { state.rating += 1; emit(state, "starBack", {}); }
  }
  state.score += points;
  state.cleaned += 1;
  room.arrivalAt = room.deadline != null ? Math.max(room.deadline, state.time + 2) : state.time + 6 + state.random() * 18;
  emit(state, "ready", { hk: hk.id, room: room.id, points, late, vip: room.vip, combo: state.combo });
}

function finish(state, reason) {
  state.over = true;
  state.endReason = reason;
  emit(state, "over", { reason });
}
