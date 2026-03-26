# Microsoft Intune Device Management Deployment

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![Microsoft Intune](https://img.shields.io/badge/Microsoft-Intune-0078D4?logo=microsoft)
![Azure AD](https://img.shields.io/badge/Azure-Entra%20ID-0078D4?logo=microsoftazure)
![License](https://img.shields.io/badge/license-MIT-green)

End-to-end deployment of Microsoft Intune (Endpoint Manager) for centralized device management, application lockdown, and security policy enforcement across Windows 10/11 devices in a cloud-managed environment.

> Designed for organizations requiring centralized device control, restricted application access, and compliance monitoring via Microsoft 365 and Entra ID.

---

## Project Overview

This project documents the design and implementation of a Microsoft Intune environment for a multi-device Windows organization (SMB, India, 2026). The goal was to create a locked-down, standardized workstation environment where employees could only access approved applications and websites, while preventing data exfiltration and unauthorized system changes.

![Email Authentication Flow](diagrams/microsoft-intune-endpoint-manager.png)

**Environment scale:** 14 enrolled devices across ASUS, HP, Dell, and Lenovo hardware — all compliant at project completion.

---

## Environment

| Component | Details |
|---|---|
| Identity Platform | Microsoft 365 / Entra ID (Azure AD) |
| Device Management | Microsoft Intune / Endpoint Manager |
| Operating Systems | Windows 10 / Windows 11 Pro |
| Enrollment Method | Azure AD Join + Automatic Intune Enrollment |
| Remote Access | Tailscale + RDP (secure, no open firewall ports) |
| Hardware | ASUS ExpertCenter, HP All-in-One, Dell Latitude, Lenovo |

---

## Deployment Phases

### Phase 1 — Environment Audit & Validation

Ran a one-click PowerShell audit (`M365_Intune_Entra_Audit.ps1`) to baseline the tenant before any changes:

- 17 users, all licensed
- 15 Entra-registered devices identified
- 14 Intune-managed devices confirmed enrolled
- All 14 devices returned **Compliant** status at audit time
- Generated structured HTML audit report with executive summary, license table, device inventory, and recommended next steps

### Phase 2 — Secure Remote Access

Configured Tailscale for secure remote connectivity:

- Tailscale deployed on client machines
- Encrypted mesh VPN — no firewall ports opened
- RDP over Tailscale used for all remote configuration sessions
- Alternative: Teams screen-share for sessions requiring client visibility

### Phase 3 — Device Enrollment Configuration

- Windows automatic enrollment configured in Intune
- Azure AD Join validated across all target devices
- Device ownership set to Company-owned
- Enrollment permissions scoped and validated
- Pilot device tested before broad rollout

### Phase 4 — Device Restriction Policies

The following restrictions were configured, tested on a pilot VM, and validated before production push:

| Restriction | Policy Type | Status |
|---|---|---|
| Block Control Panel | Configuration Profile | ✅ Deployed |
| Block Settings app | Configuration Profile | ✅ Deployed |
| Block Command Prompt | Configuration Profile | ✅ Deployed |
| Block Registry Editor | Configuration Profile | ✅ Deployed |
| Block Microsoft Store | Configuration Profile | ✅ Deployed |
| Removable storage restriction | Configuration Profile | ✅ Deployed |
| Edge browser restrictions | Configuration Profile | ✅ Deployed |
| Edge startup/home page control | Configuration Profile | ✅ Deployed |

### Phase 5 — Application Control (In Progress)

Approved application allow-list for endpoint lockdown:

- RingCentral
- TeamViewer
- Crisp
- Time Doctor

Copy/paste restrictions from approved apps to external destinations configured via DLP policies to prevent data exfiltration.

Recommended consumer app removal from Windows 11 baseline:
- Xbox
- Solitaire / Casual Games
- LinkedIn

### Phase 6 — Compliance Policies

- Device compliance monitoring enabled and reporting validated
- Policy sync and check-in intervals configured
- Non-compliant device alerting in place
- All 14 enrolled devices returned compliant at last audit

---

## Audit Script

`M365_Intune_Entra_Audit.ps1` — one-click Microsoft 365 / Entra / Intune audit tool that produces a structured HTML report.

**What it collects:**

- Tenant info and connected account
- License inventory (SKU, consumed vs available)
- All user accounts with license assignment status
- Entra-registered devices (manufacturer, model, OS version)
- Intune-managed devices (compliance state, enrollment date, last sync)
- Executive summary with counts
- Recommended next steps

**Usage:**

```powershell
# Basic run — outputs to default folder
.\M365_Intune_Entra_Audit.ps1

# Custom output path
.\M365_Intune_Entra_Audit.ps1 -OutputRoot "C:\Audits\Client"

# Skip module install (if modules already present)
.\M365_Intune_Entra_Audit.ps1 -SkipModuleInstall
```

**Required modules** (auto-installed if not present):
- `Microsoft.Graph`
- `Microsoft.Graph.Intune`

**Example report output:**

| Field | Value |
|---|---|
| Total Users | 17 |
| Licensed Users | 17 |
| Total Entra Devices | 15 |
| Intune Managed Devices | 14 |
| Compliant Devices | 14 |
| Non-Compliant Devices | 0 |

---

## Repository Structure

| Path | Description |
|---|---|
| `audit/M365_Intune_Entra_Audit.ps1` | One-click M365/Entra/Intune audit script |
| `docs/project-outline.md` | Phase-by-phase project outline |
| `docs/device-enrollment.md` | Device enrollment configuration guide |
| `docs/device-restrictions.md` | Restriction policy configuration reference |
| `docs/application-control.md` | Application allow-list and lockdown guide |
| `docs/compliance-policies.md` | Compliance policy configuration reference |
| `reports/` | Sample HTML audit report output |
| `diagrams/` | Architecture and enrollment flow diagrams |

---

## Typical Consulting Use Cases

| Scenario | Artifacts Used |
|---|---|
| Baseline a new Intune tenant before policy rollout | `M365_Intune_Entra_Audit.ps1` |
| Lock down devices to approved apps only | `docs/application-control.md` |
| Restrict system access for non-admin users | `docs/device-restrictions.md` |
| Verify all devices are enrolled and compliant | Audit script + HTML report |
| Secure remote configuration without opening firewall | Tailscale + RDP pattern (see `docs/`) |

---

## Prerequisites

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| Microsoft 365 Role | Global Admin or Intune Administrator |
| Licenses | Microsoft 365 Business Premium or Intune standalone |
| Modules | `Microsoft.Graph` (auto-installed by audit script) |

---

## License

[MIT](LICENSE) — free to use, adapt, and share.

---

## Author

**Suresh Chand** — Director of IT | Enterprise Infrastructure & Security Engineer  
📍 San Jose, CA &nbsp;|&nbsp; 📧 [suresh@echand.com](mailto:suresh@echand.com) &nbsp;|&nbsp; 💼 [LinkedIn](https://linkedin.com/in/sureshchand01) &nbsp;|&nbsp; 🐙 [GitHub](https://github.com/suresh-1001)
