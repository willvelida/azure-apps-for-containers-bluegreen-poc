# Blue/Green Deployments with Azure Web Apps for Containers

This sample shows you how you can implement Blue/Green deployments for Azure Web Apps for Containers.

## Deploying our infrastructure

To deploy our infrastructure to Azure, this sample uses GitHub Actions to deploy our Bicep templates. The workflow contains the following steps:

To use GitHub Actions to deploy our Bicep file, we need to do some initial setup.

We first need a resource group in Azure to deploy our resources to. We can create this using the Azure CLI. Using the below command, replace the name with the name you want to use for your resource group and the location that you want to deploy your resources to:

```bash
az group create -n resourceGroupName -l australiaeast
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

## Pulling our container image into App Service and performing Blue/Green Deployments
