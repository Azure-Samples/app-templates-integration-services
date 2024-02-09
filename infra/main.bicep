targetScope = 'subscription'

@description('Primary location for all resources')
param location string = deployment().location

@description('The email address of the owner of the APIM service')
@minLength(1)
param publisherEmail string = 'integrationSampleUser@sample.com'

@description('The name of the owner of the APIM service')
@minLength(1)
param publisherName string = 'Integration Sample User'

param deploymentRepositoryUrl string = 'https://github.com/aarthiem/app-templates-integration-services.git'
param deploymentBranch string = 'main'

var templatename = 'IntegrationSample'
var uniqueSuffix = substring(uniqueString(concat(subscription().id),templatename, location),0,6)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${templatename}-${uniqueSuffix}'
  location: location
  tags: {
    apptemplate: 'IntegrationSample'
  }
}

module appInsights './modules/appinsights.bicep' = {
  name: '${rg.name}-appinsights'
  scope: rg
  params: {
    applicationInsightsName: 'appinsights-${toLower(uniqueSuffix)}'
    logAnalyticsWorkspaceName: 'loganalytics-${toLower(uniqueSuffix)}'
    location: rg.location
  }
}

module logicApp './modules/logicapp.bicep' = {
  name: '${rg.name}-logicapp'
  scope: rg
  params: {
    appName: 'logicapp-${toLower(uniqueSuffix)}'
    location: rg.location
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
  }
}

module function './modules/function.bicep' = {
  name: '${rg.name}-function'
  scope: rg
  params: {
    appName: 'func-${toLower(uniqueSuffix)}'
    location: rg.location
    applicationInsightsConnectionsString: appInsights.outputs.appInsightsConnectionString
    applicationInsightsInstrumentationkey: appInsights.outputs.appInsightsInstrumentationKey
  }
}

module apim './modules/apim.bicep' = {
  name: '${rg.name}-apim'
  scope: rg
  params: {
    apimServiceName: 'apim3-${toLower(uniqueSuffix)}' //testing, remove the 3 later - Soft Delete issue
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: rg.location
    functionKey: function.outputs.functionKey  //update to secure string at some point
    functionName: function.outputs.functionAppName
  }
}

module servicebus './modules/service-bus.bicep' = {
  name: '${rg.name}-servicebus'
  scope: rg
  params: {
    nameSpace: 'sb-${toLower(uniqueSuffix)}'
    location: rg.location
  }
}

module cosmosdb './modules/cosmosdb.bicep' = {
  name: '${rg.name}-cosmosdb'
  scope: rg
  params: {
    accountName: 'cosmos-${toLower(uniqueSuffix)}'
    location: rg.location
  }
}

module roleAssignmentAPIMSenderSB './modules/configure/roleAssign-apim-service-bus.bicep' = {
  name: '${rg.name}-roleAssignmentAPIMSB'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
    sbNameSpace: servicebus.outputs.sbNameSpace
  }
  dependsOn: [
    apim
    servicebus
  ]
}

module roleAssignmentFcuntionReceiverSB './modules/configure/roleAssign-function-service-bus.bicep' = {
  name: '${rg.name}-roleAssignmentFunctionSB'
  scope: rg
  params: {
    functionAppName: function.outputs.functionAppName
    sbNameSpace: servicebus.outputs.sbNameSpace
  }
  dependsOn: [
    function
    servicebus
  ]
}

module configurFunctionAppSettings './modules/configure/configure-function.bicep' = {
  name: '${rg.name}-configureFunction'
  scope: rg
  params: {
    functionAppName: function.outputs.functionAppName
    cosmosAccountName: cosmosdb.outputs.cosmosDBAccountName
    sbHostName: servicebus.outputs.sbHostName
    deploymentRepositoryUrl: deploymentRepositoryUrl
    deploymentBranch: deploymentBranch
    sbConnString: servicebus.outputs.sbConnString
  }
  dependsOn: [
    function
    servicebus
    cosmosdb
  ]
}

module configurLogicAppSettings './modules/configure/configure-logicapp.bicep' = {
  name: '${rg.name}-configureLogicApp'
  scope: rg
  params: {
    logicAppName: logicApp.outputs.logicappAppName
    cosmosAccountName: cosmosdb.outputs.cosmosDBAccountName
    sbHostName: servicebus.outputs.sbHostName
    deploymentRepositoryUrl: deploymentRepositoryUrl
    deploymentBranch: deploymentBranch
  }
  dependsOn: [
    logicApp
    servicebus
    cosmosdb
  ]
}

//  Telemetry Deployment
@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true

var telemetryId = '69ef933a-eff0-450b-8a46-331cf62e160f-apptemp-${location}'
resource telemetrydeployment 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry) {
  name: telemetryId
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}

output apimServideBusOperation string = '${apim.outputs.apimEndpoint}/sb-operations/'
