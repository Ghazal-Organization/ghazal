// Top-level composition for the 'shared' environment in rg-ghazal-shared.
// First-run intent: az deployment group what-if reports zero changes
// (only tags may be added — that's expected).
// Improvements (managed identity, identity-based storage, dedicated LAW,
// orphan App Insights cleanup) live in a follow-up PR.

targetScope = 'resourceGroup'

@description('Logical environment name used in tags (e.g. shared, prod, staging).')
param environmentName string

@description('Region for all resources except global ones.')
param location string = 'westeurope'

param storageAccountName string
param appServicePlanName string
param functionAppName string
param appInsightsName string

@description('Stable content-share name. Changing this re-provisions the share and loses runtime state.')
param functionAppContentShare string

@description('Subscription, RG, and name of the existing Log Analytics workspace backing App Insights.')
param logAnalyticsWorkspaceSubscriptionId string
param logAnalyticsWorkspaceResourceGroup string
param logAnalyticsWorkspaceName string

param adminSwaName string
param customerSwaName string

var commonTags = {
  project: 'ghazal'
  env: environmentName
  managedBy: 'bicep'
}

var logAnalyticsWorkspaceId = resourceId(
  logAnalyticsWorkspaceSubscriptionId,
  logAnalyticsWorkspaceResourceGroup,
  'Microsoft.OperationalInsights/workspaces',
  logAnalyticsWorkspaceName
)

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    tags: commonTags
  }
}

module plan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    tags: commonTags
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalyticsWorkspaceId
    tags: commonTags
  }
}

module functionApp 'modules/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    name: functionAppName
    location: location
    tags: commonTags
    appServicePlanId: plan.outputs.id
    storageAccountName: storage.outputs.name
    appInsightsConnectionString: appInsights.outputs.connectionString
    contentShare: functionAppContentShare
  }
}

module adminSwa 'modules/staticWebApps.bicep' = {
  name: 'adminSwa'
  params: { name: adminSwaName }
}

module customerSwa 'modules/staticWebApps.bicep' = {
  name: 'customerSwa'
  params: { name: customerSwaName }
}

output functionAppHostname string = functionApp.outputs.defaultHostname
output adminSwaHostname string = adminSwa.outputs.defaultHostname
output customerSwaHostname string = customerSwa.outputs.defaultHostname
