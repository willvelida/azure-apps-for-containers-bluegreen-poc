param registryName string
param registryLocation string
param registrySku string

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
