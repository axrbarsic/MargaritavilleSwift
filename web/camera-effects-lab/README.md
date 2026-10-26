# Лаборатория эффектов камеры Margaritaville

Мобильный сайт с живой демонстрацией всех эффектов фона «Камера» из iOS-приложения
MargaritavilleSwift. Сайт включает заднюю или переднюю камеру телефона и показывает
картинку с выбранным эффектом в реальном времени.

**Сайт:** https://axr-camera-effects-lab.web.app
**Проект Firebase:** `axr-camera-effects-lab` (Firebase Hosting)

## Эффекты (29 в 7 категориях)

| Категория | Эффекты |
|---|---|
| Классика | Обычный, Матовый, Сетка, Калейдоскоп, Глитч |
| Приборы | Ночное видение, Тепловизор |
| Пиксели | Пиксели, Game Boy, Лего, ASCII |
| Ретро | ЭЛТ-телевизор, 1-бит, Полутон |
| Рисунок | Комикс, Мультфильм, Карандаш, Чертёж, Мел |
| Неон | Неон, Неоновая тень, Трон, Электричество |
| Рельеф | Тиснение, Металл, Таблица металлов, Камень, Бумага, Дерево |

Ползунки показываются только у тех эффектов, которые они меняют: сила эффекта и яркость
у всех, глубина рельефа, направление света и «Свет по кругу» у рельефов, цвет и
насыщенность у «Металла», чувствительность контуров у контурных эффектов, размер элементов
у эффектов с ячейками, ореол у «Неона».

## Откуда взяты эффекты

Шейдеры перенесены один к одному с Metal на GLSL ES 3.00 (WebGL 2):

| Сайт | Приложение |
|---|---|
| `public/js/shaders-common.js` | `MargaritavilleSwift/Effects/Camera/CameraEffectsCommon.h` |
| `public/js/shaders-effects.js` | `CameraBackgroundEffects.metal`, `CameraEffectsRetro.h`, `CameraEffectsToy.h`, `CameraEffectsEdges.h` |
| `public/js/shaders-relief.js` | `CameraEffectsRelief.h`, тиснение из `CameraEffectsEdges.h` |
| `public/js/effects.js` | `CameraBackgroundEffect.swift`, `CameraEffectCategory.swift`, `CameraEffectTuning.swift` |
| `public/js/controls.js` | `Features/Settings/CameraEffectControls.swift` |
| `public/js/renderer.js` | `CameraBackgroundRenderer.swift` |

Отличия от приложения:
- «Матовый» размывается отделимым гауссовым фильтром на четверти разрешения (в приложении — MPS).
- «Мультфильм» и «Таблица металлов» сглаживаются двумя проходами медианы 3×3 на половине
  разрешения (в приложении — две медианы MPS диаметром 9).
- `pow(x, 2.0)` заменён на `x * x`: в WebGL `pow` от отрицательного числа не определён.

Изображение с камеры обрабатывается только в браузере и никуда не отправляется.

## Запуск локально

Камера в браузере работает только по HTTPS или на `localhost`:

```bash
cd web/camera-effects-lab/public
python3 -m http.server 8766
```

Затем открыть http://localhost:8766. Без камеры работают демо-сцена и загрузка фото или видео.

Проверка всех эффектов без камеры: из папки `web/camera-effects-lab` запустить
`python3 -m http.server 8767` и открыть http://localhost:8767/tools/render-check.html —
страница рисует каждый эффект на демо-сцене и показывает ошибки WebGL.

## Публикация

```bash
cd web/camera-effects-lab
firebase deploy --only hosting
```

Нужен Firebase CLI с входом в аккаунт владельца проекта (`firebase login:list`).
