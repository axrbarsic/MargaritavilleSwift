// Эффекты, категории и настройки — копия моделей iOS-приложения:
// CameraBackgroundEffect.swift, CameraEffectCategory.swift, CameraEffectTuning.swift.

export const EFFECTS = {
  normal: { title: "Обычный", shader: 0, subtitle: "Чистое изображение камеры." },
  matte: { title: "Матовый", shader: 1, prefilter: "blur", subtitle: "Матовое стекло: сильное размытие с лёгким зерном." },
  grid: { title: "Сетка", shader: 2, subtitle: "Камера под неоновой сеткой с бегущей строкой сканирования." },
  kaleidoscope: { title: "Калейдоскоп", shader: 14, subtitle: "Восемь зеркальных секторов, медленно вращаются." },
  glitch: { title: "Глитч", shader: 15, subtitle: "Цифровой сбой: сдвиг полос, разделение каналов и вспышки." },
  nightVision: { title: "Ночное видение", shader: 3, subtitle: "Зелёный прибор ночного видения с шумом и виньеткой." },
  thermal: { title: "Тепловизор", shader: 4, subtitle: "Яркость превращается в тепловую карту." },
  pixels: { title: "Пиксели", shader: 7, subtitle: "Крупная пиксельная мозаика." },
  gameBoy: { title: "Game Boy", shader: 11, subtitle: "Экран Game Boy: крупные пиксели и четыре оттенка зелёного." },
  lego: { title: "Лего", shader: 17, subtitle: "Всё вокруг собрано из кубиков Лего с шипами в цветах настоящих деталей." },
  ascii: { title: "ASCII", shader: 8, subtitle: "Живое видео из символов, цвет берётся из камеры." },
  crt: { title: "ЭЛТ-телевизор", shader: 12, subtitle: "Выпуклый кинескоп с развёрткой, сдвигом цветов и маской триад." },
  dither: { title: "1-бит", shader: 9, subtitle: "Двухцветный дизеринг Байера в стиле игры Return of the Obra Dinn." },
  halftone: { title: "Полутон", shader: 10, subtitle: "Печатный растр CMYK, как в старых газетах и комиксах." },
  comic: { title: "Комикс", shader: 6, subtitle: "Плоские цвета и чёрные контуры, как в комиксе." },
  cartoon: { title: "Мультфильм", shader: 16, prefilter: "median", subtitle: "Мир как в мультфильме: гладкие заливки, сочные цвета и чёткие контуры." },
  sketch: { title: "Карандаш", shader: 13, subtitle: "Карандашная перекрёстная штриховка по теням и контуры." },
  blueprint: { title: "Чертёж", shader: 21, subtitle: "Белые линии на синем листе с миллиметровой сеткой, как технический чертёж." },
  chalk: { title: "Мел", shader: 22, subtitle: "Рваные меловые штрихи по контурам на школьной доске." },
  neon: { title: "Неон", shader: 19, subtitle: "Переливающиеся неоновые контуры; ползунок «Ореол» добавляет свечение." },
  neonShadow: { title: "Неоновая тень", shader: 18, subtitle: "Вирусный эффект TikTok: розовая, голубая и жёлтая копии контура расходятся и сходятся." },
  tron: { title: "Трон", shader: 20, subtitle: "Голубые и оранжевые световые контуры на тёмной сетке, как в «Троне»." },
  electric: { title: "Электричество", shader: 23, subtitle: "Дрожащие фиолетовые разряды с белой сердцевиной." },
  emboss: { title: "Тиснение", shader: 24, subtitle: "Серый рельеф, будто изображение выдавлено в листе." },
  metal: { title: "Металл", shader: 25, subtitle: "Чеканка на металле любого цвета: от серебра до золота, меди и синей стали." },
  periodicMetals: { title: "Таблица металлов", shader: 26, prefilter: "median", subtitle: "Каждый участок кадра становится металлом своего цвета: медь, золото, патина, титан, висмут, серебро и другие." },
  stoneRelief: { title: "Камень", shader: 28, subtitle: "Изображение высечено в шершавом песчанике." },
  paperRelief: { title: "Бумага", shader: 29, subtitle: "Слепое тиснение белым по белому, как на дорогой открытке." },
  woodRelief: { title: "Дерево", shader: 30, subtitle: "Резьба по доске с годичными волокнами." }
};

export const CATEGORIES = [
  { id: "classic", title: "Классика", icon: "camera", effects: ["normal", "matte", "grid", "kaleidoscope", "glitch"] },
  { id: "vision", title: "Приборы", icon: "eye", effects: ["nightVision", "thermal"] },
  { id: "pixels", title: "Пиксели", icon: "grid", effects: ["pixels", "gameBoy", "lego", "ascii"] },
  { id: "retro", title: "Ретро", icon: "tv", effects: ["crt", "dither", "halftone"] },
  { id: "drawing", title: "Рисунок", icon: "pencil", effects: ["comic", "cartoon", "sketch", "blueprint", "chalk"] },
  { id: "neon", title: "Неон", icon: "bolt", effects: ["neon", "neonShadow", "tron", "electric"] },
  { id: "relief", title: "Рельеф", icon: "mountain", effects: ["emboss", "metal", "periodicMetals", "stoneRelief", "paperRelief", "woodRelief"] }
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
  if (saturation < 0.12) return "Серебро";
  if (hue < 20) return "Медь";
  if (hue < 50) return "Золото";
  if (hue < 75) return "Латунь";
  if (hue < 160) return "Зелёная патина";
  if (hue < 250) return "Синяя сталь";
  if (hue < 320) return "Фиолетовый титан";
  return "Розовое золото";
}
