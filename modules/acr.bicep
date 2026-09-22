param resourceName string = 'azurecontainerlab'
param location string = 'westeurope'



resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  
  location: location
  name: resourceName
properties: {
  adminUserEnabled: false
  publicNetworkAccess: 'Enabled'
  dataEndpointEnabled: false
  networkRuleBypassAllowedForTasks: false
  roleAssignmentMode: 'LegacyRegistryPermissions'
  encryption: {
    status: 'disabled'
  }
}
  sku: {
    name: 'Premium'
  }
}


output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer