########
##
## Script to detect instances of Oracle Java and then remove them.
##
## Script has transcription as detection method for the "installation" of this script
## as an app in Company Portal. This is intended to use as a way for users to delete
## the apps themselves. Transcribe file will need to be removed for the app to be "uninstalled" 
## and the user be able to run it again.
##
## You can remove the transcription if desired for a remediation.
##
#########

# Transcript path set to allow for collecting diagnostics from Intune device page

$TranscriptPath = "C:\TEMP"

# Make sure to update the log name!

$TranscriptName = "java_uninstall.log"
new-item $TranscriptPath -ItemType Directory -Force

# stopping orphaned transcripts

try
{
    stop-transcript|out-null
}
  catch [System.InvalidOperationException]
{}

Start-Transcript -Path $TranscriptPath\$TranscriptName -Append



# Defined versions of Oracle Java to target for uninstallation. NOTE: This is a greater than/less than 
# lookup, meaning the min need to be the last free OLC or NFTC version

$versionRanges = @(
    @{ Min = [version]"1.5.0.220"; Max = [version]"2.0.0" },
    @{ Min = [version]"6.0.450"; Max = [version]"7.0.0" }, 
    @{ Min = [version]"7.0.800"; Max = [version]"8.0.0" }, 
    @{ Min = [version]"8.0.2020.8"; Max = [version]"9.0.0" },
    @{ Min = [version]"11.0.0"; Max = [version]"17.0.0.0" },
    @{ Min = [version]"17.0.12.0"; Max = [version]"18.0.0" }

)

# Function to determine if the software is in the range of licensed
# versions to be uninstalled.

function IsVersionInRange($version) {
    foreach ($range in $versionRanges) {
        if ($version -gt $range.Min -and $version -lt $range.Max) {
            return $true
        }
    }
    return $false
}


# Get the list of installed applications from the registry
$installedApps = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
$installedApps += Get-ItemProperty -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue

# Filter the applications to find those with "Java" or "Oracle" in their display name or "Oracle" as their publisher
$appsToUninstall = $installedApps | Where-Object { $_.DisplayName -match "Java|Oracle" -or $_.Publisher -match "Oracle" }


# Check if there are any applications to uninstall
if ($appsToUninstall.Count -eq 0) {
    Write-Host "No applications to uninstall."
} 

else {
    # Uninstall each application found using the MSI product code
    foreach ($app in $appsToUninstall) {

        # display the versions found

        $version = [version]$app.DisplayVersion
        $name = $app.DisplayName
        Write-Host "`nFound! Name: $name Version: $version`n"
        
        # This next section will uninstall application if version is found in range. Will also uninstall Java Auto Updater
        # If you wish for it to remove all Oracle java versions, replace the "if" statement with the below.
        #
        # if ($app.PSChildName -match "^\{.*\}$" -or $name -match "Java Auto Updater") {
        #

        if ($app.PSChildName -match "^\{.*\}$" -and ((IsVersionInRange $version) -or ($name -match "Java Auto Updater"))) {
                    
          
            $productCode = $app.PSChildName
            Write-Host "Uninstalling $($app.DisplayName) with product code $productCode"
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /quiet /norestart" -NoNewWindow -Wait

            # Verify uninstallation
            $uninstalledApp = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$productCode" -ErrorAction SilentlyContinue
            $uninstalledApp += Get-ItemProperty -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$productCode" -ErrorAction SilentlyContinue

            if (-not $uninstalledApp) {
                Write-Host "$($app.DisplayName) has been successfully uninstalled.`n"
                
            } else {
                Write-Host "Failed to uninstall $($app.DisplayName)."
                
            }
        }

        else {
            Write-Host "Instance `"$name`" does not need to be removed.`n"    
        }
    }
    
}


Stop-Transcript

