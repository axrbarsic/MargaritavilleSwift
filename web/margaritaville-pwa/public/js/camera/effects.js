// Эффекты, категории и настройки — копия моделей iOS-приложения:
// CameraBackgroundEffect.swift, CameraEffectCategory.swift, CameraEffectTuning.swift.
import { tr } from "../i18n/i18n.js";

export const EFFECTS = {
  normal: { title: tr("Обычный"), shader: 0, subtitle: tr("Чистое изображение камеры.") },
  matte: { title: tr("Матовый"), shader: 1, prefilter: "blur", subtitle: tr("Матовое стекло: сильное размытие с лёгким зерном.") },
  grid: { title: tr("Сетка"), shader: 2, subtitle: tr("Камера под неоновой сеткой с бегущей строкой сканирования.") },
  kaleidoscope: { title: tr("Калейдоскоп"), shader: 14, subtitle: tr("Восемь зеркальных секторов, медленно вращаются.") },
  glitch: { title: tr("Глитч"), shader: 15, subtitle: tr("Цифровой сбой: сдвиг полос, разделение каналов и вспышки.") },
  nightVision: { title: tr("Ночное видение"), shader: 3, subtitle: tr("Зелёный прибор ночного видения с шумом и виньеткой.") },
  thermal: { title: tr("Тепловизор"), shader: 4, subtitle: tr("Яркость превращается в тепловую карту.") },
  pixels: { title: tr("Пиксели"), shader: 7, subtitle: tr("Крупная пиксельная мозаика.") },
  gameBoy: { title: "Game Boy", shader: 11, subtitle: tr("Экран Game Boy: крупные пиксели и четыре оттенка зелёного.") },
  lego: { title: tr("Лего"), shader: 17, subtitle: tr("Всё вокруг собрано из кубиков Лего с шипами в цветах настоящих деталей.") },
  ascii: { title: "ASCII", shader: 8, subtitle: tr("Живое видео из символов, цвет берётся из камеры.") },
  crt: { title: tr("ЭЛТ-телевизор"), shader: 12, subtitle: tr("Выпуклый кинескоп с развёрткой, сдвигом цветов и маской триад.") },
  dither: { title: tr("1-бит"), shader: 9, subtitle: tr("Двухцветный дизеринг Байера в стиле игры Return of the Obra Dinn.") },
  halftone: { title: tr("Полутон"), shader: 10, subtitle: tr("Печатный растр CMYK, как в старых газетах и комиксах.") },
  comic: { title: tr("Комикс"), shader: 6, subtitle: tr("Плоские цвета и чёрные контуры, как в комиксе.") },
  cartoon: { title: tr("Мультфильм"), shader: 16, prefilter: "median", subtitle: tr("Мир как в мультфильме: гладкие заливки, сочные цвета и чёткие контуры.") },
  sketch: { title: tr("Карандаш"), shader: 13, subtitle: tr("Карандашная перекрёстная штриховка по теням и контуры.") },
  blueprint: { title: tr("Чертёж"), shader: 21, subtitle: tr("Белые линии на синем листе с миллиметровой сеткой, как технический чертёж.") },
  chalk: { title: tr("Мел"), shader: 22, subtitle: tr("Рваные меловые штрихи по контурам на школьной доске.") },
  neon: { title: tr("Неон"), shader: 19, subtitle: tr("Переливающиеся неоновые контуры; ползунок «Ореол» добавляет свечение.") },
  neonShadow: { title: tr("Неоновая тень"), shader: 18, subtitle: tr("Вирусный эффект TikTok: розовая, голубая и жёлтая копии контура расходятся и сходятся.") },
  tron: { title: tr("Трон"), shader: 20, subtitle: tr("Голубые и оранжевые световые контуры на тёмной сетке, как в «Троне».") },
  electric: { title: tr("Электричество"), shader: 23, subtitle: tr("Дрожащие фиолетовые разряды с белой сердцевиной.") },
  emboss: { title: tr("Тиснение"), shader: 24, subtitle: tr("Серый рельеф, будто изображение выдавлено в листе.") },
  metal: { title: tr("Металл"), shader: 25, subtitle: tr("Чеканка на металле любого цвета: от серебра до золота, меди и синей стали.") },
  periodicMetals: { title: tr("Таблица металлов"), shader: 26, prefilter: "median", subtitle: tr("Каждый участок кадра становится металлом своего цвета: медь, золото, патина, титан, висмут, серебро и другие.") },
  stoneRelief: { title: tr("Камень"), shader: 28, subtitle: tr("Изображение высечено в шершавом песчанике.") },
  paperRelief: { title: tr("Бумага"), shader: 29, subtitle: tr("Слепое тиснение белым по белому, как на дорогой открытке.") },
  woodRelief: { title: tr("Дерево"), shader: 30, subtitle: tr("Резьба по доске с годичными волокнами.") }
};

export const CATEGORIES = [
  { id: "classic", title: tr("Классика"), icon: "camera", effects: ["normal", "matte", "grid", "kaleidoscope", "glitch"] },
  { id: "vision", title: tr("Приборы"), icon: "eye", effects: ["nightVision", "thermal"] },
  { id: "pixels", title: tr("Пиксели"), icon: "grid", effects: ["pixels", "gameBoy", "lego", "ascii"] },
  { id: "retro", title: tr("Ретро"), icon: "tv", effects: ["crt", "dither", "halftone"] },
  { id: "drawing", title: tr("Рисунок"), icon: "pencil", effects: ["comic", "cartoon", "sketch", "blueprint", "chalk"] },
  { id: "neon", title: tr("Неон"), icon: "bolt", effects: ["neon", "neonShadow", "tron", "electric"] },
  { id: "relief", title: tr("Рельеф"), icon: "mountain", effects: ["emboss", "metal", "periodicMetals", "stoneRelief", "paperRelief", "woodRelief"] }
];

export function categoryOf(effectId) {
  return CATEGORIES.find((c) => c.effects.includes(effectId)) ?? CATEGORIES[0];
}

const RELIEF = new Set(["emboss", "metal", "periodicMetals", "stoneRelief", "paperRelief", "woodRelief"]);
const EDGES = new Set(["comic", "sketch", "cartoon", "neon", "neonShadow", "tron", "blueprint", "chalk", "electric"]);
const DETAIL = new Set(["grid", "pixels", "ascii", "dither", "halftone", "gameBoy", "lego", "sketch", "blueprint"]);

export const uses = {
  amount: (id) => id !== "normal",
  relief: (id) => RELIEF.has(id),
  edges: (id) => EDGES.has(id),
  detail: (id) => DETAIL.has(id),
  metalColor: (id) => id === "metal",
  glow: (id) => id === "neon"
};

export const TUNING_DEFAULTS = {
  amount: 1,
  brightness: 1,
  reliefDepth: 1,
  lightAngle: 225,
  edgeSensitivity: 1,
  detailScale: 1,
  metalHue: 42,
  metalSaturation: 0.75,
  liveLight: false,
  glowAmount: 0.5
};

export const RANGES = {
  amount: [0, 1],
  brightness: [0.5, 1.6],
  reliefDepth: [0.25, 3],
  lightAngle: [0, 360],
  edgeSensitivity: [0.4, 2.5],
  detailScale: [0.5, 2],
  metalHue: [0, 360],
  metalSaturation: [0, 1],
  glowAmount: [0, 1]
};

/// Понятное имя металла под ползунком цвета (metalName в приложении).
export function metalName(hue, saturation) {
  if (saturation < 0.12) return tr("Серебро");
  if (hue < 20) return tr("Медь");
  if (hue < 50) return tr("Золото");
  if (hue < 75) return tr("Латунь");
  if (hue < 160) return tr("Зелёная патина");
  if (hue < 250) return tr("Синяя сталь");
  if (hue < 320) return tr("Фиолетовый титан");
  return tr("Розовое золото");
}
