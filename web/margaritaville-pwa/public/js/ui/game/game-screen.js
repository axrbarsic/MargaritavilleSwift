// Экран игры «Смена»: один цикл кадров на всю игру, который спит на заставке, на паузе
// и когда приложение свёрнуто. Демо играет автопилот; любое касание поля передаёт
// управление игроку, кнопка «Автопилот» возвращает его обратно.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { backButton, pushScreen } from "../screen-stack.js";
import { segmented } from "../settings/settings-controls.js";
import { MAX_RATING, createShift, crewById, roomById } from "../../game/shift-state.js";
import { applyAction, tick } from "../../game/shift-sim.js";
import { planMoves } from "../../game/shift-ai.js";
import { clockLabel, createBoard } from "./game-board.js";
import { eventLine, introCard, resultCard, starsLabel } from "./game-overlays.js";
import { tr } from "../../i18n/i18n.js";

const AI_INTERVAL = 0.4;
const DEMO_RESTART_SECONDS = 6;
const ROOM_COUNT = 16;

/// 16 номеров из каталога отеля: до двух корпусов, равномерно по этажам.
function pickRooms(catalog) {
  const towers = catalog.filter((t) => t.rooms.length).slice(0, 2);
  if (!towers.length) return Array.from({ length: ROOM_COUNT }, (_, i) => ({ id: String(101 + (i % 4) + Math.floor(i / 4) * 100), tower: "A" }));
  const per = Math.ceil(ROOM_COUNT / towers.length);
  return towers.flatMap((t) => {
    const step = Math.max(1, t.rooms.length / per);
    return Array.from({ length: Math.min(per, t.rooms.length) }, (_, i) => ({ id: t.rooms[Math.floor(i * step)], tower: t.label }));
  }).slice(0, ROOM_COUNT);
}

/// Четыре уборщицы из списка приложения, каждая партия — другая четвёрка.
function pickCrew(list, seed) {
  if (list.length <= 4) return list;
  const start = seed % list.length;
  return Array.from({ length: 4 }, (_, i) => list[(start + i * 3) % list.length]);
}

export function openShiftGame(app) {
  const { feedback } = app;
  let stopGame = null;
  pushScreen((close) => {
    let state = null, board = null, selected = null, autopilot = false, demoRun = false;
    let speed = 1, paused = false, raf = null, last = 0, nextAI = 0, restartTimer = null, closed = false;

    const clock = h("div", { class: "game-clock" });
    const score = h("div", { class: "game-score" }, "0");
    const stars = h("div", { class: "game-stars" });
    const ticker = h("div", { class: "game-ticker" });
    const field = h("div", { class: "game-field" });
    const overlay = h("div", { class: "game-overlay" });
    const autoButton = h("button", { class: "game-auto", onclick: () => setAutopilot(!autopilot, true) }, icon("bolt", 16, 3), h("span", {}, tr("Автопилот")));
    const pauseButton = h("button", { class: "game-pause", "aria-label": tr("Пауза"), onclick: () => setPaused(!paused) }, icon("pause", 18, 3));
    const speedControl = segmented([1, 2, 3].map((v) => ({ value: v, label: `${v}×` })), speed, (v) => { speed = v; }, feedback);
    speedControl.classList.add("game-speed");

    const say = (text) => { if (text) ticker.textContent = text; };
    const name = (id) => crewById(state, id)?.name ?? "";

    function setAutopilot(on, fromButton = false) {
      autopilot = on;
      autoButton.classList.toggle("on", on);
      if (!on) demoRun = false;
      if (fromButton) { feedback.select(); say(on ? tr("Автопилот ведёт смену") : tr("Управление твоё")); }
    }

    function takeOver() {
      if (!autopilot) return;
      setAutopilot(false);
      say(tr("Управление твоё — автопилот выключен"));
    }

    function setPaused(on) {
      paused = on;
      pauseButton.replaceChildren(icon(on ? "play" : "pause", 18, 3));
      if (on) say(tr("Пауза"));
      wake();
    }

    function onRoom(id) {
      if (!state || state.over) return;
      takeOver();
      const room = roomById(state, id);
      if (room.status === "dirty" && room.hk) {
        if (applyAction(state, { type: "unassign", hk: room.hk, room: id, by: "player" })) { feedback.deselect(); return; }
      }
      if (room.status !== "dirty" || room.hk) { feedback.invalid(); return; }
      if (!selected) { feedback.invalid(); say(tr("Сначала выбери уборщицу")); state.crew.forEach((hk) => board.flashCrew(hk.id)); return; }
      if (applyAction(state, { type: "assign", hk: selected, room: id, by: "player" })) feedback.play("roomOpen");
    }

    function onCrew(id) {
      if (!state || state.over) return;
      takeOver();
      selected = selected === id ? null : id;
      feedback.select();
    }

    function onRestock(id) {
      if (!state || state.over) return;
      takeOver();
      if (applyAction(state, { type: "restock", hk: id, by: "player" })) feedback.confirm();
      else feedback.invalid();
    }

    function handleEvents() {
      for (const event of state.events) {
        say(eventLine(event, name));
        if (event.type === "assign" && event.by === "ai") { board.flashRoom(event.room, event.hk); feedback.play("roomOpen", { haptic: false }); }
        if (event.type === "ready") { board.floatText(event.room, `+${event.points}`); feedback.play("roomReady", { haptic: !autopilot }); }
        if (event.type === "missed") feedback.play("invalid", { haptic: !autopilot });
        if (event.type === "outOfSupplies") feedback.play("holdWarning", { haptic: !autopilot });
        if (event.type === "over") feedback.play("holdCommit");
      }
      state.events.length = 0;
    }

    function render() {
      clock.textContent = clockLabel(state.time);
      score.textContent = String(state.score);
      stars.textContent = `${starsLabel(state.rating, MAX_RATING)}${state.combo >= 2 ? `  ×${state.combo}` : ""}`;
      board.update(state, selected);
    }

    function frame(now) {
      raf = null;
      if (closed || document.hidden || paused || !state || state.over) return;
      const dt = Math.min((now - last) / 1000, 0.1) * speed;
      last = now;
      if (autopilot && state.time >= nextAI) {
        for (const move of planMoves(state)) applyAction(state, move);
        nextAI = state.time + AI_INTERVAL;
      }
      tick(state, dt);
      handleEvents();
      render();
      if (state.over) showResult();
      else raf = requestAnimationFrame(frame);
    }

    function wake() {
      if (raf || closed || document.hidden || paused || !state || state.over) return;
      last = performance.now();
      raf = requestAnimationFrame(frame);
    }

    function start(demo) {
      clearTimeout(restartTimer);
      const seed = Math.floor(Math.random() * 1e9);
      state = createShift({ rooms: pickRooms(app.store.catalog), housekeepers: pickCrew(app.settings.get("housekeepers"), seed), seed });
      board = createBoard(state, { onRoom, onCrew, onRestock });
      field.replaceChildren(board.crew, board.rooms);
      selected = null;
      nextAI = 0;
      demoRun = demo;
      setAutopilot(demo);
      setPaused(false);
      say(demo ? tr("Демо: смену ведёт автопилот. Коснись поля, чтобы играть самому.") : tr("Выбери уборщицу, затем коснись жёлтого номера."));
      overlay.hidden = true;
      feedback.confirm();
      render();
      wake();
    }

    function showResult() {
      const card = resultCard(state, { demo: demoRun, onPlay: () => start(false), onDemo: () => start(true) });
      overlay.replaceChildren(card);
      overlay.hidden = false;
      if (!demoRun) return;
      // Демо крутится само: через несколько секунд начинается новая смена.
      let left = DEMO_RESTART_SECONDS;
      const step = () => {
        if (closed) return;
        card.setCountdown(left);
        if (left-- <= 0) start(true);
        else restartTimer = setTimeout(step, 1000);
      };
      step();
    }

    const onVisibility = () => { if (!document.hidden) wake(); };
    document.addEventListener("visibilitychange", onVisibility);
    const stop = () => {
      closed = true;
      clearTimeout(restartTimer);
      if (raf) cancelAnimationFrame(raf);
      document.removeEventListener("visibilitychange", onVisibility);
    };
    stopGame = stop;

    overlay.replaceChildren(introCard({ onPlay: () => start(false), onDemo: () => start(true) }));
    return h("main", { class: "game-screen" },
      h("header", { class: "game-header" },
        backButton(close),
        h("div", { class: "game-title" }, h("div", { class: "game-name" }, tr("Смена")), clock),
        h("div", { class: "game-scoreboard" }, score, stars)),
      ticker, field,
      h("footer", { class: "game-controls" }, autoButton, speedControl, pauseButton),
      overlay);
  }, { onClose: () => stopGame?.() });
}
