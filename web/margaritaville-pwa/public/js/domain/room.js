// Комната и её простой цикл статусов Margaritaville. Источник: Domain/RoomModels.swift,
// Features/WorkSession/WorkSessionStore+SimpleCycle.swift. Время — миллисекунды.

export const TASKS = ["S", "L", "B"];
export const STATUS = { pending: "pending", open: "open", ready: "ready", scheduled: "scheduled" };

export function makeRoom(id, now) {
  return {
    id,
    opened: false,
    openedUpdatedAt: null,
    completedTasks: [],
    isVIP: false,
    vipUpdatedAt: null,
    scheduledTime: null,
    scheduledUpdatedAt: null,
    statusChangedAt: now,
    dayCategory: null,
    dayCategoryTime: null,
    timeline: { selectedAt: now, openedAt: null, completedAt: null },
    textNote: null,
    textNoteUpdatedAt: null,
    voiceTranscript: null,
    voiceTranscriptUpdatedAt: null,
    mediaAttachments: null
  };
}

export function isReady(room) {
  return room.opened && room.completedTasks.length === TASKS.length;
}

/// Статус в простом цикле: назначено → зелёный → красный (открыта) → жёлтый (ждёт).
export function roomStatus(room) {
  if (room.scheduledTime != null) return STATUS.scheduled;
  if (isReady(room)) return STATUS.ready;
  return room.opened ? STATUS.open : STATUS.pending;
}

function markStatusChanged(room, previous, now) {
  if (roomStatus(room) !== previous) room.statusChangedAt = now;
}

/// Касание: жёлтый → красный → зелёный; назначенная становится открытой.
export function advance(room, now) {
  const previous = roomStatus(room);
  if (previous === STATUS.ready) return;
  if (previous === STATUS.pending || previous === STATUS.scheduled) {
    room.opened = true;
    room.openedUpdatedAt = now;
    room.scheduledTime = null;
    room.scheduledUpdatedAt = now;
    room.timeline.openedAt = room.timeline.openedAt ?? now;
  } else {
    room.opened = true;
    room.completedTasks = [...TASKS];
    room.openedUpdatedAt = room.openedUpdatedAt ?? now;
    room.timeline.completedAt = room.timeline.completedAt ?? now;
  }
  markStatusChanged(room, previous, now);
}

/// Прямой выбор красного или зелёного из меню действий.
export function setStatus(room, target, now) {
  if (target !== STATUS.open && target !== STATUS.ready) return;
  const previous = roomStatus(room);
  room.opened = true;
  room.openedUpdatedAt = now;
  room.scheduledTime = null;
  room.scheduledUpdatedAt = now;
  room.completedTasks = target === STATUS.ready ? [...TASKS] : [];
  room.timeline.openedAt = room.timeline.openedAt ?? now;
  if (target === STATUS.ready) room.timeline.completedAt = room.timeline.completedAt ?? now;
  markStatusChanged(room, previous, now);
}

/// Сброс в жёлтый.
export function reset(room, now) {
  const previous = roomStatus(room);
  room.opened = false;
  room.openedUpdatedAt = now;
  room.completedTasks = [];
  room.scheduledTime = null;
  room.scheduledUpdatedAt = null;
  markStatusChanged(room, previous, now);
}

export function toggleVIP(room, now) {
  room.isVIP = !room.isVIP;
  room.vipUpdatedAt = now;
}

export function setSchedule(room, time, now) {
  const previous = roomStatus(room);
  room.scheduledTime = time;
  room.scheduledUpdatedAt = now;
  markStatusChanged(room, previous, now);
}

/// Наступило назначенное время: свободная комната открывается, занятая теряет время.
export function advanceIfDue(room, now) {
  if (room.scheduledTime == null || room.scheduledTime > now) return false;
  const previous = roomStatus(room);
  room.scheduledTime = null;
  room.scheduledUpdatedAt = now;
  const opened = !room.opened && room.completedTasks.length === 0;
  if (opened) {
    room.opened = true;
    room.openedUpdatedAt = now;
    room.timeline.openedAt = room.timeline.openedAt ?? now;
  }
  markStatusChanged(room, previous, now);
  return opened;
}
