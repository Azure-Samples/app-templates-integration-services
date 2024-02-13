@description('The name of the Logic App instance')
param logicAppName string

@description('The name of the CosmosDB instance')
param cosmosAccountName string

@description('The Service Bus Namespace Host Name')
param sbHostName string

param deploymentRepositoryUrl string
param deploymentBranch string

resource logicAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: logicAppName
}

resource cosmosDBInstance 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: cosmosAccountName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: sbHostName
}

var customAppSettings = {
  AzureCosmosDB_connectionString: cosmosDBInstance.listConnectionStrings().connectionStrings[0].connectionString
  SBConnectionString__fullyQualifiedNamespace: sbHostName
  serviceBus_connectionString: serviceBusNamespace.listConnectionStrings().primaryConnectionString
}

var currentAppSettings = list('${logicAppInstance.id}/config/appsettings', '2021-02-01').properties

module configurLogicAppSettings './append-logicapp-appsettings.bicep' = {
  name: '${logicAppName}-appendsettings'
  params: {
    logicAppName: logicAppName
    currentAppSettings: currentAppSettings
    customAppSettings: customAppSettings
  }
}

resource srcControls 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: 'web'
  parent: logicAppInstance
  properties: {
    repoUrl: deploymentRepositoryUrl
    branch: deploymentBranch
    isManualIntegration: true
  }
  dependsOn: [
    configurLogicAppSettings
  ]
}
