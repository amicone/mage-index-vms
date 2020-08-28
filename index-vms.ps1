$reportName = "vmindex.csv"
$report = @()
$subs =  Get-AzureRmSubscription | where State -eq Enabled 
foreach ($sub in $subs) {
	$cntxt = Set-AzContext -SubscriptionObject $sub
	$vms = Get-AzVm
	$publicIps = Get-AzPublicIpAddress
	$nics = Get-AzNetworkInterface | ?{ $_.VirtualMachine -NE $null}
	foreach ($nic in $nics) {
		$info = "" | Select SubscriptionName, SubscriptionId, TenantId, VmName, ResourceGroupName, Region, VirtualNetwork, Subnet, PrivateIpAddress, OsType, PublicIPAddress
		$info.SubscriptionName = $sub.Name
		$info.SubscriptionId = $sub.Id
		$info.TenantId = $sub.TenantId
		$vm = $vms | ? -Property Id -eq $nic.VirtualMachine.id
		foreach($publicIp in $publicIps) {
			if($nic.IpConfigurations.id -eq $publicIp.ipconfiguration.Id) {
				$info.PublicIPAddress = $publicIp.ipaddress
			}
		}
		$info.OsType = $vm.StorageProfile.OsDisk.OsType
		$info.VMName = $vm.Name
		$info.ResourceGroupName = $vm.ResourceGroupName
		$info.Region = $vm.Location
		$info.VirtualNetwork = $nic.IpConfigurations.subnet.Id.Split("/")[-3]
		$info.Subnet = $nic.IpConfigurations.subnet.Id.Split("/")[-1]
		foreach ($pip in $nic.IpConfigurations.PrivateIpAddress) {
			$ipinfo = $info.PSObject.Copy()
			$ipinfo.PrivateIpAddress = $pip
			$report+=$ipinfo
		}
	}
}
$report | ft SubscriptionName, SubscriptionId, TenantId, VmName, ResourceGroupName, Region, VirtualNetwork, Subnet, PrivateIpAddress, OsType, PublicIPAddress
$report | Export-CSV "$home/$reportName"
