targetScope = 'resourceGroup'

@description('The name of the API Management service')
@minLength(1)
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
param skuCount int = 1

@description('The email address of the administrator')
param publisherEmail string

@description('The name of the organization')
param publisherName string

@description('Enable Application Insights')
param enableApplicationInsights bool = true

@description('Application Insights name')
param applicationInsightsName string = '${apimServiceName}-ai'

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = '${apimServiceName}-law'

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Development'
  Purpose: 'Learning'
  ManagedBy: 'Bicep'
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableApplicationInsights) {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// APIM Instance
module apim '../modules/apim.bicep' = {
  name: 'apim-deployment'
  params: {
    apimServiceName: apimServiceName
    location: location
    sku: sku
    skuCount: skuCount
    publisherEmail: publisherEmail
    publisherName: publisherName
    enableApplicationInsights: enableApplicationInsights
    applicationInsightsId: enableApplicationInsights ? applicationInsights.id : ''
    enableManagedIdentity: true
    tags: tags
  }
}

// Sample Product - Starter
module starterProduct '../modules/product.bicep' = {
  name: 'starter-product-deployment'
  params: {
    apimServiceName: apim.outputs.apimServiceName
    productName: 'starter'
    productDisplayName: 'Starter'
    productDescription: 'Starter product with limited rate limits for testing'
    approvalRequired: false
    subscriptionRequired: true
    state: 'published'
    subscriptionsLimit: 100
  }
  dependsOn: [
    apim
  ]
}

// Sample Product - Premium
module premiumProduct '../modules/product.bicep' = {
  name: 'premium-product-deployment'
  params: {
    apimServiceName: apim.outputs.apimServiceName
    productName: 'premium'
    productDisplayName: 'Premium'
    productDescription: 'Premium product with higher rate limits and access to all APIs'
    approvalRequired: true
    subscriptionRequired: true
    state: 'published'
    subscriptionsLimit: 10
  }
  dependsOn: [
    apim
  ]
}

// Outputs
@description('The name of the APIM service')
output apimServiceName string = apim.outputs.apimServiceName

@description('The resource ID of the APIM service')
output apimServiceId string = apim.outputs.apimServiceId

@description('The gateway URL')
output gatewayUrl string = apim.outputs.gatewayUrl

@description('The developer portal URL')
output developerPortalUrl string = apim.outputs.developerPortalUrl

@description('The management API URL')
output managementApiUrl string = apim.outputs.managementApiUrl

@description('The principal ID of the managed identity')
output principalId string = apim.outputs.principalId

@description('Application Insights Instrumentation Key')
output applicationInsightsInstrumentationKey string = enableApplicationInsights ? applicationInsights.properties.InstrumentationKey : ''

@description('Application Insights Connection String')
output applicationInsightsConnectionString string = enableApplicationInsights ? applicationInsights.properties.ConnectionString : ''
