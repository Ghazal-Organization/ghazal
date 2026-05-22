param name string

// The two SWAs are linked to GitHub and managed by .github/workflows/deploy-{admin,customer}-web.yml. Bicep references them
// as read-only so the IaC catalogues them without risking the GitHub binding,
// SWA deployment token, or build properties
resource swa 'Microsoft.Web/staticSites@2023-12-01' existing = {
  name: name
}

output id string = swa.id
output defaultHostname string = swa.properties.defaultHostname
