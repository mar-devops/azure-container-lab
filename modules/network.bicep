param location string = 'westeurope'
param vnetName string = 'vnetContainerLab'
param subnetName string = 'snet-aci'
param delegationName string = 'delegation-aci'

resource vnet 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '192.168.0.0/24'
          delegations: [
            {
              name: delegationName
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
	privateEndpointVNetPolicies: 'Disabled'
  }
}

output subnetId string = vnet.properties.subnets[0].id