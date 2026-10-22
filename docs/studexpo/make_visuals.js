// App-styled visuals for the deck: the AgroZen chick (same shape as
// _ChickPainter in lib/presentation/widgets/agro_icons.dart) coloured by
// health, a flock "health map", and the gradient panels the app uses.
// Run: NODE_PATH=<deps>/node_modules node make_visuals.js
const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const A = (f) => path.join(__dirname, "assets", f);
const png = (svg, file) => sharp(Buffer.from(svg)).png().toFile(A(file));

const STATUS = {
  green: { body: "#16A34A", wing: "#DCFCE7" },
  amber: { body: "#F59E0B", wing: "#FEF3C7" },
  red: { body: "#DC2626", wing: "#FEE2E2" },
};

// One chick in a 100×100 box. "red" lies on its side with its eye closed.
function chick(status, x = 0, y = 0, s = 1) {
  const c = STATUS[status];
  const eye = status === "red"
    ? `<path d="M48 24 L56 32 M56 24 L48 32" stroke="#1F2937" stroke-width="3" stroke-linecap="round"/>`
    : status === "amber"
      ? `<path d="M47 28 Q52 32 57 28" stroke="#1F2937" stroke-width="3" fill="none" stroke-linecap="round"/>`
      : `<circle cx="52" cy="28" r="5" fill="#1F2937"/><circle cx="54" cy="26" r="2" fill="#fff"/>`;
  const feet = status === "red" ? "" :
    `<path d="M38 88 v8 M34 96 h8 M56 88 v8 M52 96 h8" stroke="#C84B31" stroke-width="3" stroke-linecap="round"/>`;
  const body = `
    ${feet}
    <ellipse cx="48" cy="58" rx="36" ry="31" fill="${c.body}"/>
    <circle cx="45" cy="32" r="30" fill="${c.body}"/>
    <path d="M72 32 L94 36 L72 42 Z" fill="#C84B31"/>
    ${eye}
    <ellipse cx="38" cy="62" rx="16" ry="12" fill="${c.wing}" opacity=".55"/>`;
  // Red has collapsed: leaning over, lowered to the floor, no feet showing.
  const tilt = status === "red" ? `translate(2 18) scale(.84) rotate(24 50 70)` : status === "amber" ? `rotate(-8 50 60)` : "";
  return `<g transform="translate(${x} ${y}) scale(${s})"><g transform="${tilt}">${body}</g></g>`;
}

(async () => {
  for (const k of Object.keys(STATUS)) {
    await png(`<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 100 100">${chick(k)}</svg>`, `chick_${k}.png`);
  }

  // Flock health map: 14 × 5 chicks, mostly green, a few amber, two red.
  const cols = 14, rows = 5, cell = 110;
  const amber = new Set([17, 30, 44, 53, 61]), red = new Set([24, 47]);
  let g = "";
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const i = r * cols + c;
      const st = red.has(i) ? "red" : amber.has(i) ? "amber" : "green";
      const jx = ((i * 37) % 11) - 5, jy = ((i * 53) % 9) - 4; // a little natural jitter
      g += chick(st, c * cell + (r % 2 ? cell / 2 : 0) + jx, r * (cell - 8) + jy, 0.92);
    }
  }
  const W = cols * cell + cell / 2, H = rows * (cell - 8) + 20;
  await png(`<svg xmlns="http://www.w3.org/2000/svg" width="${W * 2}" height="${H * 2}" viewBox="0 0 ${W} ${H}">${g}</svg>`, "chick_grid.png");

  // Dark green panel like the poster's "screens" card: gradient + soft glow.
  await png(`<svg xmlns="http://www.w3.org/2000/svg" width="2400" height="1100">
    <defs>
      <linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0B3B1F"/><stop offset=".7" stop-color="#052E16"/></linearGradient>
      <radialGradient id="r" cx=".88" cy=".05" r=".55"><stop offset="0" stop-color="#22C55E" stop-opacity=".38"/><stop offset="1" stop-color="#22C55E" stop-opacity="0"/></radialGradient>
      <radialGradient id="r2" cx=".08" cy="1" r=".5"><stop offset="0" stop-color="#F97316" stop-opacity=".18"/><stop offset="1" stop-color="#F97316" stop-opacity="0"/></radialGradient>
    </defs>
    <rect width="2400" height="1100" rx="60" fill="url(#g)"/><rect width="2400" height="1100" rx="60" fill="url(#r)"/><rect width="2400" height="1100" rx="60" fill="url(#r2)"/>
  </svg>`, "panel_dark.png");

  // The app's one "sun" hero tile (AppColors.sun → sunDeep).
  await png(`<svg xmlns="http://www.w3.org/2000/svg" width="900" height="420">
    <defs><linearGradient id="s" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F97316"/><stop offset="1" stop-color="#EA580C"/></linearGradient></defs>
    <rect width="900" height="420" rx="70" fill="url(#s)"/></svg>`, "sun_tile.png");

  // PhotoCard: barn photo under the heroShade gradient, rounded.
  const photo = fs.readFileSync(path.join(__dirname, "../../assets/images/broiler_grower.jpg")).toString("base64");
  await png(`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="2100" height="560">
    <defs>
      <clipPath id="c"><rect width="2100" height="560" rx="70"/></clipPath>
      <linearGradient id="sh" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#052E16" stop-opacity=".94"/><stop offset=".55" stop-color="#052E16" stop-opacity=".7"/><stop offset="1" stop-color="#052E16" stop-opacity=".15"/></linearGradient>
    </defs>
    <g clip-path="url(#c)"><image href="data:image/jpeg;base64,${photo}" xlink:href="data:image/jpeg;base64,${photo}" x="0" y="-620" width="2100" height="1575" preserveAspectRatio="xMidYMid slice"/>
    <rect width="2100" height="560" fill="url(#sh)"/></g></svg>`, "photo_card.png");

  console.log("visuals written");
})();
