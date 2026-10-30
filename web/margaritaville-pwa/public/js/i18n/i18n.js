// Языки интерфейса. Исходный текст в коде — русский, он же ключ словаря (как msgid в gettext):
// tr("Комната {room}", { room }) ищет перевод в словаре выбранного языка, иначе оставляет русский.
// Словари лежат в i18n/<язык>.json и собираются из tools/i18n/*.tsv скриптом tools/gen_i18n.py.

const SETTINGS_KEY = "margaritaville.settings.v1";

export const LANGUAGES = [
  { id: "ru", name: "Русский", locale: "ru-RU", speech: "ru-RU" },
  { id: "en", name: "English", locale: "en-US", speech: "en-US" },
  { id: "uk", name: "Українська", locale: "uk-UA", speech: "uk-UA" },
  { id: "es", name: "Español", locale: "es-ES", speech: "es-ES" },
  // Для креольского и патуа нет системного распознавания речи: берём ближайший язык.
  { id: "ht", name: "Kreyòl ayisyen", locale: "fr-HT", speech: "fr-FR" },
  { id: "jam", name: "Patwa (Jamaica)", locale: "en-JM", speech: "en-US" }
];

let current = LANGUAGES[0];
let dictionary = {};

/// Язык из настроек; если он не выбран — язык телефона, если он поддерживается; иначе русский.
export function preferredLanguage() {
  let saved = null;
  try { saved = JSON.parse(localStorage.getItem(SETTINGS_KEY) ?? "{}")?.language ?? null; } catch { saved = null; }
  if (LANGUAGES.some((l) => l.id === saved)) return saved;
  for (const tag of navigator.languages ?? [navigator.language ?? ""]) {
    const base = String(tag).toLowerCase().split("-")[0];
    const match = LANGUAGES.find((l) => l.id === base);
    if (match) return match.id;
  }
  return "ru";
}

export async function loadLanguage(id) {
  current = LANGUAGES.find((l) => l.id === id) ?? LANGUAGES[0];
  dictionary = {};
  if (current.id !== "ru") {
    try {
      const response = await fetch(`i18n/${current.id}.json`);
      if (response.ok) dictionary = await response.json();
    } catch {
      // Без словаря интерфейс остаётся на русском.
    }
  }
  document.documentElement.lang = current.id;
}

export const currentLanguage = () => current;

export function tr(source, params) {
  const text = dictionary[source] || source;
  if (!params) return text;
  return text.replace(/\{(\w+)\}/g, (match, name) => (name in params ? String(params[name]) : match));
}
