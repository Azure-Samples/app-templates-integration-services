@description('The name of the Logic App instance')
param logicAppName string

@description('The name of the CosmosDB instance')
param cosmosAccountName string

@description('The Service Bus Namespace Host Name')
param sbHostName string

resource logicAppInstance 'Microsoft.Web/sites@2024-04-01' existing = {
  name: logicAppName
}

resource cosmosDBInstance 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: cosmosAccountName
}

var customAppSettings = {
  serviceBus_fullyQualifiedNamespace: sbHostName
  CosmosDB__accountEndpoint: cosmosDBInstance.properties.documentEndpoint
}

var currentAppSettings = list('${logicAppInstance.id}/config/appsettings', '2024-04-01').properties

module configureLogicAppSettings './append-logicapp-appsettings.bicep' = {
  name: '${logicAppName}-appendsettings'
  params: {
    logicAppName: logicAppName
    currentAppSettings: currentAppSettings
    customAppSettings: customAppSettings
  }
}
