# Define the path to the file
$filePath = "C:\TEMP\java_uninstall.log"

# Check if the file exists
if (Test-Path $filePath) {
    # Remove the file
    Remove-Item $filePath -Force
    Write-Output "File removed successfully."
} else {
    Write-Output "File not found."
}
