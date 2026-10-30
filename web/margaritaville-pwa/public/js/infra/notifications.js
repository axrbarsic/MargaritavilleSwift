// Уведомления о назначенном времени: «Room 306 opened at 4:30 PM». Работают, пока
// приложение запущено (в PWA нет локальных отложенных уведомлений без сервера).
// Источник: Infrastructure/Notifications/ScheduleNotificationService.swift.
import { formatTime } from "../ui/dom.js";

export class ScheduleNotifications {
  constructor() {
    this.timers = new Map();
  }

  requestPermission() {
    if (!("Notification" in window) || Notification.permission !== "default") return;
    Notification.requestPermission().catch(() => {});
  }

  schedule(roomID, dueAt) {
    this.cancel(roomID);
    this.requestPermission();
    const delay = dueAt - Date.now();
    if (delay <= 0 || delay > 2 ** 31 - 1) return;
    this.timers.set(roomID, setTimeout(() => this.show(roomID, dueAt), delay));
  }

  cancel(roomID) {
    clearTimeout(this.timers.get(roomID));
    this.timers.delete(roomID);
  }

  async show(roomID, dueAt) {
    this.timers.delete(roomID);
    if (!("Notification" in window) || Notification.permission !== "granted") return;
    const body = `Room ${roomID} opened at ${formatTime(dueAt)}`;
    try {
      const registration = await navigator.serviceWorker?.getRegistration();
      if (registration) await registration.showNotification("Margaritaville", { body, tag: `margaritaville.room.schedule.${roomID}`, icon: "icons/icon-192.png" });
      else new Notification("Margaritaville", { body });
    } catch {
      // Уведомления недоступны — комната всё равно откроется по таймеру.
    }
  }

  /// Восстановить таймеры после запуска по сохранённой смене.
  restore(carts) {
    for (const cart of carts) for (const room of cart.rooms) if (room.scheduledTime != null) this.schedule(room.id, room.scheduledTime);
  }
}
