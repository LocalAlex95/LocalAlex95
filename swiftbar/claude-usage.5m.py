#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>1.0</xbar.version>
# <xbar.desc>Zeigt das verbleibende Claude-Abo-Limit (5 Stunden / Woche) in der Menüleiste.</xbar.desc>
# <xbar.dependencies>python3, Claude Code (eingeloggt)</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
#
# Der Dateiname bestimmt das Intervall: claude-usage.5m.py = alle 5 Minuten.
#
# Datenquelle: derselbe (inoffizielle, undokumentierte) Endpunkt, den Claude Code
# für /usage nutzt. Das Login-Token wird nur gelesen (Schlüsselbund-Eintrag
# "Claude Code-credentials") und ausschließlich an api.anthropic.com geschickt.

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
KEYCHAIN_SERVICE = "Claude Code-credentials"
CREDENTIALS_FILE = os.path.expanduser("~/.claude/.credentials.json")

# Welches Limit steht in der Menüleiste? "five_hour" oder "seven_day"
TITLE_LIMIT = os.environ.get("CLAUDE_USAGE_TITLE", "five_hour")

LIMITS = [
    ("five_hour", "5-Stunden-Limit"),
    ("seven_day", "Wochen-Limit (alle Modelle)"),
    ("seven_day_opus", "Wochen-Limit Opus"),
    ("seven_day_sonnet", "Wochen-Limit Sonnet"),
]


def fail(title, *lines):
    print("✳ " + title + " | color=#999999")
    print("---")
    for line in lines:
        print(line)
    print("---")
    print("Jetzt aktualisieren | refresh=true")
    sys.exit(0)


def read_credentials():
    raw = None
    try:
        raw = subprocess.run(
            ["/usr/bin/security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"],
            capture_output=True, text=True, timeout=15,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    if not raw and os.path.exists(CREDENTIALS_FILE):
        with open(CREDENTIALS_FILE, encoding="utf-8") as fh:
            raw = fh.read()
    if not raw:
        return None
    try:
        return json.loads(raw).get("claudeAiOauth")
    except ValueError:
        return None


def fetch_usage(token):
    req = urllib.request.Request(USAGE_URL, headers={
        "Authorization": "Bearer " + token,
        "anthropic-beta": "oauth-2025-04-20",
        "Accept": "application/json",
        "User-Agent": "swiftbar-claude-usage/1.0",
    })
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def parse_time(value):
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def format_reset(value, now=None):
    dt = parse_time(value)
    if dt is None:
        return None
    now = now or datetime.now(timezone.utc)
    minutes = int((dt - now).total_seconds() // 60)
    if minutes <= 0:
        return "Reset jetzt"
    days, rest = divmod(minutes, 1440)
    hours, mins = divmod(rest, 60)
    if days:
        span = "%d T %d Std" % (days, hours)
    elif hours:
        span = "%d Std %d Min" % (hours, mins)
    else:
        span = "%d Min" % mins
    local = dt.astimezone()
    return "Reset in %s (%s)" % (span, local.strftime("%a %d.%m. %H:%M"))


def remaining(entry):
    """Verbleibende Prozent aus einem Limit-Eintrag, oder None."""
    if not isinstance(entry, dict) or entry.get("utilization") is None:
        return None
    try:
        used = float(entry["utilization"])
    except (TypeError, ValueError):
        return None
    return max(0.0, min(100.0, 100.0 - used))


def color(rest):
    if rest <= 10:
        return "#FF3B30"
    if rest <= 30:
        return "#FF9500"
    return None


def bar(rest, width=20):
    filled = int(round(rest / 100.0 * width))
    return "█" * filled + "░" * (width - filled)


def render(data):
    out = []
    title_rest = remaining(data.get(TITLE_LIMIT))
    if title_rest is None:
        out.append("✳ –")
    else:
        c = color(title_rest)
        out.append("✳ %d%%" % round(title_rest) + (" | color=" + c if c else ""))
    out.append("---")
    out.append("Claude – verbleibendes Kontingent | size=12")
    shown = 0
    for key, label in LIMITS:
        entry = data.get(key)
        rest = remaining(entry)
        if rest is None:
            continue
        shown += 1
        c = color(rest)
        suffix = " color=" + c if c else ""
        out.append("---")
        out.append("%s: %d%% übrig" % (label, round(rest)) + (" |" + suffix if c else ""))
        out.append("%s | font=Menlo size=11 trim=false%s" % (bar(rest), suffix))
        reset = format_reset(entry.get("resets_at"))
        if reset:
            out.append(reset + " | size=11")
    if not shown:
        out.append("---")
        out.append("Keine Limit-Daten in der Antwort gefunden")
    out.append("---")
    out.append("Stand: " + datetime.now().strftime("%H:%M") + " | size=11")
    out.append("Jetzt aktualisieren | refresh=true")
    out.append("Nutzung auf claude.ai öffnen | href=https://claude.ai/settings/usage")
    return "\n".join(out)


def main():
    mock = os.environ.get("CLAUDE_USAGE_MOCK")
    if mock:
        with open(mock, encoding="utf-8") as fh:
            print(render(json.load(fh)))
        return

    creds = read_credentials()
    if not creds or not creds.get("accessToken"):
        fail("?", "Kein Claude-Code-Login gefunden",
             "Im Terminal `claude` starten und mit /login anmelden | size=11")

    try:
        data = fetch_usage(creds["accessToken"])
    except urllib.error.HTTPError as err:
        if err.code in (401, 403):
            fail("!", "Token abgelaufen oder ungültig (HTTP %d)" % err.code,
                 "Claude Code einmal kurz starten, dann wird es erneuert | size=11")
        fail("!", "Fehler vom Server: HTTP %d" % err.code)
    except (urllib.error.URLError, OSError, ValueError) as err:
        fail("!", "Abruf fehlgeschlagen", str(err)[:80] + " | size=11")

    print(render(data))


if __name__ == "__main__":
    main()
