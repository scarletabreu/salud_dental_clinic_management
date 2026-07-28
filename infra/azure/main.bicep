targetScope = 'subscription'

@description('Grupo que contiene los dos ambientes de Azure Static Web Apps.')
param resourceGroupName string

@description('Región del resource group.')
param resourceGroupLocation string = 'eastus'

@description('Región de Azure Static Web Apps.')
param staticWebAppsLocation string = 'eastus2'

@description('Prefijo globalmente único. Se añaden los sufijos -test y -prod.')
@minLength(3)
@maxLength(48)
param appNamePrefix string

@allowed([
  'Free'
  'Standard'
])
@description('SKU de ambos recursos. Free es suficiente mientras no se requieran funciones Standard.')
param skuName string = 'Free'

@description('Etiquetas comunes para trazabilidad y control de costos.')
param tags object = {
  application: 'salud-dental'
  managedBy: 'bicep'
  ticket: 'SD-133'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: tags
}

module staticWebApps './static-web-apps.bicep' = {
  name: 'static-web-apps-${uniqueString(resourceGroup.id)}'
  scope: resourceGroup
  params: {
    location: staticWebAppsLocation
    namePrefix: appNamePrefix
    skuName: skuName
    tags: tags
  }
}

output resourceGroupName string = resourceGroup.name
output testAppName string = staticWebApps.outputs.testAppName
output testUrl string = 'https://${staticWebApps.outputs.testDefaultHostname}'
output productionAppName string = staticWebApps.outputs.productionAppName
output productionUrl string = 'https://${staticWebApps.outputs.productionDefaultHostname}'
