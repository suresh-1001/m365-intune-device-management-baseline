# Policy Reference — Device Restrictions

This file documents the exact Intune Configuration Profile settings for device restrictions in OMA-URI / Settings Catalog format for reference and re-deployment.

---

## Profile Details

| Field | Value |
|---|---|
| Profile name | Windows Device Restrictions — Baseline |
| Platform | Windows 10 and later |
| Profile type | Device Restrictions |
| Assignment | All enrolled devices |

---

## Settings Reference

### Control Panel & Settings

| OMA-URI / Setting | Value |
|---|---|
| `./Device/Vendor/MSFT/Policy/Config/Experience/AllowCortana` | 0 (Block) |
| Control Panel — Restrict Control Panel | Enabled |
| Settings — Block Settings | Enabled |

### System Tools

| Setting Name | Value |
|---|---|
| Block Command Prompt | Yes |
| Block Registry Editing | Yes |
| Block access to run command from Start Menu | Yes |

### Microsoft Store

| Setting Name | Value |
|---|---|
| App store | Block |
| Auto-update apps from the store | Not configured |
| Trusted app installation | Block |

### Removable Storage

| Setting Name | Value |
|---|---|
| Removable storage | Block |
| USB connection | Block (if kiosk mode required) |

### Game DVR

| Setting Name | Value |
|---|---|
| Game DVR (desktop only) | Block |

---

## Profile Details — Edge Browser

| Field | Value |
|---|---|
| Profile name | Edge Browser Restrictions — Baseline |
| Platform | Windows 10 and later |
| Profile type | Settings Catalog (Microsoft Edge) |
| Assignment | All enrolled devices |

### Key Settings

| Setting | Value |
|---|---|
| Configure Home Button URL | `https://[approved-url]` |
| Set new tab page URL | `https://[approved-url]` |
| Configure the list of URLs for which InPrivate mode is not available | * (all) |
| Enable InPrivate mode | Disabled |
| Allow or block developer tools | Block |
| Enable Guest mode | Disabled |
| Configure the list of force-installed extensions | Leave blank (no extensions) |
| URLAllowList | See approved URL list in application-control.md |
| URLBlockList | * (block all, then allowlist overrides) |

---

## Re-Deployment Notes

To re-deploy this policy to a new tenant:

1. Open **Endpoint Manager → Devices → Configuration Profiles**
2. Click **Create Profile → Windows 10 and later → Device Restrictions**
3. Use the settings tables above as your reference
4. For Edge settings, use **Settings Catalog** and search for "Microsoft Edge"
5. Test on pilot device before assigning to all devices

Alternatively, export an existing profile as JSON (Endpoint Manager → Export) and import into the new tenant.

