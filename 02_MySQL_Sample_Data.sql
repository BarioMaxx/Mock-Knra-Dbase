-- KNRA Radioactive Equipment & Facility Licensing Database
-- MySQL Sample Data
-- Date: June 2026

USE knra_licensing_db;

-- ============================================================================
-- SAMPLE DATA: USERS
-- ============================================================================

INSERT INTO users (email, username, password, full_name, staff_id, role, permissions, created_at, updated_at, last_login, is_active) VALUES
('james.kimani@knra.go.ke', 'jkimani', '$2y$10$...', 'James Kimani', 'KNRA-001', 'admin', 
 '["create_users", "approve_licenses", "view_audits", "generate_reports"]', NOW(), NOW(), NOW(), TRUE),

('mary.njoroge@knra.go.ke', 'mnjoroge', '$2y$10$...', 'Mary Njoroge', 'KNRA-INS-001', 'inspector', 
 '["conduct_inspections", "submit_findings", "view_assigned_facilities"]', '2023-06-01', NOW(), DATE_SUB(NOW(), INTERVAL 1 DAY), TRUE),

('robert.mwangi@knra.go.ke', 'rmwangi', '$2y$10$...', 'Robert Mwangi', 'KNRA-INS-002', 'inspector', 
 '["conduct_inspections", "submit_findings", "view_assigned_facilities"]', '2023-09-10', NOW(), DATE_SUB(NOW(), INTERVAL 2 DAY), TRUE),

('admin@kemhospital.co.ke', 'kemhospital_admin', '$2y$10$...', 'Hospital Administrator', 'KEM-FA-001', 'facility_manager', 
 '["request_license_renewal", "update_facility_info", "view_own_licenses"]', '2024-03-20', NOW(), DATE_SUB(NOW(), INTERVAL 1 HOUR), TRUE);

-- ============================================================================
-- SAMPLE DATA: FACILITIES
-- ============================================================================

INSERT INTO facilities (hospital_name, location, latitude, longitude, facility_class, license_number, 
                       established_date, contact_person, phone, email, street_address, city, county, 
                       postal_code, country, equipment_classes, status, created_at, updated_at) VALUES

('Kenyatta National Hospital', 'Nairobi', -1.3032, 36.7469, 'Class II', 'KNRA-2023-000001', 
 '1965-09-20', 'Dr. Michael Omondi', '+254-20-7726300', 'admin@kemhospital.co.ke', 'Ngong Hills Road', 
 'Nairobi', 'Nairobi', '00100', 'Kenya', '["CT Scanner", "X-ray", "Radiotherapy"]', 'active', '2023-01-10', NOW()),

('Aga Khan University Hospital', 'Nairobi', -1.2759, 36.7695, 'Class I', 'KNRA-2024-000015', 
 '1994-01-15', 'Prof. Salim Ali', '+254-20-3665000', 'radiotherapy@agakhan.co.ke', 'Third Avenue, Parklands', 
 'Nairobi', 'Nairobi', '00100', 'Kenya', '["Radiotherapy", "Nuclear Medicine", "Diagnostic Imaging"]', 'active', '2023-02-05', NOW()),

('Mombasa Hospital', 'Mombasa', -4.0435, 39.6682, 'Class III', 'KNRA-2023-000008', 
 '1980-06-01', 'Dr. Fatuma Hassan', '+254-41-222200', 'radiology@mombasahospital.co.ke', 'Hospital Road', 
 'Mombasa', 'Mombasa', '80100', 'Kenya', '["X-ray", "CT Scanner"]', 'active', '2023-01-20', NOW());

-- ============================================================================
-- SAMPLE DATA: LICENSES
-- ============================================================================

INSERT INTO licenses (license_number, facility_id, issue_date, expiry_date, renewal_due_date, status, 
                     fee_amount, fee_paid, fee_payment_date, payment_reference, approved_by, 
                     license_conditions, authorized_equipment, last_inspected, created_at, updated_at) VALUES

('KNRA-2023-000001', 1, '2023-01-15', '2027-01-14', '2026-10-14', 'active', 250000, TRUE, 
 '2023-01-12', 'KNB/2023/001/KEM', 1, 'Must conduct annual inspections. Radiotherapy limits: max 200 Gy per day',
 '[{"equipment_type": "CT Scanner", "quantity": 2}, {"equipment_type": "X-ray", "quantity": 5}]', '2026-03-20', '2023-01-10', NOW()),

('KNRA-2024-000015', 2, '2024-02-01', '2028-01-31', '2027-11-01', 'active', 350000, TRUE, 
 '2024-01-30', 'KNB/2024/015/AKHUH', 1, 'Class I facility. Enhanced monitoring required. Quarterly compliance reviews.',
 '[{"equipment_type": "Radiotherapy", "quantity": 2}, {"equipment_type": "Nuclear Medicine", "quantity": 1}]', '2026-05-15', '2024-01-25', NOW());

-- ============================================================================
-- SAMPLE DATA: EQUIPMENT
-- ============================================================================

INSERT INTO equipment (facility_id, equipment_name, equipment_type, manufacturer, model_number, serial_number, 
                      installation_date, radiation_class, radiation_level, status, last_calibration, 
                      next_calibration_due, calibration_frequency_months, created_at, updated_at) VALUES

(1, 'GE Revolution EVO CT Scanner', 'CT Scanner', 'General Electric', 'Revolution EVO', 'GE-CT-2021-0001', 
 '2021-06-15', 'Class II', 45.5, 'operational', '2026-05-10', '2026-11-10', 6, '2021-06-10', NOW()),

(1, 'Varian TrueBeam Radiotherapy Accelerator', 'Radiotherapy', 'Varian', 'TrueBeam STx', 'VAR-RTX-2020-0042', 
 '2020-11-20', 'Class I', 200.0, 'operational', '2026-04-05', '2026-10-05', 6, '2020-11-15', NOW()),

(2, 'Gamma Camera with SPECT', 'Nuclear Medicine', 'Siemens', 'Symbia Intevo', 'SIE-NM-2022-0015', 
 '2022-03-10', 'Class II', 25.8, 'operational', '2026-06-01', '2026-12-01', 6, '2022-03-05', NOW());

-- ============================================================================
-- SAMPLE DATA: INSPECTORS
-- ============================================================================

INSERT INTO inspectors (staff_id, user_id, first_name, last_name, email, phone, qualification, hire_date, status, created_at, updated_at) VALUES

('KNRA-INS-001', 2, 'Mary', 'Njoroge', 'mary.njoroge@knra.go.ke', '+254-712-345678', 
 'BSc Radiation Physics, Certified Radiation Safety Officer', '2018-06-01', 'active', '2023-06-01', NOW()),

('KNRA-INS-002', 3, 'Robert', 'Mwangi', 'robert.mwangi@knra.go.ke', '+254-722-456789', 
 'MSc Health Physics, IAEA Radiation Safety Expert', '2019-09-01', 'active', '2023-09-10', NOW());

-- ============================================================================
-- SAMPLE DATA: INSPECTOR_FACILITIES (Assignment)
-- ============================================================================

INSERT INTO inspector_facilities (inspector_id, facility_id) VALUES
(1, 1),
(1, 2),
(2, 3),
(2, 2);

-- ============================================================================
-- SAMPLE DATA: INSPECTIONS
-- ============================================================================

INSERT INTO inspections (inspector_id, facility_id, inspection_date, inspection_type, status, 
                        findings_summary, findings_details, findings_duration_hours, compliance_rating, 
                        recommendations, next_inspection_due, report_url, created_at, updated_at) VALUES

(1, 1, '2026-03-20 10:00:00', 'routine', 'completed', 
 'Routine inspection completed. Two critical issues identified.', 
 'CT scanner shielding requires reinforcement. Radiotherapy accelerator calibration within acceptable range.',
 4.5, 'Partial Compliance', 'Urgent: Schedule shielding replacement. Implement quarterly calibration verification.',
 '2026-09-20', '/reports/inspection/KNH-2026-03-001.pdf', '2026-03-20', '2026-03-22'),

(2, 3, '2026-06-10 09:30:00', 'compliance', 'completed', 
 'Compliance inspection passed all checks.',
 'All equipment properly calibrated. Safety protocols being followed. Staff training up to date.',
 3.0, 'Compliant', 'Continue current safety practices. Next routine inspection in 12 months.',
 '2027-06-10', '/reports/inspection/AKHUH-2026-06-001.pdf', '2026-06-10', '2026-06-12');

-- ============================================================================
-- SAMPLE DATA: INSPECTION_EQUIPMENT (Equipment inspected in each inspection)
-- ============================================================================

INSERT INTO inspection_equipment (inspection_id, equipment_id) VALUES
(1, 1),
(1, 2),
(2, 3);

-- ============================================================================
-- SAMPLE DATA: INSPECTION_VIOLATIONS
-- ============================================================================

INSERT INTO inspection_violations (inspection_id, violation_code, severity, description, corrective_action_required, deadline) VALUES

(1, 'SHIELD-2026-001', 'major', 'CT scanner room lead shielding showing signs of wear', 
 'Replace lead lining in scanner room walls', '2026-05-20');

-- ============================================================================
-- SAMPLE DATA: EQUIPMENT_INSPECTIONS
-- ============================================================================

INSERT INTO equipment_inspections (equipment_id, inspection_id, calibration_date, calibration_status, 
                                 radiation_reading, expected_reading, reading_variance_percent, safety_status, 
                                 findings, corrective_action, corrective_action_due, action_completed_date, 
                                 action_verified_by, created_at, updated_at) VALUES

(1, 1, '2026-03-20', 'Pass', 45.2, 45.5, -0.66, 'Safe', 
 'CT Scanner operating within normal parameters. Beam quality acceptable.', NULL, NULL, NULL, NULL, '2026-03-20', '2026-03-22'),

(2, 1, '2026-03-20', 'Needs Adjustment', 198.5, 200.0, -0.75, 'Safe', 
 'Radiotherapy accelerator minor calibration drift detected. Still within acceptable range.', 
 'Fine-tune beam energy output. Schedule followup in 3 months.', '2026-04-20', '2026-04-18', 2, '2026-03-20', '2026-04-18');

-- ============================================================================
-- SAMPLE DATA: AUDIT_LOGS
-- ============================================================================

INSERT INTO audit_logs (user_id, entity_type, entity_id, action, old_values, new_values, changed_fields, 
                       change_reason, ip_address, timestamp, approval_status, approved_by) VALUES

(1, 'License', 1, 'update', 
 '{"status": "pending", "approved_by": null}',
 '{"status": "active", "approved_by": 1}',
 '["status", "approved_by"]',
 'License approval after successful compliance inspection',
 '192.168.1.100', '2023-01-15 10:30:00', 'auto_approved', NULL),

(2, 'Inspection', 1, 'create', 
 '{}',
 '{"inspector_id": 1, "facility_id": 1, "inspection_date": "2026-03-20", "inspection_type": "routine", "status": "completed"}',
 '["inspector_id", "facility_id", "inspection_date", "inspection_type", "status"]',
 'New routine inspection record created',
 '192.168.1.105', '2026-03-22 14:30:00', 'auto_approved', NULL);

-- ============================================================================
-- SAMPLE DATA: LICENSE_RENEWALS
-- ============================================================================

INSERT INTO license_renewals (license_id, facility_id, renewal_request_date, previous_expiry, new_expiry, 
                             status, renewal_fee, notes, created_at, updated_at) VALUES

(1, 1, NOW(), '2027-01-14', '2031-01-13', 'pending', 300000, 
 'Awaiting compliance inspection before approval', NOW(), NOW());

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT 'Sample data loaded successfully!' AS status;

-- Verify data
SELECT 'Users' AS table_name, COUNT(*) AS count FROM users
UNION ALL
SELECT 'Facilities', COUNT(*) FROM facilities
UNION ALL
SELECT 'Licenses', COUNT(*) FROM licenses
UNION ALL
SELECT 'Equipment', COUNT(*) FROM equipment
UNION ALL
SELECT 'Inspectors', COUNT(*) FROM inspectors
UNION ALL
SELECT 'Inspections', COUNT(*) FROM inspections
UNION ALL
SELECT 'Audit Logs', COUNT(*) FROM audit_logs
UNION ALL
SELECT 'License Renewals', COUNT(*) FROM license_renewals
UNION ALL
SELECT 'Equipment Inspections', COUNT(*) FROM equipment_inspections;
