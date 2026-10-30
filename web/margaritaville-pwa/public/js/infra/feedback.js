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
    this.lastPlay = { at: 0, priority: 0 };
    const unlock = () => this.unlock();
    window.addEventListener("pointerdown", unlock, { once: true, capture: true });
  }

  unlock() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    this.context ??= new AudioContext();
    if (this.context.state === "suspended") this.context.resume().catch(() => {});
  }

  async buffer(file) {
    if (!this.buffers.has(file)) {
      this.buffers.set(file, fetch(`sounds/${file}.wav`)
        .then((r) => r.arrayBuffer())
        .then((data) => new Promise((resolve, reject) => this.context.decodeAudioData(data, resolve, reject)))
        .catch(() => null));
    }
    return this.buffers.get(file);
  }

  async playAsset(asset) {
    const file = SOUND_ASSETS[asset]?.file;
    if (!file) return;
    this.unlock();
    if (!this.context) return;
    const buffer = await this.buffer(file);
    if (!buffer) return;
    const source = this.context.createBufferSource();
    source.buffer = buffer;
    source.connect(this.context.destination);
    source.start();
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
