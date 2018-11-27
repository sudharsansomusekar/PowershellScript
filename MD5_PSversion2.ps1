#***************************************************************************
# Script : MD5 Checksum
#
#1.00 : Create Md5 hash files on FTP path 
#***************************************************************************

$SourcePath=split-path -parent $MyInvocation.MyCommand.path
$FileList=Get-ChildItem -Path "$SourcePath\" | Where-Object {$_.Extension -eq ".zip"} 
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
foreach($Files in $Filelist)
{
    $File_Name=($Files.Name).TrimEnd(".zip")
    $MD5File= New-Item -Path "$SourcePath\$File_Name.md5" -ItemType File -Force
    $file = [System.IO.File]::Open("$SourcePath\$Files",[System.IO.Filemode]::Open, [System.IO.FileAccess]::Read)
    $Hash=[System.BitConverter]::ToString($md5.ComputeHash($file))
    $file.Dispose()
    Add-Content "$SourcePath\$File_Name.md5" $Hash.replace("-","") -Force
}