# KNRA API Testing Script - Simple Version
# Tests all 25+ endpoints

param(
    [string]$BaseUrl = "http://localhost:5000",
    [int]$Timeout = 5
)

$Success = "Green"
$Error = "Red"
$Info = "Cyan"

$Passed = 0
$Failed = 0
$Total = 0

function Test-Endpoint {
    param([string]$Name, [string]$Method = "GET", [string]$Endpoint)
    
    $global:Total++
    $Url = "$BaseUrl$Endpoint"
    $MethodStr = "$Method".PadRight(6)
    
    Write-Host "[$MethodStr] $Name -> $Url" -ForegroundColor $Info
    
    try {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $Timeout
        
        if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 300) {
            Write-Host "Status: $($Response.StatusCode) - OK" -ForegroundColor $Success
            $global:Passed++
            return $true
        } else {
            Write-Host "Status: $($Response.StatusCode) - FAILED" -ForegroundColor $Error
            $global:Failed++
            return $false
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor $Error
        $global:Failed++
        return $false
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "KNRA API TEST SUITE" -ForegroundColor Cyan
Write-Host "Base URL: $BaseUrl" -ForegroundColor $Info
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Health Check
Write-Host "--- HEALTH CHECK ---" -ForegroundColor Magenta
Test-Endpoint -Name "Health Check" -Endpoint "/health"

# Facilities
Write-Host ""
Write-Host "--- FACILITIES ---" -ForegroundColor Magenta
Test-Endpoint -Name "List Facilities" -Endpoint "/api/facilities"
Test-Endpoint -Name "Get Facility 1" -Endpoint "/api/facilities/1"

# Licenses
Write-Host ""
Write-Host "--- LICENSES ---" -ForegroundColor Magenta
Test-Endpoint -Name "List Licenses" -Endpoint "/api/licenses"
Test-Endpoint -Name "Get License 1" -Endpoint "/api/licenses/1"
Test-Endpoint -Name "Expiring (90 days)" -Endpoint "/api/licenses/expiring?days=90"
Test-Endpoint -Name "Expiring (30 days)" -Endpoint "/api/licenses/expiring?days=30"

# Equipment
Write-Host ""
Write-Host "--- EQUIPMENT ---" -ForegroundColor Magenta
Test-Endpoint -Name "List Equipment" -Endpoint "/api/equipment"
Test-Endpoint -Name "Get Equipment 1" -Endpoint "/api/equipment/1"
Test-Endpoint -Name "Overdue Calibration" -Endpoint "/api/equipment/overdue"

# Inspections
Write-Host ""
Write-Host "--- INSPECTIONS ---" -ForegroundColor Magenta
Test-Endpoint -Name "List Inspections" -Endpoint "/api/inspections"
Test-Endpoint -Name "Get Inspection 1" -Endpoint "/api/inspections/1"

# Inspectors
Write-Host ""
Write-Host "--- INSPECTORS ---" -ForegroundColor Magenta
Test-Endpoint -Name "List Inspectors" -Endpoint "/api/inspectors"
Test-Endpoint -Name "Inspector 1 Workload" -Endpoint "/api/inspectors/1/workload"

# Reports
Write-Host ""
Write-Host "--- REPORTS ---" -ForegroundColor Magenta
Test-Endpoint -Name "Compliance Summary" -Endpoint "/api/reports/compliance-summary"
Test-Endpoint -Name "Violations Report" -Endpoint "/api/reports/violations"
Test-Endpoint -Name "KPIs Report" -Endpoint "/api/reports/kpis"

# Results
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $Total"
Write-Host "Passed: $Passed" -ForegroundColor $Success
Write-Host "Failed: $Failed" -ForegroundColor $(if ($Failed -eq 0) { $Success } else { $Error })
$PassPercent = if ($Total -gt 0) { [math]::Round(($Passed / $Total) * 100) } else { 0 }
Write-Host "Success Rate: $PassPercent%"
Write-Host ""

if ($Failed -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor $Success
} else {
    Write-Host "SOME TESTS FAILED!" -ForegroundColor $Error
}
Write-Host ""
