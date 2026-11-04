// Тесты вечернего списка Runner. Запуск: node --test tools/tests/*.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import {
  addMember, clearMarks, emptyRunnerList, moveEntry, normalizeRunnerList, orderedEntries,
  newRunnerList, readyCount, removeMember, setMembers, sortAlphabetically, toggleDone
} from "../../public/js/domain/runner-list.js";

const NAMES = { ritza: "Ritza", denise: "Denise", miolene: "Miolene", anazline: "Anazine", kettia: "kettia" };
const nameOf = (id) => NAMES[id];
const ids = (list) => orderedEntries(list, nameOf).map((e) => e.id);
const build = (...members) => members.reduce(addMember, emptyRunnerList());

test("по умолчанию список по алфавиту без учёта регистра", () => {
  assert.deepEqual(ids(build("ritza", "kettia", "denise", "anazline")), ["anazline", "denise", "kettia", "ritza"]);
});

test("касание делает зелёным, повторное — снова жёлтым", () => {
  let list = build("ritza", "denise");
  list = toggleDone(list, "ritza");
  assert.equal(readyCount(list, nameOf), 1);
  list = toggleDone(list, "ritza");
  assert.equal(readyCount(list, nameOf), 0);
});

test("перестановка включает свой порядок, «По алфавиту» его сбрасывает", () => {
  let list = build("ritza", "denise", "miolene");
  assert.deepEqual(ids(list), ["denise", "miolene", "ritza"]);
  list = moveEntry(list, 2, 0, nameOf);
  assert.equal(list.manualOrder, true);
  assert.deepEqual(ids(list), ["ritza", "denise", "miolene"]);
  list = addMember(list, "anazline");
  assert.deepEqual(ids(list), ["ritza", "denise", "miolene", "anazline"], "новая уборщица встаёт в конец своего порядка");
  assert.deepEqual(ids(sortAlphabetically(list)), ["anazline", "denise", "miolene", "ritza"]);
});

test("отметки сохраняются при перестановке и снимаются кнопкой «Новый список»", () => {
  let list = toggleDone(build("ritza", "denise"), "denise");
  list = moveEntry(list, 0, 1, nameOf);
  assert.equal(list.entries.find((e) => e.id === "denise").done, true);
  list = clearMarks(list);
  assert.equal(readyCount(list, nameOf), 0);
  assert.deepEqual(ids(list), ["ritza", "denise"], "порядок остаётся");
});

test("удалённые из справочника и повторы не показываются", () => {
  const list = normalizeRunnerList({ entries: [{ id: "ritza" }, { id: "ritza" }, { id: "ghost", done: true }, { id: 5 }], manualOrder: "yes" });
  assert.deepEqual(list.entries.map((e) => e.id), ["ritza", "ghost"]);
  assert.equal(list.manualOrder, false);
  assert.deepEqual(ids(list), ["ritza"]);
  assert.deepEqual(ids(removeMember(list, "ritza")), []);
});

test("новый день: список собирается заново только из выбранных имён", () => {
  let list = moveEntry(toggleDone(build("ritza", "denise", "miolene"), "ritza"), 0, 2, nameOf);
  list = newRunnerList(["kettia", "ritza"]);
  assert.deepEqual(ids(list), ["kettia", "ritza"]);
  assert.equal(list.manualOrder, false);
  assert.equal(readyCount(list, nameOf), 0);
});

test("правка состава сохраняет отметки и свой порядок оставшихся", () => {
  let list = toggleDone(moveEntry(build("ritza", "denise", "miolene"), 2, 0, nameOf), "denise");
  list = setMembers(list, ["denise", "ritza", "anazline"]);
  assert.deepEqual(ids(list), ["ritza", "denise", "anazline"]);
  assert.equal(list.entries.find((e) => e.id === "denise").done, true);
});
