"""Copy every application table to an empty PostgreSQL database and verify every row.

Stop the API before running. The source database and uploaded files are preserved.
"""

import hashlib
import json
import os
import sqlite3
import subprocess
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

import psycopg
from psycopg import sql

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "src/ArtKids.API"
LOCAL = ROOT / ".local"
BACKUPS = ROOT / "backups"


def converted(value, data_type):
    if value is None:
        return None
    if data_type == "boolean":
        if value not in (0, 1, False, True):
            raise ValueError("Invalid source boolean")
        return bool(value)
    if data_type == "timestamp with time zone":
        if isinstance(value, str):
            value = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return (
            value.replace(tzinfo=timezone.utc)
            if value.tzinfo is None
            else value.astimezone(timezone.utc)
        )
    if data_type == "numeric":
        return Decimal(str(value)).quantize(Decimal("0.01"))
    return value


def digest(rows):
    encoded = json.dumps(rows, ensure_ascii=False, default=str, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def main():
    settings = json.loads((LOCAL / "postgres-connection.json").read_text())
    BACKUPS.mkdir(exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    source_path = API / "App_Data/artkids.db"
    snapshot = BACKUPS / f"artkids-sqlite-before-postgres-{stamp}.db"
    source = sqlite3.connect(source_path.as_uri() + "?mode=ro", uri=True)
    with sqlite3.connect(snapshot) as backup:
        source.backup(backup)
    source.close()
    source = sqlite3.connect(snapshot)
    assert source.execute("PRAGMA integrity_check").fetchone() == ("ok",)
    assert source.execute("PRAGMA foreign_key_check").fetchall() == []
    tables = [
        row[0]
        for row in source.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT IN ('__EFMigrationsHistory', '__EFMigrationsLock') ORDER BY name"
        )
    ]
    connect = dict(
        host=settings["host"],
        port=settings["port"],
        dbname=settings["database"],
        user=settings["username"],
        password=settings["password"],
    )
    environment = {**os.environ, "PGPASSWORD": settings["password"]}
    binary = LOCAL / "postgres/pgsql/bin"
    cli = [
        "-h",
        settings["host"],
        "-p",
        str(settings["port"]),
        "-U",
        settings["username"],
        "-d",
        settings["database"],
    ]
    with psycopg.connect(**connect) as connection:
        existing = connection.execute(
            "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name != '__EFMigrationsHistory'"
        ).fetchall()
        for (table,) in existing:
            if connection.execute(
                sql.SQL("SELECT count(*) FROM {}").format(sql.Identifier(table))
            ).fetchone()[0]:
                raise RuntimeError(
                    "Destination contains application data; migration never overwrites existing rows."
                )
    result = (
        subprocess.run(
            [
                str(binary / "psql.exe"),
                *cli,
                "-v",
                "ON_ERROR_STOP=1",
                "-f",
                str(ROOT / "scripts/postgres-migrations.sql"),
            ],
            env=environment,
            capture_output=True,
        )
        if not existing
        else None
    )
    if result and result.returncode:
        raise RuntimeError(result.stderr.decode(errors="replace"))
    report = {
        "sourceBackup": str(snapshot),
        "destination": f"{settings['host']}:{settings['port']}/{settings['database']}",
        "timestampPrecision": "UTC timestamps normalized to PostgreSQL microsecond precision",
        "tables": [],
    }
    with psycopg.connect(**connect) as connection:
        target_tables = [
            row[0]
            for row in connection.execute(
                "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name != '__EFMigrationsHistory' ORDER BY table_name"
            )
        ]
        assert tables == target_tables, (tables, target_tables)
        constraints = connection.execute(
            "SELECT conrelid::regclass::text, conname, condeferrable, condeferred FROM pg_constraint WHERE contype='f' AND connamespace='public'::regnamespace"
        ).fetchall()
        for table, name, _, _ in constraints:
            connection.execute(
                sql.SQL("ALTER TABLE {} ALTER CONSTRAINT {} DEFERRABLE INITIALLY DEFERRED").format(
                    sql.Identifier(table), sql.Identifier(name)
                )
            )
        connection.execute("SET CONSTRAINTS ALL DEFERRED")
        for table in tables:
            columns = connection.execute(
                "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position",
                (table,),
            ).fetchall()
            names = [column[0] for column in columns]
            source_names = [row[1] for row in source.execute(f'PRAGMA table_info("{table}")')]
            assert set(names) == set(source_names), table
            quoted = ", ".join('"' + name.replace('"', '""') + '"' for name in names)
            rows = [
                tuple(converted(value, columns[i][1]) for i, value in enumerate(row))
                for row in source.execute(f'SELECT {quoted} FROM "{table}" ORDER BY id')
            ]
            query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
                sql.Identifier(table),
                sql.SQL(", ").join(map(sql.Identifier, names)),
                sql.SQL(", ").join(sql.Placeholder() for _ in names),
            )
            if rows:
                with connection.cursor() as cursor:
                    cursor.executemany(query, rows)
            actual = connection.execute(
                sql.SQL("SELECT {} FROM {} ORDER BY id").format(
                    sql.SQL(", ").join(map(sql.Identifier, names)), sql.Identifier(table)
                )
            ).fetchall()
            actual = [
                tuple(converted(value, columns[i][1]) for i, value in enumerate(row))
                for row in actual
            ]
            assert rows == actual, f"Content mismatch in {table}"
            report["tables"].append(
                {
                    "table": table,
                    "sourceRows": len(rows),
                    "targetRows": len(actual),
                    "sha256": digest(rows),
                }
            )
            print(f"Verified {table}: {len(rows)} rows", flush=True)
        connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
        for table, name, deferrable, deferred in constraints:
            mode = (
                "DEFERRABLE INITIALLY DEFERRED"
                if deferred
                else "DEFERRABLE INITIALLY IMMEDIATE" if deferrable else "NOT DEFERRABLE"
            )
            connection.execute(
                sql.SQL("ALTER TABLE {} ALTER CONSTRAINT {} " + mode).format(
                    sql.Identifier(table), sql.Identifier(name)
                )
            )
        report["foreignKeysValidated"] = len(constraints)
        report["postgresMigrations"] = [
            row[0]
            for row in connection.execute(
                'SELECT "MigrationId" FROM "__EFMigrationsHistory" ORDER BY "MigrationId"'
            )
        ]
    source.close()
    dump = BACKUPS / f"artkids-postgres-{stamp}.dump"
    subprocess.run(
        [
            str(binary / "pg_dump.exe"),
            *cli,
            "--format=custom",
            "--no-owner",
            "--no-acl",
            "--file",
            str(dump),
        ],
        env=environment,
        check=True,
    )
    report["dump"] = str(dump)
    report["totalRows"] = sum(table["sourceRows"] for table in report["tables"])
    (BACKUPS / "migration-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    configuration_path = API / "appsettings.Local.json"
    configuration = (
        json.loads(configuration_path.read_text(encoding="utf-8"))
        if configuration_path.exists()
        else {}
    )
    configuration.setdefault("Database", {})["Provider"] = "Postgres"
    configuration.setdefault("ConnectionStrings", {})[
        "Postgres"
    ] = f"Host={settings['host']};Port={settings['port']};Database={settings['database']};Username={settings['username']};Password={settings['password']}"
    configuration_path.write_text(json.dumps(configuration, indent=2), encoding="utf-8")
    details = f"ART KID - PostgreSQL local\nHost: {settings['host']}\nPort: {settings['port']}\nDatabase: {settings['database']}\nUsername: {settings['username']}\nPassword: {settings['password']}\nJDBC URL: jdbc:postgresql://{settings['host']}:{settings['port']}/{settings['database']}\nBackup: {dump}\nData directory: {LOCAL / 'postgres-data'}\n"
    (BACKUPS / "dbeaver-connection.txt").write_text(details, encoding="utf-8")
    print(
        f"Migration complete: {len(tables)} tables, {report['totalRows']} rows. Backup: {dump.name}"
    )


if __name__ == "__main__":
    main()
