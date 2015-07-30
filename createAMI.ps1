Set-ExecutionPolicy unrestricted

Write-Host "Setting region...."
Set-DefaultAWSRegion us-east-1
Write-Host "Setting region done"


$myPSKeyPair =  New-EC2KeyPair -KeyName cdmeetup_auto

# save key pair to disk for later use
$myPSKeyPair.KeyMaterial | Out-File -Encoding ascii c:\tmp\cdmeetup_auto.pem

# get available windows AMIs
$results = Get-EC2ImageByName -Names WINDOWS_2012_BASE

# get the latest AMI id, which confusingly is called ImageId
$imageID = $results[0].ImageId

Write-Host "Creating new instance with " $imageID

# I hard coded roles as part of the demonstration, you'll need to create a security group, vpc, subnet, and iam role so that you can supply them to new-ec2instance
$InstanceType = "m3.medium"
$secGroup = "TODO ENTER SECGROUP HERE"
$keyName = "cdmeetup_auto"
$subnet = "TODO ENTER SUBNET HERE"
$iamRole = "TODO ENTER IAM ROLE HERE"


$instance = New-EC2Instance -imageId $imageID  -InstanceType $InstanceType -SecurityGroupId $secGroup -KeyName $keyName -SubnetId $subnet -AssociatePublicIp $true -InstanceProfile_Name $iamRole
Write-Host "Instance Created"


Write-Host "Waiting 5 minutes to be able to retrieve password"
Start-Sleep -s 300



$instanceID = $instance[0].Instances[0].InstanceId
$privateIP = $instance.Instances[0].PrivateIpAddress

Write-Host "InstanceID = " $instanceID " privateIP = " $privateIP


Write-Host "adding ec2 tags"
New-EC2Tag -Resources $instance[0].Instances[0].InstanceId -Tags @{ Key="Name"; Value="PowerShell Test Box" }
New-EC2Tag -Resources $instance[0].Instances[0].InstanceId -Tags @{ Key="Parking"; Value="Hibernate" }
New-EC2Tag -Resources $instance[0].Instances[0].InstanceId -Tags @{ Key="Environment"; Value="DC CD Meetup" }
Write-Host "adding ec2 tags complete"


# use the pem file to get the administrator password from AWS
$password = Get-EC2PasswordData -InstanceId $instanceID -PemFile C:\tmp\cdmeetup_auto.pem
$secPassword = ConvertTo-SecureString -AsPlainText -Force $password

Write-Host "password retrieved"

# create a credential
$cred = New-Object System.Management.Automation.PSCredential 'Administrator', $secPassword


Write-Host "Connecting to " $privateIP
$session = New-PSSession -ComputerName $privateIP -Credential $cred
Write-Host "Entered remote Session"


$filepath = "C:\powershell\BootStrap.ps1"
Invoke-Command -Session $session -FilePath $filepath
Exit-PSSession

Write-Host "Exit remote Session"

#Delete the keypair that we created before, don't need it anymore
Remove-EC2KeyPair -KeyName cdmeetup_auto -force
remove-item C:\tmp\cdmeetup_auto.pem


# create timestamp for AMI name
$timestamp = Get-Date -Format o | foreach {$_ -replace ":", "-"}
$timestamp = $timestamp.ToString().Split(".")[0]


$imageName = "Test Powershell based snapshot-" + $timestamp
Write-Host "Kick off AMI"
$amiID = New-EC2Image -InstanceId  $instance[0].Instances[0].InstanceId -Name $imageName -Description "web server from Powershell"
Write-Host "AMI started:" $amiID
