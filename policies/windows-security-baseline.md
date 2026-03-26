# Policy Reference — Windows Security Baseline

Microsoft publishes security baseline templates for Windows that represent recommended hardening settings based on industry standards and Microsoft's own security research. This document covers the baseline deployed in this project.

---

## What Is a Security Baseline?

A Security Baseline is a pre-built Intune profile containing hundreds of security settings aligned to the **CIS Benchmark**, **NIST**, and **Microsoft's own security guidance**. Rather than configuring individual settings manually, you deploy the baseline as a single profile.

---

## Baseline Details

| Field | Value |
|---|---|
| Baseline | Windows 10/11 Security Baseline |
| Version | Latest available in Intune at time of deployment |
| Profile type | Endpoint Security → Security Baselines |
| Assignment | All enrolled devices |

---

## Key Settings Included in the Baseline

### Account Protection

| Setting | Value |
|---|---|
| Block Microsoft accounts | Blocked |
| Block adding work or school accounts | Only Entra ID accounts allowed |
| Prevent users from adding new non-admin users | Enabled |

### BitLocker (Drive Encryption)

| Setting | Value |
|---|---|
| Require device encryption | Enabled |
| BitLocker for OS drive | Required |
| BitLocker for removable drives | Enabled (encrypt on write) |
| Recovery key backup to Entra ID | Required before encryption |

### Windows Defender (Antivirus / EDR)

| Setting | Value |
|---|---|
| Real-time protection | Enabled |
| Behavior monitoring | Enabled |
| Block at first sight (BAFS) | Enabled |
| Potentially unwanted application (PUA) protection | Block |
| Cloud-delivered protection level | High |
| Defender for Endpoint integration | Enabled (if licensed) |

### Firewall

| Setting | Value |
|---|---|
| Firewall — Domain profile | Enabled |
| Firewall — Private profile | Enabled |
| Firewall — Public profile | Enabled |
| Block inbound connections by default | Enabled |
| Notifications when firewall blocks | Disabled (reduce noise) |

### Windows Update

| Setting | Value |
|---|---|
| Automatic updates | Enabled |
| Active hours (no restart window) | 8 AM – 5 PM |
| Deadline for quality updates | 3 days |
| Deadline for feature updates | 7 days |
| Automatic restart after update | After deadline |

### Credential Protection

| Setting | Value |
|---|---|
| Windows Hello for Business | Required (replaces password at device sign-in) |
| Credential Guard | Enabled (on supported hardware) |
| LAPS (Local Admin Password Solution) | Enabled |

### Attack Surface Reduction Rules

| Rule | Value |
|---|---|
| Block executable content from email and webmail clients | Block |
| Block all Office applications from creating child processes | Block |
| Block Office applications from injecting code into other processes | Block |
| Block JavaScript or VBScript from launching downloaded executable content | Block |
| Block execution of potentially obfuscated scripts | Block |
| Block Win32 API calls from Office macros | Block |
| Block untrusted and unsigned processes that run from USB | Block |

---

## How to Deploy the Security Baseline

1. Go to **Endpoint Manager → Endpoint Security → Security Baselines**
2. Select **Windows 10/11 Security Baseline**
3. Click **Create Profile**
4. Name the profile (e.g., `Windows Security Baseline — v1`)
5. Review default settings — override specific settings only if needed for your environment
6. **Assignments:** Assign to `Intune-Pilot-Group` first
7. After 48-hour pilot validation, reassign to `Intune-ManagedDevices-All`

---

## Baseline vs Custom Policies

| Approach | Use When |
|---|---|
| Security Baseline | Starting point for any new deployment — broad hardening fast |
| Custom Configuration Profile | Fine-tuning specific settings the baseline doesn't cover (e.g., Edge URL allow-list) |
| Compliance Policy | Defining what "compliant" means and enforcing it via Conditional Access |

These are not mutually exclusive — all three are deployed together in a complete Intune setup.

---

## Monitoring Baseline Compliance

**Endpoint Manager → Endpoint Security → Security Baselines → [your profile] → Device Status**

Shows per-device:
- Profile status (Succeeded / Error / Conflict / Pending)
- Which specific settings failed or conflicted

**Common conflict:** If a Security Baseline setting and a separate Configuration Profile set the same setting to different values, Intune flags a conflict. Resolve by removing the duplicate setting from one of the profiles.

