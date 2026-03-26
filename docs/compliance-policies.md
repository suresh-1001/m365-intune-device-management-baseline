# Compliance Policies

Compliance policies define the minimum security requirements a device must meet to be considered "compliant" in Intune. Devices that fail compliance can be blocked from accessing corporate resources via Conditional Access.

---

## Overview

**Profile type:** Compliance Policy  
**Platform:** Windows 10 and later  
**Assignment:** All enrolled devices

Intune evaluates each device against the compliance policy on check-in (approximately every 8 hours, or on-demand). The result is reported to the Intune dashboard and can trigger Conditional Access enforcement.

---

## Compliance Settings Configured

### Device Health

| Setting | Value | Reason |
|---|---|---|
| Require BitLocker | Required | Protects data if device is lost or stolen |
| Require Secure Boot | Required | Prevents boot-level malware |
| Require code integrity | Required | Ensures only trusted drivers/OS files load |

### Device Properties

| Setting | Value | Reason |
|---|---|---|
| Minimum OS version | 10.0.19041 (Windows 10 2004) | Ensures devices are on a supported build |
| Maximum OS version | Leave blank | Allow all future Windows versions |

### System Security

| Setting | Value | Reason |
|---|---|---|
| Require password | Required | Prevents unauthorized access |
| Minimum password length | 8 characters | Basic password strength |
| Password type | Alphanumeric | Stronger than numeric-only |
| Maximum inactivity before screen locks | 5 minutes | Auto-lock on idle |
| Password expiration | 90 days | Periodic rotation |
| Firewall | Required | Network protection |
| Antivirus | Required | Endpoint protection |
| Antispyware | Required | Malware protection |
| Microsoft Defender Antimalware | Required | Real-time protection |
| Microsoft Defender Antimalware security intelligence up-to-date | Required | Current threat definitions |

---

## Non-Compliance Actions

When a device falls out of compliance, Intune can take automated actions:

| Timeframe | Action | Notes |
|---|---|---|
| Immediately (Day 0) | Mark device non-compliant | Shows in dashboard; triggers Conditional Access if configured |
| Day 3 | Send email notification to user | Inform user their device needs attention |
| Day 7 | Send push notification | Reminder via Company Portal app |
| Day 14 | Remotely lock device | **Confirm with client before enabling** |

> ⚠️ Remote lock (Day 14) should only be enabled after client has been briefed. Users will be locked out of their device and must contact IT to unlock.

---

## Conditional Access Integration (Recommended Next Step)

Once compliance policies are in place, Conditional Access can enforce them:

**Example policy: Block non-compliant devices from Exchange Online**

1. Go to **Entra ID → Security → Conditional Access**
2. Create a new policy:
   - **Users:** All users (or scoped group)
   - **Cloud apps:** Office 365 Exchange Online
   - **Conditions:** Device platforms → Windows
   - **Grant:** Require device to be marked as compliant
3. Set policy to **Report-only** first — validate before enabling

> This ensures users on non-compliant or unmanaged devices cannot access corporate email.

---

## How to Create the Compliance Policy in Intune

1. Go to **https://endpoint.microsoft.com**
2. Navigate to: **Devices → Compliance Policies**
3. Click **Create Policy**
4. Platform: **Windows 10 and later**
5. Configure all settings from the table above
6. Under **Actions for noncompliance**, add the actions listed above
7. **Assignments:** Assign to `Intune-ManagedDevices-All` group
8. Click **Save**

---

## Monitoring Compliance

### Dashboard View

**Endpoint Manager → Devices → Monitor → Device compliance**

Shows:
- Compliant device count
- Non-compliant device count
- Not evaluated (recently enrolled, policy not yet applied)
- In grace period

### Per-Device View

**Endpoint Manager → Devices → All Devices → [select device] → Device compliance**

Shows each compliance setting and whether it passed or failed on that specific device.

---

## Compliance Validation Checklist

- [ ] Compliance policy created and assigned to correct group
- [ ] Pilot device shows "Compliant" in Intune after check-in
- [ ] BitLocker is enabled on pilot device (Settings → Update & Security → Device Encryption)
- [ ] Defender Antivirus is running and definitions are current
- [ ] Firewall is enabled (all three profiles: Domain, Private, Public)
- [ ] Screen lock/timeout is active after inactivity period
- [ ] Non-compliant test scenario: disable Defender → device shows "Not compliant" in Intune within 8 hours

