// Резиновые номера ячеек: размер шрифта номера подстраивается под реальную ширину ячейки
// и реальный шрифт телефона (SF на iPhone, Roboto на Android и т. д.). После отрисовки один
// раз меряем фактическую ширину номеров и выставляем множитель --fit на ряды ячеек.

const FILL = 0.86; // номер занимает не больше 86 % ширины ячейки — поля по бокам на любом экране
const range = document.createRange();

function inkWidth(element) {
  range.selectNodeContents(element);
  return range.getBoundingClientRect().width;
}

const lastFit = new Map();

function measure(groups) {
  let fit = Infinity;
  for (const group of groups) {
    const current = parseFloat(group.style.getPropertyValue("--fit")) || 1;
    for (const tile of group.querySelectorAll(".tile")) {
      const number = tile.querySelector(".tile-number");
      const width = number ? inkWidth(number) : 0;
      if (width && tile.clientWidth) fit = Math.min(fit, (current * tile.clientWidth * FILL) / width);
    }
  }
  return Number.isFinite(fit) ? Math.min(1, fit).toFixed(3) : null;
}

/// Один множитель на весь экран, чтобы номера во всех секциях были одного размера.
/// Меряем сразу после вставки в документ (без мигания); если экран ещё не показан — в следующем кадре.
export function fitTileNumbers(root, selector) {
  const groups = [...root.querySelectorAll(selector)];
  const apply = (value) => groups.forEach((group) => group.style.setProperty("--fit", value));
  if (lastFit.has(selector)) apply(lastFit.get(selector));
  const run = () => {
    const value = measure(groups);
    if (value == null) return false;
    lastFit.set(selector, value);
    apply(value);
    return true;
  };
  if (!run()) requestAnimationFrame(run);
}
