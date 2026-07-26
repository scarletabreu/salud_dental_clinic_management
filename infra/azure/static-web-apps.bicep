targetScope = 'resourceGroup'

param location string
param namePrefix string
param skuName string
param tags object

resource testApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: '${namePrefix}-test'
  location: location
  tags: union(tags, {
    environment: 'test'
    authorizedBranch: 'dev'
  })
  sku: {
    name: skuName
    tier: skuName
  }
  properties: {
    allowConfigFileUpdates: true
    branch: 'dev'
    stagingEnvironmentPolicy: 'Disabled'
  }
}

resource productionApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: '${namePrefix}-prod'
  location: location
  tags: union(tags, {
    environment: 'production'
    authorizedBranch: 'main'
  })
  sku: {
    name: skuName
    tier: skuName
  }
  properties: {
    allowConfigFileUpdates: true
    branch: 'main'
    stagingEnvironmentPolicy: 'Disabled'
  }
}

output testAppName string = testApp.name
output testDefaultHostname string = testApp.properties.defaultHostname
output productionAppName string = productionApp.name
output productionDefaultHostname string = productionApp.properties.defaultHostname
