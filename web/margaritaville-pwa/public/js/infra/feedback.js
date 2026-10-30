// Звуки и вибрация интерфейса через Web Audio: события, назначения из настроек,
// приоритеты одновременных звуков. Источник: Infrastructure/Interaction/
// InteractionSoundRouting.swift, InteractionFeedbackService.swift.

export const SOUND_ASSETS = {
  none: { title: "Без звука", file: null },
  hotelBell: { title: "Старый колокольчик", file: "room_complete_hotel_bell" },
  frontDeskBell: { title: "Звонок стойки", file: "front_desk_bell_real" },
  kenneyConfirmation3: { title: "Плотное подтверждение", file: "kenney_confirmation_003" },
  kenneyBong1: { title: "Низкий бонг", file: "kenney_bong_001" },
  uiClickBright: { title: "Яркий клик", file: "xhotel_ui_click_bright" },
  uiClickSoft: { title: "Мягкий клик", file: "xhotel_ui_click_soft" },
  uiRolloverTick: { title: "Короткий тик", file: "xhotel_ui_rollover_tick" },
  uiSwitchLight: { title: "Лёгкий переключатель", file: "xhotel_ui_switch_light" },
  uiSwitchDeep: { title: "Глубокий переключатель", file: "xhotel_ui_switch_deep" },
  uiConfirmPop: { title: "Сочный поп", file: "xhotel_ui_confirm_pop" },
  uiConfirmGlass: { title: "Стеклянное подтверждение", file: "xhotel_ui_confirm_glass" },
  uiAlertSnap: { title: "Резкий сигнал", file: "xhotel_ui_alert_snap" },
  uiErrorLow: { title: "Низкий отказ", file: "xhotel_ui_error_low" },
  uiMenuOpen: { title: "Открытие меню", file: "xhotel_ui_menu_open" }
};

export const SETTINGS_PALETTE = ["none", "uiClickBright", "uiClickSoft", "uiRolloverTick", "uiSwitchLight", "uiSwitchDeep", "uiConfirmPop", "uiConfirmGlass", "kenneyConfirmation3", "uiAlertSnap", "uiErrorLow", "uiMenuOpen", "kenneyBong1", "frontDeskBell"];

/// Видимые в настройках назначения и их подписи.
export const SETTINGS_EVENTS = [
  { id: "tap", title: "Все остальные действия", subtitle: "Любые действия, которые не касаются ячеек." },
  { id: "roomOpen", title: "Ячейка", subtitle: "Любое взаимодействие с ячейкой, кроме финального зелёного статуса." },
  { id: "roomReady", title: "Зелёная ячейка", subtitle: "Когда ячейка становится зелёной." }
];

const DEFAULT_ASSET = {
  tap: "uiRolloverTick", confirm: "uiConfirmPop", longPress: "uiConfirmGlass", holdStart: "none",
  holdWarning: "uiRolloverTick", holdCommit: "uiConfirmPop", select: "uiSwitchLight", deselect: "uiClickBright",
  invalid: "uiErrorLow", detent: "uiRolloverTick", settingsOpen: "uiMenuOpen", selectionOpen: "uiConfirmGlass",
  actionMenuOpen: "uiMenuOpen", roomPending: "uiClickSoft", roomOpen: "uiConfirmGlass", roomInProgress: "uiSwitchDeep",
  roomReady: "frontDeskBell", roomScheduled: "uiAlertSnap"
};

const ROOM_EVENTS = new Set(["actionMenuOpen", "roomPending", "roomOpen", "roomInProgress", "roomScheduled"]);
const assignmentEvent = (event) => (event === "roomReady" ? "roomReady" : ROOM_EVENTS.has(event) ? "roomOpen" : "tap");

function priority(event) {
  if (event.startsWith("room")) return 80;
  if (["settingsOpen", "selectionOpen", "actionMenuOpen"].includes(event)) return 70;
  if (event === "holdCommit") return 60;
  if (["holdWarning", "longPress"].includes(event)) return 50;
  if (["confirm", "select", "deselect", "invalid", "detent"].includes(event)) return 40;
  return 20;
}

const HAPTIC = { tap: 8, confirm: 14, longPress: 18, holdStart: 6, holdWarning: [6, 30, 6], holdCommit: 22, select: 10, deselect: 8, invalid: [20, 40, 20], detent: 4 };

/// Длительность тишины в начале звука (порог −34 дБ), минус 3 мс запаса.
function leadingSilence(buffer) {
  const data = buffer.getChannelData(0);
  const limit = Math.min(data.length, Math.round(buffer.sampleRate * 0.4));
  for (let i = 0; i < limit; i += 1) {
    if (Math.abs(data[i]) > 0.02) return Math.max(0, i / buffer.sampleRate - 0.003);
  }
  return 0;
}

export function assetFor(assignments, event) {
  const key = assignmentEvent(event);
  const asset = assignments?.[key];
  return asset && SOUND_ASSETS[asset] ? asset : DEFAULT_ASSET[key];
}

export class FeedbackService {
  constructor(settings) {
    this.settings = settings;
    this.context = null;
    this.buffers = new Map();
    this.ready = new Map();
    this.lastPlay = { at: 0, priority: 0 };
    // Разблокировка звука на первом касании (iOS требует жест пользователя) и предзагрузка всех звуков,
    // чтобы в момент нажатия не ждать сеть и декодирование.
    const unlock = () => this.unlock();
    ["pointerdown", "touchend", "click", "keydown"].forEach((name) => window.addEventListener(name, unlock, { capture: true, passive: true }));
    document.addEventListener("visibilitychange", () => { if (!document.hidden) this.resume(); });
  }

  unlock() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    if (!this.context) {
      this.context = new AudioContext({ latencyHint: "interactive" });
      this.preloadAll();
    }
    this.resume();
  }

  resume() {
    const state = this.context?.state;
    if (state === "suspended" || state === "interrupted") this.context.resume().catch(() => {});
  }

  preloadAll() {
    for (const asset of Object.values(SOUND_ASSETS)) if (asset.file) this.buffer(asset.file);
  }

  buffer(file) {
    if (!this.buffers.has(file)) {
      this.buffers.set(file, fetch(`sounds/${file}.wav`)
        .then((r) => r.arrayBuffer())
        .then((data) => new Promise((resolve, reject) => this.context.decodeAudioData(data, resolve, reject)))
        .then((buffer) => { this.ready.set(file, { buffer, offset: leadingSilence(buffer) }); return buffer; })
        .catch(() => null));
    }
    return this.buffers.get(file);
  }

  /// Проигрывает сразу из готового буфера, пропуская тишину в начале файла.
  playAsset(asset) {
    const file = SOUND_ASSETS[asset]?.file;
    if (!file) return;
    this.unlock();
    if (!this.context) return;
    const ready = this.ready.get(file);
    if (ready) return this.start(ready);
    // Звук ещё грузится: сыграть, только если успеет почти сразу, иначе он уже не к месту.
    const requested = performance.now();
    this.buffer(file).then(() => {
      const late = this.ready.get(file);
      if (late && performance.now() - requested < 150) this.start(late);
    });
  }

  start({ buffer, offset }) {
    const source = this.context.createBufferSource();
    source.buffer = buffer;
    source.connect(this.context.destination);
    source.start(0, offset);
  }

  haptic(event) {
    const pattern = HAPTIC[event] ?? (event.startsWith("room") ? 16 : 10);
    navigator.vibrate?.(pattern);
  }

  /// Событие интерфейса: вибрация и звук; более важный звук не перебивается в течение 90 мс.
  play(event, { sound = true, haptic = true } = {}) {
    if (haptic) this.haptic(event);
    if (!sound) return;
    const now = performance.now();
    const p = priority(event);
    if (now - this.lastPlay.at < 90 && p < this.lastPlay.priority) return;
    this.lastPlay = { at: now, priority: p };
    this.playAsset(assetFor(this.settings.get("soundAssignments"), event));
  }

  tap() { this.play("tap"); }
  confirm() { this.play("confirm"); }
  select() { this.play("select"); }
  deselect() { this.play("deselect"); }
  invalid() { this.play("invalid"); }
  longPress() { this.play("longPress"); }
  holdStart() { this.play("holdStart"); }
  holdWarning() { this.play("holdWarning"); }
  holdCommit() { this.play("holdCommit"); }
  hapticOnly(event) { this.haptic(event); }
  preview(asset) { this.playAsset(asset); }
}
