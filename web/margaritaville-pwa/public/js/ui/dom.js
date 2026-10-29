// Маленький помощник создания элементов: h("button", { class, onclick }, детей…).

export function h(tag, attrs = {}, ...children) {
  const element = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (value == null || value === false) continue;
    if (key.startsWith("on") && typeof value === "function") element.addEventListener(key.slice(2), value);
    else if (key === "style" && typeof value === "object") {
      // CSS-переменные (--hk) задаются только через setProperty.
      for (const [name, styleValue] of Object.entries(value)) element.style.setProperty(name, styleValue);
    }
    else if (key === "class") element.className = value;
    else element.setAttribute(key, value === true ? "" : value);
  }
  for (const child of children.flat()) {
    if (child == null || child === false) continue;
    element.append(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return element;
}

/// Удержание: срабатывает через `ms`, если палец не сдвинулся больше чем на 8 px.
export function onHold(element, ms, action) {
  let timer = null;
  let start = null;
  const cancel = () => { clearTimeout(timer); timer = null; element.classList.remove("holding"); };
  element.addEventListener("pointerdown", (event) => {
    start = { x: event.clientX, y: event.clientY };
    element.classList.add("holding");
    timer = setTimeout(() => { cancel(); navigator.vibrate?.(12); action(); }, ms);
  });
  element.addEventListener("pointermove", (event) => {
    if (start && Math.hypot(event.clientX - start.x, event.clientY - start.y) > 8) cancel();
  });
  ["pointerup", "pointercancel", "pointerleave"].forEach((name) => element.addEventListener(name, cancel));
  element.addEventListener("contextmenu", (event) => event.preventDefault());
}

/// Свайп вправо по элементу (как свайп-меню ячейки в приложении).
export function onSwipeRight(element, threshold, action) {
  let start = null;
  element.addEventListener("pointerdown", (event) => { start = { x: event.clientX, y: event.clientY }; });
  element.addEventListener("pointerup", (event) => {
    if (!start) return;
    const dx = event.clientX - start.x;
    const dy = Math.abs(event.clientY - start.y);
    start = null;
    if (dx >= threshold && dx > dy * 2.5) action();
  });
}

export function formatTime(ms) {
  if (ms == null) return "--";
  return new Date(ms).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
}
