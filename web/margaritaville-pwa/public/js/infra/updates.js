// Автообновление установленного PWA. Телефон держит приложение в памяти днями, поэтому
// новую версию проверяем при каждом возврате в приложение и раз в 30 минут. Новый
// сервис-воркер сразу берёт управление (skipWaiting + claim), а страница перезагружается:
// сразу, если пользователь только что открыл приложение, иначе — при следующем возврате.
// Смена к этому моменту уже сохранена: store.flush() срабатывает при уходе в фон.

const CHECK_EVERY_MS = 30 * 60 * 1000;
const FRESH_OPEN_MS = 4000;

export function keepUpdated() {
  if (!("serviceWorker" in navigator)) return;
  const hadController = Boolean(navigator.serviceWorker.controller);
  let visibleAt = performance.now();
  let pending = false;

  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (!hadController) return; // первая установка — страница и так свежая
    if (document.hidden || performance.now() - visibleAt < FRESH_OPEN_MS) location.reload();
    else pending = true;
  });

  navigator.serviceWorker.register("sw.js", { updateViaCache: "none" }).then((registration) => {
    const check = () => registration.update().catch(() => {});
    document.addEventListener("visibilitychange", () => {
      if (document.hidden) return;
      visibleAt = performance.now();
      if (pending) location.reload();
      else check();
    });
    setInterval(check, CHECK_EVERY_MS);
  }).catch(() => {});
}
