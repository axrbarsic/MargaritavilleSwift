// Хранилище на устройстве (IndexedDB): снимок смены «current», как PersistentWorkSession,
// и файлы медиа (фото, видео, голос), как LocalMediaFileStore. Данные никуда не отправляются.

const DB_NAME = "margaritaville";
const STORES = ["workSession", "media", "files"];
let opening = null;

function open() {
  opening ??= new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 2);
    request.onupgradeneeded = () => {
      for (const name of STORES) {
        if (!request.result.objectStoreNames.contains(name)) request.result.createObjectStore(name);
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => { opening = null; reject(request.error); };
  });
  return opening;
}

async function get(store, key) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const request = db.transaction(store, "readonly").objectStore(store).get(key);
    request.onsuccess = () => resolve(request.result ?? null);
    request.onerror = () => reject(request.error);
  });
}

async function write(store, mutate) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(store, "readwrite");
    mutate(transaction.objectStore(store));
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error);
  });
}

export const loadSnapshot = () => get("workSession", "current");
export const saveSnapshot = (snapshot) => write("workSession", (s) => s.put(snapshot, "current"));

/// Файлы медиа хранятся под ключом relativePath вложения.
export const loadMedia = (key) => get("media", key);
export const saveMedia = (key, blob) => write("media", (s) => s.put(blob, key));
export const deleteMedia = (key) => write("media", (s) => s.delete(key));

/// Прочие файлы (видео фона и т. п.).
export const loadFile = (key) => get("files", key);
export const saveFile = (key, blob) => write("files", (s) => s.put(blob, key));
export const deleteFile = (key) => write("files", (s) => s.delete(key));
