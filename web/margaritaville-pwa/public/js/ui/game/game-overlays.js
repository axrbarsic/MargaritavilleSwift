// Игра «Смена»: заставка с правилами, итоги смены, рекорд и строка событий.
import { h } from "../dom.js";
import { icon } from "../icons.js";
import { shiftGrade } from "../../game/shift-state.js";
import { tr } from "../../i18n/i18n.js";

const BEST_KEY = "margaritaville.game.best.v1";

export function bestScore() {
  try { return Number(localStorage.getItem(BEST_KEY)) || 0; } catch { return 0; }
}

function saveBest(score) {
  try { localStorage.setItem(BEST_KEY, String(score)); } catch { /* без хранилища рекорд живёт до закрытия */ }
}

const rule = (color, text, extra = "") => h("li", {}, h("span", { class: `rule-swatch${extra}`, style: { "--c": color } }), h("span", {}, text));

export function introCard({ onPlay, onDemo }) {
  const best = bestScore();
  return h("div", { class: "game-card" },
    h("h2", {}, tr("Смена")),
    h("div", { class: "game-lead" }, tr("Ты супервайзер. Раздавай номера уборщицам, следи за тележками и успей подготовить номера к заезду гостей.")),
    h("ul", { class: "game-rules" },
      rule("rgba(255, 255, 255, 0.16)", tr("Серый номер ещё занят гостем — внизу время выезда.")),
      rule("var(--pending)", tr("Выбери уборщицу, затем коснись жёлтого номера.")),
      rule("var(--scheduled)", tr("Розовый номер нужен к указанному времени, иначе минус звезда.")),
      rule("#ffd700", tr("VIP приносит двойные очки."), " vip"),
      rule("#ff9f0a", tr("Пустая тележка — коснись коробки на карточке уборщицы."))),
    best ? h("div", { class: "game-best" }, tr("Рекорд: {score}", { score: best })) : null,
    h("button", { class: "game-primary", onclick: onPlay }, icon("play", 18, 3), tr("Играть")),
    h("button", { class: "game-secondary", onclick: onDemo }, tr("Смотреть демо")));
}

/// Итоги: рекорд обновляется только в своей игре, не в демо.
export function resultCard(state, { demo, onPlay, onDemo }) {
  const previous = bestScore();
  const record = !demo && state.score > previous;
  if (record) saveBest(state.score);
  const countdown = h("div", { class: "game-best" });
  const card = h("div", { class: "game-card" },
    h("h2", {}, state.endReason === "rating" ? tr("Гости недовольны") : tr("Смена окончена")),
    h("div", { class: "game-grade" }, shiftGrade(state)),
    h("div", { class: "game-final-score" }, String(state.score)),
    record ? h("div", { class: "game-record" }, tr("Новый рекорд!")) : null,
    h("ul", { class: "game-stats" },
      h("li", {}, tr("Убрано номеров: {count}", { count: state.cleaned })),
      h("li", {}, tr("Вовремя: {count}", { count: state.onTime })),
      h("li", {}, tr("Лучшая серия: {count}", { count: state.bestCombo })),
      Math.max(previous, record ? state.score : 0) > 0 ? h("li", {}, tr("Рекорд: {score}", { score: Math.max(previous, record ? state.score : 0) })) : null),
    demo ? countdown : null,
    h("button", { class: "game-primary", onclick: onPlay }, icon("play", 18, 3), demo ? tr("Играть") : tr("Ещё раз")),
    h("button", { class: "game-secondary", onclick: onDemo }, tr("Смотреть демо")));
  card.setCountdown = (seconds) => { countdown.textContent = tr("Новое демо через {seconds} с", { seconds }); };
  return card;
}

/// Текст строки событий; null — событие без подписи.
export function eventLine(event, name) {
  switch (event.type) {
    case "assign": return event.by === "ai" ? tr("Автопилот: {room} → {name}", { room: event.room, name: name(event.hk) }) : null;
    case "checkout": return event.vip ? tr("VIP выехал из {room}", { room: event.room }) : null;
    case "missed": return tr("Гость {room} ждёт — минус звезда", { room: event.room });
    case "outOfSupplies": return tr("{name}: тележка пуста", { name: name(event.hk) });
    case "starBack": return tr("Серия! Звезда вернулась");
    case "ready": return event.combo >= 3 && !event.late ? tr("Серия ×{count}", { count: event.combo }) : null;
    default: return null;
  }
}

export const starsLabel = (rating, max) => "★".repeat(rating) + "☆".repeat(Math.max(0, max - rating));
