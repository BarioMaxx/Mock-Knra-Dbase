"""
KNRA Licensing Database API
Flask REST API for radioactive equipment and facility licensing system
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta
import os
import json
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
    'database': os.getenv('DB_NAME', 'knra_licensing_db'),
    'connection_timeout': int(os.getenv('DB_CONNECTION_TIMEOUT', '5'))
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

def sample_dashboard_records():
    """Fallback records for a useful demo page when the database is unavailable."""
    return {
        'facilities': [
            {
                'id': 1,
                'hospital_name': 'Kenyatta National Hospital',
                'location': 'Nairobi',
                'facility_class': 'Class II',
                'equipment_classes': ['CT Scanner', 'X-ray', 'Radiotherapy'],
                'status': 'active'
            },
            {
                'id': 2,
                'hospital_name': 'Aga Khan University Hospital',
                'location': 'Nairobi',
                'facility_class': 'Class I',
                'equipment_classes': ['Radiotherapy', 'Nuclear Medicine', 'Diagnostic Imaging'],
                'status': 'active'
            },
            {
                'id': 3,
                'hospital_name': 'Mombasa Hospital',
                'location': 'Mombasa',
                'facility_class': 'Class III',
                'equipment_classes': ['X-ray', 'CT Scanner'],
                'status': 'active'
            }
        ],
        'licenses': [
            {
                'id': 1,
                'license_number': 'KNRA-2023-000001',
                'hospital_name': 'Kenyatta National Hospital',
                'issue_date': '2023-01-15',
                'expiry_date': '2027-01-14',
                'status': 'active',
                'fee_paid': True,
                'fee_amount': 250000
            },
            {
                'id': 2,
                'license_number': 'KNRA-2024-000015',
                'hospital_name': 'Aga Khan University Hospital',
                'issue_date': '2024-02-01',
                'expiry_date': '2028-01-31',
                'status': 'active',
                'fee_paid': True,
                'fee_amount': 350000
            }
        ],
        'source': 'sample'
    }

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

@app.route('/api/dashboard-records', methods=['GET'])
def get_dashboard_records():
    """Get the compact records needed by the React dashboard."""
    facilities_query = """
        SELECT id, hospital_name, location, facility_class, equipment_classes, status
        FROM facilities
        ORDER BY hospital_name
    """
    licenses_query = """
        SELECT l.id, l.license_number, f.hospital_name, l.issue_date, l.expiry_date,
               l.status, l.fee_paid, l.fee_amount
        FROM licenses l
        JOIN facilities f ON l.facility_id = f.id
        ORDER BY l.expiry_date ASC
    """

    facilities = execute_query(facilities_query)
    licenses = execute_query(licenses_query)

    if facilities is None or licenses is None:
        fallback = sample_dashboard_records()
        fallback['notice'] = 'Database unavailable; showing sample records.'
        return jsonify(fallback), 200

    for facility in facilities:
        equipment_classes = facility.get('equipment_classes')
        if isinstance(equipment_classes, str):
            try:
                facility['equipment_classes'] = json.loads(equipment_classes)
            except json.JSONDecodeError:
                facility['equipment_classes'] = []

    return jsonify({
        'facilities': facilities,
        'licenses': licenses,
        'source': 'database'
    }), 200

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
# FRONTEND
# ============================================================================

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_react_app(path):
    """Serve the built React app and keep API 404s as JSON."""
    if path.startswith('api/'):
        return jsonify({'error': 'Endpoint not found'}), 404

    dist_dir = os.path.join(os.path.dirname(__file__), 'dist')
    requested_file = os.path.join(dist_dir, path)

    if path and os.path.exists(requested_file):
        return send_from_directory(dist_dir, path)

    index_file = os.path.join(dist_dir, 'index.html')
    if os.path.exists(index_file):
        return send_from_directory(dist_dir, 'index.html')

    return jsonify({
        'message': 'KNRA Licensing Database API',
        'frontend': 'Run npm install && npm run build to generate the React site.',
        'health': '/health',
        'records': '/api/dashboard-records'
    }), 200

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
