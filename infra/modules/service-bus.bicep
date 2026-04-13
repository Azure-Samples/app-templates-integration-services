@description('The Service Bus Namespace name (6–50 alphanumeric characters and hyphens, must start with a letter)')
@minLength(6)
@maxLength(50)
param namespaceName string = 'sb-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The pricing tier of this Service Bus Namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: namespaceName
  location: location
  sku: {
    capacity: 1
    name: sku
    tier: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    zoneRedundant: false
  }
}


resource sbQueue 'Microsoft.ServiceBus/namespaces/queues@2024-01-01' = {
  name: 'demo-queue'
  parent: serviceBusNamespace
  properties: {
    deadLetteringOnMessageExpiration: false
    defaultMessageTimeToLive: 'P14D'
    enableBatchedOperations: true
    enableExpress: false
    enablePartitioning: false
    lockDuration: 'PT30S'
    maxDeliveryCount: 10
    requiresDuplicateDetection: false
    requiresSession: false
  }
}

output sbNamespaceName string = serviceBusNamespace.name
output sbHostName string = '${serviceBusNamespace.name}.servicebus.windows.net'
output sbEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint 
