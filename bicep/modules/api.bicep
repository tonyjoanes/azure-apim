@description('The name of the API Management service')
param apimServiceName string

@description('The name of the API')
param apiName string

@description('The display name of the API')
param apiDisplayName string

@description('The description of the API')
param apiDescription string = ''

@description('The path for the API')
param apiPath string

@description('The backend service URL')
param serviceUrl string

@description('API protocols')
@allowed([
  'http'
  'https'
])
param protocols array = ['https']

@description('Require subscription for this API')
param subscriptionRequired bool = true

@description('API type')
@allowed([
  'http'
  'soap'
  'websocket'
  'graphql'
])
param apiType string = 'http'

@description('OpenAPI specification URL or content')
param openApiSpec string = ''

@description('Format of the API specification')
@allowed([
  'openapi'
  'openapi+json'
  'openapi-link'
  'swagger-json'
  'swagger-link-json'
  'wadl-link-json'
  'wsdl'
  'wsdl-link'
])
param apiSpecFormat string = 'openapi+json'

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: apiName
  properties: {
    displayName: apiDisplayName
    description: apiDescription
    path: apiPath
    serviceUrl: serviceUrl
    protocols: protocols
    subscriptionRequired: subscriptionRequired
    type: apiType
    format: !empty(openApiSpec) ? apiSpecFormat : null
    value: !empty(openApiSpec) ? openApiSpec : null
    apiRevision: '1'
    isCurrent: true
  }
}

@description('The resource ID of the API')
output apiId string = api.id

@description('The name of the API')
output apiName string = api.name

@description('The path of the API')
output apiPath string = api.properties.path
