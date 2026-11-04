// Режим Runner: вечерний список уборщиц на завтра — кому готовить тележку.
// Отметка done — тележка готова (зелёный баннер). По умолчанию список по алфавиту;
// после ручной перестановки действует свой порядок, пока его не сбросят.
// Каждый день список собирается заново выбором имён из справочника уборщиц.
// Все функции чистые: возвращают новый список, не меняя старый.

export const emptyRunnerList = () => ({ entries: [], manualOrder: false });

/// Список из хранилища: отбрасывает мусор и повторы.
export function normalizeRunnerList(raw) {
  const seen = new Set();
  const entries = (Array.isArray(raw?.entries) ? raw.entries : [])
    .filter((e) => typeof e?.id === "string" && !seen.has(e.id) && seen.add(e.id))
    .map((e) => ({ id: e.id, done: e.done === true }));
  return { entries, manualOrder: raw?.manualOrder === true };
}

const byName = (nameOf) => (a, b) => nameOf(a.id).localeCompare(nameOf(b.id), undefined, { sensitivity: "base" });

/// Порядок на экране: свой порядок или алфавит. Уборщиц, которых нет в справочнике, не показываем.
export function orderedEntries(list, nameOf) {
  const known = list.entries.filter((e) => nameOf(e.id));
  return list.manualOrder ? known : [...known].sort(byName(nameOf));
}

export const hasMember = (list, id) => list.entries.some((e) => e.id === id);

export function addMember(list, id) {
  if (hasMember(list, id)) return list;
  return { ...list, entries: [...list.entries, { id, done: false }] };
}

export function removeMember(list, id) {
  return { ...list, entries: list.entries.filter((e) => e.id !== id) };
}

export function toggleDone(list, id) {
  return { ...list, entries: list.entries.map((e) => (e.id === id ? { ...e, done: !e.done } : e)) };
}

/// Перестановка пальцем: from/to — позиции на экране. Дальше действует свой порядок.
export function moveEntry(list, from, to, nameOf) {
  const shown = orderedEntries(list, nameOf);
  if (from === to || from < 0 || from >= shown.length) return list;
  const next = [...shown];
  const [moved] = next.splice(from, 1);
  next.splice(Math.max(0, Math.min(to, next.length)), 0, moved);
  const hidden = list.entries.filter((e) => !nameOf(e.id));
  return { entries: [...next, ...hidden], manualOrder: true };
}

export const sortAlphabetically = (list) => ({ ...list, manualOrder: false });

/// Состав из выбора имён: оставленные сохраняют отметку и место, новые встают в конец.
export function setMembers(list, ids) {
  const wanted = new Set(ids);
  const kept = list.entries.filter((e) => wanted.has(e.id));
  const added = ids.filter((id) => !kept.some((e) => e.id === id)).map((id) => ({ id, done: false }));
  return { ...list, entries: [...kept, ...added] };
}

/// Новый день: список собирается заново из выбранных имён, по алфавиту и без отметок.
export const newRunnerList = (ids) => setMembers(emptyRunnerList(), ids);

export const clearMarks = (list) => ({ ...list, entries: list.entries.map((e) => ({ ...e, done: false })) });

export const readyCount = (list, nameOf) => orderedEntries(list, nameOf).filter((e) => e.done).length;
