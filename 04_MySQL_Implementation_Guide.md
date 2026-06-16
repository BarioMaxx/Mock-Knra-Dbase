# KNRA Database - MySQL Implementation Guide

**Database System**: MySQL 8.0+  
**Database Name**: knra_licensing_db  
**Date**: June 2026  
**Status**: Production-Ready

---

## 📋 Quick Start

### Option 1: Local MySQL Installation

#### Step 1: Install MySQL
```bash
# Windows - Download from MySQL website or use Chocolatey
choco install mysql

# macOS with Homebrew
brew install mysql

# Linux (Ubuntu/Debian)
sudo apt-get install mysql-server
```

#### Step 2: Start MySQL Service
```bash
# Windows
net start MySQL80  # or your version

# macOS
brew services start mysql

# Linux
sudo systemctl start mysql
```

#### Step 3: Create Database and Load Schema
```bash
# Connect to MySQL
mysql -u root -p

# Create database (from MySQL prompt)
mysql> SOURCE 01_MySQL_Schema_Creation.sql;
mysql> SOURCE 02_MySQL_Sample_Data.sql;

# Verify installation
mysql> USE knra_licensing_db;
mysql> SHOW TABLES;
```

### Option 2: Cloud MySQL (AWS RDS, Google Cloud SQL, Azure Database)

1. Create MySQL instance in your cloud provider
2. Get connection details (host, port, username, password)
3. Connect using:
```bash
mysql -h hostname -u username -p database_name < 01_MySQL_Schema_Creation.sql
mysql -h hostname -u username -p database_name < 02_MySQL_Sample_Data.sql
```

---

## 🏗️ Database Architecture

### Tables (12 Total)

| Table | Purpose | Rows (Sample) |
|-------|---------|---|
| **users** | System authentication | 4 |
| **facilities** | Licensed hospitals | 3 |
| **licenses** | Operating licenses | 2 |
| **equipment** | Radiation devices | 3 |
| **inspectors** | Regulatory staff | 2 |
| **inspections** | Compliance records | 2 |
| **inspection_violations** | Violation details | 1 |
| **equipment_inspections** | Equipment-level checks | 2 |
| **audit_logs** | Change tracking | 2 |
| **license_renewals** | Renewal requests | 1 |
| **inspector_facilities** | Inspector assignments | 4 |
| **inspection_equipment** | Equipment in inspections | 3 |

### Key Features

✅ **Referential Integrity**: Foreign keys enforce relationships  
✅ **Indexes**: Optimized for performance on common queries  
✅ **Views**: Pre-built views for common reports  
✅ **Stored Procedures**: Ready-to-use database procedures  
✅ **Audit Trail**: Complete change tracking with user accountability  
✅ **JSON Columns**: Flexible storage for complex data

---

## 🔑 Key Relationships

```
User
├── Assigns Facility (users.assigned_facility_id)
├── Creates Inspections (inspections.inspector_id)
└── Logs Changes (audit_logs.user_id)

Facility
├── Has License (licenses.facility_id)
├── Has Equipment (equipment.facility_id)
├── Has Inspectors (inspector_facilities)
├── Has Inspections (inspections.facility_id)
└── Renewal Requests (license_renewals.facility_id)

License
├── For Facility (licenses.facility_id)
└── Renewal Tracking (license_renewals.license_id)

Equipment
├── At Facility (equipment.facility_id)
└── Equipment Inspections (equipment_inspections.equipment_id)

Inspector
├── Assigned Facilities (inspector_facilities)
└── Conducts Inspections (inspections.inspector_id)

Inspection
├── At Facility (inspections.facility_id)
├── By Inspector (inspections.inspector_id)
├── Equipment Inspected (inspection_equipment)
├── Violations (inspection_violations)
└── Equipment Details (equipment_inspections)
```

---

## 🚀 Common Operations

### Query Active Facilities
```sql
SELECT id, hospital_name, location, facility_class, status
FROM facilities
WHERE status = 'active';
```

### Check Expiring Licenses (90 days)
```sql
SELECT l.license_number, f.hospital_name, l.expiry_date,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
AND l.status = 'active'
ORDER BY l.expiry_date ASC;
```

### Find Equipment Overdue for Calibration
```sql
SELECT e.equipment_name, e.serial_number, f.hospital_name,
       e.next_calibration_due,
       DATEDIFF(CURDATE(), e.next_calibration_due) AS days_overdue
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due < CURDATE()
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;
```

### Generate Compliance Report
```sql
SELECT f.hospital_name, COUNT(DISTINCT i.id) AS total_inspections,
       SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant,
       SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant
FROM facilities f
LEFT JOIN inspections i ON f.id = i.facility_id
GROUP BY f.id, f.hospital_name;
```

---

## 📊 Views Available

### 1. vw_active_licenses
```sql
SELECT * FROM vw_active_licenses;
```
Shows all active licenses with days until expiry.

### 2. vw_overdue_calibrations
```sql
SELECT * FROM vw_overdue_calibrations;
```
Shows equipment needing calibration with days overdue.

### 3. vw_facility_compliance_summary
```sql
SELECT * FROM vw_facility_compliance_summary;
```
Comprehensive compliance metrics by facility.

---

## 🔧 Stored Procedures

### Update Expired Licenses
```sql
CALL sp_update_expired_licenses();
```

### Get Equipment Calibration Due (Next 30 days)
```sql
CALL sp_get_equipment_calibration_due(30);
```

### Get Inspection Statistics
```sql
CALL sp_get_inspection_statistics('2026-01-01', '2026-06-30');
```

---

## 🐍 Python Integration Example

### Installation
```bash
pip install mysql-connector-python
```

### Connection Example
```python
import mysql.connector
from datetime import datetime, timedelta

# Connect to database
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='your_password',
    database='knra_licensing_db'
)

cursor = conn.cursor()

# Example 1: Get expiring licenses
query = """
SELECT l.license_number, f.hospital_name, l.expiry_date,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.status = 'active'
ORDER BY l.expiry_date ASC
"""

cursor.execute(query)
results = cursor.fetchall()

for row in results:
    print(f"License: {row[0]}, Hospital: {row[1]}, Expires: {row[2]}, Days: {row[3]}")

cursor.close()
conn.close()
```

---

## 🔐 Security Setup

### Create Database Users

```sql
-- Create admin user
CREATE USER 'knra_admin'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON knra_licensing_db.* TO 'knra_admin'@'localhost';

-- Create read-only user (for reporting)
CREATE USER 'knra_reader'@'localhost' IDENTIFIED BY 'read_password';
GRANT SELECT ON knra_licensing_db.* TO 'knra_reader'@'localhost';

-- Create inspector user (limited access)
CREATE USER 'inspector_user'@'localhost' IDENTIFIED BY 'inspector_password';
GRANT SELECT, INSERT, UPDATE ON knra_licensing_db.inspections TO 'inspector_user'@'localhost';
GRANT SELECT ON knra_licensing_db.facilities TO 'inspector_user'@'localhost';
GRANT SELECT ON knra_licensing_db.equipment TO 'inspector_user'@'localhost';

FLUSH PRIVILEGES;
```

---

## 📊 Data Import/Export

### Backup Database
```bash
# Full backup
mysqldump -u root -p knra_licensing_db > knra_backup_2026-06-15.sql

# Specific table
mysqldump -u root -p knra_licensing_db licenses > licenses_backup.sql
```

### Restore Database
```bash
# Full restore
mysql -u root -p knra_licensing_db < knra_backup_2026-06-15.sql

# Specific table
mysql -u root -p knra_licensing_db < licenses_backup.sql
```

### Export to CSV
```sql
SELECT * FROM facilities
INTO OUTFILE '/path/to/facilities.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

---

## 🎯 API Integration (Node.js/Express Example)

### Installation
```bash
npm install express mysql2 cors dotenv
```

### Code Example
```javascript
const express = require('express');
const mysql = require('mysql2/promise');
const app = express();

// Connection pool
const pool = mysql.createPool({
    host: 'localhost',
    user: 'knra_admin',
    password: 'your_password',
    database: 'knra_licensing_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Get all active facilities
app.get('/api/facilities', async (req, res) => {
    try {
        const conn = await pool.getConnection();
        const [rows] = await conn.query(
            'SELECT * FROM facilities WHERE status = "active"'
        );
        conn.release();
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get licenses expiring soon
app.get('/api/licenses/expiring', async (req, res) => {
    try {
        const conn = await pool.getConnection();
        const [rows] = await conn.query(`
            SELECT l.license_number, f.hospital_name, l.expiry_date,
                   DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
            FROM licenses l
            JOIN facilities f ON l.facility_id = f.id
            WHERE l.status = 'active'
            ORDER BY l.expiry_date ASC
        `);
        conn.release();
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(3000, () => {
    console.log('API running on port 3000');
});
```

---

## 🔍 Monitoring & Maintenance

### Check Database Size
```sql
SELECT 
    table_schema,
    SUM(data_length + index_length) / 1024 / 1024 AS size_mb
FROM information_schema.tables
WHERE table_schema = 'knra_licensing_db'
GROUP BY table_schema;
```

### Check Table Sizes
```sql
SELECT 
    table_name,
    (data_length + index_length) / 1024 / 1024 AS size_mb
FROM information_schema.tables
WHERE table_schema = 'knra_licensing_db'
ORDER BY size_mb DESC;
```

### Optimize Tables
```sql
OPTIMIZE TABLE facilities;
OPTIMIZE TABLE licenses;
OPTIMIZE TABLE equipment;
OPTIMIZE TABLE inspections;
```

### Check for Slow Queries
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- View slow queries
SELECT * FROM mysql.slow_log;
```

---

## 📋 Maintenance Schedule

### Daily
```sql
-- Update expired licenses
CALL sp_update_expired_licenses();

-- Check overdue calibrations
CALL sp_get_equipment_calibration_due(30);
```

### Weekly
```sql
-- Backup database
mysqldump -u root -p knra_licensing_db > backup_$(date +%Y%m%d).sql

-- Optimize tables
OPTIMIZE TABLE licenses;
OPTIMIZE TABLE equipment;
```

### Monthly
```sql
-- Generate compliance report
SELECT * FROM vw_facility_compliance_summary;

-- Check database size
-- (see monitoring query above)
```

### Quarterly
```sql
-- Archive old inspections (before deletion)
CREATE TABLE inspections_archive AS
SELECT * FROM inspections
WHERE inspection_date < DATE_SUB(CURDATE(), INTERVAL 3 YEAR);

-- Rebuild indexes
ANALYZE TABLE facilities;
ANALYZE TABLE licenses;
ANALYZE TABLE equipment;
ANALYZE TABLE inspections;
```

---

## ✅ Troubleshooting

### Connection Refused
```bash
# Check MySQL service
sudo systemctl status mysql

# Restart MySQL
sudo systemctl restart mysql
```

### Permission Denied
```sql
-- Grant permissions
GRANT ALL PRIVILEGES ON knra_licensing_db.* TO 'user'@'hostname';
FLUSH PRIVILEGES;
```

### Slow Queries
```sql
-- Add missing index
CREATE INDEX idx_facility_status ON facilities(status);

-- Analyze query
EXPLAIN SELECT * FROM licenses WHERE status = 'active';
```

### Database Corruption
```sql
-- Check and repair table
CHECK TABLE licenses;
REPAIR TABLE licenses;
```

---

## 📞 Connection Strings

### Command Line
```bash
mysql -h localhost -u knra_admin -p knra_licensing_db
```

### Python
```python
import mysql.connector
conn = mysql.connector.connect(
    host='localhost',
    user='knra_admin',
    password='password',
    database='knra_licensing_db'
)
```

### Node.js
```javascript
const mysql = require('mysql2/promise');
const pool = mysql.createPool({
    host: 'localhost',
    user: 'knra_admin',
    password: 'password',
    database: 'knra_licensing_db'
});
```

### PHP (PDO)
```php
$pdo = new PDO('mysql:host=localhost;dbname=knra_licensing_db', 
               'knra_admin', 'password');
```

---

## 🎓 Files Included

1. **01_MySQL_Schema_Creation.sql** - DDL scripts with 12 tables, views, procedures
2. **02_MySQL_Sample_Data.sql** - 25+ sample records for testing
3. **03_MySQL_Queries_Reporting.sql** - 40+ query examples and reports
4. **04_MySQL_Implementation_Guide.md** - This file

---

## 🚀 Next Steps

1. ✅ Install MySQL 8.0+
2. ✅ Load schema (01_MySQL_Schema_Creation.sql)
3. ✅ Load sample data (02_MySQL_Sample_Data.sql)
4. ✅ Test queries (03_MySQL_Queries_Reporting.sql)
5. ✅ Create API endpoints
6. ✅ Set up backups
7. ✅ Configure monitoring
8. ✅ Deploy to production

---

**Last Updated**: June 15, 2026  
**Version**: 1.0  
**Status**: Production-Ready

Good luck with your KNRA database implementation! 🇰🇪
