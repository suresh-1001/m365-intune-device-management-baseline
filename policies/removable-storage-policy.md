# Policy Reference — Removable Storage Restriction

Blocks USB drives, SD cards, and external storage devices on managed Windows devices to prevent data exfiltration.

---

## Profile Details

| Field | Value |
|---|---|
| Profile name | Removable Storage Block — Baseline |
| Platform | Windows 10 and later |
| Profile type | Settings Catalog |
| Assignment | All enrolled devices |

---

## Settings Configured

### Via Settings Catalog

Search for "Removable" in the Settings Catalog and configure:

| Setting | Value |
|---|---|
| All Removable Storage classes: Deny all access | Enabled |
| Removable Disks: Deny execute access | Enabled |
| Removable Disks: Deny read access | Enabled |
| Removable Disks: Deny write access | Enabled |
| CD and DVD: Deny execute access | Enabled |
| CD and DVD: Deny read access | Enabled |
| CD and DVD: Deny write access | Enabled |
| WPD Devices: Deny read access | Enabled |
| WPD Devices: Deny write access | Enabled |
| Tape Drives: Deny all access | Enabled |
| Floppy Drives: Deny all access | Enabled |

---

## OMA-URI Reference

For deployments using custom OMA-URI profiles:

| Class | OMA-URI | Value |
|---|---|---|
| All removable storage | `./Device/Vendor/MSFT/Policy/Config/Storage/RemovableDiskDenyWriteAccess` | `1` |
| USB drive read | `./Vendor/MSFT/DeviceManagement/DeviceConfiguration/RemovableStorageRequireEncryption` | `1` |

For granular device class control, use the Windows Device Installation restriction policy targeting specific device class GUIDs:

| Device Class | GUID |
|---|---|
| USB Mass Storage | `{36FC9E60-C465-11CF-8056-444553540000}` |
| Portable Devices (WPD) | `{EEC5AD98-8080-425F-922A-DABF3DE3F69A}` |
| CD/DVD | `{4D36E965-E325-11CE-BFC1-08002BE10318}` |

---

## Exceptions (If Required)

If specific users or devices require USB access (e.g., IT admin accounts):

1. Create a separate Entra ID group: `Intune-USB-Allowed`
2. Assign the removable storage block policy to `Intune-ManagedDevices-All`
3. Create an exclusion assignment for `Intune-USB-Allowed`

Only users in the allowed group will retain USB access.

---

## Validation

After policy deploys to a test device:

- [ ] Insert a USB drive → Device should not appear in File Explorer
- [ ] If drive does appear, check: Settings → Windows Security → Device Security → confirm policy is applied
- [ ] Check Intune: Device → Device Configuration → confirm policy shows "Succeeded"
- [ ] Try copying a file to USB (if it mounted) → Should be blocked with an access denied error

---

## Audit Logging

To detect USB insertion attempts even when blocked, enable audit logging:

1. Open **Local Group Policy Editor** or deploy via Intune Settings Catalog
2. Navigate to: Computer Configuration → Windows Settings → Security Settings → Advanced Audit Policy
3. Enable: **Object Access → Audit Removable Storage** → Success and Failure

Logs appear in Event Viewer: **Windows Logs → Security → Event ID 4663**

