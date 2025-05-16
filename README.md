# 🔄 NinjaOne Device Location Mover

Automate the transition of devices from temporary onboarding locations to their designated operational location (“Main Office”) within NinjaOne — securely, efficiently, and with zero manual clicks.

---

## 📌 What the Project Does

This PowerShell script is designed to run as an **automation task in NinjaOne**, performing the following steps:

1. **Authenticate** to the NinjaOne API using ClientID and Secret.
2. **Identify the current device** based on hostname or IP.
3. **Find the current and target locations** within the same organization.
4. **Move the device** from the onboarding location to the desired target location (`Main Office` by default).

---

## 💡 Problem it Solves

IT teams often register new devices in a temporary or onboarding location. Moving these devices manually to their operational site is tedious and error-prone.

This script eliminates that need by:
- Automatically detecting the device context
- Resolving matching location names via wildcard patterns
- Executing the location update securely via API

---

## 🎯 Who it Helps

| Role                     | Benefit                                                    |
|--------------------------|-------------------------------------------------------------|
| IT Admins / MSPs         | Automate device lifecycle workflows                         |
| Deployment Engineers     | Streamline onboarding scripts                               |
| Asset Management Teams   | Ensure consistent and accurate location metadata in NinjaOne |

---

## 🔐 Secure Custom Fields in NinjaOne

The script makes use of **Secure Global Custom Fields** in NinjaOne for API authentication:

- `NinjaOneAPIClientID` – Public client identifier (type: string)
- `NinjaOneAPISecret` – Secret value (type: **Secure Field**)

### ✅ Why use Secure Custom Fields?
Secure Custom Fields in NinjaOne:
- Are **encrypted at rest**
- Only injected **at runtime**
- **Never displayed** in logs or script output

This ensures secrets are not exposed in the RMM interface, improving overall API security posture.

### 🧪 Built-in validation
The script checks:
- If the secret is retrieved as a `SecureString`
- If the length exceeds NinjaOne’s 200-character limit (as per documentation)

---

## 🔑 Key API Endpoints Used

| Endpoint                       | Purpose                             |
|-------------------------------|-------------------------------------|
| `POST /v2/token`              | OAuth 2.0 authentication            |
| `GET /v2/devices`             | Locate the current running device   |
| `GET /v2/organization/{id}/locations` | List all locations within the org |
| `PATCH /v2/device/{id}`       | Update the device's location        |

---

## 💻 Example Parameters in NinjaOne Automation

| Parameter                  | Example            | Description                           |
|---------------------------|--------------------|---------------------------------------|
| `OnboardingLocationPattern` | `*test*`           | Wildcard match for the old location   |
| `TargetLocationPattern`     | `*main*office*`    | Wildcard match for the target location|

These can be customized when running the script as part of a policy.

---

## 📎 Code Snippet

```powershell
# Move the device
$result = Move-DeviceToTargetLocation `
    -AccessToken $accessToken `
    -DeviceId $currentDevice.id `
    -CurrentLocationId $currentDevice.locationId `
    -TargetLocationId $locations.targetLocation.id

if ($result) {
    Write-Output "SUCCESS: Device successfully moved."
}
```

---

## 🧑‍💻 Author

Robert van Oorschot – [Advance Your IT]
🇳🇱 NinjaOne enthusiast

---
