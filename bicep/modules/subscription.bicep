@description('The name of the API Management service')
param apimServiceName string

@description('The name of the subscription')
param subscriptionName string

@description('The display name of the subscription')
param displayName string

@description('The scope of the subscription (product or API)')
param scope string

@description('State of the subscription')
@allowed([
  'active'
  'cancelled'
  'expired'
  'rejected'
  'submitted'
  'suspended'
])
param state string = 'active'

@description('Whether to allow tracing')
param allowTracing bool = false

@description('Primary subscription key (leave empty to auto-generate)')
param primaryKey string = ''

@description('Secondary subscription key (leave empty to auto-generate)')
param secondaryKey string = ''

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource subscription 'Microsoft.ApiManagement/service/subscriptions@2023-05-01-preview' = {
  parent: apimService
  name: subscriptionName
  properties: {
    displayName: displayName
    scope: scope
    state: state
    allowTracing: allowTracing
    primaryKey: !empty(primaryKey) ? primaryKey : null
    secondaryKey: !empty(secondaryKey) ? secondaryKey : null
  }
}

@description('The resource ID of the subscription')
output subscriptionId string = subscription.id

@description('The name of the subscription')
output subscriptionName string = subscription.name

@description('The primary subscription key')
output primaryKey string = subscription.properties.primaryKey

@description('The secondary subscription key')
output secondaryKey string = subscription.properties.secondaryKey
