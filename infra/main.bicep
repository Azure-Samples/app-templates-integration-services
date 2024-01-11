targetScope = 'subscription'


@description('Primary location for all resources')
param location string = deployment().location

@description('The email address of the owner of the APIM service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the APIM service')
@minLength(1)
param publisherName string

var templatename = 'IntegrationSample'
var uniqueSuffix = substring(uniqueString(concat(subscription().id),templatename, location),0,6)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${templatename}-${uniqueSuffix}'
  location: location
  tags: {
    apptemplate: 'IntegrationSample'
  }
}

module apim './modules/apim.bicep' = {
  name: '${rg.name}-apim'
  scope: rg
  params: {
    apimServiceName: 'apim-${toLower(uniqueSuffix)}'
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: rg.location
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

module function './modules/function.bicep' = {
  name: '${rg.name}-function'
  scope: rg
  params: {
    appName: 'func-${toLower(uniqueSuffix)}'
    location: rg.location
    appInsightsLocation: rg.location
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
  }
  dependsOn: [
    function
    servicebus
    cosmosdb
  ]
}

module configurAPIM './modules/configure/configure-apim.bicep' = {
  name: '${rg.name}-configureAPIM'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
    sbEndpoint: servicebus.outputs.sbEndpoint
  }
  dependsOn: [
    apim
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
