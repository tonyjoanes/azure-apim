@description('The name of the API Management service')
param apimServiceName string

@description('The name/ID of the version set')
param versionSetName string

@description('The display name of the version set')
param versionSetDisplayName string

@description('Description of the version set')
param versionSetDescription string = ''

@description('Versioning scheme')
@allowed([
  'Segment'  // URL path: /v1/resource, /v2/resource (RECOMMENDED)
  'Query'    // Query string: /resource?api-version=1
  'Header'   // HTTP header: Api-Version: 1
])
param versioningScheme string = 'Segment'

@description('Query parameter name (only used if versioningScheme is Query)')
param versionQueryName string = 'api-version'

@description('Header name (only used if versioningScheme is Header)')
param versionHeaderName string = 'Api-Version'

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apimService
  name: versionSetName
  properties: {
    displayName: versionSetDisplayName
    description: versionSetDescription
    versioningScheme: versioningScheme
    versionQueryName: versioningScheme == 'Query' ? versionQueryName : null
    versionHeaderName: versioningScheme == 'Header' ? versionHeaderName : null
  }
}

@description('The resource ID of the version set')
output versionSetId string = apiVersionSet.id

@description('The name of the version set')
output versionSetName string = apiVersionSet.name
