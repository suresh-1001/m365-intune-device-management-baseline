# Device Enrollment Guide

This guide covers how to configure and validate Windows device enrollment into Microsoft Intune via Azure AD Join and automatic MDM enrollment.

---

## Prerequisites

Before enrolling devices, confirm the following are in place:

| Requirement | Where to Check |
|---|---|
| Microsoft Intune license assigned to users | M365 Admin Center → Billing → Licenses |
| Azure AD Premium P1 (included in M365 Business Premium) | M365 Admin Center → Billing → Licenses |
| MDM auto-enrollment configured in Entra ID | Entra ID → Mobility (MDM and MAM) |
| User has local admin or standard user account on device | Device Settings → Accounts |

---

## Step 1 — Configure Automatic MDM Enrollment

This setting tells Entra ID to automatically enroll Windows devices into Intune when they join.

1. Go to **https://entra.microsoft.com**
2. Navigate to: **Identity → Mobility (MDM and MAM) → Microsoft Intune**
3. Set **MDM User Scope** to:
   - `All` — enroll all users (recommended for small orgs)
   - `Some` — select a specific group (use for pilot phase)
4. Leave MDM URLs at default (auto-populated)
5. Click **Save**

> ✅ This is the most important step. Without it, devices will join Entra ID but will NOT enroll into Intune automatically.

---

## Step 2 — Set Enrollment Restrictions (Optional but Recommended)

Limit enrollment to corporate Windows devices only.

1. Go to **https://endpoint.microsoft.com**
2. Navigate to: **Devices → Enroll Devices → Enrollment Restrictions**
3. Edit the default restriction or create a new one:
   - Allow: **Windows (MDM)**
   - Block: Android, iOS/iPadOS, macOS (if not required)
   - Set **Device limit** per user (e.g., 5)
4. Assign restriction to **All Users** or a specific group

---

## Step 3 — Enroll a Device (Azure AD Join)

### Method A — Out-of-Box Experience (New Device / Reset Device)

During Windows setup (OOBE):

1. On the "Sign in with Microsoft" screen, enter the user's **Microsoft 365 / Entra ID email address**
2. Enter password and complete MFA if prompted
3. Windows will automatically:
   - Join the device to Azure AD
   - Trigger Intune MDM enrollment
   - Apply assigned policies within 5–15 minutes

### Method B — Existing Device (Join from Settings)

For devices already running Windows 10/11:

1. Open **Settings → Accounts → Access work or school**
2. Click **Connect**
3. Click **Join this device to Azure Active Directory**
4. Enter the user's Microsoft 365 email and password
5. Confirm the tenant name and click **Join**
6. Restart the device
7. Sign in with the Entra ID account — Intune enrollment triggers automatically

> ⚠️ If the device was previously joined to a local domain or another Azure AD tenant, it must be fully reset (or Azure AD leave performed) before rejoining.

---

## Step 4 — Validate Enrollment

### On the Device

Open **Settings → Accounts → Access work or school**

You should see:
- The Entra ID account listed
- "Connected to [Tenant Name]'s Azure AD"
- "Info" button — click to confirm MDM enrollment is active

### In Intune Portal

1. Go to **https://endpoint.microsoft.com**
2. Navigate to: **Devices → All Devices**
3. Search for the device by name
4. Confirm:

| Field | Expected Value |
|---|---|
| Management type | MDM |
| Ownership | Company |
| Compliance state | Compliant (once policies sync) |
| Last check-in | Within last 15 minutes |
| Enrolled by | User's UPN |

---

## Step 5 — Trigger Manual Policy Sync (If Needed)

Policies typically apply within 5–15 minutes. To force an immediate sync:

**On the device:**
1. Open **Settings → Accounts → Access work or school**
2. Click the enrolled account → click **Info**
3. Scroll down → click **Sync**

**From Intune portal:**
1. Endpoint Manager → Devices → All Devices → select device
2. Click **Sync** in the top menu bar

---

## Troubleshooting Common Enrollment Issues

| Issue | Cause | Fix |
|---|---|---|
| Device joins Entra ID but doesn't appear in Intune | MDM auto-enrollment not configured | Check Entra ID → Mobility → MDM User Scope |
| "Your organization's policies are preventing enrollment" | Enrollment restriction blocking the device type | Check Devices → Enroll Devices → Enrollment Restrictions |
| Compliance shows "Not evaluated" | Compliance policy not yet assigned to device group | Assign compliance policy to correct group |
| Policies not applying after 30+ minutes | Device not syncing | Force sync from device or Intune portal |
| "MDM enrollment failed" error | License not assigned to user | Assign Intune license in M365 Admin Center |

---

## Enrollment Validation Checklist

Run through this after every device enrollment:

- [ ] Device appears in Endpoint Manager → Devices → All Devices
- [ ] Management type = MDM
- [ ] Ownership = Company
- [ ] Enrolled by = correct user UPN
- [ ] Last check-in = recent (within 15 min of enrollment)
- [ ] Compliance state = Compliant (allow up to 15 min for policy evaluation)
- [ ] No enrollment errors in device details → Device configuration tab
- [ ] Device restrictions visibly active (test: try opening Control Panel)

