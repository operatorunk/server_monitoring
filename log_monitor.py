#!/usr/bin/env python3

import os
import smtplib
import socket
from email.mime.text import MIMEText
from datetime import datetime

# =========================
# CONFIGURATION
# =========================

LOG_FILES = [
    "/tmp/test_error.log",
    # "/path/other/file.log",
]

STATE_FILE = "/var/tmp/log_monitor_state"

SMTP_SERVER = "localhost"
SMTP_PORT = 25

EMAIL_FROM = "email@company.com"

EMAIL_TO = [
    "myuseremail@company.com",
    # "channel-teams@company.com",
]

SUBJECT = "[ALERT] ERROR detected in logs"

SEARCH_TERMS = ["ERROR"]
MAX_LINES_PER_LOG = 20


# =========================
# STATUS CHECKS
# =========================

def load_state():
    """
    Load file state.
    Format:
    /path/log|inode|offset
    """
    state = {}

    if not os.path.exists(STATE_FILE):
        return state

    with open(STATE_FILE, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            parts = line.strip().split("|", 2)
            if len(parts) != 3:
                continue

            file_path, inode_str, offset_str = parts

            try:
                state[file_path] = {
                    "inode": int(inode_str),
                    "offset": int(offset_str),
                }
            except ValueError:
                continue

    return state


def save_state(state):
    """
    Save file state.
    """
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        for file_path, info in state.items():
            inode = info.get("inode", 0)
            offset = info.get("offset", 0)
            f.write(f"{file_path}|{inode}|{offset}\n")


# =========================
# LOGGING
# =========================

def get_file_info(file_path):
    """
    Returns inode and file size.
    """
    stat_result = os.stat(file_path)
    return stat_result.st_ino, stat_result.st_size


def read_new_lines(file_path, saved_inode, saved_offset):
    """
    Read only new lines in the log file.

    Logic:
    - Si el fichero no existe: no hace nada.
    - Si cambia el inode: es un log nuevo con el mismo nombre -> offset = 0.
    - Si el tamaño actual es menor que el offset guardado: truncado -> offset = 0.
    """
    if not os.path.exists(file_path):
        print(f"[DEBUG] File not found: {file_path}")
        return [], saved_inode, saved_offset

    current_inode, current_size = get_file_info(file_path)

    # Caso 1: fichero nuevo con mismo nombre (rotación por rename + creación)
    if saved_inode and current_inode != saved_inode:
        print(f"[DEBUG] Detected new file by inode change for {file_path}")
        saved_offset = 0

    # Caso 2: truncado / reset del fichero
    elif current_size < saved_offset:
        print(f"[DEBUG] Detected truncated file for {file_path}")
        saved_offset = 0

    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        f.seek(saved_offset)
        lines = f.readlines()
        new_offset = f.tell()

    print(
        f"[DEBUG] Read {len(lines)} new lines from {file_path} "
        f"(inode={current_inode}, old_offset={saved_offset}, new_offset={new_offset})"
    )

    return lines, current_inode, new_offset


def find_errors(lines):
    """
    Find terms defined by SEARCH_TERMS.
    """
    matches = []
    terms_upper = [term.upper() for term in SEARCH_TERMS]

    for line in lines:
        line_upper = line.upper()
        if any(term in line_upper for term in terms_upper):
            matches.append(line)

    print(f"[DEBUG] Found {len(matches)} matching lines")

    return matches


# =========================
# ALERTING
# =========================

def send_email(body):
    """
    Sends an email using Postfix.
    """
    hostname = socket.gethostname()

    msg = MIMEText(body)
    msg["Subject"] = f"{SUBJECT} [{hostname}]"
    msg["From"] = EMAIL_FROM
    msg["To"] = ", ".join(EMAIL_TO)

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())

    print("[DEBUG] Email handed off to local SMTP successfully")


# =========================
# MAIN
# =========================

def main():
    hostname = socket.gethostname()
    state = load_state()
    alerts = []

    for log_file in LOG_FILES:
        saved_info = state.get(log_file, {"inode": 0, "offset": 0})
        saved_inode = saved_info.get("inode", 0)
        saved_offset = saved_info.get("offset", 0)

        print(
            f"[DEBUG] Processing {log_file} "
            f"(saved_inode={saved_inode}, saved_offset={saved_offset})"
        )

        lines, current_inode, new_offset = read_new_lines(
            log_file,
            saved_inode,
            saved_offset,
        )

        matches = find_errors(lines)

        if matches:
            alerts.append(f"\n--- {log_file} ---\n")
            alerts.extend(matches[-MAX_LINES_PER_LOG:])

        state[log_file] = {
            "inode": current_inode,
            "offset": new_offset,
        }

    save_state(state)

    if alerts:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        body = (
            f"Alert generated at {timestamp}\n"
            f"Host: {hostname}\n"
            f"Search terms: {', '.join(SEARCH_TERMS)}\n"
            f"\n"
        )
        body += "".join(alerts)

        print("[DEBUG] Alerts found, sending email")
        send_email(body)
    else:
        print("[DEBUG] No alerts found")


if __name__ == "__main__":
    main()
