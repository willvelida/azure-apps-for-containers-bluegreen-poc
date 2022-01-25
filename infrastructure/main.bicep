param acrName string
param acrSku string
param appServicePlanName string
param appServiceName string

param location string = resourceGroup().location

module containerRegistry 'containerRegistry.bicep' = {
  name: 'containerRegistry'
  params: {
    registryLocation: location 
    registryName: acrName
    registrySku: acrSku
  }
}

module appServicePlan 'appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    appServicePlanLocation: location
    appServicePlanName: appServicePlanName
  }
}

module appService 'appService.bicep' = {
  name: 'appService'
  params: {
    appServiceLocation: location 
    appServiceName: appServiceName
    serverFarmId: appServicePlan.outputs.appServicePlanId
    appServiceSlotName: '/blue'
  }
}
