#!/usr/bin/env python3

import os
import smtplib
from email.mime.text import MIMEText
from datetime import datetime

LOG_FILES = [
    "/ruta/al/log/de/prueba.log",
]

STATE_FILE = "/var/tmp/log_monitor_state"

SMTP_SERVER = "localhost"
SMTP_PORT = 25

EMAIL_FROM = "email@company.com"

EMAIL_TO = [
    "myuseremail@company.com",
    "email_del_canal_teams@company.com",
]

SUBJECT = "[ALERT] ERROR detected in logs"


def load_state():
    if not os.path.exists(STATE_FILE):
        return {}
    state = {}
    with open(STATE_FILE, "r") as f:
        for line in f:
            parts = line.strip().split("|", 1)
            if len(parts) == 2:
                state[parts[0]] = int(parts[1])
    return state


def save_state(state):
    with open(STATE_FILE, "w") as f:
        for file_path, offset in state.items():
            f.write(f"{file_path}|{offset}\n")


def read_new_lines(file_path, last_offset):
    if not os.path.exists(file_path):
        print(f"[DEBUG] File not found: {file_path}")
        return [], last_offset

    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        f.seek(last_offset)
        lines = f.readlines()
        new_offset = f.tell()

    print(f"[DEBUG] Read {len(lines)} new lines from {file_path}")
    return lines, new_offset


def find_errors(lines):
    errors = [line for line in lines if "ERROR" in line.upper()]
    print(f"[DEBUG] Found {len(errors)} error lines")
    if errors:
        for line in errors:
            print(f"[DEBUG] Match: {line.rstrip()}")
    return errors


def send_email(body):
    print("[DEBUG] Sending email...")
    msg = MIMEText(body)
    msg["Subject"] = SUBJECT
    msg["From"] = EMAIL_FROM
    msg["To"] = ", ".join(EMAIL_TO)

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())

    print("[DEBUG] Email sent successfully")


def main():
    state = load_state()
    alerts = []

    for log_file in LOG_FILES:
        last_offset = state.get(log_file, 0)
        print(f"[DEBUG] Processing {log_file} from offset {last_offset}")

        lines, new_offset = read_new_lines(log_file, last_offset)
        errors = find_errors(lines)

        if errors:
            alerts.append(f"\n--- {log_file} ---\n")
            alerts.extend(errors)

        state[log_file] = new_offset

    save_state(state)

    if alerts:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        body = f"ERROR detected in logs at {timestamp}\n\n"
        body += "".join(alerts)
        send_email(body)
    else:
        print("[DEBUG] No alerts found")


if __name__ == "__main__":
    main()
