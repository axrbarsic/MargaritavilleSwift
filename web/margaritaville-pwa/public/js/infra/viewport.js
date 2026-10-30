// Высота экрана для полноэкранного режима iOS. В PWA со статус-баром black-translucent
// Safari считает 100% и inset: 0 без высоты статус-бара, и внизу остаётся пустая чёрная
// полоса. Поэтому высоту приложения задаём сами через --app-h по размеру экрана.

function fullHeight() {
  const portrait = window.innerHeight >= window.innerWidth;
  if (!navigator.standalone && !matchMedia("(display-mode: standalone)").matches) return window.innerHeight;
  const side = portrait ? Math.max(screen.width, screen.height) : Math.min(screen.width, screen.height);
  return Math.max(side, window.innerHeight);
}

export function fitViewport() {
  const apply = () => document.documentElement.style.setProperty("--app-h", `${fullHeight()}px`);
  apply();
  window.addEventListener("resize", apply);
  window.addEventListener("orientationchange", () => setTimeout(apply, 250));
}

/// Высота области рисования фонов (совпадает с --app-h).
export const viewportHeight = () => fullHeight();
