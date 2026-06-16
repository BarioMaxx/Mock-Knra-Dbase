"""
KNRA Licensing Database API
Flask REST API for radioactive equipment and facility licensing system.

Data is served from a self-contained SQLite database (see ``db.py``) that is
created and seeded automatically, so the API works with zero external setup.
The built React dashboard (``frontend/dist``) is served from the root path.
"""

import os
import json
import sqlite3
from datetime import datetime

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

import db

# Resolve the built frontend directory (created by `npm run build`).
FRONTEND_DIST = os.path.join(os.path.dirname(__file__), "frontend", "dist")

app = Flask(__name__, static_folder=None)
CORS(app)

# Create + seed the database on import (covers serverless cold starts too).
db.init_db()


# ============================================================================
# DATABASE HELPERS
# ============================================================================

def execute_query(query, params=None):
    """Execute a SELECT query and return a list of dict rows (or None on error)."""
    try:
        conn = db.get_connection()
    except sqlite3.Error as e:  # pragma: no cover - connection rarely fails for sqlite
        print(f"Database connection error: {e}")
        return None
    try:
        cursor = conn.execute(query, params or ())
        rows = [dict(row) for row in cursor.fetchall()]
        return rows
    except sqlite3.Error as e:
        print(f"Query error: {e}")
        return None
    finally:
        conn.close()


def execute_insert_update(query, params=None):
    """Execute an INSERT/UPDATE query. Returns the new row id, or None on error."""
    try:
        conn = db.get_connection()
    except sqlite3.Error as e:  # pragma: no cover
        print(f"Database connection error: {e}")
        return None
    try:
        cursor = conn.execute(query, params or ())
        conn.commit()
        return cursor.lastrowid
    except sqlite3.Error as e:
        print(f"Insert/Update error: {e}")
        conn.rollback()
        return None
    finally:
        conn.close()


def _parse_json_field(row, *fields):
    """Best-effort parse of JSON-encoded text columns into Python objects."""
    for field in fields:
        value = row.get(field)
        if isinstance(value, str) and value:
            try:
                row[field] = json.loads(value)
            except (ValueError, TypeError):
                pass
    return row


# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.route("/health", methods=["GET"])
def health_check():
    """Check API and database health."""
    result = execute_query("SELECT 1 AS ok")
    if result is not None:
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "database": "connected",
        }), 200
    return jsonify({"status": "unhealthy", "database": "disconnected"}), 500


# ============================================================================
# FACILITIES ENDPOINTS
# ============================================================================

@app.route("/api/facilities", methods=["GET"])
def get_facilities():
    """Get all facilities (hospital name, location, radiation equipment class)."""
    query = """
        SELECT f.id, f.hospital_name, f.location, f.facility_class, f.status,
               f.license_number, f.contact_person, f.equipment_classes, f.created_at,
               COUNT(DISTINCT e.id) AS equipment_count
        FROM facilities f
        LEFT JOIN equipment e ON e.facility_id = f.id
        GROUP BY f.id
        ORDER BY f.hospital_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    results = [_parse_json_field(r, "equipment_classes") for r in results]
    return jsonify(results), 200


@app.route("/api/facilities/<int:facility_id>", methods=["GET"])
def get_facility(facility_id):
    """Get a specific facility with related licenses and equipment."""
    facility = execute_query("SELECT * FROM facilities WHERE id = ?", (facility_id,))
    if not facility:
        return jsonify({"error": "Facility not found"}), 404

    licenses = execute_query(
        "SELECT id, license_number, issue_date, expiry_date, status, fee_paid "
        "FROM licenses WHERE facility_id = ?",
        (facility_id,),
    )
    equipment = execute_query(
        "SELECT id, equipment_name, serial_number, equipment_type, radiation_class, status "
        "FROM equipment WHERE facility_id = ?",
        (facility_id,),
    )

    return jsonify({
        "facility": _parse_json_field(facility[0], "equipment_classes"),
        "licenses": licenses,
        "equipment": equipment,
    }), 200


@app.route("/api/facilities", methods=["POST"])
def create_facility():
    """Create a new facility."""
    data = request.json or {}
    new_id = execute_insert_update(
        "INSERT INTO facilities (hospital_name, location, facility_class, status) "
        "VALUES (?, ?, ?, ?)",
        (
            data.get("hospital_name"),
            data.get("location"),
            data.get("facility_class"),
            data.get("status", "active"),
        ),
    )
    if new_id is not None:
        return jsonify({"message": "Facility created successfully", "id": new_id}), 201
    return jsonify({"error": "Failed to create facility"}), 500


# ============================================================================
# LICENSES ENDPOINTS
# ============================================================================

@app.route("/api/licenses", methods=["GET"])
def get_licenses():
    """Get all licenses with facility info (issue/expiry dates, status, fee paid)."""
    query = """
        SELECT l.id, l.license_number, l.facility_id, l.issue_date, l.expiry_date,
               l.status, l.fee_amount, l.fee_paid, f.hospital_name,
               CAST(julianday(l.expiry_date) - julianday('now') AS INTEGER) AS days_until_expiry
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        ORDER BY l.expiry_date ASC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify(results), 200


@app.route("/api/licenses/expiring", methods=["GET"])
def get_expiring_licenses():
    """Get active licenses expiring within N days (default 90)."""
    days = request.args.get("days", 90, type=int)
    query = """
        SELECT l.license_number, f.hospital_name, l.expiry_date, l.status, l.fee_paid,
               CAST(julianday(l.expiry_date) - julianday('now') AS INTEGER) AS days_until_expiry
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        WHERE l.expiry_date BETWEEN date('now') AND date('now', '+' || ? || ' days')
          AND l.status = 'active'
        ORDER BY l.expiry_date ASC
    """
    results = execute_query(query, (days,))
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify({"count": len(results), "licenses": results}), 200


@app.route("/api/licenses/<int:license_id>", methods=["GET"])
def get_license(license_id):
    """Get a specific license."""
    query = """
        SELECT l.*, f.hospital_name
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        WHERE l.id = ?
    """
    results = execute_query(query, (license_id,))
    if not results:
        return jsonify({"error": "License not found"}), 404
    return jsonify(_parse_json_field(results[0], "authorized_equipment")), 200


@app.route("/api/licenses", methods=["POST"])
def create_license():
    """Create a new license."""
    data = request.json or {}
    new_id = execute_insert_update(
        "INSERT INTO licenses (facility_id, license_number, issue_date, expiry_date, "
        "status, fee_amount, fee_paid) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            data.get("facility_id"),
            data.get("license_number"),
            data.get("issue_date"),
            data.get("expiry_date"),
            data.get("status", "active"),
            data.get("fee_amount", 0),
            1 if data.get("fee_paid") else 0,
        ),
    )
    if new_id is not None:
        return jsonify({"message": "License created successfully", "id": new_id}), 201
    return jsonify({"error": "Failed to create license"}), 500


# ============================================================================
# EQUIPMENT ENDPOINTS
# ============================================================================

@app.route("/api/equipment", methods=["GET"])
def get_equipment():
    """Get all equipment."""
    query = """
        SELECT e.*, f.hospital_name
        FROM equipment e
        JOIN facilities f ON e.facility_id = f.id
        ORDER BY f.hospital_name, e.equipment_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify(results), 200


@app.route("/api/equipment/overdue", methods=["GET"])
def get_overdue_equipment():
    """Get equipment overdue for calibration."""
    query = """
        SELECT e.equipment_name, e.serial_number, f.hospital_name, e.status,
               e.next_calibration_due,
               CAST(julianday('now') - julianday(e.next_calibration_due) AS INTEGER) AS days_overdue
        FROM equipment e
        JOIN facilities f ON e.facility_id = f.id
        WHERE e.next_calibration_due < date('now')
          AND e.status = 'operational'
        ORDER BY e.next_calibration_due ASC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify({"count": len(results), "equipment": results}), 200


@app.route("/api/equipment/<int:equipment_id>", methods=["GET"])
def get_equipment_detail(equipment_id):
    """Get specific equipment details."""
    query = """
        SELECT e.*, f.hospital_name
        FROM equipment e
        JOIN facilities f ON e.facility_id = f.id
        WHERE e.id = ?
    """
    results = execute_query(query, (equipment_id,))
    if not results:
        return jsonify({"error": "Equipment not found"}), 404
    return jsonify(results[0]), 200


@app.route("/api/equipment", methods=["POST"])
def create_equipment():
    """Create new equipment."""
    data = request.json or {}
    new_id = execute_insert_update(
        "INSERT INTO equipment (facility_id, equipment_name, equipment_type, serial_number, "
        "radiation_class, status, next_calibration_due) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            data.get("facility_id"),
            data.get("equipment_name"),
            data.get("equipment_type"),
            data.get("serial_number"),
            data.get("radiation_class"),
            data.get("status", "operational"),
            data.get("next_calibration_due"),
        ),
    )
    if new_id is not None:
        return jsonify({"message": "Equipment created successfully", "id": new_id}), 201
    return jsonify({"error": "Failed to create equipment"}), 500


# ============================================================================
# INSPECTIONS ENDPOINTS
# ============================================================================

@app.route("/api/inspections", methods=["GET"])
def get_inspections():
    """Get all inspections."""
    query = """
        SELECT i.*, f.hospital_name, ins.first_name, ins.last_name, ins.staff_id
        FROM inspections i
        JOIN facilities f ON i.facility_id = f.id
        JOIN inspectors ins ON i.inspector_id = ins.id
        ORDER BY i.inspection_date DESC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify(results), 200


@app.route("/api/inspections/<int:inspection_id>", methods=["GET"])
def get_inspection(inspection_id):
    """Get an inspection with its violations."""
    inspection = execute_query(
        """
        SELECT i.*, f.hospital_name, ins.first_name, ins.last_name, ins.staff_id
        FROM inspections i
        JOIN facilities f ON i.facility_id = f.id
        JOIN inspectors ins ON i.inspector_id = ins.id
        WHERE i.id = ?
        """,
        (inspection_id,),
    )
    if not inspection:
        return jsonify({"error": "Inspection not found"}), 404

    violations = execute_query(
        "SELECT * FROM inspection_violations WHERE inspection_id = ?", (inspection_id,)
    )
    return jsonify({"inspection": inspection[0], "violations": violations}), 200


@app.route("/api/inspections", methods=["POST"])
def create_inspection():
    """Create a new inspection."""
    data = request.json or {}
    new_id = execute_insert_update(
        "INSERT INTO inspections (facility_id, inspector_id, inspection_date, "
        "compliance_rating, findings_summary) VALUES (?, ?, ?, ?, ?)",
        (
            data.get("facility_id"),
            data.get("inspector_id"),
            data.get("inspection_date", datetime.now().strftime("%Y-%m-%d")),
            data.get("compliance_rating"),
            data.get("notes", ""),
        ),
    )
    if new_id is not None:
        return jsonify({"message": "Inspection created successfully", "id": new_id}), 201
    return jsonify({"error": "Failed to create inspection"}), 500


# ============================================================================
# INSPECTORS ENDPOINTS
# ============================================================================

@app.route("/api/inspectors", methods=["GET"])
def get_inspectors():
    """Get all inspectors with their assigned facilities and inspection counts."""
    query = """
        SELECT ins.id, ins.staff_id, ins.first_name, ins.last_name, ins.email,
               ins.qualification, ins.status,
               COUNT(DISTINCT i.id) AS inspection_count
        FROM inspectors ins
        LEFT JOIN inspections i ON i.inspector_id = ins.id
        GROUP BY ins.id
        ORDER BY ins.last_name, ins.first_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500

    # Attach assigned facility names for each inspector.
    assignments = execute_query(
        """
        SELECT inf.inspector_id, f.hospital_name
        FROM inspector_facilities inf
        JOIN facilities f ON inf.facility_id = f.id
        ORDER BY f.hospital_name
        """
    ) or []
    by_inspector = {}
    for row in assignments:
        by_inspector.setdefault(row["inspector_id"], []).append(row["hospital_name"])

    for inspector in results:
        inspector["full_name"] = f"{inspector['first_name']} {inspector['last_name']}"
        inspector["assigned_facilities"] = by_inspector.get(inspector["id"], [])

    return jsonify(results), 200


@app.route("/api/inspectors/<int:inspector_id>/workload", methods=["GET"])
def get_inspector_workload(inspector_id):
    """Get an inspector's inspection workload."""
    query = """
        SELECT i.*, f.hospital_name
        FROM inspections i
        JOIN facilities f ON i.facility_id = f.id
        WHERE i.inspector_id = ?
        ORDER BY i.inspection_date DESC
    """
    results = execute_query(query, (inspector_id,))
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify({
        "inspector_id": inspector_id,
        "inspection_count": len(results),
        "inspections": results,
    }), 200


# ============================================================================
# REPORTING ENDPOINTS
# ============================================================================

@app.route("/api/reports/compliance-summary", methods=["GET"])
def get_compliance_summary():
    """Get facility compliance summary."""
    query = """
        SELECT f.hospital_name,
               COUNT(DISTINCT i.id) AS total_inspections,
               SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant,
               SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant
        FROM facilities f
        LEFT JOIN inspections i ON f.id = i.facility_id
        GROUP BY f.id, f.hospital_name
        ORDER BY f.hospital_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify(results), 200


@app.route("/api/reports/violations", methods=["GET"])
def get_violations_report():
    """Get recent violations report."""
    query = """
        SELECT f.hospital_name, iv.violation_code, iv.description,
               iv.severity, iv.deadline, i.inspection_date
        FROM inspection_violations iv
        JOIN inspections i ON iv.inspection_id = i.id
        JOIN facilities f ON i.facility_id = f.id
        ORDER BY iv.deadline ASC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({"error": "Database error"}), 500
    return jsonify(results), 200


@app.route("/api/reports/kpis", methods=["GET"])
def get_kpis():
    """Get key performance indicators for the dashboard."""
    queries = {
        "total_facilities": "SELECT COUNT(*) AS count FROM facilities WHERE status = 'active'",
        "active_licenses": "SELECT COUNT(*) AS count FROM licenses WHERE status = 'active'",
        "total_equipment": "SELECT COUNT(*) AS count FROM equipment WHERE status = 'operational'",
        "total_inspectors": "SELECT COUNT(*) AS count FROM inspectors WHERE status = 'active'",
        "overdue_calibrations": (
            "SELECT COUNT(*) AS count FROM equipment "
            "WHERE next_calibration_due < date('now') AND status = 'operational'"
        ),
        "expiring_licenses_90_days": (
            "SELECT COUNT(*) AS count FROM licenses WHERE status = 'active' "
            "AND expiry_date BETWEEN date('now') AND date('now', '+90 days')"
        ),
    }
    results = {}
    for key, query in queries.items():
        data = execute_query(query)
        results[key] = data[0]["count"] if data else 0
    return jsonify(results), 200


# ============================================================================
# FRONTEND (serve the built React app)
# ============================================================================

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def serve_frontend(path):
    """Serve the built React dashboard, falling back to index.html for SPA routes."""
    if not os.path.isdir(FRONTEND_DIST):
        return jsonify({
            "message": "KNRA Licensing API is running.",
            "hint": "Build the frontend with `cd frontend && npm install && npm run build`.",
            "endpoints": ["/health", "/api/facilities", "/api/licenses", "/api/inspectors"],
        }), 200
    if path and os.path.exists(os.path.join(FRONTEND_DIST, path)):
        return send_from_directory(FRONTEND_DIST, path)
    return send_from_directory(FRONTEND_DIST, "index.html")


# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500


# ============================================================================
# RUN APPLICATION
# ============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("KNRA Licensing Database API (SQLite)")
    print("=" * 60)
    print(f"Database: {db.DB_PATH}")
    print("Server:   http://localhost:5000")
    print("Health:   http://localhost:5000/health")
    print("=" * 60)

    debug_mode = os.getenv("FLASK_ENV") != "production"
    app.run(debug=debug_mode, host="0.0.0.0", port=5000)
