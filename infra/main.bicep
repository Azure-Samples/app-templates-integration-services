targetScope = 'subscription'

@minLength(3)
@maxLength(16)
@description('Prefix for all resources (3–16 alphanumeric characters and hyphens). Used to construct all resource names, e.g. sb-{name}, apim-{name}.')
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

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${name}'
  location: location
  tags: {
    apptemplate: 'IntegrationSample'
  }
}


module apim './modules/apim.bicep' = {
  name: '${rg.name}-apim'
  scope: rg
  dependsOn: [servicebus, cosmosdb, function]
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
    namespaceName: 'sb-${toLower(name)}'
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
    deployerPrincipalId: principalId
  }
}

module logicApp './modules/logicapp.bicep' = {
  name: '${rg.name}-logicapp'
  scope: rg
  params: {
    appName: 'logic-${toLower(name)}'
    location: rg.location
    appInsightsLocation: rg.location
  }
}

module roleAssignmentAPIMSenderSB './modules/configure/roleAssign-apim-service-bus.bicep' = {
  name: '${rg.name}-roleAssignmentAPIMSB'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
    sbNamespaceName: servicebus.outputs.sbNamespaceName
  }
}

module roleAssignmentFunctionReceiverSB './modules/configure/roleAssign-function-service-bus.bicep' = {
  name: '${rg.name}-roleAssignmentFunctionSB'
  scope: rg
  params: {
    functionAppName: function.outputs.functionAppName
    sbNamespaceName: servicebus.outputs.sbNamespaceName
  }
}

module roleAssignmentLogicAppReceiverSB './modules/configure/roleAssign-logicapp-service-bus.bicep' = {
  name: '${rg.name}-roleAssignmentLogicAppSB'
  scope: rg
  params: {
    logicAppName: logicApp.outputs.logicAppName
    sbNamespaceName: servicebus.outputs.sbNamespaceName
  }
}

module roleAssignmentLogicAppCosmosDB './modules/configure/roleAssign-logicapp-cosmosdb.bicep' = {
  name: '${rg.name}-roleAssignmentLogicAppCosmosDB'
  scope: rg
  params: {
    logicAppName: logicApp.outputs.logicAppName
    cosmosAccountName: cosmosdb.outputs.cosmosDBAccountName
  }
}

module configureLogicAppSettings './modules/configure/configure-logicapp.bicep' = {
  name: '${rg.name}-configureLogicApp'
  scope: rg
  params: {
    logicAppName: logicApp.outputs.logicAppName
    cosmosAccountName: cosmosdb.outputs.cosmosDBAccountName
    sbHostName: servicebus.outputs.sbHostName
  }
}

module configureFunctionAppSettings './modules/configure/configure-function.bicep' = {
  name: '${rg.name}-configureFunction'
  scope: rg
  params: {
    functionAppName: function.outputs.functionAppName
    cosmosAccountName: cosmosdb.outputs.cosmosDBAccountName
    sbHostName: servicebus.outputs.sbHostName
  }
}

module configureAPIM './modules/configure/configure-apim.bicep' = {
  name: '${rg.name}-configureAPIM'
  scope: rg
  params: {
    apimServiceName: apim.outputs.apimServiceName
    sbEndpoint: servicebus.outputs.sbEndpoint
  }
}

@description('Principal ID of the deploying user. Automatically populated by azd.')
param principalId string = ''

@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true

module telemetry './modules/telemetry.bicep' = {
  name: 'telemetry'
  params: {
    enableTelemetry: enableTelemetry
    location: location
  }
  scope: rg
}

output apimServiceBusOperation string = '${apim.outputs.apimEndpoint}/sb-operations/'
