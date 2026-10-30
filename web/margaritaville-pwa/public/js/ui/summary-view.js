// Главный экран: шапка с фильтрами, секции уборщиц с бегущей строкой расходников,
// сетка ячеек, итог расходников, командный центр увеличенной ячейки.
// Источник: Features/Summary/SummaryScreen.swift, MargaritavilleSummarySection.swift.
import { h, onHold } from "./dom.js";
import { paletteColor } from "../domain/housekeepers.js";
import { roomStatus } from "../domain/room.js";
import { housekeeperSections } from "../domain/summary-grouping.js";
import { consumablesReport } from "../domain/consumables.js";
import { summaryHeader } from "./summary-header.js";
import { gridMetrics, roomTile } from "./room-tile.js";
import { roomZoomOverlay } from "./room-zoom.js";
import { consumableTicker, consumablesTable } from "./consumables-view.js";
import { openRoomActions, openSchedule } from "./sheets.js";
import { openRoomDetails } from "./room-details.js";
import { openCartDetails } from "./cart-details.js";
import { tr } from "../i18n/i18n.js";

const ROOM_EVENT = { pending: "roomPending", open: "roomOpen", ready: "roomReady", scheduled: "roomScheduled" };
const PULSE_MS = 2000;
const view = { filter: null, zoomedRoomID: null, phase: "idle", pulses: new Map() };

export function renderSummary(root, app) {
  const { store, settings } = app;
  const rooms = store.carts.flatMap((c) => c.rooms);
  const sections = housekeeperSections(store.carts, store.selection, store.catalog, view.filter);
  const report = consumablesReport(sections, store.carts, settings.get("housekeepers"), settings.get("cartConsumableCatalog"));
  const tickers = new Map(report.housekeepers.map((r) => [r.id, r.tickerText]));
  const width = Math.min(root.clientWidth || window.innerWidth, 900);
  const metrics = gridMetrics(width, settings.get("gridColumnCount"));
  const actions = summaryActions(app);

  const header = summaryHeader(app, { counts: store.counts, rooms, filter: view.filter, onFilter: (f) => { view.filter = f; app.render(); } });
  const list = h("div", { class: "summary-scroll" },
    sections.map((section) => sectionView(app, section, tickers.get(section.id), metrics, actions)),
    consumablesTable(report));

  const zoomed = view.zoomedRoomID ? store.room(view.zoomedRoomID) : null;
  if (!zoomed) view.zoomedRoomID = null;
  root.replaceChildren(h("main", { class: "screen summary" }, header, list, zoomed ? roomZoomOverlay(zoomed, actions.zoom(zoomed.id)) : null));
}

function sectionView(app, section, tickerText, metrics, actions) {
  const hk = app.settings.housekeeper(section.housekeeperID);
  const name = h("span", {
    class: "hk-name", role: "button", tabindex: "0",
    style: { "--hk": hk ? paletteColor(hk.palette) : "var(--accent)", "--hk-soft": hk ? paletteColor(hk.palette, 0.2) : "rgba(30,255,90,0.2)", "--hk-line": hk ? paletteColor(hk.palette, 0.72) : "rgba(30,255,90,0.72)" }
  }, hk?.displayName ?? tr("Уборщица"));
  onHold(name, 580, () => {
    app.feedback.longPress();
    openCartDetails(app, section.primaryCartID, hk?.displayName, section.locationLabel);
  });
  const columns = app.settings.get("gridColumnCount");
  const rows = [];
  for (let i = 0; i < section.rooms.length; i += columns) rows.push(section.rooms.slice(i, i + columns));
  return h("section", { class: "summary-section" },
    h("div", { class: "section-head" }, name, tickerText ? consumableTicker(tickerText) : h("span", { class: "section-gap" }), h("span", { class: "section-zone", style: { "font-size": `${zoneFontSize(section.locationLabel)}px` } }, section.locationLabel)),
    h("div", { class: "room-rows", style: { "--s": metrics.scale, "--tile-w": `${metrics.base}px` } },
      rows.map((row) => h("div", { class: "room-row" }, row.map((room) => {
        const tile = roomTile(app, room, { tileWidth: metrics.base, onAdvance: actions.advance, onZoom: actions.zoomRoom, onActions: actions.openActions });
        const pulse = view.pulses.get(room.id);
        if (pulse && performance.now() - pulse.at < PULSE_MS) tile.classList.add(pulse.kind);
        if (view.zoomedRoomID === room.id) tile.classList.add("zoom-source");
        return tile;
      }))))
  );
}

/// Подпись зон ужимается до 58 %, как minimumScaleFactor в SwiftUI.
const zoneFontSize = (label) => Math.max(22 * 0.58, Math.min(22, (22 * 150) / Math.max(label.length * 13, 1)));

function summaryActions(app) {
  const { store, settings, feedback } = app;
  const statusOf = (id) => { const r = store.room(id); return r ? roomStatus(r) : null; };

  const statusChanged = (id, previous) => {
    const next = statusOf(id);
    if (!next || next === previous) return;
    feedback.play(ROOM_EVENT[next], { haptic: false });
    pulse(id);
  };
  const pulse = (id) => {
    const kind = settings.get("developerStatusHDRPulseEnabled") ? "hdr-pulse" : settings.get("developerCellPhysicsEnabled") ? "spring-pulse" : null;
    if (!kind) return;
    view.pulses.set(id, { kind, at: performance.now() });
    setTimeout(() => { if (view.pulses.get(id)?.kind === kind) { view.pulses.delete(id); app.render(); } }, PULSE_MS);
  };
  const collapse = () => { view.phase = "idle"; view.zoomedRoomID = null; app.render(); };
  const childDone = (id) => { if (view.zoomedRoomID === id && view.phase === "awaiting") collapse(); };
  const childDismissed = () => { if (view.phase === "awaiting") view.phase = "idle"; };

  const schedule = (id) => openSchedule(app, id, {
    onSet: (time) => {
      const previous = statusOf(id);
      store.setSchedule(id, time);
      if (time <= Date.now()) store.advanceScheduledRooms().forEach((r) => statusChanged(r, "scheduled"));
      else statusChanged(id, previous);
      app.notifications?.schedule(id, time);
      childDone(id);
    },
    onClear: () => {
      const previous = statusOf(id);
      store.setSchedule(id, null);
      statusChanged(id, previous);
      app.notifications?.cancel(id);
      childDone(id);
    },
    onDismiss: childDismissed
  });
  const details = (id, mode) => openRoomDetails(app, id, mode, () => childDone(id));
  const begin = (phase) => { if (view.phase !== "idle") return false; view.phase = phase; return true; };

  return {
    advance: (id) => { const previous = statusOf(id); store.advance(id); statusChanged(id, previous); },
    zoomRoom: (room) => { view.phase = "idle"; view.zoomedRoomID = room.id; app.render(); },
    openActions: (id) => openRoomActions(app, id, {
      openDetails: details,
      toggleVIP: (rid) => { store.toggleVIP(rid); pulse(rid); },
      openSchedule: schedule,
      reset: (rid) => { const previous = statusOf(rid); store.reset(rid); statusChanged(rid, previous); }
    }),
    zoom: (id) => ({
      collapse,
      setStatus: (status) => {
        if (!begin("executing")) return;
        const previous = statusOf(id);
        if (status === "pending") store.reset(id);
        else store.setStatus(id, status);
        statusChanged(id, previous);
        statusOf(id) === status ? collapse() : (view.phase = "idle");
      },
      toggleVIP: () => {
        if (!begin("executing")) return;
        feedback.confirm();
        store.toggleVIP(id);
        collapse();
      },
      openSchedule: () => { if (begin("awaiting")) schedule(id); },
      openDetails: (mode) => { if (begin("awaiting")) details(id, mode); }
    })
  };
}
