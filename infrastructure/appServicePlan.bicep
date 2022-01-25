param appServicePlanName string
param appServicePlanLocation string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: appServicePlanLocation
  sku: {
    name: 'S1'
  }
  kind: 'linux'
}

output appServicePlanId string = appServicePlan.id
