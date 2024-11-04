


# Define variables
$validValues = "Yes", "Y", "yes", "y", "No", "N", "n", "no"
$OwnershipType = 'company' # Set ownership type to 'company'



# Function to check if a module is installed
function Check-Module {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "`nModule $ModuleName is not installed. Please install it using 'Install-Module $ModuleName' and try again.`n" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "The required $ModuleName module is installed! Continuing script...`n" -ForegroundColor Green
    }
}

function Get-AuthToken {
    # Prompt for user credentials
    
    $GraphToken = Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome 2>&1
    
    if ($GraphToken -like "*failed*"){
        Write-Host "`nFailed to get authentication token. Exiting script. Error below:`n`n$GraphToken`n" -ForegroundColor Red
        exit 1
    }
    else {
        return $GraphToken
    }

    

}


Write-host "
            ******************************************************************************`n
            ******************************************************************************`n
            Welcome to the Intune `"Change Ownership`" script. This script will change the`n
            ownership of a device to `"Corporate`" in Intune.`n" -ForegroundColor Yellow
Write-Host "            
            CSV must include **INTUNE** Device IDs starting in Row 2.`n" -ForegroundColor Cyan

Write-Host "
            PLEASE NOTE: This is primary intended for Android devices as there is no check`n
            for supervised status.`n
            ******************************************************************************`n
            ******************************************************************************`n" -ForegroundColor Yellow

# Check if the required modules are installed
Write-Host "Checking for the required MS Graph Powershell modules...`n" -ForegroundColor Magenta

Check-Module -ModuleName "Microsoft.Graph.Authentication"
Check-Module -ModuleName "Microsoft.Graph.DeviceManagement"

# Import the required module
Import-Module Microsoft.Graph.Authentication

            # Prompt for the directory and file name of the CSV file
$CsvDirectory = Read-Host "Please enter the directory path for the CSV file" 
$CsvFileName = Read-Host "`nPlease enter the file name of the CSV file" 
$CsvFilePath = Join-Path -Path $CsvDirectory -ChildPath $CsvFileName

# Check if the CSV file exists
if (-not (Test-Path -Path $CsvFilePath)) {
    Write-Host "`nCSV file not found at $CsvFilePath. Exiting script. Please check the file path and try again.`n" -ForegroundColor Red
    exit 1
}

Write-Host "`nAttempting to authenticate with Graph API..." -ForegroundColor Magenta

# Sign in and get the authentication token
Get-AuthToken

# Read the CSV file
$Devices = Import-Csv -Path $CsvFilePath

# Count the number of devices
$LineCount = (Get-Content -Path $CsvFilePath).Count
$DeviceCount = $LineCount - 1

# Confirm the user wants to proceed
Write-Host "`n`nNumber of devices in the CSV: $DeviceCount. `n`nThis script will change the ownership of all these devices. Would you like to proceed?" -ForegroundColor Yellow
Write-Host "[Y] Yes  [N] No" -ForegroundColor Cyan

$proceed = Read-Host

while (-not ($proceed -in $validValues)) {
    Write-Host "`nYour response needs to be `"Yes`", `"Y`", `"No`" or `"N`" (case-insensitive). Please enter it again:" -ForegroundColor Cyan
    $proceed = Read-Host
}

if ($proceed -like "y*") {
    foreach ($Device in $Devices) {
        $DeviceId = $Device.deviceId

        # Body
        $Body = @{
            'ManagedDeviceOwnerType' = $OwnershipType
        } | ConvertTo-Json

        # Update device ownership
        
        $transformOutput = Update-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceId -BodyParameter $Body 2>&1
        # write-host "$transformoutput" -ForegroundColor Green
        if ($transformOutput -like "*ErrorCode:*") {
            Write-Host "`nThere was an error modifying $DeviceId. Please check the device ID and try again." -ForegroundColor Red
        }

        else {
            Write-Host "`nSuccessfully updated device ownership for device ID: $DeviceId"  
        }
        
     
    }
} elseif ($proceed -like "n*") {
    Write-Host "`nNo devices will be updated. Exiting now...`n" -ForegroundColor Red
    exit 0
}

Disconnect-MgGraph
