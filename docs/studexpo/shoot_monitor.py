import json, sys, subprocess, time, datetime as dt
from playwright.sync_api import sync_playwright
OUT = sys.argv[1]; LANG = sys.argv[2] if len(sys.argv) > 2 else "ru"; TALL = "--tall" in sys.argv
PORT = 8793
srv = subprocess.Popen([sys.executable, "-m", "http.server", str(PORT), "-d", "/home/abraxis/Desktop/AgroZen/build/web"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1)
today = dt.datetime.now().replace(hour=8, minute=0, second=0, microsecond=0)
arrival = today - dt.timedelta(days=17)
mort = [3,2,2,2,2,2,2,2,2,2,1,2,1,1,1,1,1,0]
feed = [15,18,22,27,32,38,44,51,58,66,74,83,92,102,112,124,136,70]
hist = []
for i in range(18):
    rec = {"date": (arrival+dt.timedelta(days=i)).strftime("%Y-%m-%d"), "day": i+1, "deaths": mort[i], "feed_kg": feed[i]}
    if i == 16: rec["weight_g"] = 655
    hist.append(rec)
names = {"ru": ("Салимбек", "Наманган"), "uz": ("Salimbek", "Namangan"), "en": ("Salimbek", "Namangan")}
prefs = {
  "is_onboarded": True, "onboarding_complete": True, "disclaimer_accepted": True, "app_language": LANG,
  "farmer_name": names[LANG][0], "farmer_district": "Namangan", "farmer_locality": names[LANG][1],
  "arrival_date": arrival.isoformat(), "initial_count": 2000, "current_count": 1971,
  "location_prompt_resolved": True, "daily_reminder_set": True,
  "last_weight": 655.0, "last_weight_day": 17,
  "completed_lessons": ["1", "2", "3"],
  "flock_history_v1": json.dumps(hist),
}
def init_for(extra):
    p = dict(prefs); p.update(extra)
    return "(() => {" + "".join(f"localStorage.setItem({json.dumps('flutter.'+k)}, {json.dumps(json.dumps(v))});" for k, v in p.items()) + "})()"
shots = [
  ("monitor_normal", "/monitor", {}, 9000),
  ("monitor_ammonia", "/monitor?scenario=ammonia", {}, 15000),
  ("monitor_cold", "/monitor?scenario=cold", {}, 15000),
  ("monitor_heat", "/monitor?scenario=heat", {}, 15000),
  ("monitor_mortality", "/monitor?scenario=mortality", {}, 15000),
  ("bank_consent", "/bank-report", {}, 6000),
  ("bank_report", "/bank-report", {"bank_report_consent_at": today.replace(hour=9, minute=30).isoformat()}, 6000),
  ("today_useful", "/home", {}, 7000),
  ("today", "/home", {}, 7000),
  ("plan", "/daily-plan", {}, 6000),
  ("assistant", "/home?tab=2", {}, 6000),
  ("diary", "/diary", {}, 7000),
  ("learn", "/home?tab=3", {}, 6000),
]
only = [a for a in sys.argv[3:] if not a.startswith("--")]
with sync_playwright() as p:
    b = p.chromium.launch()
    for name, route, extra, wait in shots:
        if only and name not in only: continue
        h = 2300 if TALL else 844
        ctx = b.new_context(viewport={"width": 390, "height": h}, device_scale_factor=2 if TALL else 3, locale=f"{LANG}-{LANG.upper()}")
        ctx.add_init_script(init_for(extra))
        ctx.route(lambda u: "supabase" in u or "open-meteo" in u, lambda r: r.abort())
        pg = ctx.new_page()
        pg.goto(f"http://localhost:{PORT}/#{route}")
        pg.wait_for_timeout(wait)
        if name == "today_useful":
            pg.mouse.move(195, 500)
            for _ in range(30):
                pg.mouse.wheel(0, 400); pg.wait_for_timeout(120)
            pg.wait_for_timeout(1500)
        suffix = "_tall" if TALL else ""
        pg.screenshot(path=f"{OUT}/{LANG}_{name}{suffix}.png")
        print("shot", name, flush=True)
        ctx.close()
    b.close()
srv.terminate()
