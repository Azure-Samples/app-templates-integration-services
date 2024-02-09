@description('The name of the API Management service instance')
param apimServiceName string

@description('The name of the Function App')
param functionAppName string

@description('API Key for the function')
param functionApiKey string

var subscriptionId = subscription().subscriptionId
var resourceGroupName = resourceGroup().name

resource apimInstance 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apimServiceName
}

resource func_api 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: 'function-operations'
  parent: apimInstance
  properties: {
    displayName: 'Function Operations'
    path: 'func-operations'
    apiType: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

resource func_apiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'send-func-message'
  parent: func_api
  properties:{
    displayName: 'Send Message'
    method: 'POST'
    urlTemplate: '/'
  }
}

resource funcOperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name:'policy'
  parent: func_apiOperation
  properties: {
    format: 'rawxml'
    value: loadTextContent('./policies/apimpolicy-function.xml')
  }
}

resource func_NameValue 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  name: 'function-api-key'
  parent: apimInstance
  properties: {
    displayName: 'function-api-key'
    secret: true
    tags: [
      'key'
      'function'
    ]
    value: functionApiKey
  }
}

resource func_BackendService 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'function-backend'
  parent: apimInstance
  dependsOn: [
    func_NameValue
  ]
  properties: {
    url: 'https://func-4z34nm.azurewebsites.net/api/APIMtoSB' //this will need to be parameterized
    protocol: 'http'
    resourceId: 'https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/sites/${functionAppName}'
    credentials: {
      header: {
        'x-functions-key': ['{{function-api-key}}']
      }
    }
    tls: {
      validateCertificateChain: false
      validateCertificateName: false
    }
  }
}

