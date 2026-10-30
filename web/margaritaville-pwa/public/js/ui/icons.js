// Набор линейных иконок вместо SF Symbols. icon("mic") → <svg>.
const PATHS = {
  back: "M15 5l-7 7 7 7",
  chevron: "M9 6l6 6-6 6",
  menu: "M4 7h16M4 12h16M4 17h16",
  mic: "M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3zM5 11a7 7 0 0 0 14 0M12 18v3",
  stop: "M7 7h10v10H7z",
  camera: "M4 8h3l2-3h6l2 3h3v11H4zM12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
  video: "M3 7h12v10H3zM15 10l6-3v10l-6-3",
  trash: "M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3",
  play: "M8 5l11 7-11 7z",
  pause: "M7 5h4v14H7zM13 5h4v14h-4z",
  waveform: "M3 12h2M7 8v8M11 5v14M15 8v8M19 10v4M21 12h0",
  photo: "M4 5h16v14H4zM4 16l5-5 4 4 3-3 4 4M15 9.5a1.5 1.5 0 1 0 0-.01",
  diamond: "M12 3l8 9-8 9-8-9z",
  crown: "M3 8l4 4 5-7 5 7 4-4-2 11H5z",
  clock: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2",
  minus: "M5 12h14",
  plus: "M12 5v14M5 12h14",
  check: "M5 12l5 5 9-10",
  circle: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z",
  checkCircle: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM8 12l3 3 5-6",
  box: "M3 7l9-4 9 4v10l-9 4-9-4zM3 7l9 4 9-4M12 11v10",
  puzzle: "M9 4h3v2a2 2 0 1 0 4 0V4h4v5h-2a2 2 0 1 0 0 4h2v7h-5v-2a2 2 0 1 0-4 0v2H4v-6h2a2 2 0 1 0 0-4H4V4z",
  paperclip: "M20 11l-8.5 8.5a5 5 0 0 1-7-7L13 4a3.5 3.5 0 0 1 5 5l-8.5 8.5a2 2 0 0 1-3-3L14 7",
  note: "M5 3h10l4 4v14H5zM8 11h8M8 15h8M8 7h4",
  door: "M5 21V3h11v18M16 5l3 1v15M12 12h.01",
  reset: "M4 4v6h6M5 15a8 8 0 1 0 2-9l-3 4",
  close: "M6 6l12 12M18 6L6 18",
  palette: "M12 3a9 9 0 0 0 0 18c1 0 2-1 2-2s-1-1-1-2 1-2 2-2h2a4 4 0 0 0 4-4c0-4-4-8-9-8zM7.5 11h.01M10 7h.01M15 7h.01",
  film: "M4 4h16v16H4zM8 4v16M16 4v16M4 8h4M4 12h4M4 16h4M16 8h4M16 12h4M16 16h4",
  hand: "M8 13V5a1.5 1.5 0 0 1 3 0v6M11 10V4a1.5 1.5 0 0 1 3 0v6M14 10V5a1.5 1.5 0 0 1 3 0v8a7 7 0 0 1-12 5l-2-3a1.5 1.5 0 0 1 2.5-1.7L8 15",
  hammer: "M14 4l6 6-3 3-6-6zM11 7l-8 8 3 3 8-8",
  speaker: "M4 9h4l5-4v14l-5-4H4zM16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11",
  list: "M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01",
  user: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0",
  grid: "M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z",
  sliders: "M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0M14 4v4M8 10v4M16 16v4",
  bolt: "M13 2L4 14h7l-1 8 9-12h-7z",
  sparkle: "M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z",
  flip: "M4 8h13l-3-3M20 16H7l3 3",
  lock: "M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4",
  gear: "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"
};

const NS = "http://www.w3.org/2000/svg";

export function icon(name, size = 22, stroke = 2.4) {
  const svg = document.createElementNS(NS, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("width", size);
  svg.setAttribute("height", size);
  svg.setAttribute("fill", "none");
  svg.setAttribute("stroke", "currentColor");
  svg.setAttribute("stroke-width", stroke);
  svg.setAttribute("stroke-linecap", "round");
  svg.setAttribute("stroke-linejoin", "round");
  svg.setAttribute("aria-hidden", "true");
  svg.classList.add("icon");
  const path = document.createElementNS(NS, "path");
  path.setAttribute("d", PATHS[name] ?? PATHS.circle);
  svg.append(path);
  return svg;
}
