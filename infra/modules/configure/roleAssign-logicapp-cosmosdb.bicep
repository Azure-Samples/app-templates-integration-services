@description('The name of the Logic App instance')
param logicAppName string

@description('The name of the Cosmos DB account')
param cosmosAccountName string

resource logicAppInstance 'Microsoft.Web/sites@2024-04-01' existing = {
  name: logicAppName
}

var logicAppPrincipalId = logicAppInstance.identity.principalId

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: cosmosAccountName
}

// Cosmos DB Built-in Data Contributor role (data plane RBAC)
resource cosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-11-15' = {
  name: guid(cosmosDBAccount.id, logicAppInstance.id, '00000000-0000-0000-0000-000000000002')
  parent: cosmosDBAccount
  properties: {
    roleDefinitionId: '${cosmosDBAccount.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: logicAppPrincipalId
    scope: cosmosDBAccount.id
  }
}
