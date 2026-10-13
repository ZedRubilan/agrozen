"""Render docs/poster/agrozen_poster.html to an A3 PDF (vector) and a 300 dpi PNG.

Usage: python3 docs/poster/render_poster.py
Needs Playwright with Chromium and an internet connection (Google Fonts, QR library).
"""
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
SRC = HERE / "agrozen_poster.html"

with sync_playwright() as p:
    browser = p.chromium.launch()
    W, H = 1782, 1260  # .board size in agrozen_poster.html
    page = browser.new_page(viewport={"width": W, "height": H}, device_scale_factor=4961 / W)  # 300 dpi at A3
    page.goto(SRC.as_uri(), wait_until="networkidle")
    page.evaluate("document.fonts.ready")
    page.wait_for_timeout(800)
    overflow = page.evaluate("""() => [...document.querySelectorAll('.card, .board')]
        .filter(e => e.scrollHeight > e.clientHeight + 1 || e.scrollWidth > e.clientWidth + 1)
        .map(e => (e.className + ' ' + (e.querySelector('.label')?.textContent || '')).trim() + ` ${e.scrollHeight}>${e.clientHeight}`)""")
    print("overflow:", overflow or "none")
    page.screenshot(path=str(HERE / "agrozen_poster_A3.png"), full_page=False)
    page.pdf(path=str(HERE / "agrozen_poster_A3.pdf"), width="420mm", height="297mm",
             print_background=True, margin={"top": "0", "right": "0", "bottom": "0", "left": "0"},
             prefer_css_page_size=True, scale=1587.4 / W)
    browser.close()
print("wrote", HERE / "agrozen_poster_A3.pdf")
