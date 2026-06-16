"""
KNRA Licensing Database API
Flask REST API for radioactive equipment and facility licensing system
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'root'),
    'database': os.getenv('DB_NAME', 'knra_licensing_db')
}

# ============================================================================
# DATABASE CONNECTION
# ============================================================================

def get_db_connection():
    """Create database connection"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        print(f"Database connection error: {e}")
        return None

def execute_query(query, params=None):
    """Execute SELECT query and return results"""
    conn = get_db_connection()
    if not conn:
        return None
    try:
        cursor = conn.cursor(dictionary=True)
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        result = cursor.fetchall()
        cursor.close()
        return result
    except Error as e:
        print(f"Query error: {e}")
        return None
    finally:
        conn.close()

def execute_insert_update(query, params=None):
    """Execute INSERT/UPDATE query"""
    conn = get_db_connection()
    if not conn:
        return False
    try:
        cursor = conn.cursor()
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        conn.commit()
        cursor.close()
        return True
    except Error as e:
        print(f"Insert/Update error: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.route('/health', methods=['GET'])
def health_check():
    """Check API and database health"""
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'database': 'connected'
        }), 200
    return jsonify({
        'status': 'unhealthy',
        'database': 'disconnected'
    }), 500

# ============================================================================
# FACILITIES ENDPOINTS
# ============================================================================

@app.route('/api/facilities', methods=['GET'])
def get_facilities():
    """Get all facilities"""
    query = """
        SELECT id, hospital_name, location, facility_class, status, 
               authorized_equipment, created_at 
        FROM facilities 
        ORDER BY hospital_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/facilities/<int:facility_id>', methods=['GET'])
def get_facility(facility_id):
    """Get specific facility with related data"""
    # Get facility details
    facility_query = """
        SELECT * FROM facilities WHERE id = %s
    """
    facility = execute_query(facility_query, (facility_id,))
    
    if not facility:
        return jsonify({'error': 'Facility not found'}), 404
    
    # Get associated licenses
    licenses_query = """
        SELECT id, license_number, issue_date, expiry_date, status 
        FROM licenses 
        WHERE facility_id = %s
    """
    licenses = execute_query(licenses_query, (facility_id,))
    
    # Get associated equipment
    equipment_query = """
        SELECT id, equipment_name, serial_number, equipment_type, status 
        FROM equipment 
        WHERE facility_id = %s
    """
    equipment = execute_query(equipment_query, (facility_id,))
    
    return jsonify({
        'facility': facility[0],
        'licenses': licenses,
        'equipment': equipment
    }), 200

@app.route('/api/facilities', methods=['POST'])
def create_facility():
    """Create new facility"""
    data = request.json
    query = """
        INSERT INTO facilities (hospital_name, location, facility_class, status)
        VALUES (%s, %s, %s, %s)
    """
    params = (
        data.get('hospital_name'),
        data.get('location'),
        data.get('facility_class'),
        data.get('status', 'active')
    )
    
    if execute_insert_update(query, params):
        return jsonify({'message': 'Facility created successfully'}), 201
    return jsonify({'error': 'Failed to create facility'}), 500

# ============================================================================
# LICENSES ENDPOINTS
# ============================================================================

@app.route('/api/licenses', methods=['GET'])
def get_licenses():
    """Get all licenses with facility info"""
    query = """
        SELECT l.*, f.hospital_name,
               DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        ORDER BY l.expiry_date ASC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/licenses/expiring', methods=['GET'])
def get_expiring_licenses():
    """Get licenses expiring within 90 days"""
    days = request.args.get('days', 90, type=int)
    query = """
        SELECT l.license_number, f.hospital_name, l.expiry_date,
               DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry,
               l.status
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        WHERE l.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL %s DAY)
        AND l.status = 'active'
        ORDER BY l.expiry_date ASC
    """
    results = execute_query(query, (days,))
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify({
        'count': len(results),
        'licenses': results
    }), 200

@app.route('/api/licenses/<int:license_id>', methods=['GET'])
def get_license(license_id):
    """Get specific license"""
    query = """
        SELECT l.*, f.hospital_name 
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        WHERE l.id = %s
    """
    results = execute_query(query, (license_id,))
    if not results:
        return jsonify({'error': 'License not found'}), 404
    return jsonify(results[0]), 200

@app.route('/api/licenses', methods=['POST'])
def create_license():
    """Create new license"""
    data = request.json
    query = """
        INSERT INTO licenses 
        (facility_id, license_number, issue_date, expiry_date, status, fee_amount)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    params = (
        data.get('facility_id'),
        data.get('license_number'),
        data.get('issue_date'),
        data.get('expiry_date'),
        data.get('status', 'active'),
        data.get('fee_amount', 0)
    )
    
    if execute_insert_update(query, params):
        return jsonify({'message': 'License created successfully'}), 201
    return jsonify({'error': 'Failed to create license'}), 500

# ============================================================================
# EQUIPMENT ENDPOINTS
# ============================================================================

@app.route('/api/equipment', methods=['GET'])
def get_equipment():
    """Get all equipment"""
    query = """
        SELECT e.*, f.hospital_name
        FROM equipment e
        JOIN facilities f ON e.facility_id = f.id
        ORDER BY f.hospital_name, e.equipment_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/equipment/overdue', methods=['GET'])
def get_overdue_equipment():
    """Get equipment overdue for calibration"""
    query = """
        SELECT e.equipment_name, e.serial_number, f.hospital_name,
               e.next_calibration_due,
               DATEDIFF(CURDATE(), e.next_calibration_due) AS days_overdue,
               e.status
        FROM equipment e
        JOIN facilities f ON e.facility_id = f.id
        WHERE e.next_calibration_due < CURDATE()
        AND e.status = 'operational'
        ORDER BY e.next_calibration_due ASC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify({
        'count': len(results) if results else 0,
        'equipment': results
    }), 200

@app.route('/api/equipment/<int:equipment_id>', methods=['GET'])
def get_equipment_detail(equipment_id):
    """Get specific equipment details"""
    query = """
        SELECT e.*, f.hospital_name 
        FROM equipment e
        JOIN facilities f ON e.facility_id = f.id
        WHERE e.id = %s
    """
    results = execute_query(query, (equipment_id,))
    if not results:
        return jsonify({'error': 'Equipment not found'}), 404
    return jsonify(results[0]), 200

@app.route('/api/equipment', methods=['POST'])
def create_equipment():
    """Create new equipment"""
    data = request.json
    query = """
        INSERT INTO equipment 
        (facility_id, equipment_name, serial_number, equipment_type, status)
        VALUES (%s, %s, %s, %s, %s)
    """
    params = (
        data.get('facility_id'),
        data.get('equipment_name'),
        data.get('serial_number'),
        data.get('equipment_type'),
        data.get('status', 'operational')
    )
    
    if execute_insert_update(query, params):
        return jsonify({'message': 'Equipment created successfully'}), 201
    return jsonify({'error': 'Failed to create equipment'}), 500

# ============================================================================
# INSPECTIONS ENDPOINTS
# ============================================================================

@app.route('/api/inspections', methods=['GET'])
def get_inspections():
    """Get all inspections"""
    query = """
        SELECT i.*, f.hospital_name, ins.first_name, ins.last_name
        FROM inspections i
        JOIN facilities f ON i.facility_id = f.id
        JOIN inspectors ins ON i.inspector_id = ins.id
        ORDER BY i.inspection_date DESC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/inspections/<int:inspection_id>', methods=['GET'])
def get_inspection(inspection_id):
    """Get inspection with violations"""
    inspection_query = """
        SELECT i.*, f.hospital_name, ins.first_name, ins.last_name
        FROM inspections i
        JOIN facilities f ON i.facility_id = f.id
        JOIN inspectors ins ON i.inspector_id = ins.id
        WHERE i.id = %s
    """
    inspection = execute_query(inspection_query, (inspection_id,))
    
    if not inspection:
        return jsonify({'error': 'Inspection not found'}), 404
    
    violations_query = """
        SELECT * FROM inspection_violations 
        WHERE inspection_id = %s
    """
    violations = execute_query(violations_query, (inspection_id,))
    
    return jsonify({
        'inspection': inspection[0],
        'violations': violations
    }), 200

@app.route('/api/inspections', methods=['POST'])
def create_inspection():
    """Create new inspection"""
    data = request.json
    query = """
        INSERT INTO inspections 
        (facility_id, inspector_id, inspection_date, compliance_rating, notes)
        VALUES (%s, %s, %s, %s, %s)
    """
    params = (
        data.get('facility_id'),
        data.get('inspector_id'),
        data.get('inspection_date', datetime.now().date()),
        data.get('compliance_rating'),
        data.get('notes', '')
    )
    
    if execute_insert_update(query, params):
        return jsonify({'message': 'Inspection created successfully'}), 201
    return jsonify({'error': 'Failed to create inspection'}), 500

# ============================================================================
# INSPECTORS ENDPOINTS
# ============================================================================

@app.route('/api/inspectors', methods=['GET'])
def get_inspectors():
    """Get all inspectors"""
    query = """
        SELECT id, staff_id, first_name, last_name, email, status 
        FROM inspectors 
        ORDER BY last_name, first_name
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/inspectors/<int:inspector_id>/workload', methods=['GET'])
def get_inspector_workload(inspector_id):
    """Get inspector's inspection workload"""
    query = """
        SELECT i.*, f.hospital_name
        FROM inspections i
        JOIN facilities f ON i.facility_id = f.id
        WHERE i.inspector_id = %s
        ORDER BY i.inspection_date DESC
    """
    results = execute_query(query, (inspector_id,))
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify({
        'inspector_id': inspector_id,
        'inspection_count': len(results) if results else 0,
        'inspections': results
    }), 200

# ============================================================================
# REPORTING ENDPOINTS
# ============================================================================

@app.route('/api/reports/compliance-summary', methods=['GET'])
def get_compliance_summary():
    """Get facility compliance summary"""
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
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/reports/violations', methods=['GET'])
def get_violations_report():
    """Get recent violations report"""
    query = """
        SELECT f.hospital_name, iv.violation_code, iv.description, 
               iv.severity, iv.deadline, i.inspection_date
        FROM inspection_violations iv
        JOIN inspections i ON iv.inspection_id = i.id
        JOIN facilities f ON i.facility_id = f.id
        WHERE iv.deadline >= CURDATE()
        ORDER BY iv.deadline ASC
    """
    results = execute_query(query)
    if results is None:
        return jsonify({'error': 'Database error'}), 500
    return jsonify(results), 200

@app.route('/api/reports/kpis', methods=['GET'])
def get_kpis():
    """Get key performance indicators"""
    queries = {
        'total_facilities': 'SELECT COUNT(*) as count FROM facilities WHERE status = "active"',
        'active_licenses': 'SELECT COUNT(*) as count FROM licenses WHERE status = "active"',
        'total_equipment': 'SELECT COUNT(*) as count FROM equipment WHERE status = "operational"',
        'overdue_calibrations': 'SELECT COUNT(*) as count FROM equipment WHERE next_calibration_due < CURDATE() AND status = "operational"',
        'expiring_licenses_90_days': 'SELECT COUNT(*) as count FROM licenses WHERE status = "active" AND expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)'
    }
    
    results = {}
    for key, query in queries.items():
        data = execute_query(query)
        results[key] = data[0]['count'] if data else 0
    
    return jsonify(results), 200

# ============================================================================
# ERROR HANDLERS
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

# ============================================================================
# RUN APPLICATION
# ============================================================================

if __name__ == '__main__':
    print("=" * 60)
    print("KNRA Licensing Database API")
    print("=" * 60)
    print(f"Database: {DB_CONFIG['host']}/{DB_CONFIG['database']}")
    print(f"Server: http://localhost:5000")
    print(f"Health Check: http://localhost:5000/health")
    print("=" * 60)
    
    # Development mode - use debug=True locally
    # For Vercel: automatically runs with debug=False
    debug_mode = os.getenv('FLASK_ENV') != 'production'
    app.run(debug=debug_mode, host='0.0.0.0', port=5000)
