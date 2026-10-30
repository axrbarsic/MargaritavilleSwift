// Экран «Изменения»: сборки PWA и история сборок iOS-приложения.
// Источник: Features/Settings/BuildChangelogScreen.swift.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { backButton, pushScreen } from "../screen-stack.js";

export const PWA_CHANGELOG = [
  {
    version: "PWA 1.0.0 (4)",
    date: "2026-10-29",
    changes: [
      "Исправлено запаздывание звуков: все звуки загружаются заранее, после первого касания, и играют сразу.",
      "Срезана тишина в начале звуковых файлов — до 0,16 с у звонка зелёной ячейки и 0,1 с у звука ячейки."
    ]
  },
  {
    version: "PWA 1.0.0 (3)",
    date: "2026-10-29",
    changes: [
      "Исправлено: VIP-ячейка теперь заметно оживает — её контур волнуется и дышит, как VIP-желе в iOS-приложении.",
      "Все VIP-ячейки анимируются одним общим циклом, который останавливается, когда приложение свёрнуто."
    ]
  },
  {
    version: "PWA 1.0.0 (2)",
    date: "2026-10-29",
    changes: [
      "Полный перенос приложения: экраны комнаты и тележки, голосовые заметки с расшифровкой, фото и видео, расходники с отметками выполнения.",
      "Сводка как в iOS: фильтры по статусам, бегущая строка расходников, увеличение ячейки с командным центром, пазл возврата к выбору.",
      "Настройки целиком: внешний вид, звуки, фон, уборщицы, расходники, каталог номеров, тестовые данные и стенд типографики.",
      "Живые фоны: Matrix, сломанный телевизор, своё видео, Brooklyn 3D и камера со всеми эффектами; VIP-желе и HDR-всплески ячеек."
    ]
  },
  {
    version: "PWA 0.1.0 (1)",
    date: "2026-10-29",
    changes: [
      "Первый этап: рабочий список, сводка по уборщицам, цикл статусов удержанием, меню свайпом, назначенное время, хранение на телефоне и работа без сети."
    ]
  }
];

const entryCard = (entry) => h("section", { class: "changelog-entry" },
  h("div", { class: "changelog-head" }, h("span", { class: "changelog-version" }, entry.version), h("span", { class: "changelog-date" }, entry.date)),
  h("ul", { class: "changelog-list" }, entry.changes.map((c) => h("li", {}, icon("checkCircle", 16, 2.6), h("span", {}, c)))));

export function openChangelog() {
  pushScreen((close) => {
    const list = h("div", { class: "detail-scroll" }, PWA_CHANGELOG.map(entryCard), h("div", { class: "changelog-divider" }, "Сборки iOS-приложения"));
    fetch("data/ios-changelog.json").then((r) => r.json()).then((entries) => list.append(...entries.map(entryCard))).catch(() => {});
    return h("main", { class: "detail-screen" },
      h("header", { class: "detail-header" }, backButton(close), h("div", { class: "detail-big-title" }, "Изменения")),
      list);
  });
}
