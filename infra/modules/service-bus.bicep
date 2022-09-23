@description('The Service Bus Namespace')
param nameSpace string = 'sb-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The pricing tier of this Service Bus Namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: nameSpace
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


resource sbQueues 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
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

output sbNameSpace string = serviceBusNamespace.name
output sbHostName string = '${serviceBusNamespace.name}.servicebus.windows.net'
output sbEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint 
