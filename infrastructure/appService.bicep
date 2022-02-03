@description('Name of the app service plan')
param appServiceName string

@description('Location of the app service plan')
param appServiceLocation string

@description('Name of the slot that we want to create in our App Service')
param appServiceSlotName string

@description('The Server Farm Id for our App Plan')
param serverFarmId string

@description('Name of the Azure Container Registry that this App will pull images from')
param acrName string

@description('Username for the docker login')
param dockerUsername string

@description('The docker image and tag')
param dockerImageAndTag string = '/hellobluegreenwebapp:latest'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: appServiceLocation
  kind: 'app,linux,container'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrName}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
      ]
      linuxFxVersion: 'DOCKER|${acrName}.azurecr.io/${dockerImageAndTag}'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource blueSlot 'slots' = {
    name: appServiceSlotName
    location: appServiceLocation
    kind: 'app,linux,container'
    properties: {
      serverFarmId: serverFarmId
      siteConfig: {
        appSettings: [
          {
            name: 'DOCKER_REGISTRY_SERVER_URL'
            value: 'https://${acrName}.azurecr.io'
          }
          {
            name: 'DOCKER_REGISTRY_SERVER_USERNAME'
            value: dockerUsername
          }
          {
            name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
            value: containerRegistry.listCredentials().passwords[0].value
          }
          {
            name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
            value: 'false'
          }
          {
            name: 'WEBSITES_PORT'
            value: '80'
          }
        ]
      }
    }
    identity: {
      type: 'SystemAssigned'
    }
  }
}
