param registryName string
param registryLocation string
param registrySku string
param greenSlotName string
param blueSlotName string

var managedIdentityName = 'kenshobluegreenpocsp'

resource greenSlot 'Microsoft.Web/sites@2021-02-01' existing = {
  name: greenSlotName
}

resource blueSlot 'Microsoft.Web/sites/slots@2021-02-01' existing = {
  name: blueSlotName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: registryName
  location: registryLocation
  sku: {
    name: registrySku
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  scope: containerRegistry
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: registryLocation
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscription().id, managedIdentity.id, ownerRoleDefinition.id)
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: ownerRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  scope: containerRegistry
}

resource greenAcrPullRoleAssingment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, greenSlot.id, acrPullRoleDefinition.id)
  properties: {
    principalId: greenSlot.identity.principalId
    roleDefinitionId: acrPullRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

resource blueAcrPullRoleAssingment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, blueSlot.id, acrPullRoleDefinition.id)
  properties: {
    principalId: blueSlot.identity.principalId
    roleDefinitionId: acrPullRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}
