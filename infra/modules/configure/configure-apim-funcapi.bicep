@description('The name of the API Management service instance')
param apimServiceName string

@description('The name of the Function App')
param functionAppName string

@description('id of the app insights logger')
param loggerId string

var subscriptionId = subscription().subscriptionId
var resourceGroupName = resourceGroup().name

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: functionAppName
}

//NOTE: this doesn't feel right but I couldn't find another way to get the keys
//Should switch over to managed identities instead, but am running out of time
//So will have to make the change prior to pushing to the main repo.
resource functionAppHost 'Microsoft.Web/sites/host@2022-09-01' existing = {
  name: 'default'
  parent: functionApp
}

// Master key
var functionApiKey = functionAppHost.listKeys().masterKey

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
  dependsOn: [
    func_BackendService
  ]
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
    url: 'https://${functionAppName}.azurewebsites.net/api/APIMtoSB'
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

//wire up app insights to apim api
resource func_apiOperation_applicationinsights_wireup 'Microsoft.ApiManagement/service/apis/diagnostics@2023-03-01-preview' = {
  parent: func_api //this is the API
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    verbosity: 'verbose'
    logClientIp: true
    loggerId: loggerId
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: []
        body: {
          bytes: 0
        }
      }
      response: {
        headers: []
        body: {
          bytes: 0
        }
      }
    }
    backend: {
      request: {
        headers: []
        body: {
          bytes: 0
        }
      }
      response: {
        headers: []
        body: {
          bytes: 0
        }
      }
    }
    metrics: true
  }
}

