@description('The name of the API Management service instance')
param apimServiceName string = 'apim-${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

@description('The function name')
param functionName string

@description('App Insights Resource name')
param appInsightsName string

// @description('The function key')
// param functionKey string

@description('The pricing tier of this API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Consumption'

@description('The instance size of this API Management service. Set to zero for Consumption SKU')
@allowed([
  1
  2
])
param skuCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

var rg = resourceGroup()

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing =  {
  name: appInsightsName
}

//Create API Management Service
resource apiManagementService 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: apimServiceName
  location: location
  sku: {
    name: sku
    capacity: (sku=='Consumption' ? 0 : skuCount)
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

//Setup App Insights for the Service
resource apiManagementService_Appinsights 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'appinsights-4z34nm'
  dependsOn: [
    namedValueAppInsightsKey
  ]
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: '{{appInsightsKeyDisplayName}}'
    }
    isBuffered: true
    resourceId: applicationInsights.id
  }
}

//Setup the named value to hold the app insights key
resource namedValueAppInsightsKey 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'appInsightsKey'
  properties: {
    displayName: 'appInsightsKeyDisplayName'
    value: applicationInsights.properties.InstrumentationKey
    secret: true
  }
}


module configurApimFuncApi './configure/configure-apim-funcapi.bicep' = {
  name: '${rg.name}-configureAPIM-funcApi'
  //scope: rg
  params: {
    apimServiceName: apimServiceName
    //functionApiKey: functionKey
    loggerId: apiManagementService_Appinsights.id
    functionAppName: functionName
  }
  dependsOn: [
    apiManagementService
  ]
}

output apimServiceName string = apiManagementService.name
output apimEndpoint string = apiManagementService.properties.gatewayUrl

