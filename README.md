# Blue/Green Deployments with Azure Web Apps for Containers

This sample shows you how you can implement Blue/Green deployments for Azure Web Apps for Containers using GitHub Actions. This sample also shows you how you can create a Azure Container Registry, Linux App Service Plan and Azure App Service that you can deploy Linux containers to.

## Deploying our infrastructure

To deploy our infrastructure to Azure, this sample uses GitHub Actions to deploy our Bicep templates. The workflow contains the following steps:

To use GitHub Actions to deploy our Bicep file, we need to do some initial setup.

We first need a resource group in Azure to deploy our resources to. We can create this using the Azure CLI. Using the below command, replace the name with the name you want to use for your resource group and the location that you want to deploy your resources to:

```bash
az group create -n <resource-group-name> -l <location>
```

Note: *Replace <> with your own values.*

Once you have created your resource group, we need to generate deployment credentials. The GitHub Action that we use for our deployment needs to run under an identity. We can use the Azure CLI to create a service principal for the identity.

```bash
az ad sp create-for-rbac --name yourApp --role owner --scopes /subscriptions/{subscription-id}/resourceGroups/exampleRG --sdk-auth
```

Replace the ```--name``` parameter with the name of your application. The scope of the service principal is limited to the resource group. The output of this command will generate a JSON object with the role assignment credentials that provide access. Copy the JSON Object output:

```json
{
    "clientId": "<GUID>",
    "clientSecret": "<GUID>",
    "subscriptionId": "<GUID>",
    "tenantId": "<GUID>",
}
```

To learn more about how you can deploy Bicep files with GitHub Actions, check out [this introduction document](https://docs.microsoft.com/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI&WT.mc_id=modinfra-51296-jagord) and this [Microsoft Learn path](https://docs.microsoft.com/learn/paths/bicep-github-actions/).

## Pushing our container image to Azure Container Registry.

Once we have our service principal setup for GitHub Actions, we now need to update the credentials to allow push and pull access to our Azure Container Registry. This will allow the Github workflow to use the service principal to authenticate with our container registry and to pull and push a Docker image.

First, we need to get the resource Id of our container registry. We can do this by running the following command (Replace ```<registry-name>``` with the name of your Azure Container Registry):

```bash
registryId=$(az acr show \
  --name <registry-name> \
  --query id --output tsv)
```

Now that we have our resource Id, we can use the following AZ CLI command to assign the AcrPush role (Replace ```<ClientId>``` with the client ID of your service principal):

```bash
az role assignment create \
  --assignee <ClientId> \
  --scope $registryId \
  --role AcrPush
```

Once our role has been created, we can add the following secrets to our GitHub repo. We can do this in our repository and selecting **Settings** > **Secrets**.

| **Secret** | **Value** |
| ---------- | --------- |
| ```AZURE_CREDENTIALS``` | The entire JSON output from the service principal creation step |
| ```REGISTRY_LOGIN_SERVER``` | The login server name of your registry (all lowercase). Example: myregistry.azurecr.io |
| ```REGISTRY_USERNAME``` | The ```clientId``` from the JSON output from the service principal creation |
| ```REGISTRY_PASSWORD``` | The ```clientSecret``` from the JSON output from the service principal creation |
| ```RESOURCE_GROUP``` | The name of the resource group you used to scope the service principal |

Now that we have our secrets setup, we can create our workflow file. An example file has been created [here](./gihub/workflows/deployContainer.yml).

## Pulling our container image into App Service and performing Blue/Green Deployments

Now that we've built and pushed our container image into Azure Container Registry, we now need to grant our App Service and Deployment Slot the permissions to be able to pull container images from our Container Registry into App Service.

Pushing our container image into App Service takes the following steps:

1. Pull our Container Image from ACR into the Blue Slot.
2. Verify that the deployment to the Blue slot has been successful.
3. Swap from our blue slot into the Green slot.

Before breaking down how each step works in this sample, let's discuss how Blue/Green deployments work.

### Blue/Green Deployments

Using Blue/Green deployments helps us to achieve zero-downtime changes when deploying to production. By deploying our application to a staging environment (In this case, the Blue slot), we can validate our changes, perform smoke tests etc before deploying to our Production slot (In this case, the Green slot).

When our changes have been validated in the Blue slot, we can use the AZ CLI to swap our staging and production slots like so:

```bash
az webapp deployment slot swap --slot 'blue' --resource-group <resource-group-name> --name <web-app-name>
```

Note: *Replace the <> with your own values.*

To learn more about best practices when deploying Apps to App Service (including guidance on Deployment Slots), please read the following [documentation](https://docs.microsoft.com/en-au/azure/app-service/deploy-best-practices).


### Pulling our Container Image from ACR into the Blue Slot.

In order to pull container images from ACR into our Blue slot, we need to assign our Blue slot the 'AcrPull' role. This will allow our Blue slot to pull images from our Azure Container Registry. We can do this in Bicep like so:

```bicep
// This is the ACR Pull Role Definition Id: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

// App Service and Blue slot definition

resource appServiceSlotAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, appService::blueSlot.id, acrPullRoleDefinitionId)
  properties: {
    principalId: appService::blueSlot.identity.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
```

In this code snippet, we define a variable that specifies the AcrPull role definition id. We then bring our existing Azure Container Registry into our Bicep file so we can reference it when defining our Role Assignment.

With those resources defined, we can create our Role Assignment that is scoped to our Container Registry with the 'AcrPull' permissions.

Within our App Service Bicep code, we also need to tell our App Service to use our Managed Identity Credentials to pull container images from our Container Registry (by setting the ```acrUseManagedIdentityCreds``` flag to ```true```). We can do so by defining our App Service in Bicep like so:

```bicep
resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: appServiceLocation
  kind: 'app,linux,container'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      appSettings: appSettings
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/${dockerImageAndTag}'
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
        acrUseManagedIdentityCreds: true
        appSettings: appSettings
      }
    }
    identity: {
      type: 'SystemAssigned'
    }
  }
}
```

Once the 'AcrPull' role assignment has been created and assigned to the App Service instance, we can define our deployment to our Blue slot job within our GitHub workflow:

```yaml
deploy-to-blue-slot:
    needs: build-container-image
    runs-on: ubuntu-latest
    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@main
      
    - name: 'Login via Azure CLI'
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: 'Get App Name'
      id: getwebappname
      run: |
        a=$(az webapp list -g ${{ secrets.AZURE_RG }} --query '[].{Name:name}' -o tsv)
        echo "::set-output name=appName::$a"

    - name: 'Deploy to Blue Slot'
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ steps.getwebappname.outputs.appName }}
        images: ${{ secrets.REGISTRY_LOGIN_SERVER }}/hellobluegreenwebapp:latest
        slot-name: 'blue'
```

### Verify that the deployment to the Blue slot has been successful.

In this sample, we can verify whether or not our deployment to the blue slot was successful by simply navigating to the blue slot of our App Service.

The URL for our blue slot will take the following format:

```https://<name-of-app-service>-<slot-name>.azurewebsites.net```

In this sample, we're just deploying to our blue slot and manually verifying whether or not our container image deployed successfully. In production scenarios, we'll need to include tasks, such as automation tests, to ensure that our deployed container image works as expected before we deploy to our production slot.

### Swap from our blue slot into the Green slot.

Once we have verified that our deployment to the blue slot has been successful, we can deploy our container image to the green slot. We can do this using the following job in our GitHub Actions workflow:

```yaml
swap-to-green-slot:
    runs-on: ubuntu-latest
    environment: Dev
    needs: deploy-to-blue-slot
    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@main
      
    - name: 'Login via Azure CLI'
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: 'Get App Name'
      id: getwebappname
      run: |
        a=$(az webapp list -g ${{ secrets.AZURE_RG }} --query '[].{Name:name}' -o tsv)
        echo "::set-output name=appName::$a"

    - name: 'Swap to green slot'
      uses: Azure/cli@v1
      with:
        inlineScript: |
          az webapp deployment slot swap --slot 'blue' --resource-group ${{ secrets.AZURE_RG }} --name ${{ steps.getwebappname.outputs.appName }}
```

In this job, we use environments to manually approve the deployment to our production slot provided that our deployment to the blue slot was successful. We can assign a user or users that need to approve the deployment before this job runs.

In this sample, we just use this as a manual approval step. In production scenarios, it's a good idea to run automation tests to ensure that your new container image works as expected before deploying to your production slots.

To learn more about how environments work in GitHub Actions, check out the following [documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment).

Finally, we initiate the swap to the production slot by using the AZ CLI. Here are just swapping from our blue slot into our green slot. To learn more about how we can wrok with slots using the AZ CLI, please review the following [documentation](https://docs.microsoft.com/en-us/cli/azure/webapp/deployment/slot?view=azure-cli-latest#commands).
 
