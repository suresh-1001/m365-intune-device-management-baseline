# device-inventory.ps1
# Quick Intune device inventory — outputs CSV of all managed devices with key fields
# Author: Suresh Chand — https://github.com/suresh-1001
# Usage: .\device-inventory.ps1 [-OutputPath "C:\Temp\DeviceInventory.csv"]

[CmdletBinding()]
param(
    [string]$OutputPath = "C:\Temp\DeviceInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

$ErrorActionPreference = "Stop"

# ── Module check ───────────────────────────────────────────────────────────────

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
    Write-Host "Installing Microsoft.Graph.DeviceManagement..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement

# ── Connect ────────────────────────────────────────────────────────────────────

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -NoWelcome

$ctx = Get-MgContext
if (-not $ctx) { throw "Graph connection failed." }

Write-Host "Connected as: $($ctx.Account)" -ForegroundColor Green

# ── Collect devices ────────────────────────────────────────────────────────────

Write-Host "Retrieving Intune managed devices..." -ForegroundColor Cyan

$devices = @(Get-MgDeviceManagementManagedDevice -All)

if ($devices.Count -eq 0) {
    Write-Warning "No managed devices found in this tenant."
    exit
}

Write-Host "Found $($devices.Count) devices." -ForegroundColor Green

# ── Export ─────────────────────────────────────────────────────────────────────

$export = @(
    foreach ($d in $devices) {
        [PSCustomObject]@{
            DeviceName             = $d.DeviceName
            UserPrincipalName      = $d.UserPrincipalName
            OperatingSystem        = $d.OperatingSystem
            OSVersion              = $d.OsVersion
            Manufacturer           = $d.Manufacturer
            Model                  = $d.Model
            ComplianceState        = $d.ComplianceState
            ManagedDeviceOwnerType = $d.ManagedDeviceOwnerType
            ManagementAgent        = $d.ManagementAgent
            EnrolledDateTime       = $d.EnrolledDateTime
            LastSyncDateTime       = $d.LastSyncDateTime
            AzureADDeviceId        = $d.AzureAdDeviceId
        }
    }
)

$export | Sort-Object DeviceName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Device inventory saved to: $OutputPath" -ForegroundColor Green
Write-Host ""

# ── Summary ────────────────────────────────────────────────────────────────────

$compliant    = ($export | Where-Object { $_.ComplianceState -eq "compliant" }).Count
$nonCompliant = ($export | Where-Object { $_.ComplianceState -ne "compliant" }).Count

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total devices   : $($export.Count)"
Write-Host "  Compliant       : $compliant"
Write-Host "  Non-compliant   : $nonCompliant"
Write-Host ""

$export | Format-Table DeviceName, UserPrincipalName, ComplianceState, LastSyncDateTime -AutoSize

# ── Disconnect ─────────────────────────────────────────────────────────────────

try { Disconnect-MgGraph | Out-Null } catch {}
