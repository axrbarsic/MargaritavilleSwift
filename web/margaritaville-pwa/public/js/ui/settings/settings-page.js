// Каркас экрана настроек: шапка «назад» + заголовок и прокрутка только по вертикали.
// Один каркас на все вложенные экраны, чтобы они выглядели одинаково.
import { h } from "../dom.js";
import { backButton, pushScreen } from "../screen-stack.js";

/// Прокручиваемое тело экрана настроек с общей шапкой.
export function settingsScroller(close, title, ...content) {
  return h("div", { class: "detail-scroll settings-scroll" },
    h("header", { class: "settings-header" }, backButton(close), h("div", { class: "settings-title" }, title)),
    ...content);
}

/// Экран настроек, содержимое которого перестраивается после изменений.
export function openSettingsPage(app, title, build, { onClose } = {}) {
  pushScreen((close, setRefresh) => {
    const content = h("div", { class: "settings-content" });
    const scroller = settingsScroller(close, title, content);
    const rerender = () => {
      const top = scroller.scrollTop;
      content.replaceChildren(...build(rerender).filter(Boolean));
      scroller.scrollTop = top;
    };
    setRefresh(() => {
      // Не перестраиваем экран во время ввода текста или движения ползунка.
      if (!content.contains(document.activeElement) || document.activeElement === document.body) rerender();
    });
    rerender();
    return h("main", { class: "detail-screen settings-screen" }, scroller);
  }, { onClose });
}
