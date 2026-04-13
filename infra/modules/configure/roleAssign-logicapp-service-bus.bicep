@description('The name of the Logic App instance')
param logicAppName string

@description('The Service Bus Namespace')
param sbNamespaceName string

resource logicAppInstance 'Microsoft.Web/sites@2024-04-01' existing = {
  name: logicAppName
}

var logicAppPrincipalId = logicAppInstance.identity.principalId

resource sbInstance 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: sbNamespaceName
}

@description('This is the built-in Azure Service Bus Data Receiver role.')
resource sbDataReceiverRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: sbInstance
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: sbInstance
  name: guid(resourceGroup().id, logicAppInstance.id, sbDataReceiverRoleDefinition.id)
  properties: {
    roleDefinitionId: sbDataReceiverRoleDefinition.id
    principalId: logicAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}
