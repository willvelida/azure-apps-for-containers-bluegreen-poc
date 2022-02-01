@description('Name of the app service plan')
param appServiceName string

@description('Location of the app service plan')
param appServiceLocation string

@description('Name of the slot that we want to create in our App Service')
param appServiceSlotName string

@description('The Server Farm Id for our App Plan')
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
