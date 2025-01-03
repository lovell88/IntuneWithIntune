# This is a script to determine if any versions of Oracle's Java JRE exist on the system it is run on.

# Define the registry paths to search
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Initialize an array to store the results
$results = @()

# Define the offending version ranges to check. NOTE: This is a greater than/less than 
# lookup, meaning the min need to be the last free OLC or NFTC version
$versionRanges = @(
    @{ Min = [version]"1.5.0.220"; Max = [version]"2.0.0" },
    @{ Min = [version]"6.0.450"; Max = [version]"7.0.0" }, 
    @{ Min = [version]"7.0.800"; Max = [version]"8.0.0" }, 
    @{ Min = [version]"8.0.2020.8"; Max = [version]"9.0.0" },
    @{ Min = [version]"11.0.0"; Max = [version]"17.0.0" },
    @{ Min = [version]"17.0.12.0"; Max = [version]"18.0.0" }

)

# Function to check if a version is within any of the specified ranges
function IsVersionInRange($version) {
    foreach ($range in $versionRanges) {
        if ($version -gt $range.Min -and $version -lt $range.Max) {
            return $true
        }
    }
    return $false
}

# Loop through each registry path
foreach ($path in $registryPaths) {
    # Get all subkeys in the current path
    $subkeys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
    foreach ($subkey in $subkeys) {
        # Check if the DisplayName or Publisher matches the criteria
        if (($subkey.DisplayName -like "*java*") -or ($subkey.DisplayName -like "*J2SE*") -and ($subkey.DisplayName -notlike "*Java Auto Updater*")) {
            # Add the matching software to the results array
            $results += [PSCustomObject]@{
                DisplayName = $subkey.DisplayName
                Publisher   = $subkey.Publisher
                Version     = $subkey.DisplayVersion
                InstallDate = $subkey.InstallDate
            }
        }
    }
}

# Check if any results were found
if ($results.Count -eq 0) {
    Write-Host "No instances of Oracle Java found!"
    exit 0
} 

else {
    
    $instances = $results.Count
    $outputString = ""
    $instanceNumber = 1
    $results | ForEach-Object {
        $outputString += "**Instance${instanceNumber}**: DisplayName: $($_.DisplayName), Publisher: $($_.Publisher), DisplayVersion: $($_.Version), InstallDate: $($_.InstallDate) "
        $instanceNumber++
    }

    Write-Host "[$instances] instances of Oracle found: $outputString"

    foreach ($result in $results) {
        $version = [version]$result.Version
        if (IsVersionInRange $version -and $subkey.publisher -match "Oracle") {
                       
            exit 1
        }
    }

    
    exit 0
}







