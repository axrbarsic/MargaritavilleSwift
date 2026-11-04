// Хранилище режима Runner: вечерний список уборщиц и дата, когда его собрали.
// Живёт только на телефоне (localStorage), отдельно от утренней смены Houseman.
import { emptyRunnerList, normalizeRunnerList } from "../domain/runner-list.js";

const KEY = "margaritaville.runner.v1";

export class RunnerStore {
  constructor(storage = globalThis.localStorage) {
    this.storage = storage;
    this.listeners = new Set();
    const saved = this.read();
    this.list = normalizeRunnerList(saved.list ?? emptyRunnerList());
    this.createdAt = Number.isFinite(saved.createdAt) ? saved.createdAt : null;
  }

  read() {
    try { return JSON.parse(this.storage?.getItem(KEY) ?? "{}") ?? {}; } catch { return {}; }
  }

  /// Меняет список чистой функцией из domain/runner-list.js и сразу сохраняет.
  update(change) {
    this.list = change(this.list);
    this.save();
  }

  /// Новый день: свежий список и новая дата.
  replace(list) {
    this.list = list;
    this.createdAt = Date.now();
    this.save();
  }

  save() {
    try {
      this.storage?.setItem(KEY, JSON.stringify({ list: this.list, createdAt: this.createdAt }));
    } catch {
      // Приватный режим или переполнение: список живёт до перезапуска.
    }
    this.listeners.forEach((listener) => listener());
  }

  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
}
