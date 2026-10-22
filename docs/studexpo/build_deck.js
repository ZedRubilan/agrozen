// AgroZen — StudEXPO-2026 deck (7 slides, English), styled like the app itself.
// Assets: python3 frame_assets.py en   (phones, dashboard window, camera frame)
//         node make_visuals.js          (health-coloured chicks, panels, sun tile)
// Build:  NODE_PATH=<dir with pptxgenjs, react, react-dom, react-icons, sharp>/node_modules node build_deck.js [out.pptx]
//
// No PowerPoint shadows: some viewers draw them on images as hard grey boxes.
// Phones and windows carry a soft shadow baked into their PNGs instead.
const path = require("path");
const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const md = require("react-icons/md");

const A = (f) => path.join(__dirname, "assets", f);
const OUT = process.argv[2] || path.join(__dirname, "AgroZen_StudEXPO-2026.pptx");

// AgroZen palette (lib/config/theme.dart · DESIGN.md)
const C = {
  primary: "15803D", primaryDark: "14532D", primarySoft: "E6F4EA", hero: "052E16",
  bg: "F4F7F4", surface: "FFFFFF", muted: "F1F5F2", border: "E2EBE4",
  ink: "0F172A", ink2: "52665A", ink3: "7A8E7E", mint: "86EFAC", mintSoft: "DCFCE7",
  warning: "B45309", warningSoft: "FEF3C7", gold: "F59E0B", sun: "F97316", sunDeep: "EA580C",
  danger: "DC2626", dangerSoft: "FEE2E2", info: "1D4ED8", infoSoft: "DBEAFE", infoSolid: "2563EB",
};
const FONT = "Calibri";
// frame_assets.py: phone 868×1827 inside a 70 px shadow margin; window and
// camera frame likewise carry their shadow margin.
const PHONE = { w: 868, h: 1827, pad: 70 };
const DASH = { w: 2480, h: 2064, pad: 70 };
const CAM = { w: 716, h: 507, pad: 40 };

async function icon(name, hex, px = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(md[name], { color: "#" + hex, size: px }));
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

(async () => {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
  pres.title = "AgroZen — StudEXPO-2026";
  pres.author = "Salimbek Zamalitdinov, Ulugbek Kodirov";
  pres.theme = { headFontFace: FONT, bodyFontFace: FONT };

  // Places a framed image so that its *visible* part (without the baked
  // shadow margin) lands at x, y with width w.
  const framed = (s, file, spec, x, y, w, opts = {}) => {
    const k = w / spec.w;
    s.addImage({ path: A(file), x: x - spec.pad * k, y: y - spec.pad * k, w: (spec.w + 2 * spec.pad) * k, h: (spec.h + 2 * spec.pad) * k, ...opts });
    return spec.h * k;
  };
  const phone = (s, file, x, y, h, opts = {}) =>
    framed(s, `phone_${file}.png`, PHONE, x, y, h * PHONE.w / PHONE.h, { altText: `AgroZen screen: ${file}`, ...opts });
  const phoneW = (h) => h * PHONE.w / PHONE.h;

  const disc = async (s, name, x, y, d, fill, fg = "FFFFFF") => {
    s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: fill }, line: { type: "none" } });
    const p = d * 0.23;
    s.addImage({ data: await icon(name, fg), x: x + p, y: y + p, w: d - 2 * p, h: d - 2 * p });
  };
  // Cards: white with a hairline border, or a soft tone fill without one.
  const card = (s, x, y, w, h, fill = C.surface, r = 0.18) =>
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y, w, h, rectRadius: r, fill: { color: fill },
      line: fill === C.surface ? { color: C.border, width: 1 } : { type: "none" },
    });
  const pill = (s, text, x, y, w, fill, color, h = 0.38, size = 12) => {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: h / 2, fill: { color: fill }, line: { type: "none" } });
    s.addText(text, { x, y, w, h, fontFace: FONT, fontSize: size, bold: true, color, align: "center", valign: "middle", margin: 0 });
  };
  const label = (s, text, x, y, color = C.primary, w = 8) =>
    s.addText(text, { x, y, w, h: 0.32, fontFace: FONT, fontSize: 13, bold: true, color, charSpacing: 2, margin: 0 });
  const title = (s, text, x, y, w, color = C.ink, size = 34) =>
    s.addText(text, { x, y, w, h: 0.9, fontFace: FONT, fontSize: size, bold: true, color, margin: 0, valign: "top" });
  const pageNo = (s, n, color = C.ink3) =>
    s.addText(String(n), { x: 12.33, y: 7.02, w: 0.5, h: 0.3, fontFace: FONT, fontSize: 10, color, align: "right", margin: 0 });
  const lines = (s, head, body, x, y, w, h, o = {}) =>
    s.addText([
      { text: head, options: { bold: true, fontSize: o.hs || 15, color: o.hc || C.ink, breakLine: true } },
      { text: body, options: { fontSize: o.bs || 12, color: o.bc || C.ink2 } },
    ], { x, y, w, h, fontFace: FONT, margin: 0, valign: o.valign || "top", align: o.align || "left" });

  // ================= 1. Title =================
  let s = pres.addSlide();
  s.background = { color: C.hero };
  s.addShape(pres.shapes.OVAL, { x: 6.9, y: -1.3, w: 7.6, h: 7.6, fill: { color: C.primary, transparency: 55 }, line: { type: "none" } });
  s.addImage({ path: A("logo.png"), x: 0.7, y: 0.65, w: 0.85, h: 0.85 });
  s.addText([
    { text: "STUDEXPO-2026", options: { bold: true, fontSize: 15, charSpacing: 2, color: C.surface, breakLine: true } },
    { text: "Mobile apps and artificial intelligence", options: { fontSize: 14, color: C.mintSoft } },
  ], { x: 1.75, y: 0.65, w: 5.2, h: 0.85, fontFace: FONT, margin: 0, valign: "middle" });
  s.addText("AgroZen", { x: 0.7, y: 1.85, w: 6.3, h: 1.3, fontFace: FONT, fontSize: 80, bold: true, color: C.surface, margin: 0 });
  s.addText("An AI mentor in your smartphone for beginner poultry farmers", { x: 0.7, y: 3.2, w: 6.0, h: 1.0, fontFace: FONT, fontSize: 24, color: C.mintSoft, margin: 0, valign: "top" });
  const chips = [["Working MVP · Android", 2.45], ["3 languages", 1.4], ["Works offline", 1.6], ["Smart barn sensors", 2.05], ["Reports for banks", 1.95]];
  let cx = 0.7, cy = 4.45;
  for (const [t, w] of chips) {
    if (cx + w > 6.9) { cx = 0.7; cy += 0.55; }
    pill(s, t, cx, cy, w, C.primary, C.surface, 0.42, 13);
    cx += w + 0.15;
  }
  s.addText([
    { text: "Salimbek Zamalitdinov · Ulugbek Kodirov", options: { bold: true, fontSize: 15, color: C.surface, breakLine: true } },
    { text: "Namangan State Technical University", options: { fontSize: 13, color: C.mintSoft } },
  ], { x: 0.7, y: 6.25, w: 6.0, h: 0.7, fontFace: FONT, margin: 0 });
  phone(s, "monitor", 7.15, 1.55, 4.9, { rotate: 352 });
  phone(s, "bank_report", 10.75, 1.55, 4.9, { rotate: 8 });
  phone(s, "today", 8.75, 0.95, 5.85);
  s.addNotes("AgroZen is a working Android app: an AI mentor that guides a beginner broiler farmer through the 42-day cycle. New this autumn: a smart-barn monitor for sensors and AI cameras, and reports for banks.");

  // ================= 2. Problem =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  s.addImage({ path: A("problem_photo.jpg"), x: 0, y: 0, w: 4.9, h: 7.5, sizing: { type: "cover", w: 4.9, h: 7.5 } });
  // Two "then and now" cards over the photo.
  card(s, 0.4, 4.35, 4.1, 1.25);
  pill(s, "2017", 0.6, 4.52, 0.85, C.dangerSoft, C.danger, 0.34, 12);
  s.addText("Families got loans to raise chickens. Reportedly, many couldn't repay, and banks cut such loans.", { x: 0.6, y: 4.92, w: 3.75, h: 0.6, fontFace: FONT, fontSize: 12, color: C.ink, margin: 0, valign: "top" });
  card(s, 0.4, 5.75, 4.1, 1.25);
  pill(s, "From 1 August 2026", 0.6, 5.92, 1.95, C.primarySoft, C.primary, 0.34, 12);
  s.addText("Concessional poultry loans are back: up to 10 years at 10% a year.", { x: 0.6, y: 6.32, w: 3.75, h: 0.6, fontFace: FONT, fontSize: 12, color: C.ink, margin: 0, valign: "top" });
  label(s, "THE PROBLEM", 5.55, 0.5);
  title(s, "Loan taken, flock lost", 5.55, 0.85, 7.2);
  const problems = [
    ["MdThermostat", C.danger, C.dangerSoft, "No knowledge", "A beginner doesn't know the norms for temperature, feeding and vaccination."],
    ["MdWarningAmber", C.gold, C.warningSoft, "The first 14 days are the most dangerous", "One microclimate mistake leads to mass mortality — and nobody measures ammonia or CO2."],
    ["MdLocalHospital", C.infoSolid, C.infoSoft, "The specialist is far away", "There is no vet nearby at the moment a question comes up."],
  ];
  for (let i = 0; i < problems.length; i++) {
    const [ic, solid, soft, h, d] = problems[i];
    const y = 1.85 + i * 1.12;
    card(s, 5.55, y, 7.1, 0.98, soft);
    await disc(s, ic, 5.75, y + 0.2, 0.58, solid);
    lines(s, h, d, 6.52, y + 0.12, 6.0, 0.8, { hs: 16, bs: 12.5, bc: C.ink, valign: "middle" });
  }
  // The punchline on a photo card, with the red "not moving" chick from slide 4.
  s.addImage({ path: A("photo_card.png"), x: 5.55, y: 5.3, w: 7.1, h: 7.1 * 560 / 2100 });
  s.addText([
    { text: "The birds are gone. The debt remains.", options: { bold: true, fontSize: 20, color: C.surface, breakLine: true } },
    { text: "People lose money not because of laziness, but because of mistakes no one warned them about.", options: { fontSize: 12.5, color: C.mintSoft } },
  ], { x: 5.85, y: 5.38, w: 5.3, h: 1.75, fontFace: FONT, margin: 0, valign: "middle" });
  s.addImage({ path: A("chick_red.png"), x: 11.45, y: 5.6, w: 1.1, h: 1.1 });
  pageNo(s, 2);
  s.addNotes("2017: chicken loans for low-income families went wrong. From August 2026 the state again gives concessional poultry loans. A beginner without knowledge loses the flock in the first two weeks and keeps the debt.");

  // ================= 3. Solution: the app =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "THE SOLUTION", 0.7, 0.45);
  title(s, "AgroZen guides the farmer through all 42 days", 0.7, 0.8, 12);
  s.addImage({ path: A("panel_dark.png"), x: 0.5, y: 1.65, w: 12.33, h: 12.33 * 1100 / 2400 });
  const core = [
    ["today", "MdToday", C.sun, "Today", "Targets for temperature, feed and water"],
    ["plan", "MdCalendarMonth", C.primary, "42-day plan", "Ross-308 / Cobb-500 for every day"],
    ["assistant", "MdMic", C.infoSolid, "AI assistant", "Voice, text or photo, in your language"],
    ["diary", "MdEditNote", C.danger, "Flock diary", "Losses above the norm: the vet's number"],
    ["learn", "MdSchool", C.gold, "Course", "5 lessons and a certificate for a loan"],
  ];
  const ph = 3.95, pw = phoneW(ph), gap = (11.33 - 5 * pw) / 4;
  for (let i = 0; i < core.length; i++) {
    const [file, ic, color, h, d] = core[i];
    const x = 1.0 + i * (pw + gap);
    phone(s, file, x, 1.95, ph);
    await disc(s, ic, x, 6.12, 0.44, color);
    lines(s, h, d, x + 0.52, 6.05, pw + gap - 0.6, 0.75, { hs: 14, bs: 10.5, hc: C.surface, bc: C.mintSoft });
  }
  pageNo(s, 3);
  s.addNotes("Five screens a farmer uses every day: today's targets, the 42-day plan, the AI assistant that answers by voice, the diary with alerts and the course that ends with a certificate for a concessional loan.");

  // ================= 4. Smart barn =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "NEW · SMART BARN PROTOTYPE", 0.7, 0.45);
  title(s, "The AI camera colours every bird by its health", 0.7, 0.8, 12);
  phone(s, "monitor_alarm", 0.7, 1.75, 5.15);
  const camX = 3.55, camW = 5.55;
  const camH = framed(s, "camera_frame.png", CAM, camX, 1.75, camW, { altText: "AI camera frame with green, amber and red boxes" });
  const legend = [
    ["green", C.primarySoft, C.primary, "Active", "Moves, eats and drinks"],
    ["amber", C.warningSoft, C.warning, "Moving little", "An early sign: watch it"],
    ["red", C.dangerSoft, C.danger, "Not moving", "Remove it, call the vet"],
  ];
  for (let i = 0; i < legend.length; i++) {
    const [k, soft, ink, h, d] = legend[i];
    const y = 1.75 + i * 1.02;
    card(s, 9.45, y, 3.18, 0.9, soft);
    s.addImage({ path: A(`chick_${k}.png`), x: 9.55, y: y + 0.07, w: 0.76, h: 0.76 });
    lines(s, h, d, 10.4, y + 0.1, 2.15, 0.7, { hs: 15, hc: ink, bs: 11.5, bc: C.ink, valign: "middle" });
  }
  // Flock at a glance: the same colours over a whole house.
  card(s, 9.45, 4.9, 3.18, 1.95);
  s.addText("Flock at a glance", { x: 9.62, y: 4.98, w: 2.9, h: 0.3, fontFace: FONT, fontSize: 12.5, bold: true, color: C.ink, margin: 0 });
  s.addImage({ path: A("chick_grid.png"), x: 9.6, y: 5.32, w: 2.88, h: 2.88 * 1060 / 3190 });
  s.addText([
    { text: "63 ", options: { bold: true, color: C.primary } }, { text: "active · ", options: { color: C.ink2 } },
    { text: "5 ", options: { bold: true, color: C.warning } }, { text: "watch · ", options: { color: C.ink2 } },
    { text: "2 ", options: { bold: true, color: C.danger } }, { text: "not moving", options: { color: C.ink2 } },
  ], { x: 9.62, y: 6.35, w: 2.9, h: 0.35, fontFace: FONT, fontSize: 11.5, margin: 0 });
  // How it works, in one row under the camera.
  const flowY = 1.75 + camH + 0.3;
  const flow = [["MdSensors", C.primary, "ESP32 sensors"], ["MdMemory", C.infoSolid, "Jetson edge AI"], ["MdRule", C.gold, "Ross-308 rules"], ["MdNotificationsActive", C.danger, "Alert · vet · fans"]];
  const fw = (camW - 3 * 0.18) / 4;
  for (let i = 0; i < flow.length; i++) {
    const [ic, color, t] = flow[i];
    const x = camX + i * (fw + 0.18);
    card(s, x, flowY, fw, 0.62);
    await disc(s, ic, x + 0.1, flowY + 0.11, 0.4, color);
    s.addText(t, { x: x + 0.56, y: flowY, w: fw - 0.6, h: 0.62, fontFace: FONT, fontSize: 11.5, bold: true, color: C.ink, margin: 0, valign: "middle" });
  }
  s.addText("NH3 up to 10 ppm · CO2 up to 3 000 ppm · fans switch on by themselves. Demo mode today; hardware goes into two pilot farms in 2027.", { x: camX, y: flowY + 0.75, w: camW, h: 0.5, fontFace: FONT, fontSize: 11, italic: true, color: C.ink3, margin: 0, valign: "top" });
  pageNo(s, 4);
  s.addNotes("In the app open Smart barn and press 'Losses'. The camera colours every bird: green is active, amber moves little and needs watching, red has stopped moving — and the vet's number appears. Press 'Ammonia' to show the sensors: NH3 passes 10 ppm and the fans switch on. All checks are plain code against the Ross-308 norms.");

  // ================= 5. Banks =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "NEW · FOR BANKS", 0.7, 0.45);
  title(s, "Banks see how the flock is doing — and trust the loan", 0.7, 0.8, 12);
  phone(s, "bank_report", 0.7, 1.8, 5.0);
  const dw = 5.75;
  const dh = framed(s, "browser_dashboard.png", DASH, 3.4, 1.8, dw, { altText: "AgroZen for Banks dashboard" });
  s.addText("Bank dashboard: 10 pilot farmers, survival against the norm, risk and a district disease alert", { x: 3.4, y: 1.92 + dh, w: dw, h: 0.3, fontFace: FONT, fontSize: 11, color: C.ink2, margin: 0 });
  const bank = [
    ["MdVerifiedUser", C.primary, C.primarySoft, "Farmer's consent", "Built from the diary, sent as a PDF only after the farmer agrees."],
    ["MdShield", C.gold, C.warningSoft, "Score 0–100", "Survival, diary, weight, training: fixed rules, not AI."],
    ["MdCampaign", C.danger, C.dangerSoft, "Disease alert", "One tap warns every farmer of the bank in a district."],
  ];
  for (let i = 0; i < bank.length; i++) {
    const [ic, solid, soft, h, d] = bank[i];
    const y = 1.8 + i * 1.18;
    card(s, 9.45, y, 3.18, 1.05, soft);
    await disc(s, ic, 9.6, y + 0.15, 0.48, solid);
    lines(s, h, d, 10.2, y + 0.1, 2.35, 0.9, { hs: 14, bs: 11, bc: C.ink });
  }
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.45, y: 5.45, w: 3.18, h: 1.2, rectRadius: 0.18, fill: { color: C.primary }, line: { type: "none" } });
  s.addText([
    { text: "Free for farmers. ", options: { bold: true } },
    { text: "Banks and microfinance pay: a trained farmer is more likely to repay." },
  ], { x: 9.63, y: 5.5, w: 2.85, h: 1.1, fontFace: FONT, fontSize: 12.5, color: C.surface, margin: 0, valign: "middle" });
  pageNo(s, 5);
  s.addNotes("The farmer agrees, and the app turns the diary into a one-page PDF with a score out of 100. The bank's dashboard shows all its farmers: who is on track, who needs attention, and it can warn every farmer in a district about a disease. This is how AgroZen pays for itself.");

  // ================= 6. Result =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "THE RESULT", 0.7, 0.45);
  title(s, "Not a concept: the app already works", 0.7, 0.8, 12);
  // Stat tiles like the app's TargetTile: the first one is the "sun" hero.
  const tiles = [
    ["MdCalendarMonth", "42 days", "of norms, one plan for every day", null],
    ["MdSchool", "5 lessons", "a course with tests and a certificate", [C.infoSoft, C.infoSolid, C.info]],
    ["MdLocationOn", "13 regions", "vet contacts across Uzbekistan", [C.dangerSoft, C.danger, C.danger]],
    ["MdVerified", "260 tests", "check norms, alerts and scores", [C.primarySoft, C.primary, C.primary]],
  ];
  for (let i = 0; i < tiles.length; i++) {
    const [ic, v, d, tone] = tiles[i];
    const x = 0.7 + (i % 2) * 3.05, y = 1.8 + Math.floor(i / 2) * 1.75;
    if (tone) card(s, x, y, 2.9, 1.6, tone[0]);
    else s.addImage({ path: A("sun_tile.png"), x, y, w: 2.9, h: 1.6, sizing: { type: "cover", w: 2.9, h: 1.6 } });
    await disc(s, ic, x + 0.2, y + 0.2, 0.48, tone ? tone[1] : "FFFFFF", tone ? "FFFFFF" : C.sunDeep);
    lines(s, v, d, x + 0.2, y + 0.75, 2.55, 0.8, { hs: 26, hc: tone ? tone[2] : C.surface, bs: 11.5, bc: tone ? C.ink : "FFF7ED" });
  }
  const tech = [["MdPhoneAndroid", "Flutter"], ["MdCloud", "Supabase + Gemini"], ["MdWifiOff", "Works offline"], ["MdTranslate", "uz · ru · en"]];
  const tw = [1.05, 1.75, 1.4, 1.2];
  let tx = 0.7;
  for (let i = 0; i < tech.length; i++) {
    const [ic, t] = tech[i];
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: tx, y: 5.42, w: tw[i], h: 0.44, rectRadius: 0.22, fill: { color: C.surface }, line: { color: C.border, width: 1 } });
    s.addImage({ data: await icon(ic, C.primary), x: tx + 0.12, y: 5.51, w: 0.26, h: 0.26 });
    s.addText(t, { x: tx + 0.42, y: 5.42, w: tw[i] - 0.48, h: 0.44, fontFace: FONT, fontSize: 11.5, bold: true, color: C.ink, margin: 0, valign: "middle" });
    tx += tw[i] + 0.12;
  }
  s.addText("Alerts are counted by plain code against the norms — they never depend on an AI answer.", { x: 0.7, y: 6.05, w: 6.0, h: 0.5, fontFace: FONT, fontSize: 12, color: C.ink2, margin: 0 });
  // The assistant as it looks in the app: a chat with the knowledge-base source.
  card(s, 7.0, 1.8, 5.63, 5.05);
  s.addImage({ path: A("logo.png"), x: 7.22, y: 1.98, w: 0.48, h: 0.48 });
  lines(s, "AgroZen assistant", "Answers only from a verified knowledge base", 7.82, 1.97, 4.6, 0.55, { hs: 14, bs: 11 });
  s.addShape(pres.shapes.LINE, { x: 7.22, y: 2.65, w: 5.2, h: 0, line: { color: C.border, width: 1 } });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 8.55, y: 2.85, w: 3.85, h: 0.82, rectRadius: 0.2, fill: { color: C.primary }, line: { type: "none" } });
  s.addText("My chicks are crowding under the heater. What should I do?", { x: 8.7, y: 2.87, w: 3.6, h: 0.78, fontFace: FONT, fontSize: 12.5, color: C.surface, margin: 0, valign: "middle" });
  s.addText("voice · text · photo", { x: 8.55, y: 3.7, w: 3.85, h: 0.25, fontFace: FONT, fontSize: 10, color: C.ink3, align: "right", margin: 0 });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 7.22, y: 4.02, w: 4.55, h: 1.38, rectRadius: 0.2, fill: { color: C.muted }, line: { type: "none" } });
  s.addText([
    { text: "That is a sign of cold. On day 3 the house should be 31.5°C — raise the heating and check that the chicks spread evenly.", options: { fontSize: 12.5, color: C.ink, breakLine: true } },
    { text: "Source: AgroZen knowledge base · Ross-308", options: { fontSize: 10, color: C.ink3 } },
  ], { x: 7.37, y: 4.07, w: 4.3, h: 1.28, fontFace: FONT, margin: 0, valign: "middle" });
  card(s, 7.22, 5.55, 5.2, 1.1, C.dangerSoft);
  await disc(s, "MdHealthAndSafety", 7.38, 5.8, 0.6, C.danger);
  lines(s, "Not in the base? \"Call your district vet.\"", "No diagnoses, no medicines, no dosages — ever.", 8.12, 5.66, 4.2, 0.9, { hs: 13.5, bs: 11.5, bc: C.ink, valign: "middle" });
  pageNo(s, 6);
  s.addNotes("Everything shown is in the Android app today, in three languages and offline. 260 automated tests check the norms, the alerts and the bank score. The assistant answers only from the knowledge base; outside it, it sends the farmer to the district vet and never names medicines.");

  // ================= 7. Next step =================
  s = pres.addSlide();
  s.background = { color: C.hero };
  s.addShape(pres.shapes.OVAL, { x: 8.2, y: 3.2, w: 6.5, h: 6.5, fill: { color: C.primary, transparency: 60 }, line: { type: "none" } });
  label(s, "NEXT STEP", 0.7, 0.55, C.gold);
  title(s, "A pilot with 10 farmers and a bank in Namangan region", 0.7, 0.9, 7.6, C.surface, 32);
  const targets = [["92–95%", "flock survival"], ["80%+", "days with diary entries"], ["96%+", "AI answers matching the norms"]];
  for (let i = 0; i < targets.length; i++) {
    const [v, d] = targets[i];
    s.addText([
      { text: v, options: { bold: true, fontSize: 34, color: C.sun, breakLine: true } },
      { text: d, options: { fontSize: 13, color: C.mintSoft } },
    ], { x: 0.7 + i * 2.55, y: 2.25, w: 2.4, h: 1.15, fontFace: FONT, margin: 0, valign: "top" });
  }
  s.addText("Target figures per flock (42 days).", { x: 0.7, y: 3.5, w: 7.5, h: 0.35, fontFace: FONT, fontSize: 12.5, italic: true, color: C.mintSoft, margin: 0 });
  const road = [["MdSensors", "Sensors and AI cameras in two pilot farms"], ["MdAccountBalance", "Bank dashboard with real pilot data"], ["MdPets", "Then laying hens, sheep and cattle, greenhouses"]];
  for (let i = 0; i < road.length; i++) {
    const [ic, t] = road[i];
    await disc(s, ic, 0.7, 4.15 + i * 0.6, 0.42, C.primary);
    s.addText(t, { x: 1.27, y: 4.15 + i * 0.6, w: 6.6, h: 0.42, fontFace: FONT, fontSize: 14.5, color: C.surface, margin: 0, valign: "middle" });
  }
  s.addImage({ path: A("logo.png"), x: 0.7, y: 6.2, w: 0.7, h: 0.7 });
  s.addText([
    { text: "Salimbek Zamalitdinov, project lead", options: { bold: true, fontSize: 14, color: C.surface, breakLine: true } },
    { text: "+998 93 211 59 13 · salzamov@gmail.com", options: { fontSize: 12.5, color: C.mintSoft } },
  ], { x: 1.55, y: 6.2, w: 6.2, h: 0.7, fontFace: FONT, margin: 0, valign: "middle" });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.2, y: 0.8, w: 3.43, h: 4.75, rectRadius: 0.18, fill: { color: C.surface }, line: { type: "none" } });
  s.addImage({ path: A("qr.png"), x: 9.52, y: 1.1, w: 2.8, h: 2.8 });
  s.addText([
    { text: "Download and try it", options: { bold: true, fontSize: 17, color: C.ink, breakLine: true } },
    { text: "Android app", options: { fontSize: 13, color: C.ink2, breakLine: true } },
    { text: "github.com/ZedRubilan/agrozen", options: { fontSize: 12, color: C.primary } },
  ], { x: 9.3, y: 4.05, w: 3.23, h: 1.3, fontFace: FONT, margin: 0, align: "center", valign: "middle" });
  for (const [k, x] of [["green", 9.55], ["amber", 10.55], ["red", 11.55]]) {
    s.addImage({ path: A(`chick_${k}.png`), x, y: 5.75, w: 0.8, h: 0.8 });
  }
  s.addText("Thank you!", { x: 9.2, y: 6.6, w: 3.43, h: 0.6, fontFace: FONT, fontSize: 28, bold: true, color: C.surface, align: "center", margin: 0 });
  s.addNotes("Next: a pilot with ten farmers and one bank in Namangan region, with sensors and cameras in two farms. Scan the QR code to install the app. Thank you!");

  await pres.writeFile({ fileName: OUT });
  console.log("wrote", OUT);
})();
