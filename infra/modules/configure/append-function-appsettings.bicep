
@description('The name of the Function App instance')
param functionAppName string

@secure()
param currentAppSettings object

@secure()
param customAppSettings object


resource functionAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource appsettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionAppInstance
  name: 'appsettings'
  properties: union(customAppSettings,currentAppSettings)
}
