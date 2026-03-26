# Application Control

This document covers the configuration of application allow-listing on managed Windows devices using Microsoft Intune — restricting devices to approved applications only.

---

## Overview

The goal of application control in this deployment is a **kiosk-style locked environment** where end users can only launch approved business applications. All other applications — including most default Windows apps and any user-installed software — are blocked or removed.

**Approach:** Windows Defender Application Control (WDAC) policy deployed via Intune, combined with Intune App deployment for approved applications.

---

## Approved Application Allow-List

| Application | Publisher | Purpose |
|---|---|---|
| RingCentral | RingCentral, Inc. | Business communications / VoIP / voicemail |
| TeamViewer | TeamViewer Germany GmbH | Remote support |
| Crisp | Crisp IM SARL | Customer support chat |
| Time Doctor | Staff.com Inc. | Time tracking and productivity monitoring |
| Microsoft Edge | Microsoft Corporation | Managed browser (policy-controlled) |
| Microsoft 365 Apps | Microsoft Corporation | Core productivity (if licensed) |

---

## Step 1 — Deploy Approved Apps via Intune

For each approved application, add it as a managed app in Intune so it can be silently installed on enrolled devices.

### Adding a Win32 App (e.g., RingCentral)

1. Download the offline installer (.exe or .msi) from the vendor
2. Convert to `.intunewin` format using the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool)
3. Go to **Endpoint Manager → Apps → Windows → Add**
4. Select **Windows app (Win32)**
5. Upload the `.intunewin` file
6. Configure:
   - Name, description, publisher
   - Install command (e.g., `RingCentralSetup.exe /silent`)
   - Uninstall command
   - Detection rule (registry key or file presence)
7. Assign to **All Devices** or target group
8. Set deployment type to **Required** (auto-installs silently)

Repeat for each approved application.

---

## Step 2 — Block Unapproved Applications (WDAC)

Windows Defender Application Control (WDAC) enforces which executables are allowed to run.

### Creating a WDAC Policy

**Option A — Audit Mode First (Recommended)**

1. On a reference device with only approved apps installed, open PowerShell as Administrator:

```powershell
# Generate a base policy in audit mode
New-CIPolicy -Level Publisher -FilePath "C:\Temp\BasePolicy.xml" -UserPEs -Fallback Hash

# Convert to binary
ConvertFrom-CIPolicy -XmlFilePath "C:\Temp\BasePolicy.xml" -BinaryFilePath "C:\Temp\BasePolicy.bin"
```

2. Deploy in **Audit Mode** first — monitors violations without blocking
3. Review audit logs in Event Viewer: `Applications and Services Logs → Microsoft → Windows → CodeIntegrity → Operational`
4. Identify and add any legitimate missed apps to the policy
5. Switch to **Enforce Mode** after validation

**Option B — Managed Installer (Simpler)**

Configure Intune as a Managed Installer — any app deployed through Intune is automatically trusted, everything else is blocked.

1. Enable Managed Installer in WDAC policy:

```xml
<Option>Enabled:Managed Installer</Option>
```

2. Deploy the policy via Intune OMA-URI:
   - OMA-URI: `./Vendor/MSFT/ApplicationControl/Policies/{PolicyGUID}/Policy`
   - Data type: Base64
   - Value: Base64-encoded `.bin` policy file

---

## Step 3 — Remove Default Consumer Apps

Windows 11 ships with consumer apps that should be removed from managed corporate devices.

### Remove via PowerShell (run as Admin or via Intune script)

```powershell
# Remove Xbox apps
Get-AppxPackage *Xbox* | Remove-AppxPackage

# Remove Solitaire / Casual Games
Get-AppxPackage *MicrosoftSolitaireCollection* | Remove-AppxPackage

# Remove LinkedIn
Get-AppxPackage *LinkedIn* | Remove-AppxPackage

# Remove other consumer apps (customize as needed)
Get-AppxPackage *BingWeather* | Remove-AppxPackage
Get-AppxPackage *BingNews* | Remove-AppxPackage
Get-AppxPackage *ZuneMusic* | Remove-AppxPackage
Get-AppxPackage *ZuneVideo* | Remove-AppxPackage
```

### Deploy via Intune (Recommended)

1. Save the above as `Remove-ConsumerApps.ps1`
2. Go to **Endpoint Manager → Devices → Scripts**
3. Click **Add → Windows 10 and later**
4. Upload the script
5. Set: Run as system = Yes, Enforce script signature check = No
6. Assign to all devices

---

## Step 4 — DLP — Block Copy/Paste to External Destinations

To prevent data exfiltration from approved apps (e.g., copying customer details from RingCentral to personal email):

1. Go to **Microsoft Purview Compliance Portal**: https://compliance.microsoft.com
2. Navigate to: **Data loss prevention → Policies → Create policy**
3. Configure:
   - **Content to protect:** All content / specific sensitive info types
   - **Conditions:** Content is shared outside the organization
   - **Action:** Block or audit copy/paste, upload, print
4. Assign to users on managed devices

> This is the control that prevents users from copying data from RingCentral, Crisp, or any other app and sending it to a personal email or external service.

---

## Application Control Validation Checklist

### Approved Apps
- [ ] RingCentral installs silently on enrolled devices
- [ ] TeamViewer installs silently on enrolled devices
- [ ] Crisp installs silently on enrolled devices
- [ ] Time Doctor installs silently on enrolled devices
- [ ] All approved apps launch and function correctly

### Blocked Apps
- [ ] Attempt to install an unapproved .exe → Blocked
- [ ] Attempt to run a downloaded executable → Blocked
- [ ] Xbox app removed from Start menu
- [ ] Solitaire / Games removed from Start menu
- [ ] LinkedIn removed from Start menu

### DLP
- [ ] Copy customer data from RingCentral → paste to external email → Action blocked or alerted

