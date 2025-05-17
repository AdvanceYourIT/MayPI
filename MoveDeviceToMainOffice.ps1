<#
.SYNOPSIS
    Moves the current device from a home location to a target location within the same organization in NinjaOne.

.DESCRIPTION
    This script is designed to be run as an automation in NinjaOne. It authenticates with the NinjaOne API using credentials stored in Custom Fields (NinjaOneAPIClientID and NinjaOneAPISecret),
    identifies the current device it's running on, finds the organization the device belongs to,
    locates both the specified home and target locations within that organization,
    and moves the device from the home location to the target location.

.EXAMPLE
    Run in NinjaOne as an automation script with parameters:
    - HomeLocation: "*test*"
    - TargetLocation: "*main*"
    Ensure NinjaOneAPIClientID and NinjaOneAPISecret are set in Global Custom Fields.

.INSTANCES
    "app.ninjarmm.com",
    "us2.ninjarmm.com",
    "eu.ninjarmm.com",
    "ca.ninjarmm.com",
    "oc.ninjarmm.com"

.PARAMETER HomeLocation
    The pattern to match the home location (e.g., "*test*"). Defaults to "*onboarding*".

.PARAMETER TargetLocation
    The pattern to match the target location (e.g., "*main*"). Defaults to "*main*office*".

.NOTES
    Author: Robert van Oorschot - Advance Your IT
    Date: 2025-05-17
    Version: 1.9.2
    Custom Fields Required: NinjaOneAPIClientID, NinjaOneAPISecret
    Note: NinjaOneAPISecret must be less than 200 characters.
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$HomeLocation = "*onboarding*",

    [Parameter(Mandatory=$false)]
    [string]$TargetLocation = "*main*office*"
)

# Hardcode instance URL
$Instance = "eu.ninjarmm.com"
$InstanceUrl = "https://$Instance"

# Function to get OAuth access token
function Get-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ClientId,
        
        [Parameter(Mandatory=$true)]
        [string]$ClientSecret
    )
    
    try {
        $Scope = "monitoring management offline_access"
        $InstanceUrlClean = $InstanceUrl -replace '/ws', ''

        $Body = @{
            grant_type    = 'client_credentials'
            client_id     = $ClientId
            client_secret = $ClientSecret
            scope         = $Scope
        }

        $token = Invoke-RestMethod -Uri "$InstanceUrlClean/ws/oauth/token" -Method Post -Body $Body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing -ErrorAction Stop
        
        if ($token.access_token) {
            return $token  # Return full token object
        } else {
            throw "No access token received in the response."
        }
    } catch {
        $StatusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.Value__ } else { "Unknown" }
        $ErrorMessage = $_.Exception.Message
        $ErrorContent = if ($_.Exception.Response -and $_.Exception.Response.Content) { $_.Exception.Response.Content.ReadAsStringAsync().Result } else { "No additional error content" }
        throw "Authentication failed: Status: $StatusCode, Message: $ErrorMessage, Details: $ErrorContent"
    }
}

# Function to call NinjaOne API
function Invoke-NinjaOneApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory=$true)]
        $AccessToken,
        
        [Parameter(Mandatory=$false)]
        [string]$Method = "GET",
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Body = $null,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$QueryParams = $null
    )
    
    try {
        if (-not $AccessToken -or -not $AccessToken.access_token) {
            throw "AccessToken is null or missing access_token."
        }
        
        # Clean and use access_token from the token object
        $cleanedToken = [string]$AccessToken.access_token
        $cleanedToken = [System.Text.RegularExpressions.Regex]::Replace($cleanedToken, "[\r\n]+", "")
        $cleanedToken = $cleanedToken.Trim()
        
        $headers = @{
            "Authorization" = "Bearer $cleanedToken"
            "Content-Type" = "application/json"
        }
        
        # Build URI with query parameters if provided
        $uri = "$InstanceUrl/api/v2/$Endpoint"
        if ($QueryParams) {
            $queryString = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
            $uri = "$uri`?$queryString"
        }
        
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $headers
            ErrorAction = "Stop"
        }
        
        if ($Body -and $Method -ne "GET") {
            $jsonBody = $Body | ConvertTo-Json -Depth 5
            $params.Add("Body", $jsonBody)
        }
        
        $response = Invoke-RestMethod @params -UseBasicParsing
        return $response
    } catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.Value__ } else { "Unknown" }
        $errorMessage = $_.Exception.Message
        $errorContent = if ($_.Exception.Response) {
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $reader.ReadToEnd()
            } catch {
                "Failed to read error content: $($_.Exception.Message)"
            }
        } else { "No additional error content" }
        throw "API call failed: $Method $Endpoint, Status: $statusCode, Message: $errorMessage, Details: $errorContent"
    }
}

# Function to get current device information
function Get-CurrentDevice {
    param (
        [Parameter(Mandatory=$true)]
        $AccessToken
    )
    
    try {
        if (-not $AccessToken -or -not $AccessToken.access_token) {
            throw "AccessToken is null or missing access_token."
        }
        
        # Get hostname of the current device
        $hostname = $env:COMPUTERNAME
        
        # Get all devices with pagination
        $queryParams = @{
            "pageSize" = 1000
            "after" = 0
        }
        $devices = Invoke-NinjaOneApi -Endpoint "devices" -AccessToken $AccessToken -QueryParams $queryParams
        
        if (-not $devices -or $devices.Count -eq 0) {
            throw "No devices found in the NinjaOne instance."
        }
        
        # Try to find device by hostname
        $currentDevice = $null
        $currentDevice = $devices | Where-Object { $_.systemName -eq $hostname }
        
        # If not found by hostname, try by IP address
        if (-not $currentDevice) {
            try {
                $ipAddresses = @(Get-NetIPAddress -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress)
                
                foreach ($ip in $ipAddresses) {
                    $deviceByIp = $devices | Where-Object { 
                        $device = $_
                        if ($device.ipAddresses) {
                            $device.ipAddresses -contains $ip
                        } else {
                            $false
                        }
                    }
                    
                    if ($deviceByIp) {
                        $currentDevice = $deviceByIp
                        break
                    }
                }
            }
            catch {
            }
        }
        
        # Final check if device was found
        if (-not $currentDevice) {
            throw "Could not identify the current device in NinjaOne. Please ensure the device is enrolled."
        }
        
        return $currentDevice
    }
    catch {
        throw $_
    }
}

# Function to find locations within organization
function Get-OrganizationLocations {
    param (
        [Parameter(Mandatory=$true)]
        $AccessToken,
        
        [Parameter(Mandatory=$true)]
        [int]$OrganizationId,
        
        [Parameter(Mandatory=$true)]
        [string]$HomeLocation,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetLocation
    )
    
    try {
        if (-not $AccessToken -or -not $AccessToken.access_token) {
            throw "AccessToken is null or missing access_token."
        }
        
        # Get all locations for the organization
        $locations = Invoke-NinjaOneApi -Endpoint "organization/$OrganizationId/locations" -AccessToken $AccessToken
        
        if (-not $locations -or $locations.Count -eq 0) {
            throw "No locations found for organization ID: $OrganizationId"
        }
        
        # Find home location
        $homeLocationObj = $locations | Where-Object { $_.name -like $HomeLocation } | Select-Object -First 1
        
        if (-not $homeLocationObj) {
            throw "Could not find home location matching pattern: $HomeLocation"
        }
        
        # Find target location
        $targetLocationObj = $locations | Where-Object { $_.name -like $TargetLocation } | Select-Object -First 1
        
        if (-not $targetLocationObj) {
            throw "Could not find target location matching pattern: $TargetLocation"
        }
        
        return @{
            homeLocation = $homeLocationObj
            targetLocation = $targetLocationObj
        }
    } catch {
        throw $_
    }
}

# Function to move device to target location
function Move-DeviceToTargetLocation {
    param (
        [Parameter(Mandatory=$true)]
        $AccessToken,
        
        [Parameter(Mandatory=$true)]
        [int]$DeviceId,
        
        [Parameter(Mandatory=$true)]
        [int]$CurrentLocationId,
        
        [Parameter(Mandatory=$true)]
        [int]$TargetLocationId
    )
    
    try {
        if (-not $AccessToken -or -not $AccessToken.access_token) {
            throw "AccessToken is null or missing access_token."
        }
        
        # Check if device is already in the target location
        if ($CurrentLocationId -eq $TargetLocationId) {
            return $true
        }
        
        # Prepare request body
        $body = @{
            "locationId" = $TargetLocationId
        }
        
        # Call API to move device
        $result = Invoke-NinjaOneApi -Endpoint "device/$DeviceId" -AccessToken $AccessToken -Method "PATCH" -Body $body
        
        return $true
    } catch {
        throw $_
    }
}

# Main execution flow
try {
    # Fetch ClientId and ClientSecret directly
    $clientId = Ninja-Property-Get "NinjaOneAPIClientID"
    if (-not $clientId) {
        throw "Custom Field NinjaOneAPIClientID not found or has no value."
    }

    $clientSecretSecure = Ninja-Property-Get "NinjaOneAPISecret"
    if (-not $clientSecretSecure) {
        throw "Custom Field NinjaOneAPISecret not found or has no value."
    }
    
    # Check if ClientSecret is a SecureString and convert if necessary
    if ($clientSecretSecure -is [System.Security.SecureString]) {
        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecretSecure)
        $clientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
        
        # Validate length (max 200 characters for secure fields)
        if ($clientSecret.Length -gt 200) {
            throw "Custom Field NinjaOneAPISecret exceeds 200-character limit (length: $($clientSecret.Length))."
        }
    } else {
        $clientSecret = $clientSecretSecure.ToString()
        if ($clientSecret.Length -gt 200) {
            throw "Custom Field NinjaOneAPISecret exceeds 200-character limit (length: $($clientSecret.Length))."
        }
    }
    
    # Get access token
    $accessToken = Get-AccessToken -ClientId $clientId -ClientSecret $clientSecret
    if (-not $accessToken -or -not $accessToken.access_token) {
        throw "Failed to retrieve access token."
    }
    
    # Get current device
    $currentDevice = Get-CurrentDevice -AccessToken $accessToken
    
    # Get organization locations
    $locations = Get-OrganizationLocations -AccessToken $accessToken -OrganizationId $currentDevice.organizationId -HomeLocation $HomeLocation -TargetLocation $TargetLocation
    
    # Move device
    $result = Move-DeviceToTargetLocation -AccessToken $accessToken -DeviceId $currentDevice.id -CurrentLocationId $currentDevice.locationId -TargetLocationId $locations.targetLocation.id
    
    if ($result) {
        Write-Output "SUCCESS: Device successfully moved from $($locations.homeLocation.name) to $($locations.targetLocation.name)."
        exit 0
    } else {
        Write-Error "FAILURE: Device move operation did not complete successfully."
        exit 1
    }
} catch {
    Write-Error "FAILURE: $($_.Exception.Message)"
    exit 1
}
