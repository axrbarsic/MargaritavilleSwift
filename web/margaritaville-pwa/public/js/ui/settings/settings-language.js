// Выбор языка интерфейса. После выбора приложение перезапускается, чтобы все экраны
// и подписи модулей собрались заново на новом языке. Смена и настройки не меняются.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { openSheet } from "../sheets.js";
import { LANGUAGES, currentLanguage, tr } from "../../i18n/i18n.js";

export function chooseLanguage(app) {
  const current = currentLanguage();
  openSheet((close) => h("div", { class: "actions" },
    h("div", { class: "action-group" },
      h("div", { class: "action-title" }, tr("Язык интерфейса")),
      LANGUAGES.map((language) => h("button", {
        class: "action",
        onclick: () => {
          close();
          if (language.id === current.id) return;
          app.feedback.confirm();
          app.store.flush?.();
          app.settings.set("language", language.id);
          setTimeout(() => location.reload(), 120);
        }
      }, icon(language.id === current.id ? "check" : "globe", 18, 2.6), h("span", {}, language.name)))),
    h("button", { class: "action cancel", onclick: close }, tr("Отмена"))));
}
