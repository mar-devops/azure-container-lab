param location string = 'westeurope'
param identityName string = 'id-aci-acrpull'


resource aciIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  location: location
  name: identityName
}

output identityId string = aciIdentity.id
output identityPrincipalId string = aciIdentity.properties.principalId