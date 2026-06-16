-- KNRA Radioactive Equipment & Facility Licensing Database
-- MySQL 8.0+ Schema Creation Script
-- Date: June 2026

-- Create database
CREATE DATABASE IF NOT EXISTS knra_licensing_db;
USE knra_licensing_db;

-- ============================================================================
-- 1. USERS TABLE (System Users & Administrators)
-- ============================================================================

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    staff_id VARCHAR(50) NOT NULL UNIQUE,
    role ENUM('admin', 'inspector', 'facility_manager', 'auditor') NOT NULL,
    assigned_facility_id BIGINT,
    permissions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_staff_id (staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. FACILITIES TABLE (Hospitals & Licensed Locations)
-- ============================================================================

CREATE TABLE facilities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    facility_class ENUM('Class I', 'Class II', 'Class III') NOT NULL,
    license_number VARCHAR(50),
    established_date DATE,
    contact_person VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(255),
    street_address VARCHAR(255),
    city VARCHAR(100),
    county VARCHAR(100),
    postal_code VARCHAR(10),
    country VARCHAR(100) DEFAULT 'Kenya',
    equipment_classes JSON,
    status ENUM('active', 'inactive', 'suspended', 'under_review') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hospital_name (hospital_name),
    INDEX idx_license_number (license_number),
    INDEX idx_status (status),
    INDEX idx_facility_class (facility_class),
    INDEX idx_location (location)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. LICENSES TABLE (Facility Operating Licenses)
-- ============================================================================

CREATE TABLE licenses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    facility_id BIGINT NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    renewal_due_date DATE,
    status ENUM('active', 'expired', 'suspended', 'revoked', 'pending_renewal') DEFAULT 'active',
    fee_amount DECIMAL(10, 2),
    fee_paid BOOLEAN DEFAULT FALSE,
    fee_payment_date TIMESTAMP NULL,
    payment_reference VARCHAR(100),
    approved_by BIGINT,
    license_conditions TEXT,
    authorized_equipment JSON,
    last_inspected TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_license_number (license_number),
    INDEX idx_facility_id (facility_id),
    INDEX idx_expiry_date (expiry_date),
    INDEX idx_status (status),
    INDEX idx_renewal_due_date (renewal_due_date),
    INDEX idx_fee_paid (fee_paid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. EQUIPMENT TABLE (Radioactive Devices)
-- ============================================================================

CREATE TABLE equipment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    facility_id BIGINT NOT NULL,
    equipment_name VARCHAR(255) NOT NULL,
    equipment_type ENUM('CT Scanner', 'X-ray', 'Radiotherapy', 'Nuclear Medicine', 'Diagnostic Imaging', 'Industrial', 'Other') NOT NULL,
    manufacturer VARCHAR(255),
    model_number VARCHAR(100),
    serial_number VARCHAR(100) NOT NULL UNIQUE,
    installation_date DATE NOT NULL,
    radiation_class ENUM('Class I', 'Class II', 'Class III') NOT NULL,
    radiation_level DECIMAL(10, 4),
    status ENUM('operational', 'maintenance', 'decommissioned', 'awaiting_inspection') DEFAULT 'operational',
    last_calibration DATE,
    next_calibration_due DATE NOT NULL,
    calibration_frequency_months INT DEFAULT 6,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE,
    INDEX idx_serial_number (serial_number),
    INDEX idx_facility_id (facility_id),
    INDEX idx_equipment_type (equipment_type),
    INDEX idx_status (status),
    INDEX idx_next_calibration_due (next_calibration_due)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. INSPECTORS TABLE (Regulatory Staff)
-- ============================================================================

CREATE TABLE inspectors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    staff_id VARCHAR(50) NOT NULL UNIQUE,
    user_id BIGINT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    qualification VARCHAR(255),
    assigned_facilities JSON,
    hire_date DATE NOT NULL,
    status ENUM('active', 'inactive', 'on_leave', 'retired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_staff_id (staff_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. INSPECTIONS TABLE (Compliance Inspections)
-- ============================================================================

CREATE TABLE inspections (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    inspector_id BIGINT NOT NULL,
    facility_id BIGINT NOT NULL,
    inspection_date TIMESTAMP NOT NULL,
    inspection_type ENUM('routine', 'compliance', 'complaint_based', 'follow_up', 'pre_license') NOT NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'scheduled',
    findings_summary TEXT,
    findings_details TEXT,
    findings_duration_hours DECIMAL(5, 2),
    compliance_rating ENUM('Compliant', 'Non-compliant', 'Partial Compliance'),
    recommendations TEXT,
    next_inspection_due DATE,
    report_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (inspector_id) REFERENCES inspectors(id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE,
    INDEX idx_facility_id (facility_id),
    INDEX idx_inspector_id (inspector_id),
    INDEX idx_inspection_date (inspection_date),
    INDEX idx_status (status),
    INDEX idx_compliance_rating (compliance_rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 7. INSPECTION_VIOLATIONS TABLE (Violations from Inspections)
-- ============================================================================

CREATE TABLE inspection_violations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    inspection_id BIGINT NOT NULL,
    violation_code VARCHAR(50) NOT NULL,
    severity ENUM('critical', 'major', 'minor') NOT NULL,
    description TEXT NOT NULL,
    corrective_action_required TEXT,
    deadline DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON DELETE CASCADE,
    INDEX idx_inspection_id (inspection_id),
    INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 8. EQUIPMENT_INSPECTIONS TABLE (Equipment-Level Checks)
-- ============================================================================

CREATE TABLE equipment_inspections (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    equipment_id BIGINT NOT NULL,
    inspection_id BIGINT NOT NULL,
    calibration_date DATE NOT NULL,
    calibration_status ENUM('Pass', 'Fail', 'Needs Adjustment', 'Not Applicable') DEFAULT 'Pass',
    radiation_reading DECIMAL(10, 4),
    expected_reading DECIMAL(10, 4),
    reading_variance_percent DECIMAL(6, 2),
    safety_status ENUM('Safe', 'Unsafe', 'Maintenance Needed', 'Decommission Recommended'),
    findings TEXT,
    corrective_action TEXT,
    corrective_action_due DATE,
    action_completed_date DATE,
    action_verified_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE,
    FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON DELETE CASCADE,
    FOREIGN KEY (action_verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_equipment_id (equipment_id),
    INDEX idx_inspection_id (inspection_id),
    INDEX idx_calibration_status (calibration_status),
    INDEX idx_safety_status (safety_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 9. AUDIT_LOGS TABLE (Compliance & Change Tracking)
-- ============================================================================

CREATE TABLE audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    entity_type ENUM('Facility', 'License', 'Equipment', 'Inspector', 'Inspection', 'User') NOT NULL,
    entity_id BIGINT,
    action ENUM('create', 'update', 'delete', 'approve', 'reject') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_fields JSON,
    change_reason TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approval_status ENUM('auto_approved', 'pending', 'approved', 'rejected') DEFAULT 'auto_approved',
    approved_by BIGINT,
    approval_date TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_entity_id (entity_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_entity_type (entity_type),
    INDEX idx_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 10. LICENSE_RENEWALS TABLE (License Renewal Tracking)
-- ============================================================================

CREATE TABLE license_renewals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    license_id BIGINT NOT NULL,
    facility_id BIGINT NOT NULL,
    renewal_request_date TIMESTAMP NOT NULL,
    previous_expiry DATE,
    new_expiry DATE,
    status ENUM('pending', 'under_review', 'approved', 'rejected', 'completed') DEFAULT 'pending',
    approved_date TIMESTAMP NULL,
    approved_by BIGINT,
    renewal_fee DECIMAL(10, 2),
    fee_paid_date TIMESTAMP NULL,
    payment_reference VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_license_id (license_id),
    INDEX idx_facility_id (facility_id),
    INDEX idx_status (status),
    INDEX idx_renewal_request_date (renewal_request_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 11. INSPECTION_EQUIPMENT TABLE (Junction table for many-to-many relationship)
-- ============================================================================

CREATE TABLE inspection_equipment (
    inspection_id BIGINT NOT NULL,
    equipment_id BIGINT NOT NULL,
    PRIMARY KEY (inspection_id, equipment_id),
    FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON DELETE CASCADE,
    FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 12. INSPECTOR_FACILITIES TABLE (Junction table for many-to-many relationship)
-- ============================================================================

CREATE TABLE inspector_facilities (
    inspector_id BIGINT NOT NULL,
    facility_id BIGINT NOT NULL,
    PRIMARY KEY (inspector_id, facility_id),
    FOREIGN KEY (inspector_id) REFERENCES inspectors(id) ON DELETE CASCADE,
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE,
    INDEX idx_facility_id (facility_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Active Licenses
CREATE OR REPLACE VIEW vw_active_licenses AS
SELECT 
    l.id,
    l.license_number,
    f.hospital_name,
    f.location,
    l.issue_date,
    l.expiry_date,
    DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry,
    l.status,
    l.fee_paid
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.status = 'active'
ORDER BY l.expiry_date ASC;

-- View: Overdue Calibrations
CREATE OR REPLACE VIEW vw_overdue_calibrations AS
SELECT 
    e.id,
    e.equipment_name,
    e.serial_number,
    f.hospital_name,
    e.last_calibration,
    e.next_calibration_due,
    DATEDIFF(CURDATE(), e.next_calibration_due) AS days_overdue
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due < CURDATE()
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;

-- View: Compliance Summary by Facility
CREATE OR REPLACE VIEW vw_facility_compliance_summary AS
SELECT 
    f.id,
    f.hospital_name,
    f.facility_class,
    l.license_number,
    l.status AS license_status,
    COUNT(DISTINCT i.id) AS total_inspections,
    SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant_count,
    SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant_count,
    MAX(i.inspection_date) AS last_inspection_date
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id
LEFT JOIN inspections i ON f.id = i.facility_id
GROUP BY f.id, f.hospital_name, f.facility_class, l.license_number, l.status;

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Procedure: Update expired licenses
DELIMITER //
CREATE PROCEDURE sp_update_expired_licenses()
BEGIN
    UPDATE licenses
    SET status = 'expired'
    WHERE expiry_date < CURDATE()
    AND status = 'active';
END//
DELIMITER ;

-- Procedure: Check equipment calibration due
DELIMITER //
CREATE PROCEDURE sp_get_equipment_calibration_due(IN days_ahead INT)
BEGIN
    SELECT 
        e.id,
        e.equipment_name,
        f.hospital_name,
        e.next_calibration_due,
        DATEDIFF(e.next_calibration_due, CURDATE()) AS days_until_due
    FROM equipment e
    JOIN facilities f ON e.facility_id = f.id
    WHERE e.next_calibration_due BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL days_ahead DAY)
    AND e.status = 'operational'
    ORDER BY e.next_calibration_due ASC;
END//
DELIMITER ;

-- Procedure: Generate inspection statistics
DELIMITER //
CREATE PROCEDURE sp_get_inspection_statistics(IN start_date DATE, IN end_date DATE)
BEGIN
    SELECT 
        i.inspection_type,
        COUNT(*) AS count,
        SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant,
        SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant,
        SUM(CASE WHEN i.compliance_rating = 'Partial Compliance' THEN 1 ELSE 0 END) AS partial_compliance
    FROM inspections i
    WHERE i.inspection_date BETWEEN start_date AND end_date
    GROUP BY i.inspection_type;
END//
DELIMITER ;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT 'KNRA Database schema created successfully!' AS status;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'knra_licensing_db' ORDER BY TABLE_NAME;
