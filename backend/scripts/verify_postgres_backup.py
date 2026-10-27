"""Restore the migration backup into a temporary database and verify every table hash."""

import json
import os
import subprocess
import uuid

import psycopg
from psycopg import sql

from migrate_sqlite_to_postgres import BACKUPS, LOCAL, converted, digest


def main():
    settings = json.loads((LOCAL / "postgres-connection.json").read_text())
    report = json.loads((BACKUPS / "migration-report.json").read_text())
    database = "artkids_restore_check_" + uuid.uuid4().hex
    admin = dict(
        host=settings["host"],
        port=settings["port"],
        dbname="postgres",
        user="postgres",
        password=settings["adminPassword"],
        autocommit=True,
    )
    with psycopg.connect(**admin) as connection:
        connection.execute(
            sql.SQL("CREATE DATABASE {} OWNER {}").format(
                sql.Identifier(database), sql.Identifier(settings["username"])
            )
        )
    try:
        subprocess.run(
            [
                str(LOCAL / "postgres/pgsql/bin/pg_restore.exe"),
                "-h",
                settings["host"],
                "-p",
                str(settings["port"]),
                "-U",
                settings["username"],
                "-d",
                database,
                "--no-owner",
                "--no-acl",
                "--exit-on-error",
                report["dump"],
            ],
            env={**os.environ, "PGPASSWORD": settings["password"]},
            check=True,
        )
        with psycopg.connect(
            host=settings["host"],
            port=settings["port"],
            dbname=database,
            user=settings["username"],
            password=settings["password"],
        ) as connection:
            for item in report["tables"]:
                columns = connection.execute(
                    "SELECT column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position",
                    (item["table"],),
                ).fetchall()
                rows = connection.execute(
                    sql.SQL("SELECT {} FROM {} ORDER BY id").format(
                        sql.SQL(", ").join(sql.Identifier(column[0]) for column in columns),
                        sql.Identifier(item["table"]),
                    )
                ).fetchall()
                normalized = [
                    tuple(converted(value, columns[index][1]) for index, value in enumerate(row))
                    for row in rows
                ]
                assert (
                    len(rows) == item["sourceRows"] and digest(normalized) == item["sha256"]
                ), item["table"]
        report["backupRestoreVerified"] = True
        (BACKUPS / "migration-report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(
            f"Backup restored and verified: {len(report['tables'])} tables, {report['totalRows']} rows"
        )
    finally:
        with psycopg.connect(**admin) as connection:
            connection.execute(
                sql.SQL("DROP DATABASE {} WITH (FORCE)").format(sql.Identifier(database))
            )


if __name__ == "__main__":
    main()
