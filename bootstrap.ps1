Write-Host "Setting EP..."
Set-ExecutionPolicy unrestricted
Write-Host "done"


# powershell still doesn't have local user management, so you get to go old school to create local user accounts

Write-Host "Create Svc user..."


NET USER serviceUser "supersecretpassword" /ADD
NET LOCALGROUP "Administrators" "serviceUser" /add

Write-Host "Done"

#install IIS Roles

# get-windowsfeature gets a full list of windows features

Write-Host "Adding web-http-redirect..."
Add-WindowsFeature web-http-redirect

Write-Host "Adding web-asp-net...."
Add-WindowsFeature web-asp-net

Write-Host "Adding web-mgmt-console...."
Add-WindowsFeature web-mgmt-console

Write-Host "Adding asp.net 4.5...."
Add-WindowsFeature Web-Asp-Net45 
# configure FireWall rule

# this import module must come after adding the asp net feature
Write-Host "Importing Webadministration...."
Import-Module WebAdministration
Write-Host "done"

#  Create new IIS app pool

write-host "creating IIS pool"

cd IIS:\AppPools\
$appPool = new-item "NewAppPool"
$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value "v4.0"
$appPool | Set-ItemProperty -Name "enable32BitAppOnWin64" -Value "true"

$appPool.processModel.userName = ".\serviceUser"
$appPool.processModel.password = "supersecretpassword"
$appPool.processModel.identityType = 3
$appPool | set-item
write-host "done"


