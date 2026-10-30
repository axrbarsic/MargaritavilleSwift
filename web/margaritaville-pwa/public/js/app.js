// Точка входа PWA Margaritaville: загрузка смены, выбор экрана, живой фон, таймер
// назначенного времени и сервис-воркер для работы без сети. Источник: App/AppRootView.swift.
import { SessionStore } from "./store/session-store.js";
import { SettingsStore } from "./store/settings-store.js";
import { FeedbackService } from "./infra/feedback.js";
import { ScheduleNotifications } from "./infra/notifications.js";
import { renderSetup } from "./ui/setup-view.js";
import { renderSummary } from "./ui/summary-view.js";
import { refreshScreens } from "./ui/screen-stack.js";
import { openSettings } from "./ui/settings/settings-screen.js";
import { AppBackground } from "./ui/background/app-background.js";
import { h } from "./ui/dom.js";
import { keepUpdated } from "./infra/updates.js";
import { tr } from "./i18n/i18n.js";

export const APP_VERSION = "1.0.0";
export const APP_BUILD = 7;

const root = document.getElementById("app");
const settings = new SettingsStore();
const store = new SessionStore(settings);
const feedback = new FeedbackService(settings);
const notifications = new ScheduleNotifications();
const background = new AppBackground(document.getElementById("background"), settings);

const app = {
  store, settings, feedback, notifications, background,
  ui: {},
  version: APP_VERSION,
  build: APP_BUILD,
  render: () => render(),
  openSettings: () => openSettings(app)
};

function applySettings() {
  document.documentElement.classList.toggle("transparent-surfaces", settings.get("transparentSurfacesEnabled"));
  document.documentElement.classList.toggle("vivid-palette", settings.vividStatusPaletteEnabled);
  document.documentElement.classList.toggle("live-3d", settings.get("developerLive3DCellsEnabled"));
}

let frame = null;
function render() {
  if (frame) return;
  frame = requestAnimationFrame(() => { frame = null; draw(); });
}

function draw() {
  if (!store.loaded) {
    root.replaceChildren(h("main", { class: "screen loading" }, h("div", { class: "spinner", "aria-label": tr("Загрузка") })));
    return;
  }
  if (store.loadFailure) {
    root.replaceChildren(h("main", { class: "screen failure" },
      h("div", { class: "failure-title" }, tr("Смена не загрузилась")),
      h("p", {}, tr("Сохранённые данные не изменены. Изменения не сохраняются, пока загрузка не пройдёт.")),
      h("p", { class: "failure-detail" }, store.loadFailure),
      h("button", { class: "start-button", onclick: () => { store.loaded = false; draw(); store.load(); } }, tr("Повторить"))
    ));
    return;
  }
  const scrollTop = root.querySelector(".setup-scroll, .summary-scroll")?.scrollTop ?? 0;
  const active = document.activeElement;
  if (active?.classList?.contains("search-input")) return;
  if (store.selection.workdayLocked) renderSummary(root, app);
  else renderSetup(root, app);
  const scroller = root.querySelector(".setup-scroll, .summary-scroll");
  if (scroller) scroller.scrollTop = scrollTop;
}

store.subscribe(() => { render(); refreshScreens(); });
settings.subscribe(() => { applySettings(); background.update(); render(); refreshScreens(); });
window.addEventListener("resize", render);
applySettings();
background.update();
draw();
store.load().then(() => {
  store.advanceScheduledRooms();
  notifications.restore(store.carts);
});

setInterval(() => store.advanceScheduledRooms(), 15000);
document.addEventListener("visibilitychange", () => {
  if (document.hidden) store.flush();
  else store.advanceScheduledRooms();
  background.setVisible(!document.hidden);
});
window.addEventListener("pagehide", () => store.flush());

keepUpdated();
