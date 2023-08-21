# run in Terraform directory
# initialise Terraform
# log into Az CLI

Set-Location "C:\terraform-dir\"

Get-AzResource -Verbose | Where-Object { $_.ResourceType -eq "Microsoft.Network/dnszones" }
$dns_zone_resources = Get-AzResource -Verbose | Where-Object { $_.ResourceType -eq "Microsoft.Network/dnszones" }

foreach ($dns_zone_resource in $dns_zone_resources) {
    Write-Host Importing zone: $dns_zone_resource.Name

    $tfout = terraform import azurerm_dns_zone.zone_$($dns_zone_resource.Name.Replace(".", "_")) $dns_zone_resource.ResourceId.Replace("dnszones", "dnsZones")

    if ($tfout -like "*Terraform is already managing a remote object for*") {
        Write-Host "Already managing object for record:" $dns_record.Name $dns_record.ZoneName $dns_record.RecordType
    } else {
        Write-Host $tfout
    }

    $dns_records = Get-AzDnsRecordSet -ResourceGroupName $dns_zone_resource.ResourceGroupName -ZoneName $dns_zone_resource.Name

    foreach ($dns_record in $dns_records) {
        if ($dns_record.Name -eq "@") {
            $subdomain = ""
        } elseif ($dns_record.Name -eq "*") {
            $subdomain = "wildcard_"
        } else {
            $subdomain = "$($dns_record.Name.Replace(".", "_"))_"
        }

        if ($dns_record.RecordType -eq "SOA" -or $dns_record.RecordType -eq "NS") {
            $skip = $true
            Write-Host Skipping record: $dns_record.Name $dns_record.ZoneName $dns_record.RecordType
        }

        if (!$skip) {
            Write-Host Importing record: $dns_record.Name $dns_record.ZoneName $dns_record.RecordType

            $tfout = terraform import azurerm_dns_$($dns_record.RecordType.ToString().ToLower())_record.$($dns_record.RecordType.ToString().ToLower())_$($subdomain)$($dns_record.ZoneName.Replace(".", "_")) $dns_record.Id.Replace("dnszones", "dnsZones") *>&1 

            if ($tfout -like "*Terraform is already managing a remote object for*") {
                Write-Host "Already managing object for record:" $dns_record.Name $dns_record.ZoneName $dns_record.RecordType
            } else {
                Write-Host $tfout
            }
        }
        $skip = $false
    }   
}
