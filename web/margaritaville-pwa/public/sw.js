// Сервис-воркер: держит оболочку приложения в кэше, чтобы оно открывалось без сети.
// При обновлении версии старый кэш удаляется. Данные смены живут в IndexedDB.
const CACHE = "margaritaville-pwa-v1";
const SHELL = [
  "./",
  "index.html",
  "styles.css",
  "manifest.webmanifest",
  "icons/icon-180.png",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "js/app.js",
  "js/domain/catalog.js",
  "js/domain/housekeepers.js",
  "js/domain/room.js",
  "js/domain/selection.js",
  "js/store/db.js",
  "js/store/session-store.js",
  "js/ui/dom.js",
  "js/ui/setup-view.js",
  "js/ui/summary-view.js",
  "js/ui/sheets.js"
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

// Сначала сеть (чтобы обновления приходили сразу), без сети — кэш.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached ?? caches.match("index.html")))
  );
});
