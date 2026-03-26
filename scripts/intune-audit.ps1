# M365_Intune_Entra_Audit.ps1
# One-click Microsoft 365 / Entra / Intune audit with HTML report
# Author: Suresh Chand — https://github.com/suresh-1001
# Usage:
#   .\M365_Intune_Entra_Audit.ps1
#   .\M365_Intune_Entra_Audit.ps1 -OutputRoot "C:\Audits\Client"
#   .\M365_Intune_Entra_Audit.ps1 -SkipModuleInstall

[CmdletBinding()]
param(
    [string]$OutputRoot = "C:\Temp\M365_Audit",
    [switch]$SkipModuleInstall
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host "==== $Message ====" -ForegroundColor Cyan
}

function Ensure-NuGet {
    try {
        $null = Get-PackageProvider -Name NuGet -ErrorAction Stop
    }
    catch {
        Write-Host "Installing NuGet package provider..." -ForegroundColor Yellow
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
    }
}

function Ensure-PSGalleryTrusted {
    try {
        $repo = Get-PSRepository -Name PSGallery -ErrorAction Stop
        if ($repo.InstallationPolicy -ne "Trusted") {
            Write-Host "Setting PSGallery as Trusted..." -ForegroundColor Yellow
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
    }
    catch {
        Write-Warning "Could not verify PSGallery trust state. Continuing..."
    }
}

function Ensure-Module {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        if ($SkipModuleInstall) {
            throw "Required module '$Name' is not installed and -SkipModuleInstall was used."
        }

        Write-Host "Installing module: $Name" -ForegroundColor Yellow
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module $Name -ErrorAction Stop
}

function Safe-Count {
    param($Value)
    if ($null -eq $Value) { return 0 }
    return @($Value).Count
}

function ConvertTo-HtmlTable {
    param(
        $Data,
        [Parameter(Mandatory)]
        [string]$Title
    )

    $rows = @($Data)

    if ($null -eq $Data -or $rows.Count -eq 0) {
        return "<h2>$Title</h2><p><em>No data found.</em></p>"
    }

    $fragment = $rows | ConvertTo-Html -Fragment
    return "<h2>$Title</h2>$fragment"
}

# ── Output folder ──────────────────────────────────────────────────────────────

Write-Section "Preparing output folder"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outPath   = Join-Path $OutputRoot "M365_Audit_$timestamp"
New-Item -ItemType Directory -Path $outPath -Force | Out-Null

Write-Host "Output path: $outPath" -ForegroundColor Green

# ── Prerequisites ──────────────────────────────────────────────────────────────

Write-Section "Checking PowerShell prerequisites"

Ensure-NuGet
Ensure-PSGalleryTrusted

# ── Modules ────────────────────────────────────────────────────────────────────

Write-Section "Installing / importing required Microsoft Graph modules"

$requiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Identity.DirectoryManagement",
    "Microsoft.Graph.DeviceManagement"
)

foreach ($m in $requiredModules) {
    Ensure-Module -Name $m
}

# ── Connect ────────────────────────────────────────────────────────────────────

Write-Section "Connecting to Microsoft Graph"

$scopes = @(
    "User.Read.All",
    "Group.Read.All",
    "Directory.Read.All",
    "RoleManagement.Read.Directory",
    "Organization.Read.All",
    "Device.Read.All",
    "DeviceManagementManagedDevices.Read.All"
)

Connect-MgGraph -Scopes $scopes -NoWelcome

$ctx = Get-MgContext
if (-not $ctx) { throw "Graph connection failed." }

Write-Host "Connected as: $($ctx.Account)" -ForegroundColor Green
Write-Host "Tenant ID:    $($ctx.TenantId)"  -ForegroundColor Green

# ── Tenant Info ────────────────────────────────────────────────────────────────

Write-Section "Collecting tenant organization info"

$org = Get-MgOrganization
$tenantInfo = [PSCustomObject]@{
    DisplayName       = $org.DisplayName
    TenantId          = $ctx.TenantId
    VerifiedDomains   = (($org.VerifiedDomains | ForEach-Object { $_.Name }) -join ", ")
    CountryLetterCode = $org.CountryLetterCode
    CreatedDateTime   = $org.CreatedDateTime
    ConnectedAccount  = $ctx.Account
    AuditDateTime     = Get-Date
}

$tenantInfo | Export-Csv (Join-Path $outPath "00_TenantInfo.csv") -NoTypeInformation

# ── Licenses ───────────────────────────────────────────────────────────────────

Write-Section "Collecting license information"

$skus = @(Get-MgSubscribedSku -All)
$skuExport = @(
    foreach ($sku in $skus) {
        [PSCustomObject]@{
            SkuPartNumber = $sku.SkuPartNumber
            SkuId         = $sku.SkuId
            ConsumedUnits = $sku.ConsumedUnits
            EnabledUnits  = $sku.PrepaidUnits.Enabled
            Suspended     = $sku.PrepaidUnits.Suspended
            WarningUnits  = $sku.PrepaidUnits.Warning
        }
    }
)

$skuExport | Export-Csv (Join-Path $outPath "01_Licenses.csv") -NoTypeInformation

# ── Users ──────────────────────────────────────────────────────────────────────

Write-Section "Collecting user list"

$users = @(Get-MgUser -All -Property `
    Id,DisplayName,UserPrincipalName,Mail,AccountEnabled,Department,JobTitle,CreatedDateTime,AssignedLicenses,UserType)

$userExport = @(
    foreach ($u in $users) {
        [PSCustomObject]@{
            DisplayName       = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
            Mail              = $u.Mail
            UserType          = $u.UserType
            Department        = $u.Department
            JobTitle          = $u.JobTitle
            AccountEnabled    = $u.AccountEnabled
            CreatedDateTime   = $u.CreatedDateTime
            LicenseCount      = Safe-Count $u.AssignedLicenses
        }
    }
)

$userExport | Sort-Object DisplayName | Export-Csv (Join-Path $outPath "02_Users.csv") -NoTypeInformation

# ── Per-User License Details ───────────────────────────────────────────────────

Write-Section "Collecting per-user license details"

$userLicenseExport = @(
    foreach ($u in $users) {
        try {
            $licenseDetails = @(Get-MgUserLicenseDetail -UserId $u.Id)

            if ((Safe-Count $licenseDetails) -eq 0) {
                [PSCustomObject]@{
                    DisplayName       = $u.DisplayName
                    UserPrincipalName = $u.UserPrincipalName
                    SkuPartNumber     = "Unlicensed"
                    SkuId             = ""
                }
            }
            else {
                foreach ($ld in $licenseDetails) {
                    [PSCustomObject]@{
                        DisplayName       = $u.DisplayName
                        UserPrincipalName = $u.UserPrincipalName
                        SkuPartNumber     = $ld.SkuPartNumber
                        SkuId             = $ld.SkuId
                    }
                }
            }
        }
        catch {
            [PSCustomObject]@{
                DisplayName       = $u.DisplayName
                UserPrincipalName = $u.UserPrincipalName
                SkuPartNumber     = "ERROR"
                SkuId             = $_.Exception.Message
            }
        }
    }
)

$userLicenseExport | Sort-Object DisplayName, SkuPartNumber |
    Export-Csv (Join-Path $outPath "03_UserLicenseDetails.csv") -NoTypeInformation

# ── Entra Devices ──────────────────────────────────────────────────────────────

Write-Section "Collecting Entra devices"

$entraDevices = @(Get-MgDevice -All)
$entraDeviceExport = @(
    foreach ($d in $entraDevices) {
        [PSCustomObject]@{
            DisplayName                   = $d.DisplayName
            DeviceId                      = $d.DeviceId
            OperatingSystem               = $d.OperatingSystem
            OperatingSystemVersion        = $d.OperatingSystemVersion
            TrustType                     = $d.TrustType
            AccountEnabled                = $d.AccountEnabled
            IsCompliant                   = $d.IsCompliant
            IsManaged                     = $d.IsManaged
            ApproximateLastSignInDateTime = $d.ApproximateLastSignInDateTime
        }
    }
)

$entraDeviceExport | Sort-Object DisplayName |
    Export-Csv (Join-Path $outPath "04_EntraDevices.csv") -NoTypeInformation

# ── Intune Managed Devices ─────────────────────────────────────────────────────

Write-Section "Collecting Intune managed devices"

$managedDevices = @(Get-MgDeviceManagementManagedDevice -All)
$managedDeviceExport = @(
    foreach ($d in $managedDevices) {
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

$managedDeviceExport | Sort-Object DeviceName |
    Export-Csv (Join-Path $outPath "05_IntuneManagedDevices.csv") -NoTypeInformation

# ── Summary ────────────────────────────────────────────────────────────────────

Write-Section "Building summary"

$totalUsers          = Safe-Count $userExport
$licensedUsers       = Safe-Count ($userExport | Where-Object { $_.LicenseCount -gt 0 })
$unlicensedUsers     = Safe-Count ($userExport | Where-Object { $_.LicenseCount -eq 0 })
$disabledUsers       = Safe-Count ($userExport | Where-Object { $_.AccountEnabled -eq $false })
$totalEntraDevices   = Safe-Count $entraDeviceExport
$totalIntuneDevices  = Safe-Count $managedDeviceExport
$compliantDevices    = Safe-Count ($managedDeviceExport | Where-Object { $_.ComplianceState -eq "compliant" })
$nonCompliantDevices = Safe-Count ($managedDeviceExport | Where-Object { $_.ComplianceState -ne "compliant" })

$summary = [PSCustomObject]@{
    TenantDisplayName   = $tenantInfo.DisplayName
    TenantId            = $tenantInfo.TenantId
    ConnectedAccount    = $tenantInfo.ConnectedAccount
    TotalUsers          = $totalUsers
    LicensedUsers       = $licensedUsers
    UnlicensedUsers     = $unlicensedUsers
    DisabledUsers       = $disabledUsers
    TotalEntraDevices   = $totalEntraDevices
    TotalIntuneDevices  = $totalIntuneDevices
    CompliantDevices    = $compliantDevices
    NonCompliantDevices = $nonCompliantDevices
    OutputFolder        = $outPath
    AuditDateTime       = Get-Date
}

$summary | Export-Csv (Join-Path $outPath "00_Summary.csv") -NoTypeInformation

# ── HTML Report ────────────────────────────────────────────────────────────────

Write-Section "Generating HTML report"

$style = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; color: #222; }
h1   { color: #0f4c81; }
h2   { color: #0f4c81; border-bottom: 1px solid #ddd; padding-bottom: 4px; margin-top: 28px; }
table { border-collapse: collapse; width: 100%; margin-top: 8px; }
th, td { border: 1px solid #d9d9d9; padding: 8px; font-size: 13px; text-align: left; vertical-align: top; }
th   { background: #f2f6fb; }
.small { color: #555; font-size: 12px; }
.note  { background: #fff8dc; border-left: 4px solid #e0b100; padding: 10px; margin: 16px 0; }
</style>
"@

$bodyHtml = @"
<h1>Microsoft 365 / Entra / Intune Audit Report</h1>
<p class='small'>Generated: $(Get-Date)</p>
<p class='small'>Tenant: $($tenantInfo.DisplayName) | Account: $($tenantInfo.ConnectedAccount)</p>
<div class='note'>
  Phase 1 discovery report: tenant validation, user/licensing review, device visibility, and Intune readiness.
</div>
"@

$recommendations = @"
<h2>Recommended Next Steps</h2>
<ol>
  <li>Confirm which users need Intune-capable licenses.</li>
  <li>Validate which Windows endpoints are Entra joined vs only directory records.</li>
  <li>Compare Entra devices to Intune-managed devices to identify systems not yet enrolled.</li>
  <li>Review standard user accounts vs admin or service accounts before policy rollout.</li>
  <li>Begin pilot testing for application lockdown, browser restrictions, and device restriction policies.</li>
</ol>
"@

$topUnlicensed    = @($userExport | Where-Object { $_.LicenseCount -eq 0 } | Sort-Object DisplayName | Select-Object -First 25)
$topDisabled      = @($userExport | Where-Object { $_.AccountEnabled -eq $false } | Sort-Object DisplayName | Select-Object -First 25)
$topNonCompliant  = @($managedDeviceExport | Where-Object { $_.ComplianceState -ne "compliant" } | Sort-Object DeviceName | Select-Object -First 25)
$topRecentlySynced = @($managedDeviceExport | Sort-Object LastSyncDateTime -Descending | Select-Object -First 25)

$html = ConvertTo-Html -Title "M365 Audit Report" -Head $style -Body (
    $bodyHtml +
    (ConvertTo-HtmlTable -Data @($summary)          -Title "Executive Summary") +
    (ConvertTo-HtmlTable -Data @($skuExport)        -Title "Subscribed Licenses") +
    (ConvertTo-HtmlTable -Data @($topUnlicensed)    -Title "Users Without Licenses") +
    (ConvertTo-HtmlTable -Data @($topDisabled)      -Title "Disabled Accounts") +
    (ConvertTo-HtmlTable -Data @($topNonCompliant)  -Title "Non-Compliant Devices") +
    (ConvertTo-HtmlTable -Data @($topRecentlySynced)-Title "Recently Synced Devices") +
    $recommendations
)

$htmlPath = Join-Path $outPath "M365_Audit_Report.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

# ── Done ───────────────────────────────────────────────────────────────────────

Write-Section "Finished"
Write-Host "CSV files: $outPath"  -ForegroundColor Green
Write-Host "HTML report: $htmlPath" -ForegroundColor Green

try { Disconnect-MgGraph | Out-Null } catch { Write-Warning "Could not disconnect from Graph cleanly." }
