function Windows_User
{
$pwd1 = Read-Host -Prompt "Password" -AsSecureString
$pwd2 = Read-Host -Prompt  "Re-enter Password" -AsSecureString
$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd1))
$pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd2))
 
if ($pwd1_text -ceq $pwd2_text)
{
	Write-Host -F Green "Password Match successfuly & password never expires enabled"
	$UserAccount = Get-LocalUser -Name "Administrator"
	$UserAccount | Set-LocalUser -Password $pwd1
	$UserAccount | Set-LocalUser -PasswordNeverExpires $True
} 
else 
{
	Write-Host "Passwords re enter the password"
}
}

Function License_Check
{
#Check license status

$LicenseStatus = @("Unlicensed","Licensed","OOB Grace",
"OOT Grace","Non-Genuine Grace","Notification","Extended Grace")

$LicenseCheck= Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $env:ComputerName |`
    Where{$_.PartialProductKey -and $_.Name -like "*Windows*"} | Select `
    @{Expression={$_.PSComputerName};Name="ComputerName"},`
    @{Expression={$_.Name};Name="WindowsName"} ,ApplicationID,`
    @{Expression={$LicenseStatus[$($_.LicenseStatus)]};Name="LicenseStatus"}
	
if($LicenseCheck.LicenseStatus -eq "Licensed")
{
	Write-Host -F Green "Activated"
}
else
{
    Write-Host -F red "Windows Not activated"
}
}

Function RDP
{
#Enable remote desktop
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $env:COMPUTERNAME -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(1)
Write-Host -F Green "Remote Desktop Enabled"
}

Function Regional_Setting
{
#KeyBoard Input method    
$InputLanguage=Read-Host -Prompt "Give Language too add in keyboard layout (eg:0x040c)"           <#https://technet.microsoft.com/en-us/library/dd744369(v=ws.10).aspx#>
$language=Get-WinUserLanguageList
$language[0].InputMethodTips.Add('0409:'+$InputLanguage) #Refer the code from above link
Set-WinUserLanguageList $language -Force
Write-Host -F Green "Language has been added to layout"

#Regional Settings Format
$Format = Read-Host -Prompt "Enter Region Format (eg:en-US , fr-FR etc)"   <# https://technet.microsoft.com/en-us/library/dd744369(v=ws.10).aspx#>
Set-Culture $Format
Write-Host -F Green "Regional Format has been changed"

#Home Location
$GeoID = Read-Host -Prompt "Enter Home Location - Geo ID (eg:84)"   <#https://msdn.microsoft.com/en-us/library/windows/desktop/dd374073(v=vs.85).aspx#>
Set-WinHomeLocation -GeoId $GeoID
Write-Host -F Green "Home Location has been set"
	
#TimeZone	
$TimeZone= Read-Host -Prompt "Enter TimeZone Name (eg:Central Standard Time)"   <#https://msdn.microsoft.com/en-us/library/gg154758.aspx#>
Set-TimeZone -Name $TimeZone
Write-Host -F Green "Time Zone has been changed"
}

Function Menu
{ 
Do
{

	Write-Host -F Yellow "Select Option"
    Write-Host -F Blue  "1: Local User Configuration"
    Write-Host -F Blue  "2: Check windows license status"
    Write-Host -F Blue  "3: Enable Remote"
    Write-Host -F Blue  "4: Change Regional Settings"
    Write-Host -F Blue  "5: EXIT"
     
$global:Option = Read-Host  "Give your input"
	 

     
     switch ($global:Option)
     {
             '1' {
                
                Windows_User
                
           } '2' {
                
                License_Check
                
           } '3' {
                
                RDP
                
           } '4' {
                
                Regional_Setting
           } '5' {
               
                return
                
           }
     }
     #pause
}
until ($input -eq '5')

}

Menu
    

 