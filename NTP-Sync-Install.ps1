###############################################################################################################
# Language     :  PowerShell 
# Filename     :  Ntp-Sync-Install.ps1
# Description  :  To Avoid recurent NTP alerts 
###############################################################################################################
<#
    .SYNOPSIS
    To Install NTP Script on the servers contains NTP errors
                 
    .DESCRIPTION         
     To Run the NTP Command on the servers having NTP issues every 30 Minutes  or based on time as per need
     The Script will install the task based on OS Versions
     
    .EXAMPLE
     .\Ntp-Sync-Install.ps1 
     .\Ntp-Sync-Install.ps1  -RunEvery [Minutes user can specify based on needs]

     .NOTES
     $OsInfo - To know the exact version of OS.
     $RunEvery - Minutes based on user requirements.

#>

[Cmdletbinding()]
    param (
    [Parameter(Mandatory = $false)]
    [int]$RunEvery=30
)

$ScriptVersion = '1.00'
$ScriptName   = 'NTP-Sync-Install'
$Folder= split-path -parent $MyInvocation.MyCommand.path
$File_path = "$Folder\NTP-Synch.ps1"
$Scriptpath = ""   #PROVIDE INPUT
$NtpLog = "\"      #PROVIDE INPUT





Function RunEXE
{
    param([string]$Cmd="",[string]$Option="",[string]$WindowStyle="",[Boolean]$WARN=$True,[Boolean]$Wait=$True)
    $cmdLine = new-Object System.Diagnostics.Process
    $cmdLine.StartInfo.WindowStyle=$WindowStyle
    $cmdLine.StartInfo.FileName=$Cmd
    $cmdLine.StartInfo.Arguments=$Option
    $cmdLine.StartInfo.UseShellExecute = $false
    $cmdLine.Start() | Out-Null
    if (!$?)  
    {
        Write-Host "Could not Run $Cmd : $Cmd $Option" -foregroundcolor red
        Return 1
    }
    Else 
    {
        if ($Wait)
        {
            $cmdLine.WaitForExit()


        }
        if ($WARN) 
        {
            If ($cmdLine.ExitCode -ne 0) 
            {
                Write-host "Error while Running $Cmd : $Cmd $Option" -foregroundcolor red
            }    
        }
        $ExitCode=$cmdLine.ExitCode
        $cmdline.dispose()
        Return $ExitCode
     }

}

function CreateScheduleTask2016
{
    param(
        [string]$ScheduleTask_Name="",
        [string]$ScheduleTask_PowershellFullPath="",
        [String]$ScheduleTask_Type="",
        [Boolean]$ScheduleTask_Enabled,
        [String]$ScheduleTask_Description,
        [int]$RunEvery
    )
    
    $isExisting=Get-ScheduledTask -TaskName $ScheduleTask_Name -ErrorAction SilentlyContinue
    
    If ($isExisting -ne $null){
        #If task already available remove and recreate it
         Write-Host "NTP Task already exist..." -ForegroundColor Yellow
         Write-Host "Deleting existing NTP TASK..."
         Unregister-ScheduledTask -TaskName $ScheduleTask_Name -Confirm:$false
    }else{

         Write-Host "The NTP Task does't exit..." -ForegroundColor Yellow
    }

    $ScheduleTask_TimeSpan=New-TimeSpan -Minutes $RunEvery
    $ScheduleTask_A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File ""$ScheduleTask_PowershellFullPath"""
    $ScheduleTask_T =  New-ScheduledTaskTrigger -Daily -At 5Am
    $ScheduleTask_T.Repetition = $(New-ScheduledTaskTrigger -once -At (Get-Date).Date -RepetitionInterval $ScheduleTask_TimeSpan).Repetition
    $ScheduleTask_P = New-ScheduledTaskPrincipal "SYSTEM" -LogonType ServiceAccount -RunLevel Highest 
    $ScheduleTask_S = New-ScheduledTaskSettingsSet
    $ScheduleTask_D = New-ScheduledTask -Action $ScheduleTask_A -Principal $ScheduleTask_P -Trigger $ScheduleTask_T -Settings $ScheduleTask_S -Description $ScheduleTask_Description
    
    Register-ScheduledTask $ScheduleTask_Name -InputObject $ScheduleTask_D 
    
    Write-host "$ScheduleTask_Name  Has been created successfully" -ForegroundColor Green
   
}

function CreateScheduleTask2008R2
{
    param (
        [String]$TaskName,
        [String]$ScheduleTask_Description,
        [int]$RunEvery
    )
    
    $schedule = new-object -com("Schedule.Service") 
    $schedule.connect() 
    $tasks = $schedule.getfolder("\").gettasks(0)
    $Task = $tasks |select Name | Where-Object {$_.Name -eq "NTP"}

    #If task already available remove and recreate it
    if($Task.Name)
    { 
        RunEXE "SCHTASKS" "/delete /tn $TaskName /f" "Hidden" $true $true
       
    }

    $XMLTmpFileName="$Folder\NTP.xml"
	$XMLContent=Get-content -path $XMLTmpFileName
	$XMLContent|foreach {$_.replace("###DESCRIPTION###",$ScheduleTask_Description)} | Set-Content $XMLTmpFileName
    RunEXE "SCHTASKS" "/create  /TN $TaskName /XML $XMLTmpFileName" "Hidden" $true $true
    RunEXE "SCHTASKS" "/change /RI $RunEvery /TN $TaskName /enable" "Hidden" $true $true
    RunEXE "SCHTASKS" "/Run /TN $TaskName" "Hidden" $true $true
} 


#*****************************************
#MAIN
#*****************************************

if(-NOT (Test-path $Scriptpath)){
   
   New-Item -Path $Scriptpath -ItemType Directory 
}

Copy-Item $File_path -Destination $Scriptpath -Force



# If Function returns TRUE : The OS Version Windows 2012 , 2016 etc
# If Function returns FALSE : The OS Version Windows 2008 
if([Environment]::OSVersion.Version -ge (new-object 'Version' 6,3))
{
    
    CreateScheduleTask2016 "NTP" "$Scriptpath\NTP-Synch.ps1" -ScheduleTask_Description "NTP-$ScriptVersion" -RunEvery $RunEvery 

    $taskDescription = Get-ScheduledTask -TaskName NTP 
    if($taskDescription)
    {
        if($taskDescription.DESCRIPTION -ne "NTP-$ScriptVersion")
        {
            Unregister-ScheduledTask -TaskName NTP -Confirm:$false
            CreateScheduleTask2016 "NTP" "$Scriptpath\NTP-Synch.ps1" -ScheduleTask_Description "NTP-$ScriptVersion" -RunEvery $RunEvery 
        }
   }
   else
   {
        Write-host "task not available"
   }
}
else
{
    CreateScheduleTask2008R2 -TaskName "NTP" -ScheduleTask_Description "NTP-$ScriptVersion" -RunEvery $RunEvery
}









