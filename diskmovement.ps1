
$FileContent = Import-Csv ".\disk1.csv"

foreach($item in $FileContent)
{
  $VmName = $item.VMName
  $ResourceGroupName= Get-AzureRmResource -Name $VmName | select ResourceGroupName -ExpandProperty ResourceGroupName
  $DiskResourceId = $item.Id
  
Move-AzureRmResource -DestinationResourceGroupName $ResourceGroupName -ResourceId $DiskResourceId -Force

}

