# Architecture Overview

## High-Level Architecture

This deployment uses a cloud-only identity and device management model built entirely on Microsoft 365 and Entra ID — no on-premises Active Directory or SCCM/MECM required.

```
┌─────────────────────────────────────────────────────────┐
│                  Microsoft 365 Cloud                     │
│                                                         │
│   ┌─────────────┐        ┌──────────────────────┐      │
│   │  Entra ID   │◄──────►│  Microsoft Intune    │      │
│   │  (Azure AD) │        │  (Endpoint Manager)  │      │
│   └─────────────┘        └──────────────────────┘      │
│          │                         │                    │
│          │ Identity / Auth         │ Policy / MDM       │
│          ▼                         ▼                    │
└─────────────────────────────────────────────────────────┘
           │                         │
           ▼                         ▼
   ┌───────────────────────────────────────┐
   │         Windows 10/11 Devices         │
   │   (Azure AD Joined + Intune Enrolled) │
   │                                       │
   │  ASUS ExpertCenter  │  HP All-in-One  │
   │  Dell Latitude      │  Lenovo         │
   └───────────────────────────────────────┘
```

---

## Identity Layer — Entra ID (Azure AD)

All user identities and device registrations are managed in Microsoft Entra ID.

| Component | Role |
|---|---|
| User Accounts | Cloud-only accounts in Entra ID |
| Device Registration | Azure AD Join — devices are Entra-registered on first login |
| Conditional Access | Policy enforcement at sign-in |
| Groups | Used to scope Intune policy targets |

**Device Join Method:** Azure AD Join (no hybrid join, no on-prem domain)

When a user signs into a device with their Entra credentials, the device automatically joins Entra ID and triggers Intune enrollment — no manual MDM enrollment required.

---

## Device Management Layer — Microsoft Intune

Intune acts as the Mobile Device Management (MDM) authority for all enrolled Windows devices.

| Intune Component | Purpose |
|---|---|
| Configuration Profiles | Enforce device restrictions, browser settings, OS settings |
| Compliance Policies | Define what a "compliant" device looks like |
| App Control | Allow-list approved applications |
| Security Baselines | Microsoft-recommended hardening templates |
| Enrollment Restrictions | Limit enrollment to corporate Windows devices only |

---

## Remote Access Layer — Tailscale + RDP

All remote configuration was performed over Tailscale, a zero-config mesh VPN.

```
[Consultant Machine] ──── Tailscale VPN ──── [Client Device]
                                                    │
                                               RDP Session
                                                    │
                                          [Intune Config Work]
```

**Why Tailscale instead of opening firewall ports:**
- No inbound firewall rules required on client side
- Encrypted peer-to-peer connection
- Works across NAT without port forwarding
- No exposure of RDP (port 3389) to the public internet

---

## Policy Flow

```
Entra ID Group
     │
     ▼
Intune Policy Assignment
     │
     ├── Configuration Profile → Device Restrictions
     ├── Configuration Profile → Edge Browser Settings
     ├── Configuration Profile → Removable Storage
     ├── Compliance Policy     → BitLocker / AV / Firewall
     └── App Control Policy   → Approved App Allow-list
     │
     ▼
Device Check-in (every ~8 hours or on-demand)
     │
     ▼
Policy Applied → Compliance Status Reported → Dashboard
```

---

## Enrollment Flow

See [device-enrollment.md](device-enrollment.md) for the step-by-step enrollment process.

At a high level:

1. Device powers on and user signs in with Entra ID (Microsoft 365) credentials
2. Device joins Entra ID automatically
3. Intune MDM enrollment is triggered automatically via auto-enrollment policy
4. Intune pushes all assigned Configuration Profiles and Compliance Policies
5. Device reports compliance status back to Intune dashboard
6. Device is now fully managed

---

## Security Boundary Summary

| Layer | Control |
|---|---|
| Identity | Entra ID — MFA, Conditional Access |
| Device | Intune — Compliance, Restrictions, App Control |
| Data | DLP — Block copy/paste to external destinations |
| Browser | Edge — Managed startup, blocked sites, restricted settings |
| Storage | Removable media blocked via Configuration Profile |
| Remote Access | Tailscale VPN — no open firewall ports |

