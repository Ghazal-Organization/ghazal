param name string
param location string

@description('Resource id of the Log Analytics workspace backing this component.')
param workspaceResourceId string

param tags object

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
    IngestionMode: 'LogAnalytics'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Connection string is not a secret — it's a public ingestion endpoint.
output connectionString string = ai.properties.ConnectionString
output id string = ai.id
