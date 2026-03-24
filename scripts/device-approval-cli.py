#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path


def resolve_workspace() -> Path:
    return Path(__file__).resolve().parent.parent


def default_db_path() -> Path:
    return resolve_workspace() / ".runtime" / "macos" / "auth.db"


def connect(db_path: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    return connection


def list_pending(connection: sqlite3.Connection) -> int:
    rows = connection.execute(
        """
        SELECT
            device_approval_requests.request_token,
            users.username,
            device_approval_requests.device_name,
            device_approval_requests.device_id,
            device_approval_requests.platform,
            device_approval_requests.app_type,
            device_approval_requests.requested_ip,
            device_approval_requests.requested_user_agent,
            device_approval_requests.created_at
        FROM device_approval_requests
        LEFT JOIN users ON users.id = device_approval_requests.user_id
        WHERE status = 'pending'
        ORDER BY device_approval_requests.created_at DESC
        """
    ).fetchall()

    if not rows:
        print("No pending device approvals.")
        return 0

    for index, row in enumerate(rows, start=1):
        print(f"[{index}] token={row['request_token']}")
        print(f"    user       : {row['username'] or 'unknown'}")
        print(f"    device     : {row['device_name'] or 'unknown'}")
        print(f"    device_id  : {row['device_id'] or 'unknown'}")
        print(f"    platform   : {row['platform'] or 'unknown'}")
        print(f"    app_type   : {row['app_type'] or 'unknown'}")
        print(f"    ip         : {row['requested_ip'] or 'unknown'}")
        print(f"    created_at : {row['created_at'] or 'unknown'}")
        print(f"    user_agent : {row['requested_user_agent'] or 'unknown'}")

    return 0


def resolve_request(connection: sqlite3.Connection, request_token: str, approved: bool, note: str | None) -> int:
    row = connection.execute(
        """
        SELECT *
        FROM device_approval_requests
        WHERE request_token = ? AND status = 'pending'
        LIMIT 1
        """,
        (request_token,),
    ).fetchone()

    if row is None:
        print(f"Pending request not found: {request_token}", file=sys.stderr)
        return 1

    if approved:
        connection.execute(
            """
            INSERT INTO trusted_devices (
                user_id,
                device_id,
                device_name,
                platform,
                app_type,
                first_approved_at,
                last_seen,
                last_login,
                last_ip,
                last_user_agent,
                is_active
            )
            VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ?, ?, 1)
            ON CONFLICT(user_id, device_id)
            DO UPDATE SET
                device_name = excluded.device_name,
                platform = excluded.platform,
                app_type = excluded.app_type,
                last_seen = CURRENT_TIMESTAMP,
                last_login = CURRENT_TIMESTAMP,
                last_ip = excluded.last_ip,
                last_user_agent = excluded.last_user_agent,
                is_active = 1
            """,
            (
                row["user_id"],
                row["device_id"],
                row["device_name"],
                row["platform"],
                row["app_type"],
                row["requested_ip"],
                row["requested_user_agent"],
            ),
        )

    status = "approved" if approved else "rejected"
    timestamp_column = "approved_at" if approved else "rejected_at"
    connection.execute(
        f"""
        UPDATE device_approval_requests
        SET
            status = ?,
            updated_at = CURRENT_TIMESTAMP,
            {timestamp_column} = CURRENT_TIMESTAMP,
            resolved_note = ?
        WHERE request_token = ? AND status = 'pending'
        """,
        (status, note or "CLI action", request_token),
    )
    connection.commit()
    print(f"{status.title()} request: {request_token}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage pending device approvals for mobileCodexHelper.")
    parser.add_argument(
        "--db",
        default=str(default_db_path()),
        help="Path to auth.db. Defaults to .runtime/macos/auth.db",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("list", help="List pending device approval requests")

    approve_parser = subparsers.add_parser("approve", help="Approve a pending device request")
    approve_parser.add_argument("request_token", help="Pending request token")
    approve_parser.add_argument("--note", default="CLI approved on macOS", help="Optional note")

    reject_parser = subparsers.add_parser("reject", help="Reject a pending device request")
    reject_parser.add_argument("request_token", help="Pending request token")
    reject_parser.add_argument("--note", default="CLI rejected on macOS", help="Optional note")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    db_path = Path(args.db).expanduser().resolve()
    if not db_path.exists():
        print(f"Database not found: {db_path}", file=sys.stderr)
        return 1

    with connect(db_path) as connection:
        if args.command == "list":
            return list_pending(connection)
        if args.command == "approve":
            return resolve_request(connection, args.request_token, True, args.note)
        if args.command == "reject":
            return resolve_request(connection, args.request_token, False, args.note)

    parser.error(f"Unsupported command: {args.command}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
