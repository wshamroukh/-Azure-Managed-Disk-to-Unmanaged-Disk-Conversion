$ResourceGroupName = ''
$VNetName = ''
$SubnetName = ''
$VMName = ''
$VMSize = ''
$Location = ''
$StorageAccountName = ''
$StorageAcccountSrouceContainer = ''
$StorageAccountDestContainer = ''
$OSVHDName = ''
$DataVHDName = ''

# Login to the destination subscription where you have copied the vhd to a storage account
$sub = Connect-AzAccount -ErrorAction Stop
    if($sub){
        Get-AzSubscription| Out-GridView -PassThru -Title "Select your Azure Subscription" |Select-AzSubscription
        
}

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName
$Subnet = $VNet.Subnets |Where-Object {$_.Name -eq $SubnetName}
$NIC = New-AzNetworkInterface -Name "$VMName-NIC" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id
$credentials = Get-Credential
$VM = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VM = Set-AzVMOperatingSystem -VM $VM -Linux -ComputerName $VMName -Credential $credentials
$VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id
$SourceOSDiskURI = $StorageAccount.PrimaryEndpoints.Blob + "$StorageAcccountSrouceContainer/" + $OSVHDName
$SourceDataDiskURI = $StorageAccount.PrimaryEndpoints.Blob + "$StorageAcccountSrouceContainer/" + $DataVHDName
$DestOSDiskURI = $StorageAccount.PrimaryEndpoints.Blob + "$StorageAccountDestContainer/$OSVHDName"
$DestDataDiskURI = $StorageAccount.PrimaryEndpoints.Blob + "$StorageAccountDestContainer/$DataVHDName"
$VM = Set-AzVMOSDisk -VM $VM -SourceImageUri $SourceOSDiskURI -VhdUri $DestOSDiskURI -Name $OSVHDName -CreateOption FromImage -Linux
$VM = Add-AzVMDataDisk -VM $VM -Name $DataVHDName -VhdUri $DestDataDiskURI -Lun 0 -SourceImageUri $SourceDataDiskURI -CreateOption FromImage

New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM -Verbose

