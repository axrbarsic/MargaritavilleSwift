// Нижние листы: меню действий комнаты, выбор времени открытия, заметка.
// Источник: MargaritavilleRoomTile (confirmationDialog), RoomScheduleSheet.swift,
// Domain/RoomScheduleSelection.swift.
import { h } from "./dom.js";
import { roomStatus } from "../domain/room.js";

const HOURS = [8, 9, 10, 11, 12, 1, 2, 3, 4];
const MINUTES = [0, 15, 30, 45];

export function openSheet(content) {
  const layer = h("div", { class: "sheet-layer", onclick: (event) => { if (event.target === layer) close(); } },
    h("div", { class: "bottom-sheet" }, content(() => close()))
  );
  function close() { layer.remove(); }
  document.body.append(layer);
  return close;
}

export function openRoomActions(store, roomID, ui) {
  const room = store.room(roomID);
  if (!room) return;
  openSheet((close) => h("div", { class: "actions" },
    h("div", { class: "sheet-title" }, `Комната ${room.id}`),
    h("button", { class: "action", onclick: () => { close(); openNote(store, roomID); } }, "Заметка"),
    h("button", { class: "action", onclick: () => { store.toggleVIP(roomID); close(); } }, room.isVIP ? "VIP выключить" : "VIP включить"),
    h("button", { class: "action", onclick: () => { close(); openSchedule(store, roomID); } }, "Назначить время"),
    roomStatus(room) !== "pending" ? h("button", { class: "action warn", onclick: () => { store.reset(roomID); close(); } }, "Вернуть в жёлтый") : null,
    h("button", { class: "action cancel", onclick: close }, "Отмена")
  ));
}

function defaultSelection(fromMs) {
  const date = new Date(fromMs ?? Date.now() + (15 - (new Date().getMinutes() % 15)) * 60000);
  const hour24 = date.getHours();
  const minute = MINUTES.reduce((best, m) => (Math.abs(m - date.getMinutes()) < Math.abs(best - date.getMinutes()) ? m : best), 0);
  const hour12 = hour24 % 12 || 12;
  return { hour: HOURS.includes(hour12) ? hour12 : 11, minute, pm: hour24 >= 12 };
}

function toToday({ hour, minute, pm }) {
  const date = new Date();
  date.setHours((hour % 12) + (pm ? 12 : 0), minute, 0, 0);
  return date.getTime();
}

export function openSchedule(store, roomID) {
  const room = store.room(roomID);
  if (!room) return;
  const choice = defaultSelection(room.scheduledTime);
  openSheet((close) => {
    const render = () => body.replaceChildren(...content());
    const pill = (label, active, onclick) => h("button", { class: `pill${active ? " active" : ""}`, onclick: () => { onclick(); render(); } }, label);
    const content = () => [
      h("div", { class: "sheet-title" }, "Время открытия"),
      h("div", { class: "sheet-subtitle" }, `Комната ${room.id}`),
      h("div", { class: "pill-row" }, HOURS.map((hr) => pill(String(hr), choice.hour === hr, () => { choice.hour = hr; choice.pm = hr === 12 || hr <= 4; }))),
      h("div", { class: "pill-row" }, MINUTES.map((m) => pill(`:${String(m).padStart(2, "0")}`, choice.minute === m, () => { choice.minute = m; }))),
      h("div", { class: "pill-row" }, pill("AM", !choice.pm, () => { choice.pm = false; }), pill("PM", choice.pm, () => { choice.pm = true; })),
      h("div", { class: "sheet-buttons" },
        h("button", { class: "action warn", onclick: () => { store.setSchedule(roomID, null); close(); } }, "Очистить"),
        h("button", { class: "action primary", onclick: () => { store.setSchedule(roomID, toToday(choice)); store.advanceScheduledRooms(); close(); } }, "Установить")
      )
    ];
    const body = h("div", { class: "schedule" }, content());
    return body;
  });
}

export function openNote(store, roomID) {
  const room = store.room(roomID);
  if (!room) return;
  openSheet((close) => {
    const area = h("textarea", { class: "note-input", id: "noteInput", rows: 5, placeholder: "Заметка к комнате" });
    area.value = room.textNote ?? "";
    setTimeout(() => area.focus(), 50);
    return h("div", { class: "note" },
      h("div", { class: "sheet-title" }, `Заметка · ${room.id}`),
      area,
      h("div", { class: "sheet-buttons" },
        h("button", { class: "action cancel", onclick: close }, "Отмена"),
        h("button", { class: "action primary", onclick: () => { store.setNote(roomID, area.value); close(); } }, "Сохранить")
      )
    );
  });
}
