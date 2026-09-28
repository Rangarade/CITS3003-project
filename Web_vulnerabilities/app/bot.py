# NEON//WIRE operator bot for the XSS challenge.
# Opens the feedback board in a headless browser while holding the admin
# grid_session cookie (readable by JS), so any stored payload runs as the admin
# and can steal that cookie. Loops every 20s; --once for a single visit.

import os
import sys
import glob
import time
from playwright.sync_api import sync_playwright

APP = os.environ.get("BOT_TARGET", "http://127.0.0.1:8080")
FLAG_COOKIE = os.environ.get("BOT_FLAG_COOKIE", "FLAG{nw042_xss_cookie_theft}")


def chromium_path():
    hits = sorted(glob.glob("/opt/pw-browsers/chromium*/chrome-linux/chrome"))
    return hits[-1] if hits else None


def visit_once():
    with sync_playwright() as p:
        launch = {"headless": True, "args": ["--no-sandbox"]}
        exe = chromium_path()
        if exe:
            launch["executable_path"] = exe
        browser = p.chromium.launch(**launch)
        context = browser.new_context()
        context.add_cookies([{
            "name": "grid_session", "value": FLAG_COOKIE,
            "url": APP, "httpOnly": False, "sameSite": "Lax",
        }])
        page = context.new_page()
        page.goto(APP + "/grid/feedback", wait_until="networkidle")
        time.sleep(1.5)   # let onerror/onload fire
        browser.close()


if __name__ == "__main__":
    once = "--once" in sys.argv
    while True:
        try:
            visit_once()
        except Exception as e:
            print("[bot] error:", e, flush=True)
        if once:
            break
        time.sleep(20)
