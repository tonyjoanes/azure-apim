@description('The name of the API Management service')
param apimServiceName string

@description('The name of the backend')
param backendName string

@description('The title of the backend')
param backendTitle string = ''

@description('The description of the backend')
param backendDescription string = ''

@description('The backend URL')
param backendUrl string

@description('Backend protocol')
@allowed([
  'http'
  'soap'
])
param protocol string = 'http'

@description('Resource ID for backends hosted in Azure (App Service, Function App, etc.)')
param resourceId string = ''

@description('Enable circuit breaker')
param enableCircuitBreaker bool = false

@description('Circuit breaker failure threshold')
param circuitBreakerFailureThreshold int = 3

@description('Circuit breaker success threshold')
param circuitBreakerSuccessThreshold int = 1

@description('Circuit breaker timeout in seconds')
param circuitBreakerTimeout int = 60

@description('Circuit breaker trip duration in seconds')
param circuitBreakerTripDuration int = 60

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource backend 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apimService
  name: backendName
  properties: {
    title: !empty(backendTitle) ? backendTitle : backendName
    description: backendDescription
    url: backendUrl
    protocol: protocol
    resourceId: !empty(resourceId) ? resourceId : null
    circuitBreaker: enableCircuitBreaker ? {
      rules: [
        {
          failureCondition: {
            count: circuitBreakerFailureThreshold
            errorReasons: [
              'Server errors'
            ]
            interval: 'PT${circuitBreakerTimeout}S'
            statusCodeRanges: [
              {
                min: 500
                max: 599
              }
            ]
          }
          name: 'circuitBreakerRule'
          tripDuration: 'PT${circuitBreakerTripDuration}S'
          acceptRetryAfter: true
        }
      ]
    } : null
  }
}

@description('The resource ID of the backend')
output backendId string = backend.id

@description('The name of the backend')
output backendName string = backend.name
