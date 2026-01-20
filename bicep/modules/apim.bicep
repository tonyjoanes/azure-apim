@description('The name of the API Management service')
param apimServiceName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('The pricing tier of the API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of the API Management service')
@allowed([
  0
  1
  2
])
param skuCount int = 1

@description('The email address of the administrator')
param publisherEmail string

@description('The name of the organization for the developer portal')
param publisherName string

@description('Enable Application Insights integration')
param enableApplicationInsights bool = true

@description('Application Insights resource ID')
param applicationInsightsId string = ''

@description('Enable Managed Identity')
param enableManagedIdentity bool = true

@description('Tags to apply to resources')
param tags object = {}

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimServiceName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: skuCount
  }
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
    virtualNetworkType: 'None'
    disableGateway: false
    apiVersionConstraint: {
      minApiVersion: '2021-08-01'
    }
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (enableApplicationInsights && !empty(applicationInsightsId)) {
  parent: apimService
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: applicationInsightsId
    credentials: {
      instrumentationKey: reference(applicationInsightsId, '2020-02-02').InstrumentationKey
    }
  }
}

resource apimDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2023-05-01-preview' = if (enableApplicationInsights && !empty(applicationInsightsId)) {
  parent: apimService
  name: 'applicationinsights'
  properties: {
    loggerId: apimLogger.id
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
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
  }
}

@description('The name of the APIM service')
output apimServiceName string = apimService.name

@description('The resource ID of the APIM service')
output apimServiceId string = apimService.id

@description('The gateway URL of the APIM service')
output gatewayUrl string = apimService.properties.gatewayUrl

@description('The developer portal URL')
output developerPortalUrl string = 'https://${apimServiceName}.developer.azure-api.net'

@description('The management API URL')
output managementApiUrl string = apimService.properties.managementApiUrl

@description('The principal ID of the managed identity')
output principalId string = enableManagedIdentity ? apimService.identity.principalId : ''
