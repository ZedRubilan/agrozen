"""Frame app screenshots as phones and the bank dashboard as a browser window,
for the StudEXPO deck (build_deck.js). Usage: python3 frame_assets.py en"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
SCREENS, OUT = HERE / "screens", HERE / "assets"
LANG = sys.argv[1] if len(sys.argv) > 1 else "en"
OUT.mkdir(exist_ok=True)

def rounded(img, r):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius=r, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0)); out.paste(img, (0, 0), m)
    return out

def phone(src, dst, crop_h=None):
    shot = Image.open(src).convert("RGB")
    if crop_h: shot = shot.crop((0, 0, shot.width, crop_h))
    shot = shot.resize((824, int(824 * shot.height / shot.width)), Image.LANCZOS)
    bez = 22
    W, H = shot.width + bez * 2, shot.height + bez * 2
    body = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, W - 1, H - 1), radius=118, fill=(11, 15, 20, 255))
    d.rounded_rectangle((3, 3, W - 4, H - 4), radius=115, outline=(60, 66, 74, 255), width=3)
    body.alpha_composite(rounded(shot.convert("RGBA"), 96), (bez, bez))
    body.save(dst)

def browser(src, dst, title):
    shot = Image.open(src).convert("RGB")
    # The page centres a 1240 px column; trim the empty sides of the 1440 px window.
    side = int(shot.width * 100 / 1440)
    shot = shot.crop((side, 0, shot.width - side, shot.height))
    bar = 64
    W, H = shot.width, shot.height + bar
    win = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    d = ImageDraw.Draw(win)
    d.rectangle((0, 0, W, bar), fill=(232, 238, 234, 255))
    for i, c in enumerate([(239, 68, 68), (245, 158, 11), (34, 197, 94)]):
        d.ellipse((24 + i * 30, 22, 44 + i * 30, 42), fill=c)
    d.rounded_rectangle((140, 14, W - 140, 50), radius=18, fill=(255, 255, 255, 255))
    win.paste(shot, (0, bar))
    win = rounded(win, 28)
    win.save(dst)

PHONES = {
    "today": "today", "plan": "plan", "assistant": "assistant", "diary": "diary", "learn": "learn",
    "monitor": "monitor_ammonia", "monitor_alarm": "monitor_mortality", "monitor_cold": "monitor_cold",
    "bank_report": "bank_report", "bank_consent": "bank_consent",
}
for name, shot in PHONES.items():
    phone(SCREENS / f"{LANG}_{shot}.png", OUT / f"phone_{name}.png")
browser(Path(sys.argv[2]) if len(sys.argv) > 2 else SCREENS / f"{LANG}_bank_dashboard.png", OUT / "browser_dashboard.png", "AgroZen for Banks")
Image.open(SCREENS / f"{LANG}_camera_frame.png").save(OUT / "camera_frame.png")
print("framed", len(PHONES), "phones +", OUT / "browser_dashboard.png")
