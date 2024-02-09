@description('The name of the API Management service instance')
param apimServiceName string = 'apim-${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

// @description('The Service Bus endpoint')
// param sbEndpoint string

@description('The function name')
param functionName string

@description('The function key')
param functionKey string

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

// module configurApimSbApi './configure/configure-apim-sbapi.bicep' = {
//   name: '${rg.name}-configureAPIM-sbApi'
//   //scope: rg
//   params: {
//     apimServiceName: apimServiceName
//     sbEndpoint: sbEndpoint
//   }
//   dependsOn: [
//     apiManagementService
//   ]
// }

module configurApimFuncApi './configure/configure-apim-funcapi.bicep' = {
  name: '${rg.name}-configureAPIM-funcApi'
  //scope: rg
  params: {
    apimServiceName: apimServiceName
    functionApiKey: functionKey
    functionAppName: functionName
  }
  dependsOn: [
    apiManagementService
  ]
}

output apimServiceName string = apiManagementService.name
output apimEndpoint string = apiManagementService.properties.gatewayUrl

