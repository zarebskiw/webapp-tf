#az login

#region Config

#project 

$projName = "flolie4123"

#storageAccount

$rgName = "ws-devops"
$location = "germanywestcentral"
$stName = "cgmsgtf"
$scName = "tfstateazdevops"

#Config Service Principal

$principalName = "sp-hackathon"

#endregion Config

#region storageAccount

$resourceGroups = az group list | ConvertFrom-Json 
$rg = $resourceGroups | Where-Object {$_.Name -eq $rgName}

if ($rg){
    Write-Output "Resource Group already available"
}
else {
    # Create Resource Group
    az group create -n $rgName -l $location
}

$storageAccounts = az storage account list -g $rgName | ConvertFrom-Json 
$sa = $storageAccounts | Where-Object {$_.Name -eq $stName}

if ($sa){

    Write-Output "Storage Account already available"
}
else {

    # Create Storage Account
    az storage account create -n $stName -g $rgName -l $location --sku Standard_LRS

}

$storageContainer = az storage container list --account-name $stName --auth-mode login | ConvertFrom-Json 
$sc = $storageContainer | Where-Object {$_.Name -eq $scName}

if ($sc){
    Write-Output "Storage Container already available"
}
else {

    # Create Storage Account Container
    az storage container create -n $scName --account-name $stName --auth-mode login
}

#endregion storageAccount

#region ServicePrincipal

#Code Service Principal

$servicePrincipal = az ad sp create-for-rbac --name $principalName | ConvertFrom-Json

#endregion ServicePrincipal

#region output local.properties

$subscription = az account list | ConvertFrom-Json 
$subscription = $subscription | Where-Object {$_.name -eq "Learning & Development"}

$output = [PSCustomObject]@{
    ServicePrincipal = $servicePrincipal
    AZURE_AD_CLIENT_ID = $servicePrincipal.appId
    AZURE_AD_CLIENT_SECRET = $servicePrincipal.password
    AZURE_AD_TENANT_ID = $servicePrincipal.tenant
    AZURE_SUBSCRIPTION_ID = $subscription.id
    AZURE_STORAGE_NAME = $stName
    AZURE_STORAGE_CONTAINER_NAME = $scName
    AZURE_STORAGE_STATE_NAME = $projName + ".tfstate"
    
}
$output | ConvertTo-Json > local.properties


#endregion output local.properties