// Игра «Смена»: автопилот-диспетчер для демо и подсказок. Возвращает те же действия,
// что делает игрок, и объяснение каждого решения для подсветки на экране.
import { CART_CAPACITY, finishEstimate } from "./shift-state.js";

const MAX_QUEUE = 2;

/// Насколько срочен номер: VIP и близкий срок — первыми, номера без срока — по времени выезда.
function urgency(state, room) {
  const due = room.deadline ?? room.checkoutAt + 80;
  return due - (room.vip ? 20 : 0) - (room.missed ? 40 : 0) - state.time;
}

export function planMoves(state) {
  if (state.over) return [];
  const moves = [];
  for (const hk of state.crew) {
    if (hk.restock > 0 || hk.pendingRestock) continue;
    const empty = hk.supplies <= 0 && (hk.queue.length || hk.outOfSupplies);
    const idleLow = !hk.current && !hk.queue.length && hk.supplies <= 1;
    if (empty || idleLow || (hk.current && hk.supplies === 0 && hk.queue.length)) {
      if (hk.supplies < CART_CAPACITY) moves.push({ type: "restock", hk: hk.id, by: "ai", reason: "supplies" });
    }
  }

  const free = state.rooms.filter((room) => room.status === "dirty" && !room.hk)
    .sort((a, b) => urgency(state, a) - urgency(state, b));
  const extra = new Map();
  for (const room of free) {
    let best = null;
    for (const hk of state.crew) {
      const planned = extra.get(hk.id) ?? 0;
      if (hk.queue.length + planned >= MAX_QUEUE) continue;
      const eta = finishEstimate(state, hk, room) + planned * (room.work / hk.speed + 2);
      if (!best || eta < best.eta) best = { hk, eta };
    }
    if (!best) break;
    extra.set(best.hk.id, (extra.get(best.hk.id) ?? 0) + 1);
    const onTime = room.deadline == null || best.eta <= room.deadline;
    moves.push({ type: "assign", hk: best.hk.id, room: room.id, by: "ai", reason: room.vip ? "vip" : room.deadline != null ? (onTime ? "deadline" : "late") : "fastest" });
  }
  return moves;
}

/// Подсказка игроку: самый срочный ход автопилота без его выполнения.
export function suggestMove(state) {
  return planMoves(state).find((move) => move.type === "assign") ?? null;
}

