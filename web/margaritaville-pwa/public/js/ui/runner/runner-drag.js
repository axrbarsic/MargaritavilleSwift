// Перестановка баннеров пальцем за ручку ≡ (удержание имени переключает цвет).
// Пока строка в руке, прокрутка страницы заблокирована, у краёв экрана список подкручивается сам.

const EDGE = 64;
const EDGE_SPEED = 9;

export function enableReorder(list, { onMove, feedback }) {
  const rows = () => [...list.children];

  for (const row of rows()) {
    const grip = row.querySelector(".runner-grip");
    grip.addEventListener("pointerdown", (event) => { event.preventDefault(); begin(row, event.clientY); });
  }

  function begin(row, startY) {
    const all = rows();
    const from = all.indexOf(row);
    if (from < 0 || all.length < 2) return;
    const scroller = list.closest(".runner-scroll");
    const step = all[1].getBoundingClientRect().top - all[0].getBoundingClientRect().top || row.offsetHeight + 6 || 62;
    const startScroll = scroller.scrollTop;
    let pointerY = startY;
    let target = from;
    let raf = null;

    feedback.hapticOnly("longPress");
    list.classList.add("reordering");
    row.classList.add("dragging");

    const layout = () => {
      const dy = pointerY - startY + (scroller.scrollTop - startScroll);
      row.style.transform = `translateY(${dy}px)`;
      const next = Math.max(0, Math.min(all.length - 1, Math.round(from + dy / step)));
      if (next !== target) { target = next; feedback.hapticOnly("detent"); }
      all.forEach((other, index) => {
        if (other === row) return;
        const shift = from < index && index <= target ? -step : target <= index && index < from ? step : 0;
        other.style.transform = shift ? `translateY(${shift}px)` : "";
      });
    };

    // Подкрутка у краёв: работает, пока палец держит строку у верхнего или нижнего края.
    const edgeScroll = () => {
      const box = scroller.getBoundingClientRect();
      const delta = pointerY < box.top + EDGE ? -EDGE_SPEED : pointerY > box.bottom - EDGE ? EDGE_SPEED : 0;
      if (delta) { scroller.scrollTop += delta; layout(); }
      raf = requestAnimationFrame(edgeScroll);
    };

    const onMovePointer = (event) => { pointerY = event.clientY; layout(); };
    const blockScroll = (event) => event.preventDefault();
    const finish = () => {
      cancelAnimationFrame(raf);
      document.removeEventListener("pointermove", onMovePointer);
      document.removeEventListener("pointerup", finish);
      document.removeEventListener("pointercancel", finish);
      document.removeEventListener("touchmove", blockScroll);
      list.classList.remove("reordering");
      row.classList.remove("dragging");
      all.forEach((other) => { other.style.transform = ""; });
      if (target !== from) { feedback.confirm(); onMove(from, target); }
    };

    document.addEventListener("pointermove", onMovePointer);
    document.addEventListener("pointerup", finish);
    document.addEventListener("pointercancel", finish);
    document.addEventListener("touchmove", blockScroll, { passive: false });
    raf = requestAnimationFrame(edgeScroll);
    layout();
  }
}
