# Edit these global variables with you unique Key Vault name, resource group name and location
#Name of the Key Vault
$keyVaultName = "SHAREDSVC-EST-VAULT"
#Resource Group Name
$rgName = "SHAREDSVC-EST-RG01"
#Region
$location = "eastus"
#Password to place w/in the KeyVault
#$securePassword = ConvertTo-SecureString -String "P@ssword!" -AsPlainText -Force
#Name for the Azure AD Application
$appName = "diskencrypt"
#Name for the VM to be encrypt
$vmName = "ss-aad-vm"
#user name for the admin account in the vm being created and then encrypted
$vmAdminName = "encryptuser"
#Password to place w/in the KeyVault
$securePassword = ConvertTo-SecureString -String "P@ssword!" -AsPlainText -Force

# Create a key in your Key Vault
Add-AzureKeyVaultKey `
    -VaultName $keyVaultName `
    -Name "encryptkey" `
    -Destination "Software"
    
# Create Azure Active Directory app and service principal
$app = New-AzureRmADApplication -DisplayName $appName `
    -HomePage "https://diskencrypt.com" `
    -IdentifierUris "https://diskencrypt.com/myapp0" `
    
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

# Set permissions to allow your AAD service principal to read keys from Key Vault
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyvaultName `
    -ServicePrincipalName $app.ApplicationId  `
    -PermissionsToKeys decrypt,encrypt,unwrapKey,wrapKey,verify,sign,get,list,update `
    -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge
    # Put the password in the Key Vault as a Key Vault Secret so we can use it later
# We should never put passwords in scripts.
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name protectValue -SecretValue $securePassword


# Define required information for our Key Vault and keys
$keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $rgName;
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$keyEncryptionKeyUrl = (Get-AzureKeyVaultKey -VaultName $keyVaultName -Name "encryptkey").Key.kid;

# Encrypt our virtual machine
Set-AzureRmVMDiskEncryptionExtension `
    -ResourceGroupName $rgName `
    -VMName $vmName `
    -AadClientID $app.ApplicationId `
    -AadClientSecret (Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name protectValue).SecretValueText `
    -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
    -DiskEncryptionKeyVaultId $keyVaultResourceId `
    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
    -KeyEncryptionKeyVaultId $keyVaultResourceId

# View encryption status
Get-AzureRmVmDiskEncryptionStatus  -ResourceGroupName $rgName -VMName $vmName

<#
#clean up
Remove-AzureRmResourceGroup -Name $rgName
#removes all of the Azure AD Applications you created w/ the same name
Remove-AzureRmADApplication -ObjectId $app.ObjectId -Force
#>