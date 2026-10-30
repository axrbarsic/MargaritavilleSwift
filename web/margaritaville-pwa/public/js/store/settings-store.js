// Настройки приложения на устройстве (localStorage), как AppSettingsStore на UserDefaults.
// Каждое изменение сразу сохраняется и оповещает подписчиков.
// Источник: App/AppSettingsStore.swift, AppSettingsStoreDefaults.swift.
import { DEFAULT_HOUSEKEEPERS } from "../domain/housekeepers.js";
import { DEFAULT_CONSUMABLE_CATALOG, normalizedCatalog } from "../domain/consumables.js";

const KEY = "margaritaville.settings.v1";

export const DEFAULT_SETTINGS = Object.freeze({
  appBackgroundMode: "matrixRain",
  roomCellGeometry: "roomy",
  gridColumnCount: 4,
  transparentSurfacesEnabled: false,
  statusPaletteSaturation: 1,
  roomTaskLongPress: true,
  summaryActionMenuAllowsMultiple: false,
  soundAssignments: {},
  soundsEnabled: true,
  matrixSpeed: 1,
  backgroundVideoBlur: 0.28,
  backgroundVideoBrightness: 0.08,
  backgroundVideoGreenTint: 0.34,
  backgroundVideoGridIntensity: 0,
  backgroundVideoName: null,
  tvStaticVariant: "classicAnalog",
  tvStaticSpeed: 1,
  tvStaticParticleSize: 1,
  tvStaticBrightness: -0.08,
  tvStaticGreenTint: 0,
  brooklynSurfaceStyle: "donorExact",
  brooklynCellScale: 1,
  brooklynHue: 0.9502923976608187,
  brooklynBrightness: 1,
  brooklynContrast: 0,
  cameraEffect: "normal",
  cameraFacing: "environment",
  cameraTuning: {},
  developerCellPhysicsEnabled: false,
  developerLive3DCellsEnabled: false,
  developerCellSpringIntensity: 0.72,
  developerCellSpringSpeed: 0.82,
  developerVIPJellyEnabled: true,
  developerVIPJellySpeed: 0.75,
  developerVIPHDREnabled: false,
  developerStatusHDRPulseEnabled: false,
  housekeepers: DEFAULT_HOUSEKEEPERS,
  cartConsumableCatalog: DEFAULT_CONSUMABLE_CATALOG
});

/// Ключи, которые сброс настроек не трогает (смена, люди и каталог расходников сбрасываются отдельно).
const RESET_KEEPS = [];

export class SettingsStore {
  constructor(storage = globalThis.localStorage) {
    this.storage = storage;
    this.listeners = new Set();
    this.values = { ...DEFAULT_SETTINGS, ...this.read() };
    this.values.cartConsumableCatalog = normalizedCatalog(this.values.cartConsumableCatalog);
  }

  read() {
    try {
      return JSON.parse(this.storage?.getItem(KEY) ?? "{}") ?? {};
    } catch {
      return {};
    }
  }

  get(key) { return this.values[key]; }

  get vividStatusPaletteEnabled() { return this.values.statusPaletteSaturation >= 1.5; }
  get holdZoomEnabled() { return this.values.roomCellGeometry === "compact"; }

  set(key, value) {
    if (this.values[key] === value) return;
    this.values[key] = value;
    this.save();
  }

  update(patch) {
    Object.assign(this.values, patch);
    this.save();
  }

  save() {
    try {
      this.storage?.setItem(KEY, JSON.stringify(this.values));
    } catch {
      // Переполнение или приватный режим: настройки живут до перезапуска.
    }
    this.listeners.forEach((listener) => listener());
  }

  subscribe(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  resetToDefaults() {
    const kept = Object.fromEntries(RESET_KEEPS.map((key) => [key, this.values[key]]));
    this.values = { ...DEFAULT_SETTINGS, ...kept };
    this.save();
  }

  housekeeper(id) {
    return id ? this.values.housekeepers.find((h) => h.id === id) ?? null : null;
  }
}
