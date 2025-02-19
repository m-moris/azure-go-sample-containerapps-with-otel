param location string = resourceGroup().location
param suffix string = '01jmbwkn7kf7w9xjqbd97hpynv'
param containerRegistryName string = 'acr${suffix}'
param containerAppEnvName string = 'cae${suffix}'
param managedIdentityName string = 'umi${suffix}'

param containerAppName string = 'simpleweb'
param containerRegistryUri string = '${containerRegistryName}.azurecr.io'
param containerImageName string = '${containerRegistryUri}/simpleweb:1.0.0'

param currentTime string = utcNow()
var unixTime = dateTimeToEpoch(currentTime)

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: containerAppEnvName
}

resource containerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      registries: [
        {
          server: containerRegistryUri
          identity: userAssignedIdentity.id
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        allowInsecure: true
        external: true
        targetPort: 8080
        transport: 'auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
    }
    template: {
      revisionSuffix: '${unixTime}'
      containers: [
        {
          name: containerAppName
          image: containerImageName
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
