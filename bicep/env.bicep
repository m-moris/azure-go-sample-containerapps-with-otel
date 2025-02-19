param location string = resourceGroup().location
param suffix string = '01jmbwkn7kf7w9xjqbd97hpynv'
param containerRegistryName string = 'acr${suffix}'
param containerAppEnvName string = 'cae${suffix}'
param managedIdentityName string = 'umi${suffix}'
param applicationInsightsName string = 'ai${suffix}'

// Create User Assigned Identity
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

// Create Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
}

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}


// Create Container App Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: containerAppEnvName
  location: location
  properties: {
    appInsightsConfiguration: { connectionString: appInsightsComponents.properties.ConnectionString }
    openTelemetryConfiguration: {
      tracesConfiguration: { destinations: ['appInsights'] }
      logsConfiguration: { destinations: ['appInsights'] }
      metricsConfiguration: { destinations: ['appInsights'] }
    }
  }
}

// Create ACR Pull Role Assignment
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, userAssignedIdentity.id, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role ID
    )
    principalId: userAssignedIdentity.properties.principalId
  }
}
