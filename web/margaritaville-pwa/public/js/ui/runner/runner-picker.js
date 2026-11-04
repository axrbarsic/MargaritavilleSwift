// Выбор имён для списка Runner из всего справочника уборщиц.
// «new» — новый день: всё снято, список собирается заново; «edit» — правка состава.
// Пока не нажата «Готово», старый список не меняется.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { openSheet } from "../sheets.js";
import { paletteColor } from "../../domain/housekeepers.js";
import { newRunnerList, setMembers } from "../../domain/runner-list.js";
import { tr } from "../../i18n/i18n.js";

export function openRunnerPicker(app, mode) {
  const { runner, settings, feedback } = app;
  feedback.tap();
  const roster = [...settings.get("housekeepers")]
    .sort((a, b) => a.displayName.localeCompare(b.displayName, undefined, { sensitivity: "base" }));
  const chosen = new Set(mode === "edit" ? runner.list.entries.map((e) => e.id) : []);

  openSheet((close) => {
    const done = h("button", { class: "action picker-done" });
    const paintDone = () => {
      done.textContent = chosen.size ? tr("Готово · {count}", { count: chosen.size }) : tr("Выбери хотя бы одну");
      done.disabled = chosen.size === 0;
    };
    const rows = roster.map((hk) => {
      const row = h("button", { class: "picker-row", role: "checkbox", style: { "--hk": paletteColor(hk.palette) } },
        h("span", { class: "picker-dot" }), h("span", { class: "picker-name" }, hk.displayName), h("span", { class: "picker-check" }));
      const paint = () => {
        const on = chosen.has(hk.id);
        row.classList.toggle("on", on);
        row.setAttribute("aria-checked", String(on));
        row.lastChild.replaceChildren(on ? icon("check", 18, 3.2) : "");
      };
      row.addEventListener("click", () => {
        if (chosen.has(hk.id)) { chosen.delete(hk.id); feedback.deselect(); } else { chosen.add(hk.id); feedback.select(); }
        paint();
        paintDone();
      });
      paint();
      return row;
    });
    done.addEventListener("click", () => {
      if (!chosen.size) return;
      const ids = roster.map((hk) => hk.id).filter((id) => chosen.has(id));
      if (mode === "new") runner.replace(newRunnerList(ids));
      else runner.update((list) => setMembers(list, ids));
      feedback.confirm();
      close();
    });
    paintDone();
    return h("div", { class: "actions" },
      h("div", { class: "action-group picker" },
        h("div", { class: "action-title" }, mode === "new" ? tr("Кто работает завтра?") : tr("Состав списка")),
        mode === "new" ? h("div", { class: "action-message" }, tr("Отметь уборщиц из общего списка — новый список встанет по алфавиту.")) : null,
        h("div", { class: "picker-list" }, rows),
        done),
      h("button", { class: "action cancel", onclick: close }, tr("Отмена")));
  });
}
