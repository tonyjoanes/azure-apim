@description('The name of the API Management service')
param apimServiceName string

@description('The scope of the policy')
@allowed([
  'global'
  'product'
  'api'
  'operation'
])
param policyScope string = 'global'

@description('The name of the product (required if scope is product)')
param productName string = ''

@description('The name of the API (required if scope is api or operation)')
param apiName string = ''

@description('The name of the operation (required if scope is operation)')
param operationName string = ''

@description('The policy XML content')
param policyContent string

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource product 'Microsoft.ApiManagement/service/products@2023-05-01-preview' existing = if (policyScope == 'product') {
  parent: apimService
  name: productName
}

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' existing = if (policyScope == 'api' || policyScope == 'operation') {
  parent: apimService
  name: apiName
}

resource operation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' existing = if (policyScope == 'operation') {
  parent: api
  name: operationName
}

resource globalPolicy 'Microsoft.ApiManagement/service/policies@2023-05-01-preview' = if (policyScope == 'global') {
  parent: apimService
  name: 'policy'
  properties: {
    value: policyContent
    format: 'rawxml'
  }
}

resource productPolicy 'Microsoft.ApiManagement/service/products/policies@2023-05-01-preview' = if (policyScope == 'product') {
  parent: product
  name: 'policy'
  properties: {
    value: policyContent
    format: 'rawxml'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = if (policyScope == 'api') {
  parent: api
  name: 'policy'
  properties: {
    value: policyContent
    format: 'rawxml'
  }
}

resource operationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-05-01-preview' = if (policyScope == 'operation') {
  parent: operation
  name: 'policy'
  properties: {
    value: policyContent
    format: 'rawxml'
  }
}

@description('The resource ID of the policy')
output policyId string = policyScope == 'global' ? globalPolicy.id : policyScope == 'product' ? productPolicy.id : policyScope == 'api' ? apiPolicy.id : operationPolicy.id
