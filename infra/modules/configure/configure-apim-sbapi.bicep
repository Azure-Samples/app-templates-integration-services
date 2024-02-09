@description('The name of the API Management service instance')
param apimServiceName string

@description('The Service Bus Namespace Endpoint')
param sbEndpoint string

resource apimInstance 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apimServiceName
}

resource sb_api 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: 'service-bus-operations'
  parent: apimInstance
  properties: {
    displayName: 'Service Bus Operations'
    path: 'sb-operations'
    apiType: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

resource sb_apiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'send-sb-message'
  parent: sb_api
  properties:{
    displayName: 'Send Message'
    method: 'POST'
    urlTemplate: '/{queue_or_topic}'
    templateParameters: [
      {
        name: 'queue_or_topic'
        type: 'string'
      }
    ]
  }
}

resource sbOperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name:'policy'
  parent: sb_apiOperation
  properties: {
    format: 'rawxml'
    value: loadTextContent('./policies/apimpolicy-servicebus.xml')
  }
}


