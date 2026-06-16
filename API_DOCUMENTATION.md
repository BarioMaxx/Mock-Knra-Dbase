# KNRA API Documentation
**Version**: 1.0  
**Date**: June 15, 2026  
**Base URL**: `http://localhost:5000`

---

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Health Check](#health-check)
4. [Facilities](#facilities)
5. [Licenses](#licenses)
6. [Equipment](#equipment)
7. [Inspections](#inspections)
8. [Inspectors](#inspectors)
9. [Reports](#reports)
10. [Error Handling](#error-handling)

---

## Overview

The KNRA Licensing API provides RESTful access to the radioactive equipment and facility licensing database. All responses are in JSON format.

**Base URL**: `http://localhost:5000`

**Response Format**:
```json
{
  "data": [...],           // Array or single object
  "error": "string",       // Error message (if applicable)
  "timestamp": "ISO8601"   // Request timestamp
}
```

---

## Authentication

**Current Version**: No authentication (development mode)

**Future Production**:
```
Authorization: Bearer <JWT_TOKEN>
```

All requests should include standard HTTP headers:
```
Content-Type: application/json
Accept: application/json
```

---

## Health Check

### GET /health

Check API and database status.

**Request**:
```bash
curl http://localhost:5000/health
```

**Response** (200 OK):
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-06-15T10:45:48.061559"
}
```

**Response** (500 Service Unavailable):
```json
{
  "status": "unhealthy",
  "database": "disconnected"
}
```

---

## Facilities

### GET /api/facilities

Retrieve all active facilities.

**Request**:
```bash
curl http://localhost:5000/api/facilities
```

**Parameters**: None

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "location": "Nairobi",
    "facility_class": "Class II",
    "status": "active",
    "authorized_equipment": "CT, X-Ray, Gamma",
    "created_at": "2026-01-15T10:30:00"
  },
  {
    "id": 2,
    "hospital_name": "Aga Khan University Hospital",
    "location": "Nairobi",
    "facility_class": "Class I",
    "status": "active",
    "authorized_equipment": "All",
    "created_at": "2026-02-01T14:22:30"
  }
]
```

---

### GET /api/facilities/{id}

Retrieve specific facility with related licenses and equipment.

**Request**:
```bash
curl http://localhost:5000/api/facilities/1
```

**Parameters**:
- `id` (path, required): Facility ID

**Response** (200 OK):
```json
{
  "facility": {
    "id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "location": "Nairobi",
    "facility_class": "Class II",
    "status": "active"
  },
  "licenses": [
    {
      "id": 1,
      "license_number": "KNRA-2023-000001",
      "issue_date": "2023-01-14",
      "expiry_date": "2027-01-14",
      "status": "active"
    }
  ],
  "equipment": [
    {
      "id": 1,
      "equipment_name": "GE Revolution EVO CT Scanner",
      "serial_number": "GE-CT-2021-0001",
      "equipment_type": "CT Scanner",
      "status": "operational"
    }
  ]
}
```

**Response** (404 Not Found):
```json
{
  "error": "Facility not found"
}
```

---

### POST /api/facilities

Create a new facility.

**Request**:
```bash
curl -X POST http://localhost:5000/api/facilities \
  -H "Content-Type: application/json" \
  -d '{
    "hospital_name": "New Medical Center",
    "location": "Kisumu",
    "facility_class": "Class III",
    "status": "active"
  }'
```

**Parameters** (JSON body):
- `hospital_name` (required): Facility name
- `location` (required): Geographic location
- `facility_class` (required): Class I, II, or III
- `status` (optional): active/inactive (default: active)

**Response** (201 Created):
```json
{
  "message": "Facility created successfully"
}
```

**Response** (500 Error):
```json
{
  "error": "Failed to create facility"
}
```

---

## Licenses

### GET /api/licenses

Get all licenses with facility and expiry information.

**Request**:
```bash
curl http://localhost:5000/api/licenses
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "license_number": "KNRA-2023-000001",
    "facility_id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "issue_date": "2023-01-14",
    "expiry_date": "2027-01-14",
    "status": "active",
    "days_until_expiry": 560
  },
  {
    "id": 2,
    "license_number": "KNRA-2024-000015",
    "facility_id": 2,
    "hospital_name": "Aga Khan University Hospital",
    "issue_date": "2024-01-31",
    "expiry_date": "2028-01-31",
    "status": "active",
    "days_until_expiry": 927
  }
]
```

---

### GET /api/licenses/{id}

Get specific license details.

**Request**:
```bash
curl http://localhost:5000/api/licenses/1
```

**Response** (200 OK):
```json
{
  "id": 1,
  "license_number": "KNRA-2023-000001",
  "facility_id": 1,
  "hospital_name": "Kenyatta National Hospital",
  "issue_date": "2023-01-14",
  "expiry_date": "2027-01-14",
  "status": "active",
  "fee_amount": 500000
}
```

---

### GET /api/licenses/expiring

Get licenses expiring within specified days (default: 90).

**Request**:
```bash
curl "http://localhost:5000/api/licenses/expiring"
curl "http://localhost:5000/api/licenses/expiring?days=30"
curl "http://localhost:5000/api/licenses/expiring?days=180"
```

**Parameters**:
- `days` (optional, query): Days to check ahead (default: 90)

**Response** (200 OK):
```json
{
  "count": 2,
  "licenses": [
    {
      "license_number": "KNRA-2023-000001",
      "hospital_name": "Kenyatta National Hospital",
      "expiry_date": "2027-01-14",
      "days_until_expiry": 223,
      "status": "active"
    }
  ]
}
```

---

### POST /api/licenses

Create a new license.

**Request**:
```bash
curl -X POST http://localhost:5000/api/licenses \
  -H "Content-Type: application/json" \
  -d '{
    "facility_id": 3,
    "license_number": "KNRA-2026-000025",
    "issue_date": "2026-06-15",
    "expiry_date": "2030-06-15",
    "status": "active",
    "fee_amount": 550000
  }'
```

**Parameters** (JSON body):
- `facility_id` (required): Facility to license
- `license_number` (required): License ID
- `issue_date` (required): Issue date (YYYY-MM-DD)
- `expiry_date` (required): Expiry date (YYYY-MM-DD)
- `status` (optional): active/expired/suspended (default: active)
- `fee_amount` (optional): License fee in KES

**Response** (201 Created):
```json
{
  "message": "License created successfully"
}
```

---

## Equipment

### GET /api/equipment

Get all equipment with facility information.

**Request**:
```bash
curl http://localhost:5000/api/equipment
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "equipment_name": "GE Revolution EVO CT Scanner",
    "serial_number": "GE-CT-2021-0001",
    "equipment_type": "CT Scanner",
    "facility_id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "status": "operational",
    "radiation_level": 5.5,
    "next_calibration_due": "2026-07-15"
  }
]
```

---

### GET /api/equipment/{id}

Get specific equipment details.

**Request**:
```bash
curl http://localhost:5000/api/equipment/1
```

**Response** (200 OK):
```json
{
  "id": 1,
  "equipment_name": "GE Revolution EVO CT Scanner",
  "serial_number": "GE-CT-2021-0001",
  "equipment_type": "CT Scanner",
  "facility_id": 1,
  "hospital_name": "Kenyatta National Hospital",
  "status": "operational",
  "radiation_level": 5.5,
  "next_calibration_due": "2026-07-15",
  "last_calibration": "2026-01-15",
  "condition": "excellent"
}
```

---

### GET /api/equipment/overdue

Get equipment overdue for calibration.

**Request**:
```bash
curl http://localhost:5000/api/equipment/overdue
```

**Response** (200 OK):
```json
{
  "count": 1,
  "equipment": [
    {
      "equipment_name": "Gamma Camera with SPECT",
      "serial_number": "SIE-NM-2022-0015",
      "hospital_name": "Mombasa Hospital",
      "next_calibration_due": "2026-03-15",
      "days_overdue": 92,
      "status": "operational"
    }
  ]
}
```

---

### POST /api/equipment

Create new equipment record.

**Request**:
```bash
curl -X POST http://localhost:5000/api/equipment \
  -H "Content-Type: application/json" \
  -d '{
    "facility_id": 1,
    "equipment_name": "Siemens MAGNETOM Avanto 1.5T",
    "serial_number": "SIEMENS-MRI-2026-0001",
    "equipment_type": "MRI Machine",
    "status": "operational"
  }'
```

---

## Inspections

### GET /api/inspections

Get all inspections with facility and inspector info.

**Request**:
```bash
curl http://localhost:5000/api/inspections
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "facility_id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "inspector_id": 1,
    "first_name": "John",
    "last_name": "Kimani",
    "inspection_date": "2026-03-20",
    "compliance_rating": "Compliant",
    "notes": "All equipment properly maintained"
  }
]
```

---

### GET /api/inspections/{id}

Get inspection with violations.

**Request**:
```bash
curl http://localhost:5000/api/inspections/1
```

**Response** (200 OK):
```json
{
  "inspection": {
    "id": 1,
    "facility_id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "inspection_date": "2026-03-20",
    "compliance_rating": "Compliant"
  },
  "violations": [
    {
      "id": 1,
      "violation_code": "EQ-001",
      "description": "Calibration overdue by 30 days",
      "severity": "high",
      "deadline": "2026-04-20"
    }
  ]
}
```

---

### POST /api/inspections

Create new inspection record.

**Request**:
```bash
curl -X POST http://localhost:5000/api/inspections \
  -H "Content-Type: application/json" \
  -d '{
    "facility_id": 1,
    "inspector_id": 1,
    "inspection_date": "2026-06-15",
    "compliance_rating": "Compliant",
    "notes": "All systems operational"
  }'
```

---

## Inspectors

### GET /api/inspectors

Get all inspectors.

**Request**:
```bash
curl http://localhost:5000/api/inspectors
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "staff_id": "KNRA-001",
    "first_name": "John",
    "last_name": "Kimani",
    "email": "john.kimani@knra.go.ke",
    "status": "active"
  },
  {
    "id": 2,
    "staff_id": "KNRA-002",
    "first_name": "Sarah",
    "last_name": "Njoroge",
    "email": "sarah.njoroge@knra.go.ke",
    "status": "active"
  }
]
```

---

### GET /api/inspectors/{id}/workload

Get inspector's inspection workload and history.

**Request**:
```bash
curl http://localhost:5000/api/inspectors/1/workload
```

**Response** (200 OK):
```json
{
  "inspector_id": 1,
  "inspection_count": 12,
  "inspections": [
    {
      "id": 1,
      "facility_id": 1,
      "hospital_name": "Kenyatta National Hospital",
      "inspection_date": "2026-03-20",
      "compliance_rating": "Compliant"
    }
  ]
}
```

---

## Reports

### GET /api/reports/compliance-summary

Get facility compliance summary.

**Request**:
```bash
curl http://localhost:5000/api/reports/compliance-summary
```

**Response** (200 OK):
```json
[
  {
    "hospital_name": "Kenyatta National Hospital",
    "total_inspections": 5,
    "compliant": 4,
    "non_compliant": 1
  },
  {
    "hospital_name": "Aga Khan University Hospital",
    "total_inspections": 3,
    "compliant": 3,
    "non_compliant": 0
  }
]
```

---

### GET /api/reports/violations

Get recent violations report.

**Request**:
```bash
curl http://localhost:5000/api/reports/violations
```

**Response** (200 OK):
```json
[
  {
    "hospital_name": "Mombasa Hospital",
    "violation_code": "CAL-001",
    "description": "Calibration certificate overdue",
    "severity": "high",
    "deadline": "2026-07-15",
    "inspection_date": "2026-05-20"
  }
]
```

---

### GET /api/reports/kpis

Get key performance indicators.

**Request**:
```bash
curl http://localhost:5000/api/reports/kpis
```

**Response** (200 OK):
```json
{
  "total_facilities": 3,
  "active_licenses": 2,
  "total_equipment": 3,
  "overdue_calibrations": 1,
  "expiring_licenses_90_days": 0
}
```

---

## Error Handling

### Error Response Format

All errors return appropriate HTTP status codes with JSON body:

```json
{
  "error": "Error description"
}
```

### Common Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid parameters |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Database or server error |

### Example Errors

**404 Not Found**:
```json
{
  "error": "Facility not found"
}
```

**500 Internal Error**:
```json
{
  "error": "Database error"
}
```

---

## Rate Limiting

**Current**: No rate limiting (development)

**Future Production**: 1000 requests/minute per API key

---

## Data Types & Formats

### Status Values
- `Facilities`: active, inactive, closed
- `Licenses`: active, expired, suspended, revoked
- `Equipment`: operational, maintenance, decommissioned
- `Inspections`: Compliant, Non-compliant

### Facility Classes
- `Class I`: Highest risk facilities
- `Class II`: Medium risk facilities
- `Class III`: Lower risk facilities

### Equipment Types
- CT Scanner
- Radiotherapy
- Nuclear Medicine
- X-Ray
- Other

### Severity Levels
- critical
- high
- medium
- low

---

## Pagination

**Current**: Not implemented (returns all records)

**Future**: Add limit/offset parameters
```bash
curl "http://localhost:5000/api/facilities?limit=10&offset=20"
```

---

## Versioning

**Current Version**: 1.0

Future API versions will be accessible at:
```
/api/v2/facilities
/api/v3/licenses
```

---

## Support

For API issues or questions:
- Check IMPLEMENTATION_COMPLETE.md
- Review MySQL schema
- Check Flask logs

---

**Last Updated**: June 15, 2026  
**Status**: Production Ready
