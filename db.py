"""
Self-contained SQLite data layer for the KNRA Licensing API.

The original project required an external MySQL server, which meant the API
returned ``{"error": "Database error"}`` whenever it ran somewhere without a
reachable MySQL instance (e.g. Vercel serverless). This module replaces that
dependency with a zero-config SQLite database that is created and seeded on
first use, so the API works anywhere with no setup.

The seed data mirrors the records in ``02_MySQL_Sample_Data.sql``.
"""

import os
import sqlite3
import tempfile

# Store the database in a writable location. On serverless platforms only the
# temp directory is writable, so default to that; allow an override for tests.
DB_PATH = os.getenv("SQLITE_DB_PATH", os.path.join(tempfile.gettempdir(), "knra_licensing.db"))


SCHEMA = """
CREATE TABLE IF NOT EXISTS facilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hospital_name TEXT NOT NULL,
    location TEXT NOT NULL,
    facility_class TEXT NOT NULL,
    license_number TEXT,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    equipment_classes TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS licenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    license_number TEXT NOT NULL UNIQUE,
    facility_id INTEGER NOT NULL,
    issue_date TEXT NOT NULL,
    expiry_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    fee_amount REAL DEFAULT 0,
    fee_paid INTEGER DEFAULT 0,
    authorized_equipment TEXT,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS equipment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    facility_id INTEGER NOT NULL,
    equipment_name TEXT NOT NULL,
    equipment_type TEXT NOT NULL,
    serial_number TEXT NOT NULL UNIQUE,
    radiation_class TEXT,
    status TEXT NOT NULL DEFAULT 'operational',
    last_calibration TEXT,
    next_calibration_due TEXT NOT NULL,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inspectors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    qualification TEXT,
    hire_date TEXT,
    status TEXT NOT NULL DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS inspections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inspector_id INTEGER NOT NULL,
    facility_id INTEGER NOT NULL,
    inspection_date TEXT NOT NULL,
    inspection_type TEXT,
    status TEXT DEFAULT 'completed',
    compliance_rating TEXT,
    findings_summary TEXT,
    recommendations TEXT,
    next_inspection_due TEXT,
    FOREIGN KEY (inspector_id) REFERENCES inspectors(id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inspection_violations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inspection_id INTEGER NOT NULL,
    violation_code TEXT NOT NULL,
    severity TEXT NOT NULL,
    description TEXT NOT NULL,
    deadline TEXT,
    FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inspector_facilities (
    inspector_id INTEGER NOT NULL,
    facility_id INTEGER NOT NULL,
    PRIMARY KEY (inspector_id, facility_id),
    FOREIGN KEY (inspector_id) REFERENCES inspectors(id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE
);
"""


FACILITIES = [
    # hospital_name, location, facility_class, license_number, contact_person, phone, email, equipment_classes
    ("Kenyatta National Hospital", "Nairobi", "Class II", "KNRA-2023-000001",
     "Dr. Michael Omondi", "+254-20-7726300", "admin@kemhospital.co.ke",
     '["CT Scanner", "X-ray", "Radiotherapy"]'),
    ("Aga Khan University Hospital", "Nairobi", "Class I", "KNRA-2024-000015",
     "Prof. Salim Ali", "+254-20-3665000", "radiotherapy@agakhan.co.ke",
     '["Radiotherapy", "Nuclear Medicine", "Diagnostic Imaging"]'),
    ("Mombasa Hospital", "Mombasa", "Class III", "KNRA-2023-000008",
     "Dr. Fatuma Hassan", "+254-41-222200", "radiology@mombasahospital.co.ke",
     '["X-ray", "CT Scanner"]'),
]

LICENSES = [
    # license_number, facility_id, issue_date, expiry_date, status, fee_amount, fee_paid, authorized_equipment
    ("KNRA-2023-000001", 1, "2023-01-15", "2027-01-14", "active", 250000, 1,
     '[{"equipment_type": "CT Scanner", "quantity": 2}, {"equipment_type": "X-ray", "quantity": 5}]'),
    ("KNRA-2024-000015", 2, "2024-02-01", "2028-01-31", "active", 350000, 1,
     '[{"equipment_type": "Radiotherapy", "quantity": 2}, {"equipment_type": "Nuclear Medicine", "quantity": 1}]'),
    ("KNRA-2023-000008", 3, "2023-03-10", "2026-08-09", "pending_renewal", 180000, 0,
     '[{"equipment_type": "X-ray", "quantity": 3}, {"equipment_type": "CT Scanner", "quantity": 1}]'),
]

EQUIPMENT = [
    # facility_id, equipment_name, equipment_type, serial_number, radiation_class, status, last_calibration, next_calibration_due
    (1, "GE Revolution EVO CT Scanner", "CT Scanner", "GE-CT-2021-0001", "Class II", "operational", "2026-05-10", "2026-11-10"),
    (1, "Varian TrueBeam Radiotherapy Accelerator", "Radiotherapy", "VAR-RTX-2020-0042", "Class I", "operational", "2026-04-05", "2026-10-05"),
    (2, "Gamma Camera with SPECT", "Nuclear Medicine", "SIE-NM-2022-0015", "Class II", "operational", "2026-06-01", "2026-12-01"),
    (3, "Philips Digital X-ray System", "X-ray", "PHI-XR-2019-0033", "Class III", "maintenance", "2026-01-15", "2026-04-15"),
]

INSPECTORS = [
    # staff_id, first_name, last_name, email, phone, qualification, hire_date, status
    ("KNRA-INS-001", "Mary", "Njoroge", "mary.njoroge@knra.go.ke", "+254-712-345678",
     "BSc Radiation Physics, Certified Radiation Safety Officer", "2018-06-01", "active"),
    ("KNRA-INS-002", "Robert", "Mwangi", "robert.mwangi@knra.go.ke", "+254-722-456789",
     "MSc Health Physics, IAEA Radiation Safety Expert", "2019-09-01", "active"),
]

# inspector_id, facility_id
INSPECTOR_FACILITIES = [(1, 1), (1, 2), (2, 3), (2, 2)]

INSPECTIONS = [
    # inspector_id, facility_id, inspection_date, inspection_type, status, compliance_rating, findings_summary, recommendations, next_inspection_due
    (1, 1, "2026-03-20", "routine", "completed", "Partial Compliance",
     "Routine inspection completed. Two critical issues identified.",
     "Urgent: Schedule shielding replacement. Implement quarterly calibration verification.", "2026-09-20"),
    (2, 3, "2026-06-10", "compliance", "completed", "Compliant",
     "Compliance inspection passed all checks.",
     "Continue current safety practices. Next routine inspection in 12 months.", "2027-06-10"),
    (1, 2, "2026-05-15", "follow_up", "completed", "Compliant",
     "Follow-up inspection confirmed corrective actions completed.",
     "No further action required.", "2027-05-15"),
]

INSPECTION_VIOLATIONS = [
    # inspection_id, violation_code, severity, description, deadline
    (1, "SHIELD-2026-001", "major", "CT scanner room lead shielding showing signs of wear", "2026-05-20"),
]


def get_connection():
    """Return a SQLite connection with dict-like rows and FK enforcement."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def _is_seeded(conn):
    row = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='facilities'"
    ).fetchone()
    if not row:
        return False
    count = conn.execute("SELECT COUNT(*) AS c FROM facilities").fetchone()["c"]
    return count > 0


def init_db(force=False):
    """Create the schema and seed sample data if the database is empty."""
    conn = get_connection()
    try:
        conn.executescript(SCHEMA)
        if force:
            for table in (
                "inspection_violations", "inspections", "inspector_facilities",
                "inspectors", "equipment", "licenses", "facilities",
            ):
                conn.execute(f"DELETE FROM {table}")
        if force or not _is_seeded(conn):
            conn.executemany(
                "INSERT INTO facilities (hospital_name, location, facility_class, license_number, "
                "contact_person, phone, email, equipment_classes) VALUES (?,?,?,?,?,?,?,?)",
                FACILITIES,
            )
            conn.executemany(
                "INSERT INTO licenses (license_number, facility_id, issue_date, expiry_date, status, "
                "fee_amount, fee_paid, authorized_equipment) VALUES (?,?,?,?,?,?,?,?)",
                LICENSES,
            )
            conn.executemany(
                "INSERT INTO equipment (facility_id, equipment_name, equipment_type, serial_number, "
                "radiation_class, status, last_calibration, next_calibration_due) VALUES (?,?,?,?,?,?,?,?)",
                EQUIPMENT,
            )
            conn.executemany(
                "INSERT INTO inspectors (staff_id, first_name, last_name, email, phone, qualification, "
                "hire_date, status) VALUES (?,?,?,?,?,?,?,?)",
                INSPECTORS,
            )
            conn.executemany(
                "INSERT INTO inspector_facilities (inspector_id, facility_id) VALUES (?,?)",
                INSPECTOR_FACILITIES,
            )
            conn.executemany(
                "INSERT INTO inspections (inspector_id, facility_id, inspection_date, inspection_type, "
                "status, compliance_rating, findings_summary, recommendations, next_inspection_due) "
                "VALUES (?,?,?,?,?,?,?,?,?)",
                INSPECTIONS,
            )
            conn.executemany(
                "INSERT INTO inspection_violations (inspection_id, violation_code, severity, description, "
                "deadline) VALUES (?,?,?,?,?)",
                INSPECTION_VIOLATIONS,
            )
            conn.commit()
    finally:
        conn.close()
