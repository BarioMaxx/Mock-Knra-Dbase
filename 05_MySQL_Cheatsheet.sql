-- KNRA Database - MySQL Quick Reference & Cheatsheet
-- Date: June 2026

-- ============================================================================
-- CONNECTION
-- ============================================================================

-- Connect to database
mysql -h localhost -u root -p knra_licensing_db

-- Select database
USE knra_licensing_db;

-- ============================================================================
-- DATABASE INFORMATION
-- ============================================================================

-- Show all databases
SHOW DATABASES;

-- Show all tables
SHOW TABLES;

-- Show table structure
DESCRIBE facilities;
-- or
SHOW COLUMNS FROM facilities;

-- Show table creation statement
SHOW CREATE TABLE facilities;

-- ============================================================================
-- BASIC CRUD OPERATIONS
-- ============================================================================

-- CREATE (INSERT)
INSERT INTO facilities (hospital_name, location, facility_class, status)
VALUES ('New Hospital', 'Nairobi', 'Class II', 'active');

-- INSERT multiple rows
INSERT INTO equipment (facility_id, equipment_name, serial_number, status)
VALUES 
  (1, 'Equipment 1', 'SN-001', 'operational'),
  (1, 'Equipment 2', 'SN-002', 'operational');

-- READ (SELECT)
SELECT * FROM facilities;
SELECT hospital_name, location FROM facilities WHERE status = 'active';

-- SELECT with WHERE and ORDER BY
SELECT * FROM licenses
WHERE status = 'active'
ORDER BY expiry_date ASC;

-- SELECT with LIMIT
SELECT * FROM inspections LIMIT 10;
SELECT * FROM inspections LIMIT 10 OFFSET 20;  -- pagination

-- UPDATE
UPDATE licenses
SET status = 'expired'
WHERE expiry_date < CURDATE();

-- DELETE (use with caution!)
DELETE FROM inspections WHERE id = 123;

-- ============================================================================
-- COMMON FILTERS & OPERATORS
-- ============================================================================

-- Equal
WHERE status = 'active'

-- Not equal
WHERE status != 'expired'

-- Greater than
WHERE expiry_date > CURDATE()

-- Less than
WHERE fee_amount < 300000

-- Greater than or equal
WHERE expiry_date >= CURDATE()

-- Less than or equal
WHERE days_overdue <= 30

-- IN (match any value)
WHERE status IN ('active', 'pending')

-- NOT IN
WHERE status NOT IN ('expired', 'revoked')

-- BETWEEN
WHERE expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)

-- LIKE (pattern matching)
WHERE hospital_name LIKE '%Hospital%'
WHERE hospital_name LIKE 'K%'  -- starts with K
WHERE hospital_name LIKE '%National%'  -- contains National

-- IS NULL
WHERE last_login IS NULL

-- IS NOT NULL
WHERE last_login IS NOT NULL

-- ============================================================================
-- JOINS
-- ============================================================================

-- INNER JOIN
SELECT l.license_number, f.hospital_name
FROM licenses l
INNER JOIN facilities f ON l.facility_id = f.id;

-- LEFT JOIN (include unmatched left table rows)
SELECT f.hospital_name, l.license_number
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id;

-- Multiple JOINs
SELECT f.hospital_name, l.license_number, e.equipment_name
FROM facilities f
JOIN licenses l ON f.id = l.facility_id
JOIN equipment e ON f.id = e.facility_id;

-- ============================================================================
-- AGGREGATION & GROUPING
-- ============================================================================

-- COUNT
SELECT COUNT(*) FROM facilities;
SELECT COUNT(*) FROM licenses WHERE status = 'active';

-- SUM
SELECT SUM(fee_amount) FROM licenses WHERE status = 'active';

-- AVG
SELECT AVG(radiation_level) FROM equipment;

-- MIN, MAX
SELECT MIN(expiry_date) FROM licenses;
SELECT MAX(inspection_date) FROM inspections;

-- GROUP BY
SELECT equipment_type, COUNT(*) AS count
FROM equipment
GROUP BY equipment_type;

-- GROUP BY with HAVING
SELECT facility_id, COUNT(*) AS inspection_count
FROM inspections
GROUP BY facility_id
HAVING inspection_count > 2;

-- ============================================================================
-- DATE FUNCTIONS
-- ============================================================================

-- Current date
SELECT CURDATE();

-- Current timestamp
SELECT NOW();
SELECT CURRENT_TIMESTAMP;

-- Date arithmetic
SELECT DATE_ADD(CURDATE(), INTERVAL 90 DAY);  -- 90 days from now
SELECT DATE_SUB(CURDATE(), INTERVAL 30 DAY);  -- 30 days ago
SELECT DATE_ADD(CURDATE(), INTERVAL 1 MONTH);  -- 1 month from now
SELECT DATE_SUB(CURDATE(), INTERVAL 1 YEAR);  -- 1 year ago

-- Days between dates
SELECT DATEDIFF(expiry_date, CURDATE()) AS days_until_expiry
FROM licenses;

-- Extract components
SELECT YEAR(inspection_date), MONTH(inspection_date), DAY(inspection_date)
FROM inspections;

-- ============================================================================
-- COMMON QUERY PATTERNS
-- ============================================================================

-- Licenses expiring soon (90 days)
SELECT l.license_number, f.hospital_name, l.expiry_date,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
AND l.status = 'active'
ORDER BY l.expiry_date ASC;

-- Equipment overdue for calibration
SELECT e.equipment_name, e.serial_number, f.hospital_name,
       DATEDIFF(CURDATE(), e.next_calibration_due) AS days_overdue
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due < CURDATE()
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;

-- Compliance summary by facility
SELECT f.hospital_name,
       COUNT(DISTINCT i.id) AS total_inspections,
       SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant,
       SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant
FROM facilities f
LEFT JOIN inspections i ON f.id = i.facility_id
GROUP BY f.id, f.hospital_name;

-- Inspections with violations
SELECT i.id, f.hospital_name, i.inspection_date,
       COUNT(iv.id) AS violation_count
FROM inspections i
LEFT JOIN inspection_violations iv ON i.id = iv.inspection_id
LEFT JOIN facilities f ON i.facility_id = f.id
GROUP BY i.id, f.hospital_name, i.inspection_date
HAVING violation_count > 0
ORDER BY i.inspection_date DESC;

-- Active facilities with licenses
SELECT DISTINCT f.id, f.hospital_name, f.facility_class, l.license_number, l.status
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id
WHERE f.status = 'active'
ORDER BY f.hospital_name;

-- ============================================================================
-- CONDITIONAL LOGIC (CASE)
-- ============================================================================

-- CASE statement
SELECT hospital_name,
       CASE 
           WHEN facility_class = 'Class I' THEN 'High Risk'
           WHEN facility_class = 'Class II' THEN 'Medium Risk'
           WHEN facility_class = 'Class III' THEN 'Low Risk'
           ELSE 'Unknown'
       END AS risk_level
FROM facilities;

-- CASE with conditions
SELECT license_number,
       CASE 
           WHEN DATEDIFF(expiry_date, CURDATE()) <= 30 THEN 'Urgent'
           WHEN DATEDIFF(expiry_date, CURDATE()) <= 60 THEN 'Soon'
           WHEN DATEDIFF(expiry_date, CURDATE()) <= 90 THEN 'Pending'
           ELSE 'Active'
       END AS expiry_status
FROM licenses;

-- ============================================================================
-- VIEWS (Saved Queries)
-- ============================================================================

-- Create a view
CREATE VIEW vw_expiring_licenses AS
SELECT l.license_number, f.hospital_name, l.expiry_date,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.status = 'active';

-- Use the view
SELECT * FROM vw_expiring_licenses
WHERE days_until_expiry < 90
ORDER BY days_until_expiry ASC;

-- Drop view
DROP VIEW vw_expiring_licenses;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Create single-column index
CREATE INDEX idx_status ON licenses(status);

-- Create composite index
CREATE INDEX idx_facility_status ON facilities(facility_class, status);

-- Create unique index
CREATE UNIQUE INDEX idx_license_number ON licenses(license_number);

-- List indexes
SHOW INDEXES FROM licenses;

-- Drop index
DROP INDEX idx_status ON licenses;

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Call stored procedure
CALL sp_update_expired_licenses();

-- Call procedure with parameters
CALL sp_get_equipment_calibration_due(30);

-- View procedure definition
SHOW CREATE PROCEDURE sp_update_expired_licenses;

-- ============================================================================
-- TRANSACTIONS
-- ============================================================================

-- Start transaction
START TRANSACTION;

-- Multiple operations
INSERT INTO licenses (...) VALUES (...);
UPDATE facilities SET status = 'active' WHERE id = 1;

-- Commit (save changes)
COMMIT;

-- Rollback (undo changes)
ROLLBACK;

-- ============================================================================
-- BACKUP & RESTORE
-- ============================================================================

-- Backup entire database
mysqldump -u root -p knra_licensing_db > backup.sql

-- Backup specific table
mysqldump -u root -p knra_licensing_db licenses > licenses_backup.sql

-- Restore database
mysql -u root -p knra_licensing_db < backup.sql

-- ============================================================================
-- STATISTICS & ANALYSIS
-- ============================================================================

-- Count records
SELECT COUNT(*) FROM facilities;
SELECT COUNT(*) FROM licenses WHERE status = 'active';

-- Count distinct values
SELECT COUNT(DISTINCT facility_id) FROM equipment;

-- Table sizes
SELECT 
    table_name,
    (data_length + index_length) / 1024 / 1024 AS size_mb
FROM information_schema.tables
WHERE table_schema = 'knra_licensing_db'
ORDER BY size_mb DESC;

-- Query execution plan
EXPLAIN SELECT * FROM licenses WHERE status = 'active';

-- ============================================================================
-- PERMISSIONS & USERS
-- ============================================================================

-- Create user
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';

-- Grant permissions
GRANT SELECT ON knra_licensing_db.* TO 'username'@'localhost';
GRANT INSERT, UPDATE ON knra_licensing_db.licenses TO 'username'@'localhost';
GRANT ALL PRIVILEGES ON knra_licensing_db.* TO 'admin'@'localhost';

-- Revoke permissions
REVOKE DELETE ON knra_licensing_db.* FROM 'username'@'localhost';

-- Refresh permissions
FLUSH PRIVILEGES;

-- ============================================================================
-- MIGRATION FROM MONGODB
-- ============================================================================

-- Key differences:
-- MongoDB                          MySQL
-- ================================ ================================
-- _id: ObjectId                    id: BIGINT AUTO_INCREMENT PRIMARY KEY
-- Collections                      Tables
-- Documents                        Rows
-- Fields                           Columns
-- Arrays (JSON)                    JSON columns or separate tables
-- Embedded documents              Foreign keys + JOINs
-- db.collection.find()            SELECT
-- db.collection.insertOne()       INSERT
-- db.collection.updateOne()       UPDATE
-- db.collection.deleteOne()       DELETE
-- Aggregation pipeline            SELECT with JOINs

-- ============================================================================
-- HELPFUL TIPS
-- ============================================================================

-- Escape special characters
SELECT * FROM facilities WHERE hospital_name LIKE '%O\\'Neal%';

-- Use backticks for reserved words
SELECT `order` FROM table;

-- Comment in SQL
-- This is a comment
/* This is also a comment */

-- Show query results in different formats
SELECT * FROM facilities\G  -- vertical format

-- Change delimiter for procedures
DELIMITER //
CREATE PROCEDURE ...
END//
DELIMITER ;

-- ============================================================================
-- PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Use indexes on frequently filtered columns
CREATE INDEX idx_expiry_date ON licenses(expiry_date);

-- Avoid SELECT *
SELECT hospital_name, location FROM facilities;  -- Better

-- Use LIMIT
SELECT * FROM inspections LIMIT 100;  -- Better than SELECT ALL

-- Use EXISTS for checking
SELECT * FROM facilities f
WHERE EXISTS (SELECT 1 FROM licenses l WHERE l.facility_id = f.id);

-- ============================================================================
-- QUICK EXAMPLES
-- ============================================================================

-- Example 1: Get all active facilities with license info
SELECT f.*, l.license_number, l.status, l.expiry_date
FROM facilities f
LEFT JOIN licenses l ON f.id = l.facility_id
WHERE f.status = 'active';

-- Example 2: Find critical violations
SELECT f.hospital_name, iv.violation_code, iv.description, iv.deadline
FROM inspection_violations iv
JOIN inspections i ON iv.inspection_id = i.id
JOIN facilities f ON i.facility_id = f.id
WHERE iv.severity = 'critical'
ORDER BY iv.deadline ASC;

-- Example 3: Inspector workload
SELECT ins.first_name, ins.last_name, COUNT(*) AS inspection_count
FROM inspectors ins
LEFT JOIN inspections i ON ins.id = i.inspector_id
GROUP BY ins.id
ORDER BY inspection_count DESC;

-- Example 4: Equipment status by facility
SELECT f.hospital_name, e.equipment_type, COUNT(*) AS count, e.status
FROM facilities f
JOIN equipment e ON f.id = e.facility_id
GROUP BY f.hospital_name, e.equipment_type, e.status;

-- Example 5: Compliance trend
SELECT YEAR(inspection_date) AS year, MONTH(inspection_date) AS month,
       SUM(CASE WHEN compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant
FROM inspections
GROUP BY YEAR(inspection_date), MONTH(inspection_date)
ORDER BY year DESC, month DESC;

-- ============================================================================
-- END OF CHEATSHEET
-- ============================================================================
