@description('The name of the Function App instance')
param functionAppName string

@description('The Service Bus Namespace')
param sbNameSpace string

resource functionAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

var functionId = functionAppInstance.identity.principalId

resource sbInstance 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: sbNameSpace
}

@description('This is the built-in Azure Service Bus Data Sender role. ')
resource sbDataReceiverRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: sbInstance
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: sbInstance
  name: guid(resourceGroup().id, functionAppInstance.id, sbDataReceiverRoleDefinition.id)
  properties: {
    roleDefinitionId: sbDataReceiverRoleDefinition.id
    principalId: functionId
    principalType: 'ServicePrincipal'
  }
}
