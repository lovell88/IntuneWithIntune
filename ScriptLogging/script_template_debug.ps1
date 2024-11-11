# Transcript path set to allow for collecting diagnostics from Intune device page

$TranscriptPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

# Make sure to update the log name!

$TranscriptName = "<NAME>.log"
new-item $TranscriptPath -ItemType Directory -Force

# stopping orphaned transcripts

try
{
    stop-transcript|out-null
}
  catch [System.InvalidOperationException]
{}

Start-Transcript -Path $TranscriptPath\$TranscriptName -Append

### CODE HERE ####

Stop-Transcript
