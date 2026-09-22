param subnetId string
param acrLoginServer string
param identityId string
param location string = 'westeurope'

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2026-07-01' = {
  name: 'aci-container-lab'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
 properties: {
  containers: [
    {
      name: 'hello-world'
      properties: {
        image: '${acrLoginServer}/hello-world:v1'
        resources: {
          requests: {
            cpu: 1
            memoryInGB: 1
          }
        }
      }
    }
  ]
  osType: 'Linux'
  subnetIds: [
    { id: subnetId }
  ]
  imageRegistryCredentials: [
    {
      server: acrLoginServer
      identity: identityId
    }
  ]
}
}