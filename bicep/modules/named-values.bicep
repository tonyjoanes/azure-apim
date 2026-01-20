@description('The name of the API Management service')
param apimServiceName string

@description('The name of the named value')
param namedValueName string

@description('The display name of the named value')
param displayName string

@description('The value')
@secure()
param value string

@description('Whether the value is secret')
param secret bool = false

@description('Tags for the named value')
param tags array = []

@description('Key Vault secret identifier (if using Key Vault)')
param keyVaultSecretId string = ''

resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

resource namedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apimService
  name: namedValueName
  properties: {
    displayName: displayName
    secret: secret
    tags: tags
    value: empty(keyVaultSecretId) ? value : null
    keyVault: !empty(keyVaultSecretId) ? {
      secretIdentifier: keyVaultSecretId
    } : null
  }
}

@description('The resource ID of the named value')
output namedValueId string = namedValue.id

@description('The name of the named value')
output namedValueName string = namedValue.name
