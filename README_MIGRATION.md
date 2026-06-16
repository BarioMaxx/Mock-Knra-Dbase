# KNRA Database - MongoDB to MySQL Migration

**Status**: ✅ Complete Migration  
**Original Database**: MongoDB (Not available due to billing)  
**New Database**: MySQL 8.0+  
**Date**: June 2026

---

## 📋 What Changed?

### Why MySQL?

✅ **No Cloud Billing Issues** - Run locally or on your own server  
✅ **Open Source & Free** - No subscription required  
✅ **Relational Structure** - Better for regulatory compliance with enforced relationships  
✅ **ACID Compliance** - Guaranteed data integrity  
✅ **Wide Support** - Compatible with all frameworks and programming languages  
✅ **Easy Deployment** - Works on Windows, macOS, Linux

---

## 📂 New Files Created for MySQL

| File | Purpose |
|------|---------|
| **01_MySQL_Schema_Creation.sql** | Complete database schema with 12 tables |
| **02_MySQL_Sample_Data.sql** | Test data for development |
| **03_MySQL_Queries_Reporting.sql** | 40+ query examples and reports |
| **04_MySQL_Implementation_Guide.md** | Detailed setup & integration guide |
| **05_MySQL_Cheatsheet.sql** | Quick reference for common operations |
| **README_MIGRATION.md** | This file |

---

## 🔄 Data Structure Mapping

### MongoDB → MySQL

| Aspect | MongoDB | MySQL |
|--------|---------|-------|
| Database | Database | Database |
| Collections | Tables | Tables |
| Documents | Rows | Rows |
| Fields | Columns | Columns |
| _id | ObjectId (automatic) | BIGINT AUTO_INCREMENT |
| Arrays | JSON arrays | JSON columns or junction tables |
| Relationships | Document references | Foreign keys + JOINs |
| Transactions | Limited | Full ACID compliance |
| Validation | JSON schema | Column types + constraints |

### Collections → Tables

```
MongoDB                          MySQL
================================ ================================
users                            users (11 cols)
facilities                       facilities (16 cols)
licenses                         licenses (17 cols)
equipment                        equipment (14 cols)
inspectors                       inspectors (11 cols)
inspections                      inspections (12 cols)
+ violations                     inspection_violations (6 cols)
+ equipment_inspected            inspection_equipment (2 cols)
audit_logs                       audit_logs (13 cols)
license_renewals                 license_renewals (12 cols)
equipment_inspections            equipment_inspections (14 cols)
(inspector assignments)          inspector_facilities (2 cols)
```

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Install MySQL
```bash
# Windows - Download from mysql.com or use chocolatey
choco install mysql

# macOS with Homebrew
brew install mysql

# Linux (Ubuntu/Debian)
sudo apt-get install mysql-server
```

### Step 2: Start MySQL
```bash
# Windows
net start MySQL80

# macOS
brew services start mysql

# Linux
sudo systemctl start mysql
```

### Step 3: Load Schema
```bash
# Open terminal/command prompt in Mock Dbase folder
mysql -u root -p < 01_MySQL_Schema_Creation.sql
mysql -u root -p < 02_MySQL_Sample_Data.sql
```

### Step 4: Verify
```bash
mysql -u root -p knra_licensing_db
mysql> SHOW TABLES;
```

Expected output:
```
+--------------------------------+
| Tables_in_knra_licensing_db    |
+--------------------------------+
| audit_logs                     |
| equipment                      |
| equipment_inspections          |
| facilities                     |
| inspection_equipment           |
| inspection_violations          |
| inspections                    |
| inspector_facilities           |
| inspectors                     |
| license_renewals               |
| licenses                        |
| users                          |
+--------------------------------+
12 rows in set
```

---

## 📊 Database Overview

### 12 Tables

1. **users** - System authentication (4 sample records)
2. **facilities** - Licensed hospitals (3 sample)
3. **licenses** - Operating licenses (2 sample)
4. **equipment** - Radiation devices (3 sample)
5. **inspectors** - Regulatory staff (2 sample)
6. **inspections** - Compliance records (2 sample)
7. **inspection_violations** - Violation details (1 sample)
8. **equipment_inspections** - Equipment-level checks (2 sample)
9. **audit_logs** - Change tracking (2 sample)
10. **license_renewals** - Renewal requests (1 sample)
11. **inspector_facilities** - Staff assignments (4 records)
12. **inspection_equipment** - Equipment in inspections (3 records)

### 3 Views (Pre-built Queries)

```sql
-- View expiring licenses
SELECT * FROM vw_active_licenses;

-- View equipment needing calibration
SELECT * FROM vw_overdue_calibrations;

-- View compliance summary
SELECT * FROM vw_facility_compliance_summary;
```

### 3 Stored Procedures

```sql
-- Update expired license status
CALL sp_update_expired_licenses();

-- Get equipment calibration due
CALL sp_get_equipment_calibration_due(30);

-- Get inspection statistics
CALL sp_get_inspection_statistics('2026-01-01', '2026-06-30');
```

---

## 🔑 Key Features in MySQL Version

### ✅ Data Integrity
- Foreign keys enforce relationships
- Unique constraints (license_number, serial_number, email)
- NOT NULL constraints on required fields
- CHECK constraints for valid values

### ✅ Performance
- Indexed on 30+ frequently queried fields
- Composite indexes for common JOIN patterns
- Partitioning-ready for large datasets

### ✅ Security
- User role support (admin, inspector, manager)
- Audit trail with user accountability
- IP logging for compliance
- Permission management

### ✅ Reporting
- 3 pre-built views for common reports
- 40+ query examples included
- Dashboard queries ready to use
- Export to CSV functionality

---

## 📖 Usage Examples

### Find Expiring Licenses
```sql
SELECT l.license_number, f.hospital_name, l.expiry_date,
       DATEDIFF(l.expiry_date, CURDATE()) AS days_until_expiry
FROM licenses l
JOIN facilities f ON l.facility_id = f.id
WHERE l.status = 'active'
ORDER BY l.expiry_date ASC;
```

### Get Equipment Overdue for Calibration
```sql
SELECT e.equipment_name, e.serial_number, f.hospital_name,
       DATEDIFF(CURDATE(), e.next_calibration_due) AS days_overdue
FROM equipment e
JOIN facilities f ON e.facility_id = f.id
WHERE e.next_calibration_due < CURDATE()
AND e.status = 'operational'
ORDER BY e.next_calibration_due ASC;
```

### Generate Compliance Report
```sql
SELECT f.hospital_name,
       COUNT(DISTINCT i.id) AS total_inspections,
       SUM(CASE WHEN i.compliance_rating = 'Compliant' THEN 1 ELSE 0 END) AS compliant,
       SUM(CASE WHEN i.compliance_rating = 'Non-compliant' THEN 1 ELSE 0 END) AS non_compliant
FROM facilities f
LEFT JOIN inspections i ON f.id = i.facility_id
GROUP BY f.id, f.hospital_name;
```

### Find Critical Violations
```sql
SELECT f.hospital_name, iv.violation_code, iv.description, iv.deadline
FROM inspection_violations iv
JOIN inspections i ON iv.inspection_id = i.id
JOIN facilities f ON i.facility_id = f.id
WHERE iv.severity = 'critical'
ORDER BY iv.deadline ASC;
```

More examples in **03_MySQL_Queries_Reporting.sql**

---

## 💻 Integration with Applications

### Node.js (Express)
```bash
npm install express mysql2 cors dotenv
```

```javascript
const mysql = require('mysql2/promise');
const pool = mysql.createPool({
    host: 'localhost',
    user: 'knra_admin',
    password: 'password',
    database: 'knra_licensing_db'
});

app.get('/api/licenses/expiring', async (req, res) => {
    const conn = await pool.getConnection();
    const [rows] = await conn.query(
        `SELECT l.license_number, f.hospital_name, l.expiry_date
         FROM licenses l
         JOIN facilities f ON l.facility_id = f.id
         WHERE l.status = 'active'
         ORDER BY l.expiry_date ASC`
    );
    res.json(rows);
});
```

### Python
```bash
pip install mysql-connector-python
```

```python
import mysql.connector

conn = mysql.connector.connect(
    host='localhost',
    user='knra_admin',
    password='password',
    database='knra_licensing_db'
)

cursor = conn.cursor()
cursor.execute("""
    SELECT license_number, hospital_name, expiry_date
    FROM licenses l
    JOIN facilities f ON l.facility_id = f.id
    WHERE status = 'active'
""")

for row in cursor.fetchall():
    print(row)
```

### PHP (PDO)
```php
$pdo = new PDO(
    'mysql:host=localhost;dbname=knra_licensing_db',
    'knra_admin',
    'password'
);

$stmt = $pdo->query(
    'SELECT * FROM facilities WHERE status = "active"'
);

foreach ($stmt as $row) {
    echo $row['hospital_name'];
}
```

---

## 🔐 Security Setup

### Create User Accounts
```sql
-- Admin user (full access)
CREATE USER 'knra_admin'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON knra_licensing_db.* TO 'knra_admin'@'localhost';

-- Read-only user (for reports)
CREATE USER 'knra_reader'@'localhost' IDENTIFIED BY 'read_password';
GRANT SELECT ON knra_licensing_db.* TO 'knra_reader'@'localhost';

-- Inspector user (limited)
CREATE USER 'inspector'@'localhost' IDENTIFIED BY 'inspector_password';
GRANT SELECT, INSERT, UPDATE ON knra_licensing_db.inspections TO 'inspector'@'localhost';
GRANT SELECT ON knra_licensing_db.facilities TO 'inspector'@'localhost';

FLUSH PRIVILEGES;
```

---

## 📊 Backup & Recovery

### Create Backup
```bash
mysqldump -u root -p knra_licensing_db > backup_2026-06-15.sql
```

### Restore Backup
```bash
mysql -u root -p knra_licensing_db < backup_2026-06-15.sql
```

### Automated Backups (Linux)
```bash
# Add to crontab for daily backups at 2 AM
0 2 * * * mysqldump -u root -p knra_licensing_db > /backups/knra_$(date +\%Y\%m\%d).sql
```

---

## 🔍 Monitoring

### Check Database Size
```sql
SELECT 
    SUM(data_length + index_length) / 1024 / 1024 AS size_mb
FROM information_schema.tables
WHERE table_schema = 'knra_licensing_db';
```

### Check Specific Tables
```sql
SELECT table_name, (data_length + index_length) / 1024 / 1024 AS size_mb
FROM information_schema.tables
WHERE table_schema = 'knra_licensing_db'
ORDER BY size_mb DESC;
```

### Find Slow Queries
```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
SELECT * FROM mysql.slow_log;
```

---

## 📋 Migration Checklist

- [ ] Install MySQL 8.0+
- [ ] Start MySQL service
- [ ] Load schema (01_MySQL_Schema_Creation.sql)
- [ ] Load sample data (02_MySQL_Sample_Data.sql)
- [ ] Verify all 12 tables created
- [ ] Test 3 sample queries
- [ ] Create user accounts
- [ ] Set up automated backups
- [ ] Test API integration
- [ ] Load production data
- [ ] Update connection strings in applications
- [ ] Deploy to production
- [ ] Monitor first 48 hours

---

## ❌ Common Issues & Solutions

### Issue: "Access denied for user 'root'@'localhost'"
```bash
# Reset MySQL root password
mysql -u root
mysql> FLUSH PRIVILEGES;
mysql> SET PASSWORD FOR 'root'@'localhost' = PASSWORD('new_password');
```

### Issue: "Can't connect to MySQL server"
```bash
# Check if MySQL is running
sudo systemctl status mysql

# Restart MySQL
sudo systemctl restart mysql
```

### Issue: "Table already exists"
```sql
-- Drop and recreate
DROP TABLE IF EXISTS facilities;
-- Then reload schema
```

### Issue: "Slow queries"
```sql
-- Add missing indexes
CREATE INDEX idx_facility_status ON facilities(status);
CREATE INDEX idx_license_expiry ON licenses(expiry_date);
```

---

## 📞 File Summary

| File | Lines | Purpose |
|------|-------|---------|
| 01_MySQL_Schema_Creation.sql | 300+ | Complete schema with validation |
| 02_MySQL_Sample_Data.sql | 150+ | Sample test data |
| 03_MySQL_Queries_Reporting.sql | 350+ | Query examples & reporting |
| 04_MySQL_Implementation_Guide.md | 400+ | Setup & integration guide |
| 05_MySQL_Cheatsheet.sql | 250+ | Quick reference |
| README_MIGRATION.md | 300+ | This file |

---

## ✅ What You Get

✅ Complete SQL schema with 12 tables  
✅ Foreign key relationships  
✅ 30+ indexes for performance  
✅ 3 pre-built views  
✅ 3 stored procedures  
✅ 40+ query examples  
✅ Sample test data  
✅ Security setup guide  
✅ API integration examples (Node.js, Python, PHP)  
✅ Backup/restore procedures  
✅ Performance monitoring queries  

---

## 🎯 Next Steps

1. **Install MySQL** (5 min)
2. **Load Schema** (2 min)
3. **Verify Installation** (2 min)
4. **Test Queries** (5 min)
5. **Create Users** (5 min)
6. **Set Up Backups** (5 min)
7. **Integrate with API** (varies)
8. **Deploy to Production** (varies)

---

## 📞 Support Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [SQL Tutorial](https://www.w3schools.com/sql/)
- [StackOverflow - MySQL Tag](https://stackoverflow.com/questions/tagged/mysql)

---

## 📝 Database Summary

**Organization**: Kenya Nuclear Regulatory Authority (KNRA)  
**Purpose**: Radioactive Equipment & Facility Licensing  
**Database**: MySQL 8.0+  
**Tables**: 12  
**Relationships**: Fully relational with foreign keys  
**Sample Data**: 25+ records included  
**Status**: ✅ Production-Ready

---

**Migration completed successfully!** 🎉

Your KNRA database is now ready to use with MySQL. All features from the MongoDB version are preserved with the added benefits of relational integrity and full compliance support.

**Good luck with your implementation!** 🇰🇪

---

**Last Updated**: June 15, 2026  
**Version**: 1.0 (MySQL)  
**Original Version**: MongoDB (unavailable due to billing)
