# Device Restriction Policies

This document covers the configuration of Intune Device Restriction profiles to lock down Windows 10/11 managed devices.

---

## Overview

Device restriction policies are deployed as **Configuration Profiles** in Microsoft Intune. They control what users can access on their managed devices — blocking system tools, restricting the browser, and controlling hardware access.

All policies in this deployment were:
1. Created in Endpoint Manager
2. Tested on a pilot VM
3. Validated before push to production devices

---

## Policy 1 — Windows Device Restrictions

**Profile type:** Device Restrictions  
**Platform:** Windows 10 and later  
**Assignment:** All enrolled devices

### Settings Configured

#### Control Panel & Settings

| Setting | Value |
|---|---|
| Control Panel | Block |
| Settings app | Block |

> Users cannot change system settings, network configuration, or device preferences.

#### System Tools

| Setting | Value |
|---|---|
| Command Prompt | Block |
| Registry Editor | Block |
| Task Manager | Block (optional — confirm with client) |
| PowerShell | Block (optional — confirm with client) |

#### Microsoft Store & App Installs

| Setting | Value |
|---|---|
| Microsoft Store | Block |
| Installing apps from unknown sources | Block |
| Game DVR | Block |

#### Removable Storage

| Setting | Value |
|---|---|
| Removable storage (USB drives) | Block |
| SD cards | Block |

> This prevents data exfiltration via USB or external media.

#### How to Configure in Intune

1. Go to **Endpoint Manager → Devices → Configuration Profiles**
2. Click **Create Profile**
3. Platform: **Windows 10 and later**
4. Profile type: **Device Restrictions**
5. Configure the settings listed above
6. Assign to target group
7. Click **Save**

---

## Policy 2 — Microsoft Edge Browser Restrictions

**Profile type:** Administrative Templates (or Settings Catalog)  
**Platform:** Windows 10 and later  
**Assignment:** All enrolled devices

### Settings Configured

#### Startup & Homepage

| Setting | Value |
|---|---|
| Configure the home button | Enabled — set to specific URL |
| Set new tab page URL | Configured to approved intranet/app URL |
| Configure start-up pages | Set to approved URL list |
| Allow users to change startup pages | Disabled |

#### Browser Security

| Setting | Value |
|---|---|
| Block access to a list of URLs | Configured (see allowed URL list below) |
| Allow access to a list of URLs | Approved URLs only |
| InPrivate mode availability | Disabled |
| Save browser history | Enabled (for audit purposes) |
| Browser sign-in settings | Force sign-in with Entra ID account |

#### Extensions & Developer Tools

| Setting | Value |
|---|---|
| Control which extensions cannot be installed | Block all extensions (allowlist approach) |
| Developer tools | Disabled |
| Guest mode | Disabled |

### Approved URL List (Template — Customize Per Client)

```
# Add approved URLs below — one per line
# Example format: [*.]domain.com

ringcentral.com
teamviewer.com
crisp.chat
timedoctor.com
login.microsoftonline.com
outlook.office.com
```

#### How to Configure in Intune

1. Go to **Endpoint Manager → Devices → Configuration Profiles**
2. Click **Create Profile**
3. Platform: **Windows 10 and later**
4. Profile type: **Settings Catalog** (search for "Microsoft Edge")
5. Add the settings listed above
6. Assign to target group
7. Click **Save**

---

## Policy 3 — Removable Storage (Standalone Policy)

**Profile type:** Settings Catalog  
**Platform:** Windows 10 and later

If removable storage is not covered by the Device Restrictions profile, create a dedicated policy:

| Setting | Value |
|---|---|
| All Removable Storage classes: Deny all access | Enabled |
| WPD Devices: Deny Write Access | Enabled |

---

## Validation — Testing Restrictions on a Pilot Device

After deploying each policy, validate on the pilot device before production rollout:

### Device Restrictions Checklist

- [ ] Open **Control Panel** → Should be blocked or open but show no accessible settings
- [ ] Open **Settings app** → Should be blocked or restricted
- [ ] Open **Command Prompt** (Win+R → cmd) → Should be blocked
- [ ] Open **Registry Editor** (Win+R → regedit) → Should be blocked
- [ ] Insert a USB drive → Should not appear in File Explorer
- [ ] Try opening **Microsoft Store** → Should be blocked

### Edge Browser Checklist

- [ ] Open Edge → Verify startup page loads approved URL
- [ ] Try navigating to an unapproved website → Should be blocked
- [ ] Try opening InPrivate window → Should be blocked
- [ ] Try accessing Edge Extensions (edge://extensions) → Should be locked
- [ ] Try opening Developer Tools (F12) → Should be disabled

---

## Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| Restrictions not applying after 30 min | Policy not synced | Force sync from Intune portal or device |
| Policy shows "Error" in Intune | Setting conflict or unsupported OS version | Check device OS version; review policy conflict report |
| Edge policy not applying | Edge not signed in with Entra ID | Ensure user is signed into Edge with their M365 account |
| USB still accessible | Removable storage setting needs dedicated policy | Create standalone removable storage policy via Settings Catalog |

