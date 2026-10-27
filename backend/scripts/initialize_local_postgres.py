"""Initialize the project's private PostgreSQL runtime without changing an existing server."""

import json
import os
import secrets
import subprocess
from pathlib import Path

import psycopg
from psycopg import sql

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / ".local"
BIN = LOCAL / "postgres/pgsql/bin"
DATA = LOCAL / "postgres-data"
SETTINGS = LOCAL / "postgres-connection.json"


def main():
    LOCAL.mkdir(exist_ok=True)
    if not (BIN / "initdb.exe").exists():
        raise RuntimeError(
            "Extract the official PostgreSQL Windows binaries into backend/.local/postgres first."
        )
    if SETTINGS.exists():
        settings = json.loads(SETTINGS.read_text())
    else:
        if (DATA / "PG_VERSION").exists():
            raise RuntimeError(
                "An initialized cluster already exists without its connection settings."
            )
        settings = {
            "host": "127.0.0.1",
            "port": 5432,
            "database": "artkids",
            "username": "artkids",
            "password": "ArtKids-" + secrets.token_hex(12),
            "adminPassword": secrets.token_urlsafe(32),
        }
        SETTINGS.write_text(json.dumps(settings, indent=2), encoding="utf-8")
    if not (DATA / "PG_VERSION").exists():
        password_file = LOCAL / "initdb-password.txt"
        password_file.write_text(settings["adminPassword"], encoding="utf-8")
        try:
            subprocess.run(
                [
                    str(BIN / "initdb.exe"),
                    "-D",
                    str(DATA),
                    "-U",
                    "postgres",
                    "--encoding=UTF8",
                    "--locale=C",
                    "--auth=scram-sha-256",
                    "--pwfile",
                    str(password_file),
                ],
                check=True,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
            )
        finally:
            password_file.unlink(missing_ok=True)
        with (DATA / "postgresql.conf").open("a", encoding="utf-8") as config:
            config.write("\nlisten_addresses = '127.0.0.1'\nport = 5432\n")
    status = subprocess.run(
        [str(BIN / "pg_ctl.exe"), "-D", str(DATA), "status"], capture_output=True
    )
    if status.returncode != 0:
        subprocess.run(
            [
                str(BIN / "pg_ctl.exe"),
                "-D",
                str(DATA),
                "-l",
                str(LOCAL / "postgres-server.log"),
                "-w",
                "start",
            ],
            check=True,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
        )
    with psycopg.connect(
        host=settings["host"],
        port=settings["port"],
        dbname="postgres",
        user="postgres",
        password=settings["adminPassword"],
        autocommit=True,
    ) as connection:
        if not connection.execute(
            "SELECT 1 FROM pg_roles WHERE rolname = %s", (settings["username"],)
        ).fetchone():
            connection.execute(
                sql.SQL("CREATE ROLE {} LOGIN PASSWORD {}").format(
                    sql.Identifier(settings["username"]), sql.Literal(settings["password"])
                )
            )
        if not connection.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s", (settings["database"],)
        ).fetchone():
            connection.execute(
                sql.SQL("CREATE DATABASE {} OWNER {} ENCODING 'UTF8'").format(
                    sql.Identifier(settings["database"]), sql.Identifier(settings["username"])
                )
            )
        print(connection.execute("SELECT version()").fetchone()[0])
    print("Local PostgreSQL ready: 127.0.0.1:5432 / artkids")


if __name__ == "__main__":
    main()
