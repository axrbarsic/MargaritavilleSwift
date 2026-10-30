// Полноэкранные листы поверх главного экрана (аналог .sheet/.fullScreenCover).
// Экран строится один раз; refresh() вызывается при изменении данных, чтобы не сбивать ввод.
import { h } from "./dom.js";
import { icon } from "./icons.js";

const stack = [];

/// Пока открыт экран, главный экран под ним скрыт — виден только живой фон, как в iOS-листах.
function syncCovered() {
  document.getElementById("app")?.classList.toggle("covered", stack.some((e) => !e.closed));
}

export function pushScreen(build, { className = "", onClose } = {}) {
  const layer = h("div", { class: `screen-layer ${className}` });
  const entry = { layer, refresh: null, onClose, closed: false };
  const close = () => {
    if (entry.closed) return;
    entry.closed = true;
    stack.splice(stack.indexOf(entry), 1);
    syncCovered();
    layer.classList.add("leaving");
    setTimeout(() => layer.remove(), 220);
    entry.onClose?.();
  };
  const content = build(close, (refresh) => { entry.refresh = refresh; });
  layer.append(content);
  stack.push(entry);
  document.body.append(layer);
  syncCovered();
  requestAnimationFrame(() => layer.classList.add("shown"));
  return close;
}

/// Обновить открытые экраны после изменения данных.
export function refreshScreens() {
  for (const entry of stack) entry.refresh?.();
}

export const hasOpenScreens = () => stack.length > 0;

/// Шапка с кнопкой «назад», как в RoomDetailsScreen/CartDetailsScreen.
export function backButton(close, label = "Назад") {
  return h("button", { class: "back-button", "aria-label": label, onclick: close }, icon("back", 24, 3));
}

export function panel(title, ...children) {
  return h("section", { class: "detail-panel-wrap" },
    title ? h("h2", { class: "detail-panel-title" }, title) : null,
    h("div", { class: "detail-panel" }, ...children)
  );
}

/// Дата для «Обновлено: …» — «Oct 29, 4:30 PM».
export function updatedLabel(ms) {
  if (ms == null) return null;
  return new Date(ms).toLocaleString("en-US", { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}
