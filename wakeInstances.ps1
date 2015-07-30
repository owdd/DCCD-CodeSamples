Set-DefaultAWSRegion us-east-1

# get all stopped instances that have a Parking tag w/ value Sleep
$instances = (Get-EC2Instance).instances | Where-Object {$_.Tag.Count -gt 0 -and $_.Tag.Key -eq "Parking" -and $_.Tag.Value -eq "Sleep" }

# Start them
foreach ($instance in $instances) {
    Start-EC2Instance $instance.InstanceId 
}