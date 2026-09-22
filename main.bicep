param identityName string = 'id-aci-acrpull'
param resourceName string = 'azurecontainerlab'

module acr './modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    resourceName: resourceName
    location: 'westeurope'
  }
}
output acrLoginServer string = acr.outputs.acrLoginServer


module identity './modules/identity.bicep' = {
  name: 'identityDeployment'
  params: {
    location: 'westeurope'
    identityName: identityName
  }
}
output identityId string = identity.outputs.identityId
output identityPrincipalId string = identity.outputs.identityPrincipalId


module network './modules/network.bicep' = {
  name: 'networkDeployment'
  params: {
    location: 'westeurope'
    vnetName: 'vnetContainerLab'
  }
}
output subnetId string = network.outputs.subnetId


module aci './modules/aci.bicep' = {
  name: 'aciDeployment'
  params: {
    location: 'westeurope'
    subnetId: network.outputs.subnetId
    acrLoginServer: acr.outputs.acrLoginServer
    identityId: identity.outputs.identityId
  }
}


module rbac './modules/rbac.bicep' = {
  name: 'rbacDeployment'
  params: {
    acrName: resourceName
    identityPrincipalId: identity.outputs.identityPrincipalId
  }
  
dependsOn: [
    acr
  ]
}

