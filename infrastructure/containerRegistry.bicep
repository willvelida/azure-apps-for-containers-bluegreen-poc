param registryName string
param registryLocation string
param registrySku string
param greenSlotName string
param blueSlotName string

var managedIdentityName = 'kenshobluegreenpocsp'
var actions = [
  'Microsoft.Authorization/roleAssignments/write'
]
var notActions = []
var roleName = 'Role Assigment Writer'
var roleDescription = 'Allows the resource to write role assignments'

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

resource roleAssignmentWriteDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(subscription().id, string(actions), string(notActions))
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      managedIdentity.id
    ]
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
