// Расходники: строки тележки со шкалой 0–10, отметка выполнения удержанием, обнуление
// с 5-секундным предупреждением; бегущая строка и итоговая таблица сводки.
// Источник: Features/CartDetails/CartConsumablesSection.swift, CartConsumableQuantitySlider.swift,
// Features/Summary/SummaryConsumablesViews.swift, Design/MatrixConsumableStyle.swift.
import { h, onHold, formatTime } from "./dom.js";
import { icon } from "./icons.js";
import { MAX_QUANTITY, clampQuantity, mergedConsumables } from "../domain/consumables.js";
import { tr } from "../i18n/i18n.js";

const ZERO_COMMIT_DELAY = 5000;

export function consumablesSection(store, cartID, feedback) {
  const element = h("div", { class: "consumables" });
  const pendingZero = new Map();

  const refresh = () => {
    const cart = store.cart(cartID);
    const items = mergedConsumables(cart?.consumables, store.settings.get("cartConsumableCatalog"));
    element.replaceChildren(...items.map((item) => row(item)));
  };

  const commit = (item, quantity) => {
    store.setConsumableQuantity(cartID, item.id, item.title, quantity);
    feedback.confirm();
  };

  function select(item, quantity) {
    const next = clampQuantity(quantity);
    if (next === 0 && clampQuantity(item.quantity) !== 0) {
      clearTimeout(pendingZero.get(item.id));
      feedback.holdWarning();
      pendingZero.set(item.id, setTimeout(() => {
        pendingZero.delete(item.id);
        commit(item, 0);
        feedback.holdCommit();
      }, ZERO_COMMIT_DELAY));
      refresh();
      return;
    }
    if (pendingZero.has(item.id)) {
      clearTimeout(pendingZero.get(item.id));
      pendingZero.delete(item.id);
    }
    if (next !== clampQuantity(item.quantity)) commit(item, next);
    else refresh();
  }

  function row(item) {
    const pending = pendingZero.has(item.id);
    const visible = pending ? 0 : clampQuantity(item.quantity);
    const done = item.completedAt != null;
    const check = h("div", { class: "consumable-check", role: "button", "aria-label": tr("{item} выполнено", { item: tr(item.title) }) }, icon(done ? "checkCircle" : "circle", 28, 2.6));
    onHold(check, 520, () => {
      feedback.confirm();
      store.toggleConsumableCompletion(cartID, item.id, item.title);
    });
    const subtitle = done ? tr("Выполнено {time}", { time: formatTime(item.completedAt) }) : item.updatedAt ? tr("Обновлено {time}", { time: formatTime(item.updatedAt) }) : tr("Не задано");
    const percent = visible / MAX_QUANTITY;
    const step = (name, enabled, delta) => h("button", {
      class: `qty-step${enabled ? "" : " disabled"}`,
      "aria-label": delta > 0 ? tr("Больше") : tr("Меньше"),
      onclick: () => (enabled ? select(item, visible + delta) : feedback.tap())
    }, icon(name, 22, 3));
    return h("div", { class: `consumable-row${done ? " done" : ""}` },
      h("div", { class: "consumable-head" },
        check,
        h("div", { class: "consumable-text" }, h("div", { class: "consumable-title" }, tr(item.title)), h("div", { class: "consumable-subtitle" }, subtitle)),
        h("div", { class: "consumable-qty" }, String(visible))
      ),
      h("div", { class: "qty-slider", role: "group", "aria-label": tr("Количество"), "aria-valuenow": visible },
        step("minus", visible > 0, -1),
        h("div", { class: `qty-track${pending ? " warn" : ""}`, style: { "--p": percent } },
          h("div", { class: "qty-ruler" }, Array.from({ length: MAX_QUANTITY + 1 }, (_, i) => h("span", { class: i <= visible ? "on" : "" }))),
          h("div", { class: "qty-fill" }),
          h("div", { class: "qty-handle" }, String(visible))
        ),
        step("plus", visible < MAX_QUANTITY, 1)
      ),
      pending ? h("div", { class: "zero-warning" }, icon("bolt", 18, 3), tr("ВНИМАНИЕ • 5 сек до скрытия")) : null
    );
  }

  refresh();
  return { element, refresh };
}

/// Бегущая строка нужных расходников в шапке секции.
export function consumableTicker(text) {
  const line = () => h("span", { class: "ticker-text" }, icon("box", 12, 2.8), text);
  const duration = Math.max((text.length * 11 + 200) / 34, 4);
  return h("div", { class: "ticker", "aria-label": tr("Нужны расходники: {list}", { list: text }) },
    h("div", { class: "ticker-track", style: { "--duration": `${duration}s` } }, line(), line()));
}

/// Итоговая таблица расходников под сводкой.
export function consumablesTable(report) {
  if (!report.totals.length) return null;
  return h("div", { class: "consumables-table" },
    report.totals.map((item) => h("div", { class: "consumable-total" },
      h("span", { class: "consumable-total-title" }, tr(item.title)),
      h("span", { class: "consumable-total-qty" }, String(item.quantity))
    )));
}
