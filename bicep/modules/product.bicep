@description('The name of the API Management service')
param apimServiceName string

@description('The name of the product')
param productName string

@description('The display name of the product')
param productDisplayName string

@description('The description of the product')
param productDescription string = ''

@description('Whether subscription approval is required')
param approvalRequired bool = false

@description('Whether a subscription is required to access APIs in this product')
param subscriptionRequired bool = true

@description('Whether the product is published')
param state string = 'published'

@description('Maximum number of subscriptions allowed')
param subscriptionsLimit int = 1

@description('Terms of use for the product')
param terms string = ''

@description('Array of API names to associate with this product')
param apiNames array = []

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource product 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apimService
  name: productName
  properties: {
    displayName: productDisplayName
    description: productDescription
    approvalRequired: approvalRequired
    subscriptionRequired: subscriptionRequired
    state: state
    subscriptionsLimit: subscriptionsLimit
    terms: terms
  }
}

resource productApis 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = [for apiName in apiNames: {
  parent: product
  name: apiName
}]

@description('The resource ID of the product')
output productId string = product.id

@description('The name of the product')
output productName string = product.name
