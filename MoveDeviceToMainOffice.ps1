<#
.SYNOPSIS
    Moves devices from a home location to a target location across all organizations in NinjaOne if the device is located in the specified HomeLocation and has the OnboardingDone field set to true.

.DESCRIPTION
    This script is intended to be run as an automation in NinjaOne. It authenticates using the NinjaOne API via ClientId and ClientSecret retrieved from secure custom fields on the device. 
    It retrieves all devices along with their location and organization details, checks if the device is in the specified HomeLocation (by name), and verifies whether the custom field 
    "OnboardingDone" is set to true. If both conditions are met, the device is moved to the specified TargetLocation (also by name) within the same organization.

.EXAMPLE
    Run in NinjaOne as an automation script with Script Variables:
    - homelocation: "Onboarding" (optional, defaults to "Onboarding" if not set)
    - targetlocation: "Main Office" (optional, defaults to "Main Office" if not set)

.INSTANCES
    Replace your $Instance with one of the hardcoded samples.
    "app.ninjarmm.com",
    "us2.ninjarmm.com",
    "eu.ninjarmm.com",
    "ca.ninjarmm.com",
    "oc.ninjarmm.com"

.SCRIPT VARIABLES
    Create 2 Script Variables of [String/Text] and give them the following names:
    - homelocation
    - targetlocation
    In my own script, I gave them default values of "Onboarding" and "Main Office", they are called upon with the $HomeLocation and $TargetLocation parameters. You can hardcode these or leave the defaults 

.NOTES
    Author: Robert van Oorschot - Advance Your IT
    Date: 2025-05-26
    Version: 2.0.0 - Simplified version without logging or error handling, using name-based location matching and OnboardingDone field check.
    Script Variables (Optional): homelocation (defaults to "Onboarding"), targetlocation (defaults to "Main Office")
#>

# Config
$Instance = "eu.ninjarmm.com"
$InstanceUrl = "https://$Instance"
$ClientId = Ninja-Property-Get "NinjaOneAPIClientID"
$ClientSecret = Ninja-Property-Get "NinjaOneAPISecret"
$HomeLocation = $env:homelocation
$TargetLocation = $env:targetlocation

# Get access token
$TokenResponse = Invoke-RestMethod -Method Post -Uri "$InstanceUrl/ws/oauth/token" -Body @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "monitoring management offline_access"
} -ContentType "application/x-www-form-urlencoded"
$AccessToken = $TokenResponse.access_token
$Headers = @{ Authorization = "Bearer $AccessToken" }

# Get all devices (including location and organization info)
$Devices = Invoke-RestMethod -Uri "$InstanceUrl/api/v2/devices?expand=location,organization&pageSize=1000" -Headers $Headers

# Loop through all devices
foreach ($device in $Devices) {
    # Validate required fields and check if device is in HomeLocation
    if (-not $device.id -or -not $device.references.location -or -not $device.references.organization -or $device.references.location.name.Trim().ToLower() -ne $HomeLocation.ToLower()) { 
        continue 
    }

    # Get custom fields
    $CustomFields = Invoke-RestMethod -Uri "$InstanceUrl/api/v2/device/$($device.id)/custom-fields" -Headers $Headers

    # Check if OnboardingDone is true
    if ([bool]$CustomFields.OnboardingDone) {
        # Get locations for the organization
        $Locations = Invoke-RestMethod -Uri "$InstanceUrl/api/v2/organization/$($device.references.organization.id)/locations" -Headers $Headers

        # Move device if target location exists and differs from current
        $targetId = ($Locations | Where-Object { $_.name.Trim().ToLower() -eq $TargetLocation.ToLower() }).id
        if ($targetId -and $targetId -ne $device.locationId) {
            # Move device with explicit Content-Type for JSON
            Invoke-RestMethod -Method Patch -Uri "$InstanceUrl/api/v2/device/$($device.id)" -Headers $Headers -Body (@{ locationId = $targetId } | ConvertTo-Json) -ContentType "application/json"
        }
    }
}
