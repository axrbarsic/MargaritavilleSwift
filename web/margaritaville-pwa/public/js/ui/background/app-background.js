// Единая точка живого фона: создаёт нужный режим, гасит его, когда приложение скрыто
// или поверх открыт непрозрачный экран. Источник: App/AppBackgroundView.swift,
// AppBackgroundPresence.swift.
import { MatrixRain } from "./matrix-rain.js";
import { TVStatic } from "./tv-static.js";
import { Brooklyn } from "./brooklyn.js";
import { CameraBackground, VideoBackground } from "./media-backgrounds.js";
import { tr } from "../../i18n/i18n.js";

const MODES = { matrixRain: MatrixRain, tvStaticNoise: TVStatic, video: VideoBackground, brooklyn: Brooklyn, camera: CameraBackground };

export const BACKGROUND_MODES = [
  { id: "off", title: tr("Выкл"), description: tr("Чёрный фон") },
  { id: "matrixRain", title: "Matrix", description: "Matrix Rain" },
  { id: "tvStaticNoise", title: "TV", description: tr("Сломанный телевизор") },
  { id: "video", title: tr("Видео"), description: tr("Видео фон") },
  { id: "brooklyn", title: "Brooklyn", description: "Brooklyn 3D" },
  { id: "camera", title: tr("Камера"), description: tr("Задняя камера") }
];

/// Камера как фон — тестовая функция: без переключателя в «Для разработчика» её нет в списке.
export const availableModes = (settings) =>
  BACKGROUND_MODES.filter((m) => m.id !== "camera" || settings.get("cameraBackgroundEnabled"));

/// Режим, который реально работает: выбранная камера при выключенной функции заменяется на Matrix,
/// а сам выбор сохраняется — после включения камера вернётся.
export function effectiveMode(settings) {
  const mode = settings.get("appBackgroundMode");
  if (!MODES[mode]) return "off";
  return mode === "camera" && !settings.get("cameraBackgroundEnabled") ? "matrixRain" : mode;
}

export class AppBackground {
  constructor(container, settings) {
    this.container = container;
    this.settings = settings;
    this.mode = null;
    this.layer = null;
    this.visible = !document.hidden;
    this.occluders = 0;
  }

  update() {
    const mode = effectiveMode(this.settings);
    if (mode !== this.mode) {
      this.layer?.destroy();
      this.layer = mode === "off" ? null : new MODES[mode](this.container, this.settings);
      this.mode = mode;
    }
    this.layer?.apply?.();
    this.sync();
  }

  /// Видео-фон после выбора нового файла.
  reloadVideo() { if (this.mode === "video") this.layer.loadVideo(); }

  setVisible(visible) {
    this.visible = visible;
    this.sync();
  }

  /// Экран поверх (просмотр медиа, камера съёмки) закрывает фон — его анимация не нужна.
  occlude(delta) {
    this.occluders = Math.max(0, this.occluders + delta);
    this.sync();
  }

  sync() {
    if (!this.layer) return;
    if (this.visible && this.occluders === 0) this.layer.start();
    else this.layer.stop();
  }
}
