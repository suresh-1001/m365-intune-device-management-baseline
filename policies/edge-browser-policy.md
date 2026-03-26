# Policy Reference — Microsoft Edge Browser

Full settings reference for the Microsoft Edge Configuration Profile deployed via Intune.

---

## Profile Details

| Field | Value |
|---|---|
| Profile name | Edge Browser Restrictions — Baseline |
| Platform | Windows 10 and later |
| Profile type | Settings Catalog |
| Assignment | All enrolled devices |

---

## URL Control Settings

### Allowed URLs (URLAllowList)

Only the URLs listed here are accessible. All others are blocked by the URLBlockList wildcard.

```
# Customize this list per deployment

# Business applications
ringcentral.com
[*.]ringcentral.com
teamviewer.com
[*.]teamviewer.com
crisp.chat
[*.]crisp.chat
timedoctor.com
[*.]timedoctor.com

# Microsoft 365 authentication and services
login.microsoftonline.com
[*.]login.microsoftonline.com
outlook.office.com
[*.]office.com
[*.]microsoft.com

# Windows Update (required for OS patches)
[*.]windowsupdate.com
[*.]update.microsoft.com
```

### Blocked URLs (URLBlockList)

```
*
```

Setting URLBlockList to `*` blocks all URLs by default. URLAllowList entries override this — so only explicitly allowed URLs are reachable.

> ⚠️ Test thoroughly before deploying. Overly restrictive URL blocking can break Windows Update, licensing activation, and app sign-in flows.

---

## Startup & Homepage Settings

| Setting | Value | Notes |
|---|---|---|
| Action on startup | Open a list of URLs | Set to approved landing page |
| URLs to open on startup | `https://[approved-url]` | Customize per client |
| Configure the home button | Show home button, set to specific URL | |
| Home button URL | `https://[approved-url]` | |
| Set new tab page URL | `https://[approved-url]` | |
| Allow users to change the new tab page | Disabled | Prevents users reverting settings |
| Allow users to change startup settings | Disabled | |

---

## Security & Privacy Settings

| Setting | Value |
|---|---|
| InPrivate mode availability | InPrivate mode disabled |
| Allow or block developer tools | Block developer tools |
| Enable Guest mode | Disabled |
| Configure the list of types that are excluded from synchronization | Passwords, History, Extensions |
| Block access to flags page (edge://flags) | Enabled |
| Prevent users from bypassing Microsoft Defender SmartScreen warnings | Enabled |
| Enable Microsoft Defender SmartScreen | Enabled |

---

## Extensions Settings

| Setting | Value |
|---|---|
| Control which extensions cannot be installed | * (block all) |
| Allow specific extensions to be installed | Leave blank (no exceptions) |
| Allow extension side-loading | Disabled |

---

## Sign-In Settings

| Setting | Value |
|---|---|
| Browser sign-in settings | Force users to sign-in to use the browser |
| Configure list of forced-signed-in profiles | Entra ID account |

Forcing sign-in with the Entra ID account enables:
- Consistent policy enforcement per user
- Browser history and activity tied to corporate identity
- Conditional Access evaluation at browser level

---

## OMA-URI Reference (For Manual Deployment)

If using custom OMA-URI instead of Settings Catalog:

| Setting | OMA-URI | Value |
|---|---|---|
| URLBlockList | `./Device/Vendor/MSFT/Policy/Config/Browser/PreventSmartScreenPromptOverride` | `<enabled/>` |
| Homepage | `./Device/Vendor/MSFT/Policy/Config/Browser/HomePages` | `<data id="HomePagesPrompt" value="https://[approved-url]"/>` |
| InPrivate | `./Device/Vendor/MSFT/Policy/Config/Browser/AllowInPrivate` | `0` |

> For most deployments, Settings Catalog is easier to configure and manage than raw OMA-URI.

