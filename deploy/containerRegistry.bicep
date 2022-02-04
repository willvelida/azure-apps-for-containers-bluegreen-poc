param registryName string
param registryLocation string
param registrySku string
param greenSlotName string
param blueSlotName string

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
  properties: {
    adminUserEnabled: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}
