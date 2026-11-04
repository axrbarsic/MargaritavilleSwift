// Удержание вместо касания — защита от случайных нажатий, как у ячеек Houseman:
// отдача при нажатии, 0,46 с без сдвига пальца — действие; сдвиг больше 8 px — это прокрутка.
// Источник поведения: ui/room-tile.js (HOLD_STATUS_MS, holdStart/holdCommit).

export const HOLD_MS = 460;
const SLOP = 8;

export function onHoldAction(element, feedback, action, ms = HOLD_MS) {
  let timer = null;
  let start = null;
  const cancel = () => { clearTimeout(timer); timer = null; element.classList.remove("holding"); };
  element.addEventListener("pointerdown", (event) => {
    if (event.button > 0) return;
    start = { x: event.clientX, y: event.clientY };
    element.classList.add("holding");
    feedback.hapticOnly("holdStart");
    timer = setTimeout(() => { cancel(); feedback.hapticOnly("holdCommit"); action(); }, ms);
  });
  element.addEventListener("pointermove", (event) => {
    if (timer && Math.hypot(event.clientX - start.x, event.clientY - start.y) > SLOP) cancel();
  });
  ["pointerup", "pointercancel", "pointerleave"].forEach((name) => element.addEventListener(name, cancel));
  element.addEventListener("contextmenu", (event) => event.preventDefault());
  element.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") { event.preventDefault(); action(); }
  });
}
