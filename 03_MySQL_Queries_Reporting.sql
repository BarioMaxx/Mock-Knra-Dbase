-- KNRA Database - MySQL Query Examples & Reporting
-- Date: June 2026

-- ============================================================================
-- COMMON QUERIES
-- ============================================================================

-- 1. Find All Active Facilities
SELECT id, hospital_name, location, facility_class, status
FROM facilities
WHERE status = 'active'
ORDER BY hospital_name;

-- 2. Find Licenses Expiring Soon (within 90 days)
SELECT l.license_number, f.hospital_name, l.expiry_date,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
AND l.status = 'active'
ORDER BY l.expiry_date ASC;

-- 3. Find Equipment Needing Calibration
SELECT e.equipment_name, e.serial_number, e.equipment_type, f.hospital_name,
       e.next_calibration_due,
       DATEDIFF(e.next_calibration_due, CURDATE()) AS days_until_due
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due <= CURDATE()
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;

-- 4. Get Facility Details with Related Info
SELECT f.hospital_name, f.location, f.facility_class,
       l.license_number, l.status AS license_status,
       COUNT(DISTINCT e.id) AS equipment_count,
       COUNT(DISTINCT i.id) AS inspection_count
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id
LEFT JOIN equipment e ON f.id = e.facility_id
LEFT JOIN inspections i ON f.id = i.facility_id
GROUP BY f.id, f.hospital_name, f.location, f.facility_class, l.license_number, l.status;

-- 5. Find Inspections Conducted by Specific Inspector
SELECT i.id, f.hospital_name, i.inspection_date, i.inspection_type, i.compliance_rating
FROM inspections i
JOIN facilities f ON i.facility_id = f.id
WHERE i.inspector_id = 1
ORDER BY i.inspection_date DESC;

-- 6. Find Non-Compliant Facilities
SELECT DISTINCT f.id, f.hospital_name, f.location,
       COUNT(DISTINCT i.id) AS violation_count,
       MAX(i.inspection_date) AS last_inspection
FROM facilities f
JOIN inspections i ON f.id = i.facility_id
WHERE i.compliance_rating = 'Non-compliant'
GROUP BY f.id, f.hospital_name, f.location
ORDER BY violation_count DESC;

-- 7. Get Inspector's Assigned Facilities
SELECT ins.staff_id, ins.first_name, ins.last_name, f.hospital_name, f.location, f.facility_class
FROM inspectors ins
JOIN inspector_facilities inf ON ins.id = inf.inspector_id
JOIN facilities f ON inf.facility_id = f.id
WHERE ins.staff_id = 'KNRA-INS-001'
ORDER BY f.hospital_name;

-- 8. Find Equipment with Expired Calibration
SELECT e.equipment_name, e.serial_number, f.hospital_name,
       e.next_calibration_due,
       DATEDIFF(CURDATE(), e.next_calibration_due) AS days_overdue
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due < CURDATE()
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;

-- 9. Get Audit Trail for Specific License
SELECT al.id, u.full_name, al.action, al.entity_type, al.timestamp,
       al.change_reason, al.ip_address
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.entity_type = 'License'
AND al.entity_id = 1
ORDER BY al.timestamp DESC;

-- 10. Find Critical Violations Requiring Action
SELECT f.hospital_name, iv.violation_code, iv.description,
       iv.corrective_action_required, iv.deadline,
       DATEDIFF(CURDATE(), iv.deadline) AS days_overdue
FROM inspection_violations iv
JOIN inspections i ON iv.inspection_id = i.id
JOIN facilities f ON i.facility_id = f.id
WHERE iv.severity = 'critical'
AND iv.deadline < CURDATE()
ORDER BY iv.deadline ASC;

-- ============================================================================
-- REPORTING QUERIES
-- ============================================================================

-- 1. Facilities Compliance Summary Report
SELECT f.hospital_name, f.facility_class, f.location, l.license_number, l.status,
       l.expiry_date, COUNT(DISTINCT i.id) AS total_inspections,
       SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant_count,
       SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant_count,
       MAX(i.inspection_date) AS last_inspection_date
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id
LEFT JOIN inspections i ON f.id = i.facility_id
GROUP BY f.id, f.hospital_name, f.facility_class, f.location, l.license_number, l.status, l.expiry_date
ORDER BY f.hospital_name;

-- 2. License Renewal Status Report
SELECT lr.id, f.hospital_name, l.license_number, lr.renewal_request_date,
       lr.previous_expiry, lr.new_expiry, lr.status, lr.renewal_fee,
       CASE WHEN lr.fee_paid_date IS NOT NULL THEN 'Paid' ELSE 'Unpaid' END AS fee_status
FROM license_renewals lr
JOIN licenses l ON lr.license_id = l.id
JOIN facilities f ON lr.facility_id = f.id
GROUP BY lr.id, f.hospital_name, l.license_number, lr.renewal_request_date,
         lr.previous_expiry, lr.new_expiry, lr.status, lr.renewal_fee, lr.fee_paid_date
ORDER BY lr.renewal_request_date DESC;

-- 3. Inspection Statistics by Month
SELECT YEAR(inspection_date) AS year, MONTH(inspection_date) AS month,
       COUNT(*) AS total_inspections,
       SUM(CASE WHEN compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant,
       SUM(CASE WHEN compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant,
       SUM(CASE WHEN compliance_rating = 'Partial Compliance' THEN 1 ELSE 0 END) AS partial
FROM inspections
WHERE inspection_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY YEAR(inspection_date), MONTH(inspection_date)
ORDER BY year DESC, month DESC;

-- 4. Equipment Maintenance Schedule (Next 30 Days)
SELECT e.equipment_name, e.serial_number, e.equipment_type, f.hospital_name,
       e.next_calibration_due,
       DATEDIFF(e.next_calibration_due, CURDATE()) AS days_until_due
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;

-- 5. User Activity Report by Role
SELECT role, COUNT(*) AS total_users,
       SUM(CASE WHEN is_active = TRUE THEN 1 ELSE 0 END) AS active_users,
       SUM(CASE WHEN is_active = FALSE THEN 1 ELSE 0 END) AS inactive_users,
       MAX(last_login) AS last_activity
FROM users
GROUP BY role;

-- 6. Critical Violations Pending Resolution
SELECT f.hospital_name, iv.violation_code, iv.description,
       iv.corrective_action_required, iv.deadline,
       DATEDIFF(CURDATE(), iv.deadline) AS days_overdue,
       i.inspector_id
FROM inspection_violations iv
JOIN inspections i ON iv.inspection_id = i.id
JOIN facilities f ON i.facility_id = f.id
WHERE iv.severity = 'critical'
AND iv.deadline <= CURDATE()
ORDER BY days_overdue DESC;

-- 7. License Expiry Alerts (30, 60, 90 days)
SELECT f.hospital_name, l.license_number, l.expiry_date,
       CASE 
           WHEN DATEDIFF(l.expiry_date, CURDATE()) <= 30 THEN '0-30 Days'
           WHEN DATEDIFF(l.expiry_date, CURDATE()) <= 60 THEN '31-60 Days'
           WHEN DATEDIFF(l.expiry_date, CURDATE()) <= 90 THEN '61-90 Days'
       END AS urgency_level,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_remaining
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.status = 'active'
AND l.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY l.expiry_date ASC;

-- 8. Equipment Status Overview
SELECT equipment_type, status, COUNT(*) AS count
FROM equipment
GROUP BY equipment_type, status
ORDER BY equipment_type, status;

-- 9. Inspector Performance Metrics
SELECT ins.staff_id, ins.first_name, ins.last_name,
       COUNT(DISTINCT i.id) AS total_inspections,
       SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant_count,
       ROUND(SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) * 100 / COUNT(DISTINCT i.id), 2) AS compliance_percentage,
       MAX(i.inspection_date) AS last_inspection
FROM inspectors ins
LEFT JOIN inspections i ON ins.id = i.inspector_id
GROUP BY ins.id, ins.staff_id, ins.first_name, ins.last_name
ORDER BY compliance_percentage DESC;

-- 10. Violations by Severity
SELECT severity, COUNT(*) AS count
FROM inspection_violations
GROUP BY severity
ORDER BY CASE severity
    WHEN 'critical' THEN 1
    WHEN 'major' THEN 2
    WHEN 'minor' THEN 3
END;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- Update Expired Licenses Status
UPDATE licenses
SET status = 'expired'
WHERE expiry_date < CURDATE()
AND status = 'active';

-- Archive Old Inspections (older than 3 years)
SELECT COUNT(*) FROM inspections
WHERE inspection_date < DATE_SUB(CURDATE(), INTERVAL 3 YEAR);

-- Generate Monthly Compliance Summary
SELECT YEAR(inspection_date) AS year, MONTH(inspection_date) AS month,
       compliance_rating, COUNT(*) AS count
FROM inspections
WHERE inspection_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY YEAR(inspection_date), MONTH(inspection_date), compliance_rating;

-- ============================================================================
-- DASHBOARD QUERIES
-- ============================================================================

-- Dashboard: Key Performance Indicators
SELECT 
    'Total Facilities' AS metric, CAST(COUNT(*) AS CHAR) AS value
FROM facilities
WHERE status = 'active'
UNION ALL
SELECT 'Active Licenses', CAST(COUNT(*) AS CHAR)
FROM licenses
WHERE status = 'active'
UNION ALL
SELECT 'Operational Equipment', CAST(COUNT(*) AS CHAR)
FROM equipment
WHERE status = 'operational'
UNION ALL
SELECT 'Pending Inspections', CAST(COUNT(*) AS CHAR)
FROM inspections
WHERE status IN ('scheduled', 'in_progress')
UNION ALL
SELECT 'Facilities Non-Compliant', CAST(COUNT(DISTINCT facility_id) AS CHAR)
FROM inspections
WHERE compliance_rating = 'Non-compliant'
UNION ALL
SELECT 'Critical Violations', CAST(COUNT(*) AS CHAR)
FROM inspection_violations
WHERE severity = 'critical';

-- Dashboard: Expiry Calendar (Next 90 days)
SELECT CURDATE() AS current_date,
       SUM(CASE WHEN DATEDIFF(expiry_date, CURDATE()) BETWEEN 1 AND 30 THEN 1 ELSE 0 END) AS expiring_next_30_days,
       SUM(CASE WHEN DATEDIFF(expiry_date, CURDATE()) BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS expiring_31_60_days,
       SUM(CASE WHEN DATEDIFF(expiry_date, CURDATE()) BETWEEN 61 AND 90 THEN 1 ELSE 0 END) AS expiring_61_90_days
FROM licenses
WHERE status = 'active';

-- ============================================================================
-- EXPORT QUERIES (for Reports)
-- ============================================================================

-- Export: All Facilities with License Details
SELECT f.*, l.license_number, l.status, l.expiry_date, l.fee_paid
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id
ORDER BY f.hospital_name;

-- Export: Inspection Records with Violations
SELECT i.*, f.hospital_name,
       GROUP_CONCAT(iv.violation_code SEPARATOR '; ') AS violation_codes,
       GROUP_CONCAT(iv.description SEPARATOR '; ') AS violations
FROM inspections i
LEFT JOIN facilities f ON i.facility_id = f.id
LEFT JOIN inspection_violations iv ON i.id = iv.inspection_id
GROUP BY i.id
ORDER BY i.inspection_date DESC;

-- Export: Equipment Inventory
SELECT e.*, f.hospital_name, f.location,
       DATEDIFF(e.next_calibration_due, CURDATE()) AS days_until_calibration_due
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
ORDER BY f.hospital_name, e.equipment_name;
