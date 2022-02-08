param appServicePlanName string
param appServicePlanLocation string
param appServicePlanSkuName string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: appServicePlanLocation
  sku: {
    name: appServicePlanSkuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output appServicePlanId string = appServicePlan.id
