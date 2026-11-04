// Главный экран режима Runner: вечерний список уборщиц, как левая колонка листа на доске.
// Касание баннера — тележка готова (зелёный), повторное — снова жёлтый.
// Перетаскивание за ручку или долгим нажатием на баннер — свой порядок.
import { h, onHold } from "../dom.js";
import { icon } from "../icons.js";
import { orderedEntries, readyCount, sortAlphabetically, toggleDone, moveEntry } from "../../domain/runner-list.js";
import { enableReorder } from "./runner-drag.js";
import { openRunnerPicker } from "./runner-picker.js";
import { currentLanguage, tr } from "../../i18n/i18n.js";

/// Дата списка в стиле листа на доске: «4 нояб.» на языке интерфейса.
function listDate(ms) {
  return new Date(ms ?? Date.now()).toLocaleDateString(currentLanguage().locale, { day: "numeric", month: "short" });
}

export function renderRunner(root, app) {
  const { runner, settings, feedback } = app;
  const nameOf = (id) => settings.housekeeper(id)?.displayName ?? null;
  const entries = orderedEntries(runner.list, nameOf);
  const ready = readyCount(runner.list, nameOf);

  const menu = h("button", { class: "header-menu", "aria-label": tr("Открыть настройки") }, icon("menu", 24, 3));
  onHold(menu, 460, () => { feedback.play("settingsOpen"); app.openSettings(); });
  const header = h("header", { class: "runner-header" }, menu,
    h("div", { class: "runner-heading" }, h("div", { class: "runner-title" }, "Runner"), h("div", { class: "runner-date" }, listDate(runner.createdAt))),
    entries.length ? h("div", { class: `runner-count${ready === entries.length ? " all" : ""}` }, `${ready}/${entries.length}`) : null);

  const body = entries.length ? listView(app, entries, nameOf) : emptyView(app);
  const actions = h("footer", { class: "runner-actions" },
    entries.length ? h("button", { class: "runner-action", onclick: () => openRunnerPicker(app, "edit") }, icon("user", 18, 2.6), h("span", {}, tr("Состав"))) : null,
    runner.list.manualOrder ? h("button", { class: "runner-action", onclick: () => { feedback.confirm(); runner.update(sortAlphabetically); } }, icon("list", 18, 2.6), h("span", {}, tr("По алфавиту"))) : null,
    h("button", { class: "runner-action primary", onclick: () => openRunnerPicker(app, "new") }, icon("plus", 18, 3), h("span", {}, tr("Новый список"))));

  root.replaceChildren(h("main", { class: "screen runner" }, header, h("div", { class: "runner-scroll" }, body), actions));
}

function emptyView(app) {
  return h("div", { class: "runner-empty" },
    h("div", { class: "runner-empty-title" }, tr("Список на завтра пуст")),
    h("div", { class: "runner-empty-text" }, tr("Выбери уборщиц, которым нужно подготовить тележки. Список встанет по алфавиту.")),
    h("button", { class: "runner-action primary", onclick: () => openRunnerPicker(app, "new") }, icon("user", 18, 2.6), h("span", {}, tr("Выбрать уборщиц"))));
}

function listView(app, entries, nameOf) {
  const { runner, feedback } = app;
  const rows = entries.map((entry, index) => {
    const banner = h("button", { class: "runner-banner", "aria-pressed": String(entry.done) }, nameOf(entry.id));
    const grip = h("span", { class: "runner-grip", "aria-label": tr("Перетащить") }, icon("menu", 20, 2.6));
    const row = h("li", { class: `runner-row${entry.done ? " done" : ""}`, "data-id": entry.id },
      h("span", { class: "runner-index" }, String(index + 1)), banner, grip);
    banner.addEventListener("click", () => {
      if (Date.now() - Number(row.dataset.droppedAt ?? 0) < 450) return;
      if (entry.done) feedback.deselect(); else feedback.play("roomReady");
      runner.update((list) => toggleDone(list, entry.id));
    });
    return row;
  });
  const list = h("ol", { class: "runner-list" }, rows);
  enableReorder(list, {
    feedback,
    onMove: (from, to) => runner.update((current) => moveEntry(current, from, to, nameOf))
  });
  return h("div", { class: "runner-sheet" }, list,
    h("div", { class: "runner-hint" }, tr("Коснись имени — тележка готова. Перетащи за ≡ или удержи имя, чтобы поменять порядок.")));
}
