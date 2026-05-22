using 'main.bicep'

param environmentName = 'shared'
param location = 'westeurope'

param storageAccountName = 'rgghazalsharedae2ee'
param appServicePlanName = 'ASP-rgghazalshared-9d01'
param functionAppName = 'func-ghazal-api'
param appInsightsName = 'fuc-ghazal-api'
param functionAppContentShare = 'func-ghazal-api8e2c'

// Default workspace MS auto-created. The improvements PR moves this into our RG.
param logAnalyticsWorkspaceSubscriptionId = 'c88722d5-d15f-4cd6-b123-2bc377b49266'
param logAnalyticsWorkspaceResourceGroup = 'DefaultResourceGroup-WEU'
param logAnalyticsWorkspaceName = 'DefaultWorkspace-c88722d5-d15f-4cd6-b123-2bc377b49266-WEU'

param adminSwaName = 'swa-ghazal-admin'
param customerSwaName = 'swa-ghazal-customer'
