#!/usr/bin/env python3

import os
import smtplib
from email.mime.text import MIMEText
from datetime import datetime

# =========================
# CONFIGURACIÓN
# =========================

LOG_FILES = [
    "/var/log/messages",
    "/var/log/secure",
    # add more logs
]

STATE_FILE = "/var/tmp/log_monitor_state"

SMTP_SERVER = "localhost"   # usa localhost si tienes postfix
SMTP_PORT = 25

EMAIL_FROM = "alerts@tu-dominio.com"

EMAIL_TO = [
    "tuemail@empresa.com",          # email normal
    "canal-teams@empresa.com"       # email del canal de Teams
]

SUBJECT = "[ALERT] ERROR detected in logs"

# =========================
# FUNCIONES
# =========================

def load_state():
    if not os.path.exists(STATE_FILE):
        return {}
    state = {}
    with open(STATE_FILE, "r") as f:
        for line in f:
            file, offset = line.strip().split("|")
            state[file] = int(offset)
    return state


def save_state(state):
    with open(STATE_FILE, "w") as f:
        for file, offset in state.items():
            f.write(f"{file}|{offset}\n")


def read_new_lines(file, last_offset):
    try:
        with open(file, "r") as f:
            f.seek(last_offset)
            lines = f.readlines()
            new_offset = f.tell()
        return lines, new_offset
    except FileNotFoundError:
        return [], last_offset


def find_errors(lines):
    return [line for line in lines if "ERROR" in line.upper()]


def send_email(body):
    msg = MIMEText(body)
    msg["Subject"] = SUBJECT
    msg["From"] = EMAIL_FROM
    msg["To"] = ", ".join(EMAIL_TO)

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())


# =========================
# MAIN
# =========================

def main():
    state = load_state()
    alerts = []

    for log_file in LOG_FILES:
        last_offset = state.get(log_file, 0)

        lines, new_offset = read_new_lines(log_file, last_offset)
        errors = find_errors(lines)

        if errors:
            alerts.append(f"\n--- {log_file} ---\n")
            alerts.extend(errors[-20:])  # limita a últimas 20 líneas

        state[log_file] = new_offset

    save_state(state)

    if alerts:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        body = f"ERROR detected in logs at {timestamp}\n"
        body += "".join(alerts)

        send_email(body)


if __name__ == "__main__":
    main()
