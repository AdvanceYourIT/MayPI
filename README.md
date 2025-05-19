# 🏢 NinjaOne Device Location Automator

Automated PowerShell script to detect and move a device from an onboarding location to its main operational location using the NinjaOne Public API. Ideal for MSPs and IT teams who want clean, scalable onboarding workflows.

---

## 🔧 What the project does

This script securely connects to the NinjaOne Public API, identifies the current device it’s running on, checks its location, and moves it to the target location ("Main Office") within the same organization. It uses wildcard pattern matching to detect onboarding and destination locations.

---

## ❗ The problem it solves

Many environments onboard new devices into temporary locations. If not moved manually, this leads to:
- Automation misfires
- Incorrect asset tagging
- Manual clean-up work

This script ensures every endpoint ends up in the correct place — automatically.

![Screenshot](https://github.com/user-attachments/assets/7ab9ef02-c8e3-4857-bd44-faa9d228a92a)


---

## 👥 Who it helps

| Role/Team                   | Benefit                                                 |
|----------------------------|----------------------------------------------------------|
| IT Administrators          | Automatically move devices post-onboarding              |
| MSP Onboarding Teams       | Reduce manual cleanup after provisioning                |
| Asset Management/Compliance| Maintain proper device-to-location assignment            |
| Security Teams             | Ensure devices end up in the correct automation scopes   |

---

## 🔑 Key API endpoints used

| Endpoint                                | Purpose                                            |
|-----------------------------------------|----------------------------------------------------|
| `POST /v2/token`                        | Authenticate via OAuth2 with Client ID/Secret     |
| `GET /v2/devices`                       | Detect current device via hostname or IP          |
| `GET /v2/organization/{id}/locations`   | Retrieve all locations for the device's org       |
| `PATCH /v2/device/{id}`                 | Update device to new location                     |

---

## 🔐 Secure Custom Field Handling

This script uses NinjaOne's Secure Global Custom Fields:
- `NinjaOneAPIClientID` — normal string field
- `NinjaOneAPISecret` — stored as a Secure Field

Safe handling is implemented:
```powershell
if ($clientSecretSecure -is [System.Security.SecureString]) {
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecretSecure)
    $clientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)

    if ($clientSecret.Length -gt 200) {
        throw "Custom Field NinjaOneAPISecret exceeds 200-character limit."
    }
}
```

---

## ▶️ Usage

This script is intended to be executed inside a NinjaOne Automation Policy.

```powershell
param (
    [string]$OnboardingLocationPattern = "*onboard*",
    [string]$TargetLocationPattern = "*main*office*"
)
```

✔ Securely authenticates using global fields  
✔ Automatically checks device location and org  
✔ Only moves device if location mismatch is detected  

---

## 👨‍💻 Author

Robert van Oorschot  
Advance Your IT
🇳🇱 NinjaOne Automation Enthousiast

---
