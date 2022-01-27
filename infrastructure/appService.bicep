@description('Name of the app service plan')
param appServiceName string
param appServiceLocation string
param appServiceSlotName string
param serverFarmId string

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: appServiceLocation
  properties: {
    serverFarmId: serverFarmId
  }

  resource blueSlot 'slots' = {
    name: appServiceSlotName
    location: appServiceLocation
    properties: {
      serverFarmId: serverFarmId
    }
  }
}
