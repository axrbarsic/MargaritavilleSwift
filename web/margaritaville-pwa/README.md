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
| 1 | Рабочий список (уборщицы, тележки, зоны, номера, занятые номера), сводка по уборщицам, простой цикл статусов по удержанию, меню свайпом (заметка, VIP, время, возврат в жёлтый), назначенное время с автооткрытием, история, хранение на устройстве, защита от затирания при ошибке загрузки, работа без сети | готово |
| 2 | Экраны номера и тележки: заметки, голос с расшифровкой, фото и видео, расходники, отметки выполнения; история событий | далее |
| 3 | Категории дня (Due Out, Stayover…), фильтры и счётчики, увеличение ячейки, точная типографика и геометрия сетки, звуки и вибрация | далее |
| 4 | Настройки целиком: внешний вид, работа, разработчик, редактирование уборщиц и каталога номеров, журнал сборок | далее |
| 5 | Живые фоны: Matrix, ТВ-шум, видео, Brooklyn, камера с 29 эффектами (из `web/camera-effects-lab`), VIP-эффекты ячеек | далее |

## Соответствие исходникам

| PWA | iOS |
|---|---|
| `js/domain/catalog.js` | `Domain/HotelProfile.swift` (каталог Margaritaville), `Domain/RoomCatalog.swift` |
| `js/domain/room.js` | `Domain/RoomModels.swift`, `WorkSessionStore+SimpleCycle.swift` |
| `js/domain/selection.js` | `Domain/WorkSessionSelection.swift` |
| `js/domain/housekeepers.js` | `Domain/HousekeeperCatalog.swift`, `Design/HousekeeperPalette+Color.swift` |
| `js/store/session-store.js` | `Features/WorkSession/WorkSessionStore*.swift` |
| `js/ui/setup-view.js` | `Features/WorkSetup/*` |
| `js/ui/summary-view.js`, `js/ui/sheets.js` | `Features/Summary/*`, `RoomScheduleSheet.swift` |

## Публикация

```bash
cd web/margaritaville-pwa
firebase deploy --only hosting
```

При изменении файлов оболочки увеличить версию кэша `CACHE` в `public/sw.js`.
