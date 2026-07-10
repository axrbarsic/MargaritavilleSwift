# Стартовый prompt для новой сессии: Margaritaville Flutter

Скопируй в новую Codex-сессию весь текст ниже. Рабочую папку новой сессии лучше
сразу открыть как `/Users/alex/Developer`, чтобы агент видел Swift-эталон,
migration-документы и новый соседний Flutter-проект.

---

Ты начинаешь отдельную долгую задачу: профессиональный перенос самостоятельного
iOS-приложения Margaritaville с нативного Swift/SwiftUI на Flutter без заметной
потери визуального, тактильного и медиа-качества.

Отвечай мне и пиши все видимые служебные заголовки/progress summaries только на
русском языке. Не останавливайся после анализа или плана: после быстрой
ориентации реализуй первый проверяемый checkpoint, проверь его и продолжай
к следующему шагу, пока не возникнет реальный внешний блокер.

## Пути И Текущее Состояние

- Рабочий корень: `/Users/alex/Developer`.
- Текущий эталон продукта: `/Users/alex/Developer/MargaritavilleSwift`.
- Swift-ветка: `codex/restore-pre-xhotel-margaritaville`.
- Актуальный Swift checkpoint на старте: commit `d0344ba`, build 37.
- Bundle ID текущего production-like Swift-приложения:
  `com.alex.margaritaville.swift`.
- Новый Flutter-проект должен жить отдельно:
  `/Users/alex/Developer/MargaritavilleFlutter`.
- Старое `/Users/alex/Developer/OceanKeyFlutterRun` больше не относится к
  текущей работе: это архив Ocean, который не нужно читать или изменять без
  отдельной прямой просьбы Alex.
- OceanKey Swift остаётся отдельным приложением:
  `/Users/alex/Developer/OceanKeySwift`.
- Физический iPhone 17 Pro Max для проверки:
  - CoreDevice UUID: `81B4DF0D-A9BE-5131-93C8-8247618F9428`;
  - Xcode UDID: `00008150-001418301E68C01C`.

Каталог `MargaritavilleFlutter` уже создан как чистый iOS Flutter scaffold с
beta identity, iOS 17, собственным git-репозиторием и project-local
`AGENTS.md`. Не создавай его заново: сначала прочитай текущее состояние и
продолжай существующий проект.

## Сначала Прочитать

1. `/Users/alex/Developer/MargaritavilleSwift/AGENTS.md`
2. `/Users/alex/Developer/MargaritavilleSwift/Docs/FlutterMigrationFeasibility.md`
3. `/Users/alex/Developer/MargaritavilleSwift/Docs/SessionRecoveryHandoff.md`
4. `/Users/alex/Developer/MargaritavilleSwift/Docs/SharedFoundationPlan.md`
5. `/Users/alex/Developer/MargaritavilleSwift/Docs/MigrationPlan.md`
6. `/Users/alex/Developer/MargaritavilleSwift/Docs/FlutterParityPlan.md`
7. Текущие `git status`, `git log`, `project.yml`, доменные модели, persistence,
   summary UI, visual effects, media и interaction infrastructure Swift-проекта.

Некоторые старые документы могут содержать устаревшие номера build. Текущий
код, git log и build 37 приоритетнее старых снимков.

## Главный Контракт

Переноси идею, поведение, доменные правила и визуальное восприятие, а не форму
Swift-кода. Flutter-реализация должна быть идиоматичной и модульной.

Нельзя:

- превращать SwiftUI-файлы в механически похожие Dart widgets;
- строить домен на `ChangeNotifier`, callback-цепочках или огромных God-файлах;
- хранить критичную смену целым JSON в SharedPreferences;
- открывать SwiftData store напрямую из Dart/Drift;
- использовать старый `OceanKeyFlutterRun` как источник, зависимость или
  архитектурный фундамент;
- редактировать `OceanKeyFlutterRun`, `OceanKeySwift` или Swift-эталон без
  конкретной необходимости и явно ограниченного migration-contract изменения;
- использовать production bundle ID до безопасного cutover;
- считать белый glow заменой настоящего HDR/EDR;
- создавать отдельный ticker/controller на каждую комнатную ячейку;
- создавать отдельный iOS `PlatformView` для каждой VIP-ячейки;
- проверять финальное качество только в симуляторе.

Swift-репозиторий сейчас может иметь локальные `AGENTS.md`, `.build` и
`Docs/SessionRecoveryHandoff.md`. Не сбрасывай, не удаляй и не коммить чужие
незавершённые изменения.

## Целевая Архитектура

Используй feature-first Clean Architecture:

```text
Flutter features
  -> application commands/use-cases
  -> pure Dart domain
  -> repository contracts
  -> Drift/local files/sync adapters/iOS bridge
```

Базовые модули:

- `domain`
- `application`
- `local_data`
- `sync_contract`
- `visual_runtime`
- `margaritaville_ios_bridge`
- feature-модули `work_setup`, `summary`, `room_details`, `cart_details`,
  `history`, `settings` и `media`.

Предпочтительный фундамент:

- Riverpod `Notifier`/`AsyncNotifier` для состояния и DI;
- Drift/SQLite для транзакционной локальной БД и schema migrations;
- immutable value models и явные commands;
- Pigeon или другой типизированный контракт для Dart/Swift bridge;
- единый visual runtime/frame clock с visibility gating, thermal/low-power
  governor и бюджетом кадра;
- local-first repository как единый источник истины;
- media-файлы local-only по умолчанию.

## Нативная iOS Граница Внутри Flutter

Flutter-приложение имеет право и должно использовать узкие Swift-плагины там,
где это сохраняет Apple-quality:

- один прозрачный EDR `CALayer` поверх Flutter для всех видимых VIP-ячеек и
  одноразовых HDR-вспышек;
- `AVPlayerLayer`/нативный container для тяжёлого видеофона и HDR playback;
- единый владелец `AVAudioSession`;
- AAC 44,1 кГц mono и файловый `SFSpeechURLRecognitionRequest`;
- точные UIKit haptics и существующий пул SFX;
- CloudKit/`CKSyncEngine` adapter поверх явного versioned sync contract.

Не передавай значения анимации через platform channel каждый кадр. Dart должен
передавать нативному EDR runtime геометрию видимых ячеек, статус/цвет и
одноразовые pulse events; нативная сторона сама ведёт временную кривую.

Для Android позднее потребуется Kotlin-аналог или явно согласованный SDR
fallback. Первый migration track — iPhone; Android/Web пока не должны ухудшать
iOS-архитектуру.

## Что Нужно Сохранить

- Margaritaville simple-cycle workflow, назначение уборщиц и всех номеров.
- Статусы, timestamps, scheduled transitions, VIP, carts и consumables.
- Историю, заметки, фото, видео, голос и файловую transcription.
- Настройки, диагностику, changelog и тестовый генератор назначений.
- Жесты: long press не срабатывает во время вертикального скролла.
- HDR-события одноразовые и не воспроизводятся повторно после recycling ячейки.
- VIP HDR/EDR использует цвет текущего статуса, а не белый блик.
- HDR flash: плавный нагрев, пик и длинное двухсекундное охлаждение.
- Rubber pulse: inflate-first, центрированный, одинаковый слева и справа,
  амплитуда 1,7x и общий timeline с HDR.
- VIP jelly/deformation, Matrix Rain, пять TV-noise режимов, video wallpaper,
  haptics и SFX.
- Фото/видео viewer, zoom, previews и корректный lifecycle ресурсов.

## Данные И Cutover

До двухсторонней синхронизации зафиксируй canonical schema v2:

- явная `RoomPhase`, без скрытого кодирования зелёного статуса заполнением S/L/B;
- field timestamps;
- tombstones для удалений;
- versioned event/command IDs;
- history/audit projection;
- sync outbox/inbox;
- media manifest с origin device, checksum, updatedAt и deletion state.

Нужен отдельный Swift export bridge или versioned JSON/manifest для переноса из
SwiftData. Импорт Flutter должен быть идемпотентным, проверяемым и сохранять
rollback-архив. Сначала Flutter beta работает с отдельным bundle ID, например
`com.alex.margaritaville.flutter.beta`, и не становится вторым writer того же
production store до общего sync protocol и двухустройственных тестов.

## Очередность Работы

1. Preflight: disk guard, инструменты, текущие репозитории, версии Flutter/Dart,
   Xcode и доступность физического iPhone.
2. Создать или продолжить отдельный `MargaritavilleFlutter`, отдельный git repo
   и beta app identity.
3. Добавить `AGENTS.md`, migration log, архитектурные границы и quality gates.
4. Зафиксировать canonical domain/schema v2 и Swift-to-Dart golden fixtures.
5. Реализовать pure Dart domain/application commands и contract tests.
6. Поднять Drift schema/migrations/repositories.
7. Реализовать setup и summary на fixture/local data без тяжёлых эффектов.
8. Перенести details, history, settings и test-data workflow.
9. Добавить media/audio/Speech через Flutter UI и узкий Swift bridge.
10. Реализовать общий visual runtime, затем Matrix/TV noise/jelly/rubber.
11. Реализовать единый Swift EDR overlay и HDR pulse events.
12. Добавить export/import, shadow comparison, sync protocol и cutover gates.

Ранний технический spike EDR обязателен: не откладывай проверку единого
нативного overlay до конца всей миграции. Но не позволяй эффектам опередить
canonical domain и persistence contracts.

## Первый Проверяемый Checkpoint

После чтения контекста не выдавай только отчёт. В первой сессии:

1. Создай новый Flutter project/repo, если его ещё нет.
2. Настрой отдельную beta identity и iOS minimum deployment target не ниже 17.
3. Создай модульный skeleton и project-local `AGENTS.md`.
4. Реализуй первую версию canonical Dart domain для hotel/work session,
   housekeeper assignment, room phase, timestamps, VIP и carts.
5. Добавь contract fixtures и unit tests на основные status transitions,
   duplicate-room blocking и simple-cycle.
6. Подними минимальную Drift schema и проверяемую migration strategy либо, если
   это слишком велико для одного checkpoint, сначала зафиксируй schema SQL и
   реализуй первую транзакционную вертикаль repository.
7. Собери и запусти минимальное приложение на физическом iPhone.
8. Сделай commit и push, затем продолжи следующий пункт critical path.

Не трать первый checkpoint на декоративный landing screen. Первый экран должен
быть началом реального рабочего приложения или честным operational shell,
подключённым к настоящему domain state.

## Проверка Качества

- Только физический iPhone для итоговой UI/performance проверки.
- После shader warm-up P95 frame time должен укладываться в 8,33 мс для 120 Гц.
- Геометрия относительно Swift baseline: расхождение не более 1 pt.
- Цветовой ориентир: `Delta E <= 3` на контрольных состояниях.
- Проверять одновременно Matrix + несколько jelly/HDR-ячеек + video background.
- Фото/видео не должны терять разрешение/bitrate относительно baseline.
- Speech сверять на общей контрольной выборке AAC-файлов.
- Обязательны kill/restart, low-memory, low-disk, offline, interruption и
  двухустройственные sync tests перед production cutover.
- Для Wi-Fi установки прочитай
  `/Users/alex/Developer/MargaritavilleSwift/Docs/DeviceWiFiInstallRunbook.md`.

Перед тяжёлыми сборками запускай:

```sh
~/.codex/tools/disk_guard.sh --force
```

Не используй симулятор без моего прямого разрешения. Не проси у меня скриншот,
пока проблему можно воспроизвести и снять локально на физическом устройстве.
Используй sub-agent'ов для параллельного аудита/контрактов/визуального spike,
если это ускоряет работу без дублирования критического пути.

Каждый существенный блок: format, analyze, tests, independence/size guards,
физическая сборка, commit, push и запись в migration log. Не коммить секреты,
DerivedData и чужие изменения.

Начинай сейчас: сначала коротко сообщи, что прочитал и какой checkpoint берёшь,
затем выполняй работу до проверяемого результата.

---
