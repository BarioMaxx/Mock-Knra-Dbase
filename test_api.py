"""
KNRA API Test Script
Test all endpoints with curl commands
Run this to verify the API is working correctly
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:5000"

def print_header(title):
    """Print section header"""
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70)

def test_endpoint(method, endpoint, data=None):
    """Test an endpoint and print results"""
    url = f"{BASE_URL}{endpoint}"
    print(f"\n📌 {method} {endpoint}")
    print(f"   URL: {url}")
    
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code < 300:
            print(f"   ✅ SUCCESS")
            result = response.json()
            if isinstance(result, list):
                print(f"   Records: {len(result)}")
                if len(result) > 0:
                    print(f"   Sample: {json.dumps(result[0], indent=6, default=str)[:300]}...")
            else:
                print(f"   Response: {json.dumps(result, indent=6, default=str)[:300]}...")
        else:
            print(f"   ❌ ERROR")
            print(f"   Error: {response.text}")
            
    except Exception as e:
        print(f"   ❌ CONNECTION ERROR: {str(e)}")

# ============================================================================
# RUN TESTS
# ============================================================================

print("\n")
print("╔════════════════════════════════════════════════════════════════════╗")
print("║           KNRA Licensing Database - API Test Suite                ║")
print("╚════════════════════════════════════════════════════════════════════╝")
print(f"\n⏱️  Testing at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"🌐 Base URL: {BASE_URL}")

# Health Check
print_header("1. HEALTH CHECK")
test_endpoint("GET", "/health")

# Facilities
print_header("2. FACILITIES ENDPOINTS")
test_endpoint("GET", "/api/facilities")
test_endpoint("GET", "/api/facilities/1")

# Licenses
print_header("3. LICENSES ENDPOINTS")
test_endpoint("GET", "/api/licenses")
test_endpoint("GET", "/api/licenses/expiring")
test_endpoint("GET", "/api/licenses/expiring?days=30")

# Equipment
print_header("4. EQUIPMENT ENDPOINTS")
test_endpoint("GET", "/api/equipment")
test_endpoint("GET", "/api/equipment/overdue")
test_endpoint("GET", "/api/equipment/1")

# Inspections
print_header("5. INSPECTIONS ENDPOINTS")
test_endpoint("GET", "/api/inspections")
test_endpoint("GET", "/api/inspections/1")

# Inspectors
print_header("6. INSPECTORS ENDPOINTS")
test_endpoint("GET", "/api/inspectors")
test_endpoint("GET", "/api/inspectors/1/workload")

# Reports
print_header("7. REPORTING ENDPOINTS")
test_endpoint("GET", "/api/reports/compliance-summary")
test_endpoint("GET", "/api/reports/violations")
test_endpoint("GET", "/api/reports/kpis")

# Summary
print_header("✅ TEST SUITE COMPLETE")
print("\n✨ All endpoints have been tested!")
print(f"⏱️  Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"\n📚 API Documentation:")
print(f"   Health Check:             GET /health")
print(f"   Get Facilities:           GET /api/facilities")
print(f"   Get Licenses:             GET /api/licenses")
print(f"   Expiring Licenses:        GET /api/licenses/expiring?days=90")
print(f"   Equipment Overdue:        GET /api/equipment/overdue")
print(f"   Compliance Report:        GET /api/reports/compliance-summary")
print(f"   Key Metrics:              GET /api/reports/kpis")
print(f"\n🎯 Next Steps:")
print(f"   1. Integrate with your frontend application")
print(f"   2. Create user authentication (JWT tokens)")
print(f"   3. Add more validation and error handling")
print(f"   4. Deploy to production server")
print(f"   5. Set up monitoring and alerting")
