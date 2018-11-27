###############################################################################################################
# Language     :  PowerShell 
# Filename     :  Ntp-Synch.ps1
# Description  :  To Avoid recurent NTP alerts 
###############################################################################################################

<#
    .SYNOPSIS
    This script synchronize the host time with the valeo ntp
    
    .Description
    
    Script Will Synchronize the time with NTP Server
    File_Log function will help to clear the log file content when it exceeds 25 Mb                 

    .EXAMPLE
     .\Ntp-Synch.ps1
#>


$ScriptVersion = '1.00'
$ScriptName   = 'NTP-Synch'
$Scriptpath = ""   #PROVIDE INPUT
$NtpLog = "\"      #PROVIDE INPUT

Function RunEXE
{
    param(
        [string]$Cmd="",
        [string]$Option="",
        [string]$WindowStyle="",
        [Boolean]$WARN=$True,
        [Boolean]$Wait=$True
    )

    $cmdLine = new-Object System.Diagnostics.Process
    $cmdLine.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $cmdLine.StartInfo.WindowStyle=$WindowStyle
    $cmdLine.StartInfo.FileName=$Cmd
    $cmdLine.StartInfo.Arguments=$Option
    $cmdLine.StartInfo.UseShellExecute = $false
    $cmdLine.StartInfo.RedirectStandardOutput =$true
    $cmdLine.StartInfo.RedirectStandardError = $true
    $cmdLine.Start() | Out-Null


    if (!$?)  
    {
        Write-Host "Could not Run $Cmd : $Cmd $Option" -foregroundcolor red
	    Stop-Transcript | Out-Null
        Exit 1
    }
    Else 
    {
        if ($Wait)
        {
            $cmdLine.WaitForExit()
            $stdout = $cmdLine.StandardOutput.ReadToEnd()
            $stderr = $cmdLine.StandardError.ReadToEnd()
    
        }
        if ($WARN) 
        {
            If ($cmdLine.ExitCode -ne 0) 
            {
                 write-host "Error while Running $Cmd : $Cmd $Option" -foregroundcolor red
                 Write-Output $(get-date -f MM-dd-yyyy_HH_mm_ss) "$stderr" |  Out-File $NtpLog -Append
            }    
            else
            {
                Write-Output $(get-date -f MM-dd-yyyy_HH_mm_ss) "$stdout" |  Out-File $NtpLog -Append
            }
        }
        $ExitCode=$cmdLine.ExitCode
        $cmdline.dispose()
        Return $ExitCode
         
     }

}

function File_Log_Size
{
    $MAX_FileSize = 25mb
    if(Test-path -path $NtpLog)
    {
        $Size=((Get-Item -Path $NtpLog).Length / 1Mb)
        if([math]::Round($Size) -gt $MAX_FileSize)
        {
            Clear-Content -Path $NtpLog
        }
  
    }
    else
    {
        write-host "File Notfound"
    }
}


RunEXE "net" "/set time /YES" "Hidden" $true $true
File_Log_Size


