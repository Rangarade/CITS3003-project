# NEON//WIRE grid portal - web challenges for the CITS3006 CTF box.
# Three vulns in one Flask app:
#   1. blind SQL injection    -> /grid/records
#   2. stored XSS             -> /grid/feedback   (operator bot steals cookie)
#   3. Jinja2 SSTI -> RCE     -> /grid/ops/template  (admin only)

import os
import re
import sqlite3
import html
from flask import (
    Flask, request, redirect, url_for,
    render_template, render_template_string, g
)

app = Flask(__name__)

BASE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE, "grid.db")

FLAG_SQLI = "FLAG{nw042_blind_sqli}"
FLAG_XSS  = "FLAG{nw042_xss_cookie_theft}"
FLAG_SSTI = "FLAG{nw042_ssti_rce}"

# SSTI flag goes on disk so solving it means a real file read via RCE.
SSTI_FLAG_PATH = os.path.join(BASE, "flag_ssti.txt")
with open(SSTI_FLAG_PATH, "w") as fh:
    fh.write(FLAG_SSTI + "\n")

# The admin cookie the XSS challenge is after. Not httponly, so JS can read it.
ADMIN_COOKIE = FLAG_XSS


def init_db():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()
    cur.execute("CREATE TABLE records (id INTEGER PRIMARY KEY, codename TEXT, sector TEXT)")
    cur.executemany(
        "INSERT INTO records (codename, sector) VALUES (?, ?)",
        [("nexus", "CORE"), ("halcyon", "PERIMETER"), ("vantablack", "ARCHIVE"),
         ("cinder", "RELAY"), ("obsidian", "CORE")],
    )
    # flag lives in its own table so the lookup never returns it directly
    cur.execute("CREATE TABLE vault (id INTEGER PRIMARY KEY, flag TEXT)")
    cur.execute("INSERT INTO vault (flag) VALUES (?)", (FLAG_SQLI,))
    con.commit()
    con.close()


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
    return g.db


@app.teardown_appcontext
def close_db(exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()


@app.route("/")
def home():
    return render_template("home.html")


# --- Challenge 1: blind SQL injection ---------------------------------------
# codename goes straight into the query. Response is only found/not-found and
# errors are hidden, so no union/error path - you extract the vault flag with a
# boolean oracle, one character at a time.
@app.route("/grid/records")
def records():
    q = request.args.get("q", "")
    result = None
    if q:
        sql = "SELECT id FROM records WHERE codename = '" + q + "'"
        try:
            cur = get_db().cursor()
            cur.execute(sql)
            result = "found" if cur.fetchall() else "empty"
        except Exception:
            result = "empty"          # stay blind - never leak the SQL error
    return render_template("records.html", q=q, result=result)


# --- Challenge 2: stored XSS ------------------------------------------------
FEEDBACK = []

# only strips the <script> open tag, so any other tag+handler gets through
SCRIPT_RE = re.compile(r"<\s*script[^>]*>", re.IGNORECASE)


def naive_filter(s):
    return SCRIPT_RE.sub("", s)


@app.route("/grid/feedback", methods=["GET", "POST"])
def feedback():
    if request.method == "POST":
        FEEDBACK.append(naive_filter(request.form.get("message", "")))
        return redirect(url_for("feedback"))
    return render_template("feedback.html", entries=FEEDBACK)   # rendered |safe


@app.route("/grid/ops")
def ops_dashboard():
    if request.cookies.get("grid_session") != ADMIN_COOKIE:
        return render_template("denied.html"), 403
    return render_template("ops.html")


# --- Challenge 3: Jinja2 SSTI -> RCE ----------------------------------------
# admin-only. operator input is rendered as a template. blocklist kills the
# textbook '__class__' payload, so you need the \x5f hex-escape + |attr bypass.
SSTI_BLOCK = ["__", "mro", "subclasses"]


@app.route("/grid/ops/template", methods=["GET", "POST"])
def ops_template():
    if request.cookies.get("grid_session") != ADMIN_COOKIE:
        return render_template("denied.html"), 403

    rendered = None
    error = None
    tpl = ""
    if request.method == "POST":
        tpl = request.form.get("template", "")
        if any(bad in tpl.lower() for bad in SSTI_BLOCK):
            error = "TEMPLATE REJECTED :: restricted token detected"
        else:
            try:
                rendered = render_template_string(tpl)   # vulnerable sink
            except Exception as e:
                error = "RENDER ERROR :: " + html.escape(str(e))
    return render_template("template.html", rendered=rendered, error=error, tpl=tpl)


# --- test harness (off by default; only for our own testing) ----------------
COLLECTED = []


@app.route("/collect")
def collect():
    if os.environ.get("NEONWIRE_TESTHARNESS") != "1":
        return ("disabled", 404)
    COLLECTED.append(dict(request.args))
    return ("ok", 200)


@app.route("/collected")
def collected():
    if os.environ.get("NEONWIRE_TESTHARNESS") != "1":
        return ("disabled", 404)
    return {"collected": COLLECTED}


init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
