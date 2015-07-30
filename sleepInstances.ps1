Set-DefaultAWSRegion us-east-1

# get all running instances that have a Parking tag w/ value Hibernate
$instances = (Get-EC2Instance).RunningInstance | Where-Object {$_.Tag.Count -gt 0 -and $_.Tag.Key -eq "Parking" -and ($_.Tag.Value -eq "Sleep" -or $_.Tag.Value -eq "Hibernate" )}

# stop them
foreach ($instance in $instances) {
    Write-Host Stopping $instance.InstanceId
    Stop-EC2Instance $instance.InstanceId 
}