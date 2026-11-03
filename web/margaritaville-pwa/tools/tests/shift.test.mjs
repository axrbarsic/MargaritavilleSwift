// Тесты игры «Смена»: правила смены, действия и автопилот. Запуск: node --test tools/tests/*.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import { CART_CAPACITY, MAX_RATING, createShift, roomById, crewById } from "../../public/js/game/shift-state.js";
import { applyAction, tick } from "../../public/js/game/shift-sim.js";
import { planMoves } from "../../public/js/game/shift-ai.js";

const ROOMS = Array.from({ length: 16 }, (_, i) => ({ id: String(101 + (i % 4) + Math.floor(i / 4) * 100), tower: i < 8 ? "A1" : "B1" }));
const CREW = ["ritza", "denise", "nadia", "marie"].map((id) => ({ id, displayName: id, palette: "blue" }));
const shift = (seed = 7) => createShift({ rooms: ROOMS, housekeepers: CREW, seed });

function play(state, { autopilot }) {
  let next = 0;
  while (!state.over) {
    if (autopilot && state.time >= next) {
      for (const move of planMoves(state)) applyAction(state, move);
      next = state.time + 0.4;
    }
    tick(state, 0.25);
  }
  return state;
}

test("одинаковый seed даёт одинаковую смену", () => {
  assert.deepEqual(shift(11).rooms.map((r) => [r.status, r.deadline]), shift(11).rooms.map((r) => [r.status, r.deadline]));
});

test("назначенный номер убирается, тратит расходник и приносит очки", () => {
  const state = shift();
  const room = state.rooms.find((r) => r.status === "dirty");
  assert.ok(applyAction(state, { type: "assign", hk: "ritza", room: room.id, by: "player" }));
  assert.equal(applyAction(state, { type: "assign", hk: "denise", room: room.id, by: "player" }), false, "номер нельзя отдать дважды");
  for (let i = 0; i < 200 && roomById(state, room.id).status !== "ready"; i += 1) tick(state, 0.1);
  assert.equal(roomById(state, room.id).status, "ready");
  assert.equal(crewById(state, "ritza").supplies, CART_CAPACITY - 1);
  assert.ok(state.score >= 100);
});

test("пустая тележка останавливает уборщицу до пополнения", () => {
  const state = shift();
  const hk = crewById(state, "ritza");
  hk.supplies = 0;
  const room = state.rooms.find((r) => r.status === "dirty");
  applyAction(state, { type: "assign", hk: "ritza", room: room.id, by: "player" });
  tick(state, 1);
  assert.equal(hk.outOfSupplies, true);
  assert.equal(hk.current, null);
  assert.ok(applyAction(state, { type: "restock", hk: "ritza", by: "player" }));
  for (let i = 0; i < 6; i += 1) tick(state, 1);
  assert.equal(hk.current, room.id, "после пополнения уборщица идёт в номер");
  assert.equal(hk.supplies, CART_CAPACITY - 1);
});

test("снятый с очереди номер снова свободен", () => {
  const state = shift();
  const [a, b] = state.rooms.filter((r) => r.status === "dirty");
  applyAction(state, { type: "assign", hk: "ritza", room: a.id, by: "player" });
  applyAction(state, { type: "assign", hk: "ritza", room: b.id, by: "player" });
  tick(state, 0.2);
  assert.ok(applyAction(state, { type: "unassign", hk: "ritza", room: b.id, by: "player" }));
  assert.equal(roomById(state, b.id).hk, null);
});

test("без диспетчера гости недовольны, автопилот держит смену", () => {
  for (const seed of [1, 2, 3, 4, 5]) {
    const idle = play(shift(seed), { autopilot: false });
    assert.equal(idle.rating, 0, `seed ${seed}: бездействие должно проигрывать`);
    const auto = play(shift(seed), { autopilot: true });
    assert.equal(auto.endReason, "time", `seed ${seed}: автопилот должен доиграть смену`);
    assert.ok(auto.rating >= 3 && auto.rating <= MAX_RATING, `seed ${seed}: рейтинг ${auto.rating}`);
    assert.ok(auto.cleaned >= 30, `seed ${seed}: убрано ${auto.cleaned}`);
  }
});
