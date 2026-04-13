@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true

@description('Location for the telemetry deployment.')
param location string

var telemetryId = '69ef933a-eff0-450b-8a46-331cf62e160f-apptemp-${location}'

#disable-next-line no-deployments-resources
resource telemetrydeployment 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: telemetryId
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}
