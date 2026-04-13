@description('The name of the Logic App instance')
param logicAppName string

@secure()
param currentAppSettings object

@secure()
param customAppSettings object

resource logicAppInstance 'Microsoft.Web/sites@2024-04-01' existing = {
  name: logicAppName
}

resource appsettings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: logicAppInstance
  name: 'appsettings'
  properties: union(currentAppSettings, customAppSettings)
}
