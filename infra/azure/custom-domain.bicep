targetScope = 'resourceGroup'

@description('Nombre del Static Web App de producción ya creado.')
param staticWebAppName string

@description('Dominio de producción, por ejemplo app.clinica.example.')
param customDomainName string

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' existing = {
  name: staticWebAppName
}

resource customDomain 'Microsoft.Web/staticSites/customDomains@2023-12-01' = {
  parent: staticWebApp
  name: customDomainName
  properties: {
    validationMethod: 'dns-txt-token'
  }
}

output customDomainName string = customDomain.name
