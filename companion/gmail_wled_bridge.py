#!/usr/bin/env python3
"""
Gmail -> WLED notification bridge.

Watches a Gmail inbox over IMAP and switches your WLED lamps to a
preset whenever there is UNREAD mail matching a rule (specific sender
or Gmail label). When the matching mail is read/archived, the lamps
return to the idle preset. Rules are checked top-down; the first rule
with unread mail wins, so put the most important senders first.

Runs on any always-on machine on the same network as the lamps
(Raspberry Pi, desktop, NAS). Python 3.8+, standard library only.

Setup:
  1. Gmail: enable IMAP (Gmail settings > Forwarding and POP/IMAP).
  2. Google account: turn on 2-Step Verification, then create an App
     Password (myaccount.google.com/apppasswords) for "Mail".
  3. Set environment variables GMAIL_USER and GMAIL_APP_PASSWORD.
  4. Edit LAMPS and RULES below.
  5. In the WLED app, save presets matching the numbers in RULES
     (e.g. preset 1 = idle warm white, 2 = red breathe, 3 = blue).
  6. Run:  python3 gmail_wled_bridge.py

Tip - many lamps, one command: turn on WLED Sync (Config > Sync) with
one lamp set to "send" and the rest to "receive", then list ONLY the
sending lamp in LAMPS; every lamp in the house follows it.

Tip - manage senders in Gmail instead of here: create a Gmail filter
that applies a label like "lamp-red" to whoever you want, and use
{"label": "lamp-red", ...} rules. Then you never edit this file to
add/remove senders.
"""

import imaplib
import json
import os
import time
import urllib.request

# ---------------------------------------------------------------- config
GMAIL_USER = os.environ.get("GMAIL_USER")
GMAIL_APP_PASSWORD = os.environ.get("GMAIL_APP_PASSWORD")

LAMPS = [
    "192.168.1.50",          # WLED lamp IPs or mDNS names (wled-xxxx.local)
    # "192.168.1.51",
]

IDLE_PRESET = 1              # preset when no rule matches (your normal look)
POLL_SECONDS = 25            # how often to check the mailbox

# First matching rule (top-down) wins. Each rule needs a WLED preset
# number and EITHER "from" (matches sender address, substrings ok,
# e.g. "@bigclient.com") OR "label" (a Gmail label applied by filters).
RULES = [
    {"from": "boss@example.com",     "preset": 2},   # red
    {"from": "@importantclient.com", "preset": 3},   # blue
    {"label": "lamp-urgent",         "preset": 4},   # whatever you saved
]

# ------------------------------------------------------------- internals
def imap_connect():
    imap = imaplib.IMAP4_SSL("imap.gmail.com", 993)
    imap.login(GMAIL_USER, GMAIL_APP_PASSWORD)
    imap.select("INBOX", readonly=True)
    return imap


def unread_matches(imap, rule):
    if "label" in rule:
        criteria = ("UNSEEN", "X-GM-LABELS", '"%s"' % rule["label"])
    else:
        criteria = ("UNSEEN", "FROM", '"%s"' % rule["from"])
    typ, data = imap.search(None, *criteria)
    return typ == "OK" and bool(data and data[0].split())


def set_preset(lamp, preset):
    req = urllib.request.Request(
        "http://%s/json/state" % lamp,
        data=json.dumps({"ps": preset}).encode(),
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req, timeout=5).read()


def apply_preset(preset):
    for lamp in LAMPS:
        try:
            set_preset(lamp, preset)
        except Exception as exc:
            print("lamp %s unreachable: %s" % (lamp, exc), flush=True)


def main():
    if not GMAIL_USER or not GMAIL_APP_PASSWORD:
        raise SystemExit("Set GMAIL_USER and GMAIL_APP_PASSWORD env vars.")
    current = None
    imap = None
    while True:
        try:
            if imap is None:
                imap = imap_connect()
                print("connected to Gmail as %s" % GMAIL_USER, flush=True)
            imap.noop()
            wanted = IDLE_PRESET
            for rule in RULES:
                if unread_matches(imap, rule):
                    wanted = rule["preset"]
                    break
            if wanted != current:
                print("preset -> %s" % wanted, flush=True)
                apply_preset(wanted)
                current = wanted
        except (imaplib.IMAP4.abort, imaplib.IMAP4.error, OSError) as exc:
            print("IMAP hiccup, reconnecting: %s" % exc, flush=True)
            try:
                if imap is not None:
                    imap.logout()
            except Exception:
                pass
            imap = None
            time.sleep(10)
            continue
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
