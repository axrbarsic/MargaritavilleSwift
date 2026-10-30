// Загрузчик: сначала высота экрана и словарь выбранного языка, потом приложение — так все
// подписи модулей уже на нужном языке в момент импорта.
import { loadLanguage, preferredLanguage } from "./i18n/i18n.js";
import { fitViewport } from "./infra/viewport.js";

fitViewport();
await loadLanguage(preferredLanguage());
await import("./app.js");
