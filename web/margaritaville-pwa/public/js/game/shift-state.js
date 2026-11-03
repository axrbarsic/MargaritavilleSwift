// Игра «Смена»: модель смены — номера, уборщицы с тележками, очки и рейтинг.
// Чистые данные без DOM и переводов: UI получает коды событий и сам подбирает текст.

export const SHIFT_SECONDS = 240;
export const SHIFT_START_MINUTES = 9 * 60;
export const CLOCK_MINUTES_PER_SECOND = 1.5;
export const MAX_RATING = 5;
export const CART_CAPACITY = 4;
export const RESTOCK_SECONDS = 5;
export const CREW_SIZE = 4;
const BASE_WORK = 9;
const VIP_WORK = 13;
const CREW_SPEED = [1.15, 1, 0.9, 1.05];

/// Детерминированный генератор (mulberry32): одна и та же партия по одному seed.
export function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const floorOf = (id) => {
  const n = parseInt(id, 10);
  return Number.isFinite(n) ? Math.floor(n / 100) : 0;
};

/// Время перехода между номерами: другой этаж дольше, другой корпус — ещё дольше.
export function walkSeconds(from, to) {
  if (!from) return 1.5;
  if (from.id === to.id) return 0.5;
  if (from.tower !== to.tower) return 4.5;
  return floorOf(from.id) === floorOf(to.id) ? 1.5 : 3;
}

/// Нагрузка растёт к концу смены: гости выезжают чаще.
export const rushFactor = (state) => 1 + (state.time / state.duration) ** 1.4 * 1.6;

/// Новый цикл гостя: когда выедет, нужен ли номер к сроку и VIP ли он.
export function planStay(room, state, from = state.time) {
  const r = state.random;
  room.vip = r() < 0.14;
  room.checkoutAt = from + (26 + r() * 34) / rushFactor(state);
  const needsDeadline = room.vip || r() < 0.42;
  room.deadline = needsDeadline ? room.checkoutAt + (room.vip ? 20 : 26) + r() * 22 : null;
  room.work = room.vip ? VIP_WORK : BASE_WORK;
  room.status = "occupied";
  room.hk = null;
  room.progress = 0;
  room.arrivalAt = null;
  room.missed = false;
}

export function createShift({ rooms, housekeepers, seed = Date.now(), duration = SHIFT_SECONDS }) {
  const random = rng(seed);
  const state = {
    seed, random, duration, time: 0, over: false, endReason: null,
    score: 0, rating: MAX_RATING, combo: 0, bestCombo: 0, cleaned: 0, onTime: 0, missed: 0,
    events: [], rooms: [], crew: []
  };
  state.rooms = rooms.map(({ id, tower }) => {
    const room = { id, tower };
    planStay(room, state, 0);
    // Часть номеров уже свободна к началу смены, остальные выезжают в первые минуты.
    if (random() < 0.3) {
      room.checkoutAt = 0;
      room.status = "dirty";
      if (room.deadline != null) room.deadline = 26 + random() * 40;
    } else {
      room.checkoutAt = 3 + random() * duration * 0.45;
      if (room.deadline != null) room.deadline = room.checkoutAt + (room.vip ? 24 : 32) + random() * 26;
    }
    return room;
  });
  state.crew = housekeepers.slice(0, CREW_SIZE).map((hk, index) => ({
    id: hk.id, name: hk.displayName ?? hk.name, palette: hk.palette,
    speed: CREW_SPEED[index % CREW_SPEED.length] * (0.95 + random() * 0.1),
    supplies: CART_CAPACITY, queue: [], current: null, walk: 0, restock: 0,
    pendingRestock: false, at: null, outOfSupplies: false
  }));
  return state;
}

export const roomById = (state, id) => state.rooms.find((room) => room.id === id);
export const crewById = (state, id) => state.crew.find((hk) => hk.id === id);

/// Что сейчас делает уборщица: для подписи на карточке и для автопилота.
export function crewActivity(hk) {
  if (hk.restock > 0) return "restocking";
  if (hk.current) return hk.walk > 0 ? "walking" : "cleaning";
  if (hk.outOfSupplies) return "empty";
  return hk.queue.length ? "walking" : "idle";
}

/// Оценка, через сколько секунд уборщица освободится со всей своей очередью.
export function busySeconds(state, hk) {
  let seconds = hk.restock;
  let supplies = hk.supplies;
  let at = hk.at ? roomById(state, hk.at) : null;
  if (hk.current) {
    const room = roomById(state, hk.current);
    seconds += hk.walk + ((1 - room.progress) * room.work) / hk.speed;
    at = room;
  }
  for (const id of hk.queue) {
    const room = roomById(state, id);
    if (supplies <= 0) { seconds += RESTOCK_SECONDS; supplies = CART_CAPACITY; }
    supplies -= 1;
    seconds += walkSeconds(at, room) + room.work / hk.speed;
    at = room;
  }
  return { seconds, supplies, at };
}

/// Когда номер был бы готов, если отдать его этой уборщице прямо сейчас.
export function finishEstimate(state, hk, room) {
  const busy = busySeconds(state, hk);
  const restock = busy.supplies <= 0 ? RESTOCK_SECONDS : 0;
  return state.time + busy.seconds + restock + walkSeconds(busy.at, room) + room.work / hk.speed;
}

export const clockMinutes = (seconds) => SHIFT_START_MINUTES + seconds * CLOCK_MINUTES_PER_SECOND;

/// Итоговая оценка смены по очкам и звёздам.
export function shiftGrade(state) {
  if (state.rating <= 0) return "F";
  const perMinute = (state.score / Math.max(1, state.duration / 60)) * (state.rating / MAX_RATING);
  if (perMinute >= 2600) return "S";
  if (perMinute >= 1900) return "A";
  if (perMinute >= 1200) return "B";
  if (perMinute >= 600) return "C";
  return "D";
}
