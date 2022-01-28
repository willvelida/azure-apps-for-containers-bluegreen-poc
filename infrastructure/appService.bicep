@description('Name of the app service plan')
param appServiceName string
@description('Location of the app service plan')
param appServiceLocation string
param appServiceSlotName string
param serverFarmId string

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: appServiceLocation
  properties: {
    serverFarmId: serverFarmId
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource blueSlot 'slots' = {
    name: appServiceSlotName
    location: appServiceLocation
    properties: {
      serverFarmId: serverFarmId
    }
    identity: {
      type: 'SystemAssigned'
    }
  }
}
