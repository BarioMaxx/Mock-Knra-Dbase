# KNRA API Testing Script - Local and Vercel
# Tests all 25+ endpoints and displays results

param(
    [string]$BaseUrl = "http://localhost:5000",
    [int]$Timeout = 5
)

# Color coding
$Success = "Green"
$Error = "Red"
$Info = "Cyan"
$Warning = "Yellow"

# Test results tracking
$Results = @{
    Passed = 0
    Failed = 0
    Total = 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Endpoint,
        [object]$Body = $null
    )
    
    $Results.Total++
    $Url = "$BaseUrl$Endpoint"
    $MethodStr = "$Method".PadRight(6)
    
    Write-Host "  [$MethodStr] $Name" -ForegroundColor $Info
    Write-Host "       URL: $Url" -ForegroundColor Gray
    
    try {
        if ($Method -eq "POST") {
            $Response = Invoke-WebRequest -Uri $Url -Method POST -Body ($Body | ConvertTo-Json) `
                -ContentType "application/json" -UseBasicParsing -TimeoutSec $Timeout
        } else {
            $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $Timeout
        }
        
        if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 300) {
            Write-Host "       Status: $($Response.StatusCode) ✅ SUCCESS" -ForegroundColor $Success
            $Results.Passed++
            
            # Show sample of response
            try {
                $Data = $Response.Content | ConvertFrom-Json
                if ($Data -is [array]) {
                    Write-Host "       Records: $($Data.Count)" -ForegroundColor Gray
                } elseif ($Data.PSObject.Properties.Count -gt 0) {
                    $Props = $Data.PSObject.Properties.Name -join ", " | Select-Object -First 3
                    Write-Host "       Data: $Props..." -ForegroundColor Gray
                }
            } catch { }
            
            return $true
        } else {
            Write-Host "       Status: $($Response.StatusCode) ❌ FAILED" -ForegroundColor $Error
            $Results.Failed++
            return $false
        }
    } catch {
        Write-Host "       Error: $($_.Exception.Message)" -ForegroundColor $Error
        $Results.Failed++
        return $false
    }
}

# ============================================================================
# MAIN TEST SUITE
# ============================================================================

function Run-Tests {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           KNRA Licensing Database - API Test Suite                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Base URL: $BaseUrl" -ForegroundColor $Info
    Write-Host "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Info
    Write-Host ""
    
    # Test connectivity
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "1️⃣  CONNECTION & HEALTH CHECK" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "Health Check" -Endpoint "/health"
    
    # Facilities endpoints
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "2️⃣  FACILITIES ENDPOINTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "List All Facilities" -Endpoint "/api/facilities"
    Test-Endpoint -Name "Get Facility #1" -Endpoint "/api/facilities/1"
    
    # Licenses endpoints
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "3️⃣  LICENSES ENDPOINTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "List All Licenses" -Endpoint "/api/licenses"
    Test-Endpoint -Name "Get License #1" -Endpoint "/api/licenses/1"
    Test-Endpoint -Name "Get Expiring Licenses (90 days)" -Endpoint "/api/licenses/expiring?days=90"
    Test-Endpoint -Name "Get Expiring Licenses (30 days)" -Endpoint "/api/licenses/expiring?days=30"
    
    # Equipment endpoints
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "4️⃣  EQUIPMENT ENDPOINTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "List All Equipment" -Endpoint "/api/equipment"
    Test-Endpoint -Name "Get Equipment #1" -Endpoint "/api/equipment/1"
    Test-Endpoint -Name "Get Overdue Equipment" -Endpoint "/api/equipment/overdue"
    
    # Inspections endpoints
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "5️⃣  INSPECTIONS ENDPOINTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "List All Inspections" -Endpoint "/api/inspections"
    Test-Endpoint -Name "Get Inspection #1" -Endpoint "/api/inspections/1"
    
    # Inspectors endpoints
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "6️⃣  INSPECTORS ENDPOINTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "List All Inspectors" -Endpoint "/api/inspectors"
    Test-Endpoint -Name "Get Inspector #1 Workload" -Endpoint "/api/inspectors/1/workload"
    
    # Reporting endpoints
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "7️⃣  REPORTING ENDPOINTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Test-Endpoint -Name "Compliance Summary Report" -Endpoint "/api/reports/compliance-summary"
    Test-Endpoint -Name "Violations Report" -Endpoint "/api/reports/violations"
    Test-Endpoint -Name "Key Performance Indicators" -Endpoint "/api/reports/kpis"
    
    # Display results
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "📊 TEST RESULTS" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    $PassPercent = if ($Results.Total -gt 0) { [math]::Round(($Results.Passed / $Results.Total) * 100) } else { 0 }
    
    Write-Host "  Total Tests:    $($Results.Total)" -ForegroundColor $Info
    Write-Host "  Passed:         $($Results.Passed)" -ForegroundColor $Success
    Write-Host "  Failed:         $($Results.Failed)" -ForegroundColor $(if ($Results.Failed -eq 0) { $Success } else { $Error })
    Write-Host "  Success Rate:   $PassPercent%" -ForegroundColor $(if ($PassPercent -eq 100) { $Success } else { $Warning })
    
    Write-Host ""
    if ($Results.Failed -eq 0) {
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║           ✅ ALL TESTS PASSED - API IS WORKING!                    ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    } else {
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Warning
        Write-Host "║           ⚠️  SOME TESTS FAILED - CHECK ERRORS ABOVE               ║" -ForegroundColor $Warning
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Warning
    }
    
    Write-Host ""
    Write-Host "Tested Endpoints: $(if ($BaseUrl -contains 'localhost') { 'Local Development' } else { 'Vercel Production' })" -ForegroundColor $Info
    Write-Host "Base URL: $BaseUrl" -ForegroundColor $Info
    Write-Host ""
}

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests

# Return exit code based on results
if ($Results.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
