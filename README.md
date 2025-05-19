# 🏢 NinjaOne Device Location Automator

PowerShell script for automating the relocation of devices in NinjaOne from an onboarding location to a main office using the public API.

---

## 🔧 What the project does

The `MoveDeviceToMainOffice.ps1` script is a PowerShell automation for NinjaOne that moves devices from a home location (e.g., an onboarding site) to a target location (e.g., a main office) within the same organization. It authenticates with the NinjaOne API using client credentials stored in Custom Fields, identifies the current device, retrieves the organization’s locations, and updates the device's location. 

The script uses environment variables (`$env:homelocation` and `$env:targetlocation`) to dynamically set location patterns, with fallback defaults (`*onboarding*` and `*main*office*`), making it flexible and easy to configure within NinjaOne.

---

## ❗ The problem it solves

In NinjaOne, devices are often placed in a temporary onboarding location during setup, requiring manual relocation to their final destination (e.g., "Main Office"). This manual process is time-consuming and error-prone, especially for organizations managing large numbers of devices.

The script automates this relocation, eliminating manual effort, reducing errors, and ensuring consistency. By leveraging environment variables, it allows IT teams to customize location patterns dynamically without altering the script, enhancing adaptability for different organizational setups.

![Screenshot](https://github.com/user-attachments/assets/6e0f5bc2-378c-4552-b847-8ceab8a49264)

---

## 👥 Who it helps

This project benefits IT administrators and system engineers managing device onboarding in NinjaOne, particularly within IT operations teams at small to medium-sized businesses or managed service providers (MSPs). 

It streamlines device management workflows, allowing these teams to focus on higher-priority tasks instead of repetitive manual processes.

---

## 🔑 Key API endpoints used

The script interacts with the NinjaOne API (version 2) to perform its operations. The key endpoints used are:

- `POST /ws/oauth/token`: Authenticates and obtains an OAuth access token using client credentials.
- `GET /api/v2/devices`: Retrieves a list of devices to identify the current device, supporting pagination with query parameters `pageSize` and `after`.
- `GET /api/v2/organization/{organizationId}/locations`: Fetches all locations for a given organization to find the home and target locations.
- `PATCH /api/v2/device/{deviceId}`: Updates the device’s location by setting a new `locationId` in the request body.

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
}
```

> 🔄 Note: As of recent updates, Secure Custom Fields in NinjaOne support up to 65,535 characters, removing the previous 200-character limitation.

---

## ▶️ Usage

This script is intended to be executed inside a NinjaOne Automation Policy.

```powershell
param (
    [string]$OnboardingLocationPattern = $env:homelocation  # e.g., "*staging*"
    [string]$TargetLocationPattern = $env:targetlocation    # e.g., "*main*office*"
)
```

✔ Securely authenticates using global fields  
✔ Automatically checks device location and organization  
✔ Only moves device if current and target location differ  
✔ Supports dynamic environment variable-based configuration  

---

## 👨‍💻 Author

Robert van Oorschot  
Advance Your IT 
🇳🇱 NinjaOne Automation Enthousiast

---
