param name string
param location string
param tags object

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    // Shared-key access stays enabled because the Function App still uses
    // connection strings. Flipped to identity-based access in the
    // improvements PR (required managed identity + RBAC role assignment).
    allowSharedKeyAccess: true
  }
}

output id string = storage.id
output name string = storage.name
