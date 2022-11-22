@description('The name of the Function App instance')
param functionAppName string

@description('The name of the CosmosDB instance')
param cosmosAccountName string

@description('The Service Bus Namespace Host Name')
param sbHostName string

resource functionAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource cosmosDBInstance 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: cosmosAccountName
}

var customAppSettings = {
  CosmosDbConnectionString: cosmosDBInstance.listConnectionStrings().connectionStrings[0].connectionString
  SBConnectionString__fullyQualifiedNamespace: sbHostName
}

var currentAppSettings = list('${functionAppInstance.id}/config/appsettings', '2021-02-01').properties

module configurFunctionAppSettings './append-function-appsettings.bicep' = {
  name: '${functionAppName}-appendsettings'
  params: {
    functionAppName: functionAppName
    currentAppSettings: currentAppSettings
    customAppSettings: customAppSettings
  }
}
