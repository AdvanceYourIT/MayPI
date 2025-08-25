# 🖥️ NinjaOne Device Location Automator

_A regular topic in `#api` – so this one had to be tackled!_

## 🚀 What the project does
This PowerShell script automates the relocation of devices in NinjaOne. It checks whether a device is located in a specified onboarding location and whether the custom field `OnboardingDone` is set to `true`. If both conditions are satisfied, the device is moved to a specified target location within the same organization.

## 🧠 The problem it solves
IT teams often onboard devices to a temporary location such as `"Onboarding"`, but forget to update the location after setup is complete. This leads to:

- ❌ Incorrect policy assignment
- 📉 Inaccurate reporting
- 🗂️ Cluttered inventory

By automating the move process, this script ensures device location data remains accurate and clean — saving time and reducing errors.

## 👥 Who it helps
- 👨‍💻 **IT Administrators**: Eliminates manual post-onboarding tasks
- 🛠️ **MSPs**: Maintains accurate inventories across multiple clients
- 🤖 **Automation teams**: Seamlessly integrates with NinjaOne automation flows

## 🔑 Key API endpoints used
| Endpoint | Purpose |
|----------|---------|
| `POST /ws/oauth/token` | Authenticate using client credentials from custom fields |
| `GET /api/v2/devices?expand=location,organization` | Retrieve all devices with location and org details |
| `GET /api/v2/device/{deviceId}/custom-fields` | Read the `OnboardingDone` field |
| `GET /api/v2/organization/{orgId}/locations` | Get available locations for a given org |
| `PATCH /api/v2/device/{deviceId}` | Move the device to a new location |

## ⚙️ Script Variables
Create the following **Script Variables** in NinjaOne (type: `String/Text`):

- `homelocation` – default: `"Onboarding"`
- `targetlocation` – default: `"Main Office"`

These are injected at runtime via `$env:homelocation` and `$env:targetlocation` and can be set per policy or left at default.

## 🛡️ Custom Fields
This script uses secure authentication and custom fields based on the [Getting Started guide by Luke Whitelock](https://docs.mspp.io/ninjaone/getting-started):

- 🔐 `NinjaOneAPIClientID`
- 🔐 `NinjaOneAPISecret`
- ✅ `OnboardingDone` (checkbox)

> To set `OnboardingDone` to true from another automation:
```powershell
Ninja-Property-Set onboardingdone 1
```

## 🧪 Example usage
This script is intended for use in a NinjaOne **automation policy**. Devices in the `"Onboarding"` location with `OnboardingDone = true` will be automatically moved to `"Main Office"` within the same organization.

📝 Author: Robert van Oorschot – Advance Your IT
📅 Date: 2025-05-26
🏷️ Version: 2.0.0
