
@description('The name of the Function App instance')
param logicAppName string

@secure()
param currentAppSettings object

@secure()
param customAppSettings object


resource logicAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: logicAppName
}

resource appsettings 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: logicAppInstance
  name: 'appsettings'
  properties: union(customAppSettings,currentAppSettings)
}
