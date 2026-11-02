"""Verify upgrade/rollback preserves legacy catalog, stock and order snapshots.
Run from backend: python -m unittest discover -s tests -p marketplace_migration_test.py -v
Requires dotnet and the repository's dotnet-ef tool on PATH.
"""

import os
from contextlib import closing
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MarketplaceMigrationTests(unittest.TestCase):
    def test_sqlite_existing_data_survives_upgrade_rollback_and_reupgrade(self):
        (ROOT / ".test-data").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / ".test-data") as directory:
            database = Path(directory) / "upgrade.db"

            def migrate(target):
                result = subprocess.run([
                    "dotnet", "ef", "database", "update", target,
                    "--context", "SqliteAppDbContext", "--project", "src/ArtKids.DAL",
                    "--startup-project", "src/ArtKids.API", "--no-build",
                    "--connection", f"Data Source={database}",
                ], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", timeout=120,
                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            previous = "20261022144057_CourseSoftDeletion"
            migrate(previous)
            with closing(sqlite3.connect(database)) as db, db:
                def insert(table, values):
                    for _, name, kind, required, default, _ in db.execute(f"PRAGMA table_info({table})"):
                        if required and default is None and name not in values:
                            values[name] = 0 if kind in ("INTEGER", "REAL") else ""
                    columns = ",".join(values)
                    db.execute(f"INSERT INTO {table} ({columns}) VALUES ({','.join('?' for _ in values)})", list(values.values()))

                insert("users", {"id": "legacy-admin", "email": "legacy@example.invalid", "role": "admin"})
                insert("products", {"id": "legacy-product", "name": "Existing platform kit", "price_vnd": 125000,
                    "created_by": "legacy-admin", "images": "[]", "kit_items": "[]", "is_active": 1})
                insert("inventory_skus", {"id": "legacy-stock", "product_id": "legacy-product", "sku": "LEGACY",
                    "quantity_available": 7, "quantity_reserved": 2})
                insert("orders", {"id": "legacy-order", "order_code": "LEGACY-ORDER", "parent_id": "legacy-admin"})
                insert("order_items", {"id": "legacy-line", "order_id": "legacy-order", "product_id": "legacy-product",
                    "quantity": 2, "unit_price_vnd": 125000, "kit_items": "[]"})
            for target in ["TeacherMarketplace", previous, "TeacherMarketplace"]:
                migrate(target)
                with closing(sqlite3.connect(database)) as db, db:
                    self.assertEqual(db.execute("SELECT quantity_available,quantity_reserved FROM inventory_skus").fetchone(), (7, 2))
                    self.assertEqual(db.execute("SELECT quantity,unit_price_vnd FROM order_items").fetchone(), (2, 125000))
                    if target == "TeacherMarketplace":
                        self.assertEqual(db.execute("SELECT approval_status,fulfillment_mode,is_available,revision FROM products").fetchone(), ("approved", "platform", 1, 1))
                        self.assertIsNone(db.execute("SELECT seller_id FROM order_items").fetchone()[0])
                        self.assertEqual(db.execute("PRAGMA foreign_key_check").fetchall(), [])
