targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
  tags: {
    apptemplate: 'IntegrationSample'
  }
}


module apim './modules/apim.bicep' = {
  name: '${rg.name}-apim'
  scope: rg
  params: {
    apimServiceName: 'apim-${toLower(name)}'
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: rg.location
  }
}

module servicebus './modules/service-bus.bicep' = {
  name: '${rg.name}-servicebus'
  scope: rg
  params: {
    nameSpace: 'sb-${toLower(name)}'
    location: rg.location
  }
}

module cosmosdb './modules/cosmosdb.bicep' = {
  name: '${rg.name}-cosmosdb'
  scope: rg
  params: {
    accountName: 'cosmos-${toLower(name)}'
    location: rg.location
  }
}

module function './modules/function.bicep' = {
  name: '${rg.name}-function'
  scope: rg
  params: {
    appName: 'func-${toLower(name)}'
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
