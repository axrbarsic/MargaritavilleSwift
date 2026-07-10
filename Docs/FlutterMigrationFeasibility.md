# Оценка полного переноса MargaritavilleSwift на Flutter

Дата аудита: 2026-07-09

## Вывод

Полный перенос реалистичен. Фундаментального ограничения Flutter, которое
запрещало бы сохранить продуктовый контракт приложения, нет. Однако требование
сохранить HDR/EDR, визуальные эффекты, медиа и тактильную отдачу без заметного
ухудшения исключает вариант «только Dart».

Рекомендуемая цель:

- Flutter/Impeller владеет UI, навигацией, доменом, настройками и локальной БД.
- Один общий visual runtime управляет frame clock, видимостью, thermal/low-power
  деградацией и бюджетом 8,33 мс для 120 Гц.
- Узкий iOS bridge на Swift владеет EDR/HDR compositor layer, общей
  `AVAudioSession`, файловым Speech, точными haptics/SFX, чувствительным
  `AVPlayer` lifecycle и CloudKit.
- Нативные модули имеют типизированные Pigeon-контракты. Никакие значения
  анимации не передаются через platform channel каждый кадр.

Гибридный путь способен дать примерно 90-95% perceptual parity. Абсолютная
pixel parity между SwiftUI/Core Animation и Flutter невозможна из-за отличий
растеризации текста, blur и spring-интеграции, но результат можно сделать
практически неотличимым на физическом iPhone.

## Границы Переноса

### Flutter

- Feature-first экраны `work_setup`, `summary`, `room_details`, `cart_details`,
  `history`, `settings`.
- Pure Dart domain и application commands вместо переноса Swift-формы кода.
- Riverpod `Notifier`/`AsyncNotifier` для состояния.
- Drift/SQLite для нормализованных rooms, carts, history, settings catalogs,
  tombstones и sync outbox.
- `FragmentProgram`, `AnimatedSampler`, `CustomPainter` и общий frame clock для
  jelly, rubber, Matrix и процедурного TV noise.
- Камера, viewer и notifications через Flutter API там, где они сохраняют
  исходный контракт.

### Swift iOS Bridge

- Один прозрачный EDR `CALayer` поверх Flutter для всех видимых VIP-ячеек и
  одноразовых HDR-вспышек. Не создавать `PlatformView` на каждую ячейку.
- Нативный `AVPlayerLayer` для тяжёлого видеофона и полноэкранного HDR-видео.
- Единый владелец `AVAudioSession`, AAC 44,1 кГц mono и файловый
  `SFSpeechURLRecognitionRequest`.
- Точные UIKit haptics и существующий пул коротких звуков.
- CloudKit/`CKSyncEngine` adapter поверх явного versioned sync contract.

## Матрица Качества

| Возможность | Целевой путь | Риск |
| --- | --- | --- |
| VIP HDR/EDR и HDR-вспышка | Единый Swift EDR overlay, события из Dart | Критический без bridge, низкий с ним |
| VIP jelly | Flutter fragment shader/SDF | Средний при множестве VIP |
| Rubber/live cells | Общий frame clock + `SpringSimulation` | Средний |
| Matrix Rain | Impeller `drawAtlas`, существующий Flutter reference | Низкий |
| Пять TV-noise фонов | Процедурный fragment shader | Средний |
| Видео-заставка | Native AVPlayer container | Средний |
| Фото/видео и viewer | Flutter UI + точечный iOS adapter | Низкий-средний |
| Голос и transcription | Swift audio/Speech plugin | Низкий после device QA |
| Haptics и SFX | Swift feedback plugin | Низкий |
| 120 Гц | Общий runtime и profile/release QA | Средний |

Текущий EDR-контракт использует 16-bit float layer, P3 и headroom в
`MargaritavilleSwift/Features/Summary/VIPHDREffects.swift`. Публичный Flutter
shader не заменяет `CALayer.preferredDynamicRange` и `contentsHeadroom`, поэтому
белый glow нельзя считать HDR-паритетом.

## Данные И Совместимость

Flutter-референс нельзя использовать как persistence-фундамент: критичные
данные не должны храниться полным JSON в SharedPreferences. Целевой source of
truth — Drift/SQLite с транзакциями и schema migrations.

SwiftData store нельзя напрямую открыть из Drift. До cutover нужен Swift-релиз,
который экспортирует versioned manifest: snapshot, settings, presets, media,
background assets и SHA-256. Импорт Flutter должен быть идемпотентным и хранить
rollback-архив.

Перед параллельной записью нужно исправить существующие sync-инварианты:

- `catalogOverrides` и `dayCategory` сейчас не полностью участвуют в merge.
- Удаления notes/media/tasks не имеют устойчивых tombstones.
- Repository `save()` не возвращает подтверждённый результат записи.
- История является audit trail, но не replayable event log.
- Физический iPhone сейчас работает в `.localOnly`; CloudKit device entitlement
  ещё не является production-контрактом.

## Этапы

1. Зафиксировать canonical schema v2, команды и golden Swift-to-JSON fixtures.
2. Исправить merge, tombstones и подтверждение persistence в текущем Swift.
3. Реализовать Dart domain/application и contract tests с теми же fixtures.
4. Поднять Drift schema, migration runner, file manifest и outbox.
5. Перенести setup, summary, details, history и settings без тяжёлых эффектов.
6. Реализовать visual runtime и Swift EDR/audio/media bridge.
7. Выпустить Flutter beta с отдельным bundle ID в read-only/shadow режиме.
8. Разрешить два writer только после общего sync protocol и device matrix tests.
9. Выполнить production cutover с идемпотентным импортом и rollback-архивом.

## Паритетные Гейты

- Одинаковые command fixtures дают одинаковые статусы, timestamps, selections,
  carts, consumables и history IDs.
- Kill/restart после каждой мутации не теряет подтверждённую операцию.
- Геометрия отличается не более чем на 1 pt, цвета — `Delta E <= 3`.
- После shader warm-up P95 frame time не превышает 8,33 мс на 120 Гц.
- Matrix + несколько jelly/HDR-ячеек + video проверяются одновременно в
  profile/release на физическом iPhone.
- Фото/видео не теряют разрешение и bitrate; аудио остаётся AAC 44,1 кГц mono.
- Speech сверяется на общей контрольной выборке записей.
- Sync проверяется на двух iPhone: offline edits, clock skew, удаления, schedules,
  catalog overrides, media metadata и повторная доставка событий.

## Трудоёмкость

Ориентир полного production cutover: 26-40 человеко-недель при выборочном
переиспользовании уже существующих Flutter shaders/media UI/native Speech или
31-48 человеко-недель при построении заново. Для двух сильных Flutter+iOS
инженеров это примерно 4-6 календарных месяцев. Android/Web с отдельными
fallback-политиками добавят примерно 30-50% к визуально-платформенному объёму.

Оценки визуального и медиа слоёв частично перекрываются и не должны механически
складываться.
