// Увеличенная ячейка — командный центр комнаты (режим «Расширенные»): быстрый статус,
// VIP и время, заметки и медиа. Закрывается после успешного действия.
// Источник: Features/Summary/MargaritavilleRoomZoomOverlay.swift, RoomCommandCenterState.swift.
import { h } from "./dom.js";
import { icon } from "./icons.js";
import { roomStatus } from "../domain/room.js";
import { tileTime } from "./room-tile.js";
import { formatTime } from "./dom.js";

const STATUS = {
  pending: { title: "Жёлтый", icon: "reset" },
  open: { title: "Красный", icon: "door" },
  ready: { title: "Зелёный", icon: "check" },
  scheduled: { title: "Розовый", icon: "clock" }
};
const FLOWS = {
  voice: { title: "Голос / аудио", icon: "waveform" },
  media: { title: "Фото, видео, галерея", icon: "photo" },
  text: { title: "Текстовая заметка", icon: "note" }
};

/// actions: { setStatus(status), toggleVIP(), openSchedule(), openDetails(mode), collapse() }
export function roomZoomOverlay(room, actions) {
  const status = roomStatus(room);
  const media = room.mediaAttachments ?? [];
  const audio = media.filter((a) => a.kind === "audio").length;
  const visual = media.filter((a) => a.kind !== "audio").length;
  const badge = (title, name) => h("span", { class: "zoom-badge" }, icon(name, 12, 3), title);

  const section = (title, subtitle, ...content) => h("section", { class: "zoom-section" },
    h("div", { class: "zoom-section-title" }, title),
    h("div", { class: "zoom-section-subtitle" }, subtitle),
    ...content);

  const command = (title, name, value, onclick) => h("button", { class: "zoom-command", onclick },
    icon(name, 18, 2.8),
    h("span", { class: "zoom-command-text" }, h("span", {}, title), value ? h("small", {}, value) : null),
    icon("chevron", 12, 3.4));

  const statusButton = (s) => {
    const active = status === s;
    return h("button", {
      class: `zoom-status status-${s}${active ? " active" : ""}`,
      disabled: active && s !== "scheduled",
      onclick: () => (s === "scheduled" ? actions.openSchedule() : actions.setStatus(s))
    }, icon(STATUS[s].icon, 16, 3), h("span", {}, STATUS[s].title), active ? icon("checkCircle", 16, 3) : null);
  };

  const card = h("div", { class: `zoom-card status-${status}`, onclick: (e) => e.stopPropagation() },
    h("div", { class: "zoom-head" },
      h("div", { class: "zoom-number-block" }, h("div", { class: "tile-number" }, room.id), h("div", { class: "tile-time" }, tileTime(room))),
      h("div", { class: "zoom-badges" },
        badge(STATUS[status].title, STATUS[status].icon),
        room.isVIP ? badge("VIP", "diamond") : null,
        media.length ? badge(`Медиа ${media.length}`, "paperclip") : null)
    ),
    h("div", { class: "zoom-scroll" },
      section("Быстрый статус", "Выбор применяется к живой комнате и закрывает центр после commit.",
        h("div", { class: "zoom-status-grid" }, ["pending", "open", "ready", "scheduled"].map(statusButton))),
      section("VIP и время", room.scheduledTime == null
        ? "Время не назначено. Штатный экран поддерживает назначение, изменение и очистку."
        : `Назначено: ${formatTime(room.scheduledTime)}. Нажми для изменения или очистки.`,
      h("div", { class: "zoom-row" },
        command(room.isVIP ? "VIP включён" : "Включить VIP", "diamond", room.isVIP ? "Выключить" : null, actions.toggleVIP),
        command(room.scheduledTime == null ? "Назначить время" : "Изменить время", "clock", room.scheduledTime == null ? null : formatTime(room.scheduledTime), actions.openSchedule))),
      section("Заметки и медиа", "Capture и редакторы закрывают увеличенную ячейку только после успешного сохранения.",
        h("div", { class: "zoom-row" },
          command(FLOWS.voice.title, FLOWS.voice.icon, audio ? `Аудио ${audio}` : null, () => actions.openDetails("voice")),
          command(FLOWS.media.title, FLOWS.media.icon, visual ? `Файлов ${visual}` : null, () => actions.openDetails("media"))),
        command(FLOWS.text.title, FLOWS.text.icon, room.textNote?.trim() ? "Есть текст" : null, () => actions.openDetails("text")))
    )
  );

  return h("div", { class: "zoom-layer", "aria-label": `Командный центр комнаты ${room.id}`, onclick: actions.collapse }, card);
}
