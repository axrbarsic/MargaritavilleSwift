// Точка входа PWA Margaritaville: загрузка смены, выбор экрана, таймер назначенного
// времени и сервис-воркер для работы без сети. Источник: App/AppRootView.swift.
import { SessionStore } from "./store/session-store.js";
import { renderSetup } from "./ui/setup-view.js";
import { renderSummary } from "./ui/summary-view.js";
import { openRoomActions, openSheet } from "./ui/sheets.js";
import { h } from "./ui/dom.js";

export const APP_VERSION = "0.1.0 (PWA этап 1)";

const root = document.getElementById("app");
const store = new SessionStore();

const ui = {
  openRoomActions: (roomID) => openRoomActions(store, roomID, ui),
  openSettings: () => openSheet((close) => h("div", { class: "actions" },
    h("div", { class: "sheet-title" }, "Настройки"),
    h("div", { class: "sheet-subtitle" }, `Margaritaville ${APP_VERSION}`),
    h("p", { class: "sheet-text" }, "Смена хранится только на этом телефоне. Фоны, медиа, голос и остальные настройки переносятся на следующих этапах."),
    h("button", { class: "action cancel", onclick: close }, "Закрыть")
  ))
};

function render() {
  if (!store.loaded) {
    root.replaceChildren(h("main", { class: "screen loading" }, h("div", { class: "spinner", "aria-label": "Загрузка" })));
    return;
  }
  if (store.loadFailure) {
    root.replaceChildren(h("main", { class: "screen failure" },
      h("div", { class: "failure-title" }, "Смена не загрузилась"),
      h("p", {}, "Сохранённые данные не изменены. Изменения не сохраняются, пока загрузка не пройдёт."),
      h("p", { class: "failure-detail" }, store.loadFailure),
      h("button", { class: "start-button", onclick: () => { store.loaded = false; render(); store.load(); } }, "Повторить")
    ));
    return;
  }
  const scrollTop = root.querySelector(".setup-scroll, .summary-scroll")?.scrollTop ?? 0;
  if (store.selection.workdayLocked) renderSummary(root, store, ui);
  else renderSetup(root, store, ui);
  const scroller = root.querySelector(".setup-scroll, .summary-scroll");
  if (scroller) scroller.scrollTop = scrollTop;
}

store.subscribe(render);
render();
store.load().then(() => store.advanceScheduledRooms());

setInterval(() => store.advanceScheduledRooms(), 15000);
document.addEventListener("visibilitychange", () => {
  if (document.hidden) store.flush();
  else store.advanceScheduledRooms();
});
window.addEventListener("pagehide", () => store.flush());

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("sw.js").catch(() => {});
}
