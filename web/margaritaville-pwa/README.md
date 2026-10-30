# Margaritaville PWA

Перенос iOS-приложения MargaritavilleSwift в устанавливаемое веб-приложение (PWA)
для любого телефона.

**Адрес:** https://axr-margaritaville.web.app
**Firebase:** проект `axr-camera-effects-lab`, сайт хостинга `axr-margaritaville`

## Установка на телефон

- **iPhone (Safari):** открыть адрес → кнопка «Поделиться» → «На экран „Домой“».
- **Android (Chrome):** открыть адрес → меню → «Установить приложение».

Приложение открывается без адресной строки и работает без интернета. Смена хранится
только на этом телефоне (IndexedDB), как в iOS-приложении, где синхронизация выключена.

## Этапы переноса

| Этап | Что входит | Состояние |
|---|---|---|
| 1 | Рабочий список (уборщицы, тележки, зоны, номера, занятые номера), сводка по уборщицам, цикл статусов, назначенное время, хранение на устройстве, защита от затирания, работа без сети | готово |
| 2 | Экраны комнаты и тележки: текстовая заметка, голос с расшифровкой (Web Speech API), фото и видео через системную камеру, просмотр с листанием, расходники со шкалой 0–10, отметкой выполнения и 5-секундным обнулением; хронология изменений | готово |
| 3 | Сводка как в iOS: точная сетка (масштаб рядов 3/4), типографика ячеек, фильтры-счётчики по статусам, пазл возврата к выбору, свайп-меню, увеличение ячейки с командным центром, бегущая строка и итог расходников, звуки и вибрация | готово |
| 4 | Настройки: внешний вид, звуки, сброс, фон, уборщицы, расходники, каталог номеров, мульти-меню, экспериментальные режимы, тестовые данные, стенд типографики, журнал сборок (PWA + 188 сборок iOS) | готово |
| 5 | Живые фоны: Matrix Rain, сломанный телевизор (5 вариантов), своё видео, Brooklyn 3D (исходный меш, текстуры, HDR-окружение), камера с 29 эффектами; VIP-желе, VIP HDR, HDR-всплеск и пружина ячеек | готово |

### Отличия, которые задаёт платформа

- Уведомления о назначенном времени приходят, только пока приложение открыто: у PWA нет локальных отложенных уведомлений без сервера. Комната всё равно откроется по времени.
- Расшифровка голоса работает там, где браузер даёт Web Speech API (Safari на iOS, Chrome). Без неё голос сохраняется без текста — как в iOS при отказе распознавания.
- Частота кадров живых фонов ограничена браузером (Safari обычно даёт 60 Гц); в Brooklyn упрощено свечение (bloom).
- Синхронизации нет — как и в iOS-приложении, где она выключена.

## Соответствие исходникам

| PWA | iOS |
|---|---|
| `js/domain/catalog.js` | `Domain/HotelProfile.swift` (каталог Margaritaville), `Domain/RoomCatalog.swift` |
| `js/domain/room.js` | `Domain/RoomModels.swift`, `WorkSessionStore+SimpleCycle.swift` |
| `js/domain/selection.js` | `Domain/WorkSessionSelection.swift` |
| `js/domain/housekeepers.js` | `Domain/HousekeeperCatalog.swift`, `Design/HousekeeperPalette+Color.swift` |
| `js/store/session-store.js` | `Features/WorkSession/WorkSessionStore*.swift` |
| `js/ui/setup-view.js` | `Features/WorkSetup/*` |
| `js/ui/summary-view.js`, `summary-header.js`, `room-tile.js`, `room-zoom.js`, `sheets.js` | `Features/Summary/*`, `RoomScheduleSheet.swift` |
| `js/ui/room-details.js`, `cart-details.js`, `consumables-view.js`, `media-views.js`, `voice-panel.js` | `Features/RoomDetails`, `CartDetails`, `Media`, `Notes` |
| `js/domain/consumables.js`, `summary-grouping.js` | `Domain/CartConsumables.swift`, `SummaryConsumablesReport.swift`, `MargaritavilleSummaryRoomGrouping.swift` |
| `js/store/settings-store.js`, `js/ui/settings/*` | `App/AppSettingsStore*.swift`, `Features/Settings/*` |
| `js/infra/feedback.js`, `voice.js`, `media-files.js`, `notifications.js` | `Infrastructure/Interaction`, `Speech`, `Data/LocalMediaFileStore.swift`, `Notifications` |
| `js/ui/background/*`, `js/camera/*` | `App/*Background*.swift`, `Effects/SpriteKit`, `Packages/BrooklynBackgroundKit`, `Effects/Camera` |

## Разработка

```bash
python3 tools/serve.py          # локально без кэша: http://127.0.0.1:8765
python3 tools/gen_ios_changelog.py   # обновить журнал сборок iOS
```

## Публикация

```bash
cd web/margaritaville-pwa
firebase deploy --only hosting
```

При изменении файлов оболочки увеличить версию кэша `CACHE` в `public/sw.js`.
