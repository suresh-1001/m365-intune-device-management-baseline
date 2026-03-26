# Deployment Phases

This document outlines the full deployment process from initial access through production rollout.

---

## Phase 1 — Environment Audit & Validation

**Goal:** Establish access, validate tenant readiness, and understand current device and licensing state before making any changes.

**Time estimate:** 1–2 hours

### Step 1 — Confirm Access & Admin Roles

Log into the following portals and verify permissions:

| Portal | URL | Required Role |
|---|---|---|
| Microsoft 365 Admin Center | https://admin.microsoft.com | Global Admin or Intune Admin |
| Endpoint Manager (Intune) | https://endpoint.microsoft.com | Intune Administrator |
| Entra ID | https://entra.microsoft.com | Global Admin or Cloud Device Admin |

Verify you can access Users, Devices, and Endpoint Manager policies without permission errors.

> ⚠️ If permissions are missing, stop and request correct role assignment before proceeding. Do not attempt to work around insufficient access.

### Step 2 — Tenant Health & Licensing Check

- Confirm tenant is active with no alerts in Entra ID
- Review all users — count should match expected headcount
- Verify licenses include **Microsoft Intune** and **Azure AD Premium P1** at minimum
- Recommended license: **Microsoft 365 Business Premium** (includes Intune + Entra ID P1 + Defender)

> ⚠️ If licenses are insufficient, advise client before proceeding. Device compliance policies and Conditional Access require AAD P1 or higher.

### Step 3 — Device Visibility & Enrollment Status

Navigate to Endpoint Manager → Devices → All Devices and document:

- Total devices registered vs expected
- Azure AD Join status (Joined / Hybrid / Not joined)
- Current compliance status
- Last check-in timestamps

**Common starting states:**

| Finding | Meaning |
|---|---|
| No devices listed | Starting from scratch |
| Devices present, not compliant | Enrolled but no policies applied |
| Devices present and compliant | Pre-existing MDM setup — review before changing |

### Step 4 — Run Baseline Audit Script

Run `scripts/intune-audit.ps1` to generate a structured HTML report covering:
- Tenant summary
- License inventory
- All user accounts and license assignments
- Entra-registered devices
- Intune-managed devices and compliance state

See [scripts/intune-audit.ps1](../scripts/intune-audit.ps1) for usage.

### Phase 1 Deliverable

Send client a structured Phase 1 summary email covering:
- Admin access status
- Tenant health
- License adequacy
- Device enrollment state
- Recommended next steps

---

## Phase 2 — Secure Remote Access Setup

**Goal:** Establish a secure, repeatable remote access method for all configuration work.

**Recommended method:** Tailscale + RDP

### Tailscale Setup

1. Install Tailscale on the consultant machine: https://tailscale.com/download
2. Install Tailscale on one client device (pilot machine)
3. Both machines join the same Tailscale network (tailnet)
4. RDP from consultant machine to client device's Tailscale IP

**Why Tailscale:**
- No firewall ports opened on client network
- Encrypted peer-to-peer VPN
- Works through NAT without port forwarding
- RDP (port 3389) is never exposed to the public internet

**Alternative:** Teams screen-share session if client prefers visibility into all changes.

---

## Phase 3 — Device Enrollment Configuration

**Goal:** Ensure all target devices are enrolled in Intune and manageable before policies are applied.

### Tasks

1. Configure Windows automatic MDM enrollment in Entra ID
   - Entra ID → Mobility (MDM and MAM) → Microsoft Intune → set scope to All or a specific group
2. Define device enrollment restrictions
   - Limit to Windows devices only
   - Set ownership to Corporate
3. Create device groups in Entra ID for policy targeting
   - Example: `Intune-ManagedDevices-All`, `Intune-Pilot-Group`
4. Validate enrollment on pilot device
   - Sign in with Entra ID credentials
   - Confirm device appears in Intune within 5–10 minutes
   - Verify policy sync and compliance check-in

### Enrollment Validation Checklist

- [ ] Device appears in Endpoint Manager → Devices → All Devices
- [ ] Ownership shows as "Company"
- [ ] Management agent shows as "MDM"
- [ ] Last sync is recent
- [ ] No enrollment errors in device details

---

## Phase 4 — Device Restriction Policies

**Goal:** Apply configuration profiles to lock down device access to system settings and control browser behavior.

See [device-restrictions.md](device-restrictions.md) for full policy configuration details.

### Policies Deployed

| Policy | Profile Type | Target |
|---|---|---|
| Block Control Panel / Settings | Device Restrictions | All enrolled devices |
| Block Command Prompt | Device Restrictions | All enrolled devices |
| Block Registry Editor | Device Restrictions | All enrolled devices |
| Block Microsoft Store | Device Restrictions | All enrolled devices |
| Removable Storage Restriction | Device Restrictions | All enrolled devices |
| Edge Browser Restrictions | Administrative Templates | All enrolled devices |

### Deployment Process

1. Create each Configuration Profile in Endpoint Manager
2. Assign to `Intune-Pilot-Group` first
3. Validate on pilot device — confirm restrictions are active
4. Reassign to `Intune-ManagedDevices-All` for full rollout
5. Monitor for policy errors in Endpoint Manager → Devices → Monitor

---

## Phase 5 — Compliance Policies

**Goal:** Define what a compliant device looks like and enforce reporting.

See [compliance-policies.md](compliance-policies.md) for full configuration details.

### Compliance Requirements Configured

- BitLocker encryption enabled
- Microsoft Defender Antivirus enabled and up to date
- Windows Firewall enabled
- Minimum OS version enforced
- Device health attestation

### Non-Compliance Actions

| Timeframe | Action |
|---|---|
| Day 0 | Mark device non-compliant |
| Day 3 | Send email notification to user |
| Day 7 | Remotely lock device (optional, confirm with client) |

---

## Phase 6 — Application Control

**Goal:** Restrict devices to approved applications only.

See [application-control.md](application-control.md) for full configuration details.

### Approved Application Allow-List

| Application | Purpose |
|---|---|
| RingCentral | Business communications / VoIP |
| TeamViewer | Remote support |
| Crisp | Customer support chat |
| Time Doctor | Time tracking |
| Microsoft Edge | Managed browser (policy-controlled) |
| Microsoft 365 Apps | Core productivity (if licensed) |

### Consumer App Removal

Remove default Windows 11 consumer apps from managed devices:
- Xbox and Xbox Game Bar
- Solitaire / Casual Games collection
- LinkedIn

---

## Phase 7 — Production Rollout

**Goal:** Staged rollout from pilot to full deployment.

### Rollout Sequence

```
Pilot Device (1 machine)
        ↓ validate — 24 hours
Pilot Group (2–3 users)
        ↓ validate — 48 hours
Full Deployment (all devices)
        ↓ monitor — 1 week
Project Handover
```

### Go-Live Checklist

- [ ] All target devices enrolled and compliant
- [ ] Device restriction policies confirmed active
- [ ] Compliance policies reporting correctly
- [ ] Application allow-list tested on all approved apps
- [ ] Browser restrictions validated — approved URLs accessible
- [ ] Sent test email from managed device — DLP policy firing correctly
- [ ] Client walkthrough completed
- [ ] Admin documentation handed over

