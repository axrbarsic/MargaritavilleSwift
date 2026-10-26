// Лаборатория эффектов камеры: состояние, меню категорий и эффектов, ползунки,
// источники картинки и цикл отрисовки.
import { EFFECTS, CATEGORIES, categoryOf, TUNING_DEFAULTS } from "./effects.js";
import { Renderer } from "./renderer.js";
import { Sources } from "./sources.js";
import { renderControls, isDefaultTuning } from "./controls.js";

const ICONS = {
  camera: '<path d="M4 7h3l2-2h6l2 2h3v12H4z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="13" r="3.5" fill="none" stroke="currentColor" stroke-width="2"/>',
  eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="3" fill="currentColor"/>',
  grid: '<path d="M4 4h4v4H4zM10 4h4v4h-4zM16 4h4v4h-4zM4 10h4v4H4zM10 10h4v4h-4zM16 10h4v4h-4zM4 16h4v4H4zM10 16h4v4h-4zM16 16h4v4h-4z" fill="currentColor"/>',
  tv: '<rect x="3" y="6" width="18" height="13" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><path d="M8 3l4 3 4-3" fill="none" stroke="currentColor" stroke-width="2"/>',
  pencil: '<path d="M4 20l4-1 11-11-3-3L5 16z" fill="none" stroke="currentColor" stroke-width="2"/>',
  bolt: '<path d="M13 2L4 14h6l-1 8 9-12h-6z" fill="currentColor"/>',
  mountain: '<path d="M2 20l7-12 4 6 3-4 6 10z" fill="currentColor"/>'
};

const STORAGE_KEY = "cameraEffectsLab.v1";
const $ = (id) => document.getElementById(id);

function loadState() {
  const fallback = { effect: "normal", facing: "environment", tuning: { ...TUNING_DEFAULTS } };
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
    if (!saved) return fallback;
    return {
      effect: EFFECTS[saved.effect] ? saved.effect : "normal",
      facing: saved.facing === "user" ? "user" : "environment",
      tuning: { ...TUNING_DEFAULTS, ...(saved.tuning || {}) }
    };
  } catch (_) {
    return fallback;
  }
}

const state = loadState();
let shownCategory = categoryOf(state.effect).id;

function saveState() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (_) { /* приватный режим */ }
}

function setStatus(text, warn) {
  const status = $("status");
  status.textContent = text;
  status.classList.toggle("warn", Boolean(warn));
}

const sources = new Sources(setStatus);
let renderer = null;
try {
  renderer = new Renderer($("stage"));
} catch (error) {
  setStatus(error.message.startsWith("Ошибка") ? error.message : "Этот браузер не поддерживает WebGL 2, поэтому эффекты не запустятся.", true);
  console.error(error);
}

function renderCategories() {
  const container = $("categories");
  container.replaceChildren();
  CATEGORIES.forEach((category) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "chip";
    button.setAttribute("role", "tab");
    button.setAttribute("aria-selected", String(category.id === shownCategory));
    button.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true">${ICONS[category.icon]}</svg>`;
    button.append(category.title);
    button.addEventListener("click", () => {
      shownCategory = category.id;
      renderCategories();
      renderEffects();
    });
    container.append(button);
  });
}

function renderEffects() {
  const container = $("effects");
  container.replaceChildren();
  CATEGORIES.find((c) => c.id === shownCategory).effects.forEach((id) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "effect";
    button.textContent = EFFECTS[id].title;
    button.setAttribute("aria-pressed", String(id === state.effect));
    button.addEventListener("click", () => selectEffect(id));
    container.append(button);
  });
}

function renderInfo() {
  const effect = EFFECTS[state.effect];
  $("effectTitle").textContent = effect.title;
  $("effectSubtitle").textContent = effect.subtitle;
  $("handleTitle").textContent = effect.title;
  $("badge").textContent = `${effect.title} · ${sourceLabel()}`;
  renderControls($("controls"), state.effect, state.tuning, (key, value, rerender) => {
    state.tuning[key] = value;
    saveState();
    $("reset").disabled = isDefaultTuning(state.tuning);
    if (rerender) renderInfo();
  });
  $("reset").disabled = isDefaultTuning(state.tuning);
}

function sourceLabel() {
  if (sources.kind === "camera") return sources.facing === "user" ? "передняя камера" : "задняя камера";
  if (sources.kind === "video") return "видео";
  if (sources.kind === "image") return "фото";
  return "демо-сцена";
}

function selectEffect(id) {
  state.effect = id;
  saveState();
  renderEffects();
  renderInfo();
}

function updateSourceButtons() {
  const camera = sources.kind === "camera";
  $("camBack").setAttribute("aria-pressed", String(camera && sources.facing === "environment"));
  $("camFront").setAttribute("aria-pressed", String(camera && sources.facing === "user"));
  $("srcFile").setAttribute("aria-pressed", String(sources.kind === "video" || sources.kind === "image"));
  $("srcDemo").setAttribute("aria-pressed", String(sources.kind === "demo"));
  renderInfo();
}

async function useCamera(facing) {
  state.facing = facing;
  saveState();
  await sources.startCamera(facing);
  updateSourceButtons();
}

$("camBack").addEventListener("click", () => useCamera("environment"));
$("camFront").addEventListener("click", () => useCamera("user"));
$("srcFile").addEventListener("click", () => $("fileInput").click());
$("fileInput").addEventListener("change", async (event) => {
  const file = event.target.files && event.target.files[0];
  if (!file) return;
  await sources.useFile(file);
  updateSourceButtons();
  event.target.value = "";
});
$("srcDemo").addEventListener("click", () => {
  sources.useDemo();
  setStatus("Демо-сцена анимирована, чтобы было видно эффекты с движением.", false);
  updateSourceButtons();
});
$("reset").addEventListener("click", () => {
  state.tuning = { ...TUNING_DEFAULTS };
  saveState();
  renderInfo();
});
$("sheetToggle").addEventListener("click", () => {
  const collapsed = $("sheet").classList.toggle("collapsed");
  $("sheetToggle").setAttribute("aria-expanded", String(!collapsed));
  $("handleHint").textContent = collapsed ? "Настройки" : "Свернуть";
});

function resizeCanvas() {
  const canvas = $("stage");
  const ratio = Math.min(window.devicePixelRatio || 1, 2);
  const width = Math.max(2, Math.round(canvas.clientWidth * ratio));
  const height = Math.max(2, Math.round(canvas.clientHeight * ratio));
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
}

function frame(now) {
  if (renderer && !document.hidden) {
    resizeCanvas();
    const time = now / 1000;
    const { element, mirror } = sources.frame(time);
    const effect = EFFECTS[state.effect];
    renderer.render(element, mirror, { shader: effect.shader, prefilter: effect.prefilter, tuning: state.tuning }, time);
  }
  requestAnimationFrame(frame);
}

renderCategories();
renderEffects();
renderInfo();
updateSourceButtons();
requestAnimationFrame(frame);
useCamera(state.facing);
