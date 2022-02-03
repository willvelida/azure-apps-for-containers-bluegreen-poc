# Blue/Green Deployments with Azure Web Apps for Containers

This sample shows you how you can implement Blue/Green deployments for Azure Web Apps for Containers.

## Deploying our infrastructure

To deploy our infrastructure to Azure, this sample uses GitHub Actions to deploy our Bicep templates. The workflow contains the following steps:

To use GitHub Actions to deploy our Bicep file, we need to do some initial setup.

We first need a resource group in Azure to deploy our resources to. We can create this using the Azure CLI. Using the below command, replace the name with the name you want to use for your resource group and the location that you want to deploy your resources to:

```bash
az group create -n exampleRG -l australiaeast
```

Once you have created your resource group, we need to generate deployment credentials. The GitHub Action that we use for our deployment needs to run under an identity. We can use the Azure CLI to create a service principal for the identity.

```bash
az ad sp create-for-rbac --name yourApp --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/exampleRG --sdk-auth
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

Now that we have our secrets setup, we cann create our workflow file. An example file has been created [here](./gihub/workflows/deployContainer.yml).

## Pulling our container image into App Service and performing Blue/Green Deployments

[TODO]

- [Talking about deployment for containers](https://docs.microsoft.com/en-us/azure/app-service/tutorial-custom-container?pivots=container-linux#optional-examine-the-docker-file)
- Talk about environments in GitHub
- [assigning identity to pull container](https://docs.microsoft.com/en-us/cli/azure/webapp/identity?view=azure-cli-latest#az_webapp_identity-assign)
- [swapping slots](https://docs.microsoft.com/en-us/cli/azure/webapp/deployment/slot?view=azure-cli-latest#az-webapp-deployment-slot-swap) 
