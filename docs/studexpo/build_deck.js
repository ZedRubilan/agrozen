// AgroZen — StudEXPO-2026 deck (7 slides, English).
// Assets: python3 frame_assets.py en   (phones, dashboard window, camera frame)
// Build:  NODE_PATH=<dir with pptxgenjs, react, react-dom, react-icons, sharp>/node_modules node build_deck.js [out.pptx]
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
  warning: "B45309", warningSoft: "FEF3C7", gold: "F59E0B", sun: "F97316",
  danger: "DC2626", dangerSoft: "FEE2E2", info: "1D4ED8", infoSoft: "DBEAFE",
};
const FONT = "Calibri";
const PHONE_RATIO = 868 / 1827; // frame_assets.py output
const DASH_RATIO = 2480 / 2064;
const CAM_RATIO = 716 / 507;

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

  const cardShadow = () => ({ type: "outer", color: "0F172A", opacity: 0.12, blur: 14, offset: 3, angle: 90 });
  const phoneShadow = () => ({ type: "outer", color: "000000", opacity: 0.35, blur: 20, offset: 8, angle: 90 });

  const phone = (s, file, x, y, h, opts = {}) =>
    s.addImage({ path: A(`phone_${file}.png`), x, y, h, w: h * PHONE_RATIO, shadow: phoneShadow(), altText: `AgroZen screen: ${file}`, ...opts });
  const disc = async (s, name, x, y, d, fill, fg = "FFFFFF") => {
    s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: fill }, line: { type: "none" } });
    const p = d * 0.23;
    s.addImage({ data: await icon(name, fg), x: x + p, y: y + p, w: d - 2 * p, h: d - 2 * p });
  };
  const card = (s, x, y, w, h, fill = C.surface, shadow = true) =>
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.16, fill: { color: fill }, line: { type: "none" }, ...(shadow ? { shadow: cardShadow() } : {}) });
  const label = (s, text, x, y, color = C.primary, w = 8) =>
    s.addText(text, { x, y, w, h: 0.32, fontFace: FONT, fontSize: 13, bold: true, color, charSpacing: 2, margin: 0 });
  const title = (s, text, x, y, w, color = C.ink, size = 34) =>
    s.addText(text, { x, y, w, h: 0.9, fontFace: FONT, fontSize: size, bold: true, color, margin: 0, valign: "top" });
  const pageNo = (s, n, color = C.ink3) =>
    s.addText(String(n), { x: 12.33, y: 7.02, w: 0.5, h: 0.3, fontFace: FONT, fontSize: 10, color, align: "right", margin: 0 });

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
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: cx, y: cy, w, h: 0.42, rectRadius: 0.21, fill: { color: C.primary }, line: { type: "none" } });
    s.addText(t, { x: cx, y: cy, w, h: 0.42, fontFace: FONT, fontSize: 13, bold: true, color: C.surface, align: "center", valign: "middle", margin: 0 });
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
  card(s, 0.4, 4.75, 4.1, 2.25);
  s.addText([
    { text: "2017", options: { bold: true, fontSize: 15, color: C.danger, breakLine: true } },
    { text: "Low-income families got loans to raise chickens. Reportedly, many borrowers couldn't repay, and banks began cutting such loans.", options: { fontSize: 12.5, color: C.ink, breakLine: true, paraSpaceAfter: 8 } },
    { text: "From 1 August 2026", options: { bold: true, fontSize: 15, color: C.primary, breakLine: true } },
    { text: "The state launched concessional poultry loans: up to 10 years at 10% a year.", options: { fontSize: 12.5, color: C.ink } },
  ], { x: 0.62, y: 4.88, w: 3.7, h: 2.0, fontFace: FONT, margin: 0, valign: "top" });
  label(s, "THE PROBLEM", 5.6, 0.55);
  title(s, "Loan taken, flock lost", 5.6, 0.9, 7.2);
  const problems = [
    ["MdThermostat", "No knowledge", "A beginner doesn't know the norms for temperature, feeding and vaccination."],
    ["MdWarningAmber", "The first 14 days are the most dangerous", "A microclimate mistake leads to mass mortality — and nobody measures ammonia or CO2."],
    ["MdLocalHospital", "The specialist is far away", "There is no vet nearby at the moment a question comes up."],
  ];
  for (let i = 0; i < problems.length; i++) {
    const [ic, h, d] = problems[i];
    const y = 2.05 + i * 1.12;
    await disc(s, ic, 5.6, y, 0.6, C.dangerSoft, C.danger);
    s.addText([
      { text: h, options: { bold: true, fontSize: 17, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 13.5, color: C.ink2 } },
    ], { x: 6.4, y: y - 0.05, w: 6.3, h: 0.95, fontFace: FONT, margin: 0, valign: "top" });
  }
  card(s, 5.6, 5.6, 7.1, 1.15, C.surface);
  s.addText([
    { text: "The birds are gone. The debt remains.", options: { bold: true, fontSize: 19, color: C.danger, breakLine: true } },
    { text: "People lose money not because of laziness, but because of mistakes no one warned them about.", options: { fontSize: 13.5, color: C.ink } },
  ], { x: 5.85, y: 5.7, w: 6.7, h: 0.95, fontFace: FONT, margin: 0, valign: "middle" });
  pageNo(s, 2);
  s.addNotes("2017: chicken loans for low-income families went wrong. From August 2026 the state again gives concessional poultry loans. A beginner without knowledge loses the flock in the first two weeks and keeps the debt.");

  // ================= 3. Solution: the app =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "THE SOLUTION", 0.7, 0.45);
  title(s, "AgroZen guides the farmer through all 42 days", 0.7, 0.8, 12);
  const core = [
    ["today", "MdToday", C.sun, "Today", "Targets for temperature, feed and water"],
    ["plan", "MdCalendarMonth", C.primary, "42-day plan", "Ross-308 / Cobb-500 norms for every day"],
    ["assistant", "MdMic", C.info, "AI assistant", "Voice, text or photo — in your language"],
    ["diary", "MdEditNote", C.danger, "Flock diary", "Losses above the norm — the vet's number"],
    ["learn", "MdSchool", C.gold, "Course", "5 lessons and a certificate for a loan"],
  ];
  const ph = 4.25, pw = ph * PHONE_RATIO, gap = (11.93 - 5 * pw) / 4;
  for (let i = 0; i < core.length; i++) {
    const [file, ic, color, h, d] = core[i];
    const x = 0.7 + i * (pw + gap);
    phone(s, file, x, 1.75, ph);
    await disc(s, ic, x, 6.2, 0.46, color);
    s.addText([
      { text: h, options: { bold: true, fontSize: 15, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 11.5, color: C.ink2 } },
    ], { x: x + 0.56, y: 6.12, w: pw + gap - 0.6, h: 0.8, fontFace: FONT, margin: 0, valign: "top" });
  }
  pageNo(s, 3);
  s.addNotes("Five screens a farmer uses every day: today's targets, the 42-day plan, the AI assistant that answers by voice, the diary with alerts and the course that ends with a certificate for a concessional loan.");

  // ================= 4. Smart barn =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "NEW · SMART BARN PROTOTYPE", 0.7, 0.45);
  title(s, "Sensors and an AI camera watch the flock day and night", 0.7, 0.8, 12);
  phone(s, "monitor", 0.7, 1.8, 5.0);
  phone(s, "monitor_alarm", 3.3, 1.8, 5.0);
  const camW = 3.55, camH = camW / CAM_RATIO;
  s.addImage({ path: A("camera_frame.png"), x: 6.0, y: 1.8, w: camW, h: camH, shadow: cardShadow() });
  s.addText([
    { text: "AI camera", options: { bold: true, fontSize: 14, color: C.ink, breakLine: true } },
    { text: "Birds that stop moving, huddling, heat stress", options: { fontSize: 12, color: C.ink2 } },
  ], { x: 6.0, y: 1.9 + camH, w: camW, h: 0.5, fontFace: FONT, margin: 0, valign: "top" });
  const limits = [
    ["MdScience", C.warning, C.warningSoft, "NH3 up to 10 ppm", "People smell it only at 20"],
    ["MdCo2", C.info, C.infoSoft, "CO2 up to 3 000 ppm", "Minimum ventilation"],
    ["MdAir", C.primary, C.primarySoft, "Fans switch on", "Automatically, by relay"],
  ];
  for (let i = 0; i < limits.length; i++) {
    const [ic, fg, bg, h, d] = limits[i];
    const y = 1.8 + i * 0.93;
    card(s, 9.95, y, 2.68, 0.8);
    await disc(s, ic, 10.08, y + 0.15, 0.5, bg, fg);
    s.addText([
      { text: h, options: { bold: true, fontSize: 13.5, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 11, color: C.ink2 } },
    ], { x: 10.68, y: y + 0.08, w: 1.9, h: 0.64, fontFace: FONT, margin: 0, valign: "middle" });
  }
  const flow = [
    ["MdSensors", C.primary, "Sensors", "ESP32: temperature, humidity, NH3, CO2, water, scale"],
    ["MdMemory", C.info, "Edge AI", "Jetson Orin Nano + IP cameras, video stays on the farm"],
    ["MdRule", C.gold, "Norms", "Ross-308 / Cobb-500 for the day — plain code, not AI"],
    ["MdNotificationsActive", C.danger, "Action", "Alert, the vet's number, fans on"],
  ];
  const fw = 1.5, fgap = (6.63 - 4 * fw) / 3;
  for (let i = 0; i < flow.length; i++) {
    const [ic, color, h, d] = flow[i];
    const x = 6.0 + i * (fw + fgap);
    card(s, x, 5.0, fw, 1.5);
    await disc(s, ic, x + 0.14, 5.12, 0.44, color);
    s.addText([
      { text: h, options: { bold: true, fontSize: 13, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 10.5, color: C.ink2 } },
    ], { x: x + 0.14, y: 5.62, w: fw - 0.24, h: 0.85, fontFace: FONT, margin: 0, valign: "top" });
    if (i < flow.length - 1) s.addImage({ data: await icon("MdArrowForward", C.ink3), x: x + fw + fgap / 2 - 0.08, y: 5.67, w: 0.16, h: 0.16 });
  }
  s.addText("Demo mode today: readings are simulated. Hardware goes into two pilot farms in 2027.", { x: 6.0, y: 6.62, w: 6.63, h: 0.3, fontFace: FONT, fontSize: 11, italic: true, color: C.ink3, margin: 0 });
  pageNo(s, 4);
  s.addNotes("In the app open Smart barn and press 'Ammonia': within seconds NH3 passes 10 ppm, the alarm fires and the fans switch on. 'Losses' shows the AI camera boxes on birds that are not moving and the button to call the district vet. All checks are plain code against the Ross-308 norms.");

  // ================= 5. Banks =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "NEW · FOR BANKS", 0.7, 0.45);
  title(s, "Banks see how the flock is doing — and trust the loan", 0.7, 0.8, 12);
  phone(s, "bank_report", 0.7, 1.8, 5.0);
  const dw = 5.75, dh = dw / DASH_RATIO;
  s.addImage({ path: A("browser_dashboard.png"), x: 3.4, y: 1.8, w: dw, h: dh, shadow: cardShadow(), altText: "AgroZen for Banks dashboard" });
  s.addText("Bank dashboard: 10 pilot farmers, survival against the norm, risk and a district disease alert", { x: 3.4, y: 1.88 + dh, w: dw, h: 0.3, fontFace: FONT, fontSize: 11, color: C.ink2, margin: 0 });
  const bank = [
    ["MdVerifiedUser", C.primary, "Farmer's consent", "The report is built from the diary and sent as a PDF only after the farmer agrees."],
    ["MdShield", C.gold, "Score 0–100", "Survival, diary, weight, training — fixed rules the bank can check, not AI."],
    ["MdCampaign", C.danger, "Disease alert", "One tap warns every farmer of the bank in a district."],
  ];
  for (let i = 0; i < bank.length; i++) {
    const [ic, color, h, d] = bank[i];
    const y = 1.8 + i * 1.18;
    await disc(s, ic, 9.5, y, 0.5, color);
    s.addText([
      { text: h, options: { bold: true, fontSize: 14.5, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 11.5, color: C.ink2 } },
    ], { x: 10.1, y: y - 0.04, w: 2.55, h: 1.1, fontFace: FONT, margin: 0, valign: "top" });
  }
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.5, y: 5.45, w: 3.13, h: 1.2, rectRadius: 0.16, fill: { color: C.primary }, line: { type: "none" } });
  s.addText([
    { text: "Free for farmers. ", options: { bold: true } },
    { text: "Banks and microfinance pay: a trained farmer is more likely to repay." },
  ], { x: 9.68, y: 5.5, w: 2.8, h: 1.1, fontFace: FONT, fontSize: 12.5, color: C.surface, margin: 0, valign: "middle" });
  pageNo(s, 5);
  s.addNotes("The farmer agrees, and the app turns the diary into a one-page PDF with a score out of 100. The bank's dashboard shows all its farmers: who is on track, who needs attention, and it can warn every farmer in a district about a disease. This is how AgroZen pays for itself.");

  // ================= 6. Result =================
  s = pres.addSlide();
  s.background = { color: C.bg };
  label(s, "THE RESULT", 0.7, 0.45);
  title(s, "Not a concept: the app already works", 0.7, 0.8, 12);
  const stats = [
    ["42 days", "growing plan with norms for every day", C.primary],
    ["5 lessons", "a course with tests and a certificate", C.info],
    ["13 regions", "vet contacts across Uzbekistan", C.danger],
    ["260 tests", "automated tests check norms, alerts and scores", C.warning],
  ];
  for (let i = 0; i < stats.length; i++) {
    const [v, d, color] = stats[i];
    const x = 0.7 + (i % 2) * 3.05, y = 1.8 + Math.floor(i / 2) * 1.6;
    card(s, x, y, 2.9, 1.42);
    s.addText([
      { text: v, options: { bold: true, fontSize: 30, color, breakLine: true } },
      { text: d, options: { fontSize: 12, color: C.ink2 } },
    ], { x: x + 0.22, y: y + 0.12, w: 2.5, h: 1.2, fontFace: FONT, margin: 0, valign: "middle" });
  }
  const tech = [["MdPhoneAndroid", "Flutter", "Android, iOS, web"], ["MdCloud", "Supabase + Gemini", "cloud data and AI"], ["MdWifiOff", "Offline", "plan and diary"], ["MdTranslate", "3 languages", "uz · ru · en"]];
  for (let i = 0; i < tech.length; i++) {
    const [ic, h, d] = tech[i];
    const x = 0.7 + i * 1.53;
    await disc(s, ic, x, 5.12, 0.42, C.primarySoft, C.primary);
    s.addText([
      { text: h, options: { bold: true, fontSize: 12, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 10.5, color: C.ink2 } },
    ], { x, y: 5.62, w: 1.45, h: 0.6, fontFace: FONT, margin: 0, valign: "top" });
  }
  // How the AI answers
  card(s, 7.0, 1.8, 5.63, 3.0);
  s.addText("The AI answers only from a verified knowledge base", { x: 7.25, y: 1.95, w: 5.2, h: 0.4, fontFace: FONT, fontSize: 15, bold: true, color: C.ink, margin: 0 });
  const steps = [
    ["MdMic", C.info, "Question", "voice, text or photo"],
    ["MdMenuBook", C.primary, "Search the base", "Ross-308 / Cobb-500"],
    ["MdLocalHospital", C.danger, "Not in the base?", "\"ask your vet\""],
  ];
  for (let i = 0; i < steps.length; i++) {
    const [ic, color, h, d] = steps[i];
    const x = 7.25 + i * 1.78;
    await disc(s, ic, x + 0.5, 2.6, 0.55, color);
    s.addText([
      { text: h, options: { bold: true, fontSize: 12.5, color: C.ink, breakLine: true } },
      { text: d, options: { fontSize: 11, color: C.ink2 } },
    ], { x, y: 3.25, w: 1.55, h: 0.7, fontFace: FONT, margin: 0, align: "center", valign: "top" });
    if (i < steps.length - 1) s.addImage({ data: await icon("MdArrowForward", C.ink3), x: x + 1.6, y: 2.78, w: 0.18, h: 0.18 });
  }
  s.addText("Alerts are counted by plain code against the norms — they never depend on an AI answer.", { x: 7.25, y: 4.05, w: 5.2, h: 0.55, fontFace: FONT, fontSize: 11.5, color: C.ink2, margin: 0 });
  card(s, 7.0, 5.05, 5.63, 0.9, C.dangerSoft, false);
  await disc(s, "MdHealthAndSafety", 7.22, 5.25, 0.5, C.danger);
  s.addText("No diagnoses or dosages — the app calls the district vet in time.", { x: 7.88, y: 5.1, w: 4.6, h: 0.8, fontFace: FONT, fontSize: 14, bold: true, color: C.ink, margin: 0, valign: "middle" });
  pageNo(s, 6);
  s.addNotes("Everything shown is in the Android app today, in three languages and offline. 260 automated tests check the norms, the alerts and the bank score. The AI never names medicines: outside its knowledge base it sends the farmer to the vet.");

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
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.2, y: 0.8, w: 3.43, h: 4.75, rectRadius: 0.18, fill: { color: C.surface }, line: { type: "none" }, shadow: cardShadow() });
  s.addImage({ path: A("qr.png"), x: 9.52, y: 1.1, w: 2.8, h: 2.8 });
  s.addText([
    { text: "Download and try it", options: { bold: true, fontSize: 17, color: C.ink, breakLine: true } },
    { text: "Android app", options: { fontSize: 13, color: C.ink2, breakLine: true } },
    { text: "github.com/ZedRubilan/agrozen", options: { fontSize: 12, color: C.primary } },
  ], { x: 9.3, y: 4.05, w: 3.23, h: 1.3, fontFace: FONT, margin: 0, align: "center", valign: "middle" });
  s.addText("Thank you!", { x: 9.2, y: 5.85, w: 3.43, h: 0.7, fontFace: FONT, fontSize: 30, bold: true, color: C.surface, align: "center", margin: 0 });
  s.addNotes("Next: a pilot with ten farmers and one bank in Namangan region, with sensors and cameras in two farms. Scan the QR code to install the app. Thank you!");

  await pres.writeFile({ fileName: OUT });
  console.log("wrote", OUT);
})();
