// Сервис-воркер: держит оболочку приложения в кэше, чтобы оно открывалось без сети.
// При обновлении версии старый кэш удаляется. Данные смены живут в IndexedDB.
const CACHE = "margaritaville-pwa-v8";
const SHELL = [
  "./",
  "brooklyn/BrooklynDonorMesh.bin",
  "brooklyn/environment.json",
  "brooklyn/tex0.png",
  "brooklyn/tex1.png",
  "data/ios-changelog.json",
  "i18n/en.json",
  "i18n/es.json",
  "i18n/ht.json",
  "i18n/jam.json",
  "i18n/uk.json",
  "icons/icon-180.png",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "index.html",
  "js/app.js",
  "js/boot.js",
  "js/camera/controls.js",
  "js/camera/effects.js",
  "js/camera/renderer.js",
  "js/camera/shaders-common.js",
  "js/camera/shaders-effects.js",
  "js/camera/shaders-relief.js",
  "js/domain/catalog.js",
  "js/domain/consumables.js",
  "js/domain/housekeepers.js",
  "js/domain/room.js",
  "js/domain/selection.js",
  "js/domain/summary-grouping.js",
  "js/i18n/i18n.js",
  "js/infra/feedback.js",
  "js/infra/media-files.js",
  "js/infra/notifications.js",
  "js/infra/viewport.js",
  "js/infra/updates.js",
  "js/infra/voice.js",
  "js/store/db.js",
  "js/store/session-store-carts.js",
  "js/store/session-store.js",
  "js/store/settings-store.js",
  "js/ui/background/app-background.js",
  "js/ui/background/brooklyn-shaders.js",
  "js/ui/background/brooklyn.js",
  "js/ui/background/matrix-rain.js",
  "js/ui/background/media-backgrounds.js",
  "js/ui/background/tv-static.js",
  "js/ui/cart-details.js",
  "js/ui/consumables-view.js",
  "js/ui/dom.js",
  "js/ui/icons.js",
  "js/ui/media-views.js",
  "js/ui/number-fit.js",
  "js/ui/room-details.js",
  "js/ui/room-tile.js",
  "js/ui/room-zoom.js",
  "js/ui/screen-stack.js",
  "js/ui/settings/changelog-screen.js",
  "js/ui/settings/settings-background.js",
  "js/ui/settings/settings-controls.js",
  "js/ui/settings/settings-language.js",
  "js/ui/settings/settings-screen.js",
  "js/ui/settings/settings-work.js",
  "js/ui/settings/typography-lab.js",
  "js/ui/setup-view.js",
  "js/ui/sheets.js",
  "js/ui/summary-header.js",
  "js/ui/summary-view.js",
  "js/ui/vip-jelly.js",
  "js/ui/voice-panel.js",
  "manifest.webmanifest",
  "sounds/click.wav",
  "sounds/front_desk_bell_real.wav",
  "sounds/kenney_bong_001.wav",
  "sounds/kenney_confirmation_001.wav",
  "sounds/kenney_confirmation_002.wav",
  "sounds/kenney_confirmation_003.wav",
  "sounds/kenney_confirmation_004.wav",
  "sounds/kenney_select_001.wav",
  "sounds/kenney_select_002.wav",
  "sounds/kenney_select_003.wav",
  "sounds/kenney_select_004.wav",
  "sounds/kenney_tick_001.wav",
  "sounds/pressed.wav",
  "sounds/room_complete_hotel_bell.wav",
  "sounds/xhotel_ui_alert_snap.wav",
  "sounds/xhotel_ui_click_bright.wav",
  "sounds/xhotel_ui_click_soft.wav",
  "sounds/xhotel_ui_confirm_glass.wav",
  "sounds/xhotel_ui_confirm_pop.wav",
  "sounds/xhotel_ui_error_low.wav",
  "sounds/xhotel_ui_menu_open.wav",
  "sounds/xhotel_ui_rollover_tick.wav",
  "sounds/xhotel_ui_switch_deep.wav",
  "sounds/xhotel_ui_switch_light.wav",
  "styles-screens.css",
  "styles-settings.css",
  "styles.css"
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
    // no-cache: всегда сверяемся с сервером, а не с HTTP-кэшем браузера
    // (запрос навигации пересоздать нельзя, у index.html и так заголовок no-cache).
    fetch(event.request.mode === "navigate" ? event.request : new Request(event.request, { cache: "no-cache" }))
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached ?? caches.match("index.html")))
  );
});
