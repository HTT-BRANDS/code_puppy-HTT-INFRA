# Cost Center Dashboard - Authentication & Credentials Setup

Complete guide to migrate authentication from the old cost-center repository to the new code-puppy-HTT-INFRA fork.

## 📋 Overview

The Cost Center Dashboard uses **Azure OIDC (OpenID Connect)** for secure GitHub Actions authentication to Azure. This eliminates the need for long-lived secrets.

### Architecture
```
GitHub Actions → GitHub OIDC Token → Azure OIDC Federated Credential → Azure Resources
                 (JWT from github.com)                                  (No stored secrets)
```

## 🔐 Prerequisites

Before setting up authentication, ensure you have:

1. **Azure Subscription** with appropriate permissions
2. **Azure App Registration** (Service Principal) for cost-center data collection
3. **Azure OIDC Federated Credential** configured (already created in Migration phase)
4. **GitHub repository** with write access to secrets
5. **GitHub CLI** (`gh`) installed and authenticated

Verify prerequisites:
```bash
# Check GitHub CLI
gh auth status

# Check Azure CLI
az account show

# List app registrations
az ad app list --display-name "cost-center" --query "[].{name:displayName, appId:appId}"
```

## 🔑 Step-by-Step Setup

### Step 1: Verify Azure App Registration

Ensure your cost-center app registration has the required API permissions:

```bash
# List your app registrations
APP_ID=$(az ad app list --display-name "cost-center" --query "[0].appId" -o tsv)

# View API permissions
az ad app permission list --id "$APP_ID"

# Required permissions:
# - Microsoft Graph: User.Read.All, Directory.Read.All
# - Azure Cost Management: user_impersonation
# - Azure Resource Manager: user_impersonation
```

### Step 2: Verify OIDC Federated Credential

Check that the GitHub OIDC federated credential is configured:

```bash
# List federated credentials
az identity federated-credential list \
  --resource-group <your-rg> \
  --identity-name <your-identity> \
  --query "[].{name:name, issuer:issuer, subject:subject}"

# Expected values:
# issuer: https://token.actions.githubusercontent.com
# subject: repo:HTT-BRANDS/code_puppy-HTT-INFRA:ref:refs/heads/main
```

**Reference Credential ID**: `3446b1f1-be9f-4f57-a3fe-f29dc5bd2008`

### Step 3: Configure GitHub Secrets

Use the interactive setup script:

```bash
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

This script will prompt you for:

1. **AZURE_OIDC_CLIENT_ID** - Your app registration's Client ID
   ```bash
   az ad app list --display-name "cost-center" --query "[0].appId" -o tsv
   ```

2. **AZURE_TENANT_ID** - Your Azure tenant ID
   ```bash
   az account show --query tenantId -o tsv
   ```

3. **AZURE_SUBSCRIPTION_ID** - Your Azure subscription ID
   ```bash
   az account show --query id -o tsv
   ```

4. **TENANTS_CONFIG** - Base64-encoded JSON configuration
   ```json
   {
     "azureClientId": "<your-app-id>",
     "tenants": [
       {
         "name": "Production",
         "tenantId": "<tenant-id>",
         "subscriptions": ["<sub-1>", "<sub-2>"],
         "githubOrg": "HTT-BRANDS"
       }
     ]
   }
   ```

5. **AZURE_STATIC_WEB_APPS_API_TOKEN** (optional) - For dashboard deployment

### Step 4: Manual GitHub Secret Configuration

Alternatively, set secrets manually via GitHub CLI:

```bash
REPO="HTT-BRANDS/code_puppy-HTT-INFRA"
ENV="production"

# Set secrets in production environment
echo "$AZURE_OIDC_CLIENT_ID" | gh secret set AZURE_OIDC_CLIENT_ID --repo "$REPO" --env "$ENV"
echo "$AZURE_TENANT_ID" | gh secret set AZURE_TENANT_ID --repo "$REPO" --env "$ENV"
echo "$AZURE_SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID --repo "$REPO" --env "$ENV"

# Base64 encode and set tenants configuration
cat tenants.json | base64 | gh secret set TENANTS_CONFIG --repo "$REPO" --env "$ENV"

# Verify secrets are set (shows only names, not values)
gh secret list --repo "$REPO" --env "$ENV"
```

### Step 5: Verify Secret Configuration

List configured secrets:

```bash
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
```

Expected output:
```
AZURE_OIDC_CLIENT_ID      Updated 2026-01-05
AZURE_TENANT_ID           Updated 2026-01-05
AZURE_SUBSCRIPTION_ID     Updated 2026-01-05
TENANTS_CONFIG            Updated 2026-01-05
AZURE_STATIC_WEB_APPS_API_TOKEN  Updated 2026-01-05 (if set)
```

## 🧪 Testing Authentication

### Test 1: Run Manual Workflow

```bash
# Trigger cost-center-audit workflow manually
gh workflow run cost-center-audit.yml \
  --repo HTT-BRANDS/code_puppy-HTT-INFRA \
  --ref main

# Monitor the run
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 5

# View logs
gh run view <run-id> --log
```

### Test 2: Check OIDC Token Exchange

The workflow will automatically:
1. Generate GitHub OIDC token with issuer `https://token.actions.githubusercontent.com`
2. Exchange it for Azure access token using federated credential
3. Authenticate to Azure without storing credentials

### Test 3: Verify Cost Data Collection

Monitor the workflow execution:
- ✅ Checkout code
- ✅ Setup Python 3.12
- ✅ Install dependencies (uv sync)
- ✅ **Azure Login via OIDC** - Federated credential exchange
- ✅ Copy tenant configuration from secrets
- ✅ Run cost center collectors
- ✅ Upload report artifacts
- ✅ Deploy dashboard (if enabled)

## 🔄 Migration from Old Repository

### Remove Old Secrets

If migrating from a previous cost-center repository:

```bash
# List and remove old repository secrets
gh secret list --repo <old-repo>

# Delete secrets from old repo
gh secret delete AZURE_ACCOUNT --repo <old-repo>
gh secret delete AZURE_TENANT_ID --repo <old-repo>
# ... etc
```

### Key Differences

| Aspect | Old Setup | New Setup |
|--------|-----------|-----------|
| Auth Method | Service Principal (stored credentials) | Azure OIDC (federated credential) |
| Secrets | Long-lived account key | Temporary OIDC token |
| Risk | High (credentials in storage) | Low (ephemeral tokens) |
| Setup | Manual secret rotation | Automatic token exchange |
| Maintenance | Regular updates needed | No manual updates |

## 🛡️ Security Best Practices

1. **Never commit secrets** - Always use GitHub repository secrets
2. **Use environments** - Set secrets per environment (production, staging)
3. **Rotate credentials regularly** - Though OIDC tokens are ephemeral
4. **Audit access** - Review workflow logs in GitHub Actions
5. **Monitor permissions** - Verify app registration has minimum required permissions
6. **Base64 encode configs** - Use `echo "config" | base64` for complex JSON

## 🚨 Troubleshooting

### Error: "Azure Login via OIDC failed"

**Cause**: Federated credential not configured or incorrect values

**Solution**:
```bash
# Verify federated credential exists
az identity federated-credential show \
  --name <credential-name> \
  --identity-name <identity-name> \
  --resource-group <rg>

# Check issuer and subject
# issuer: https://token.actions.githubusercontent.com
# subject: repo:HTT-BRANDS/code_puppy-HTT-INFRA:ref:refs/heads/main
```

### Error: "Unauthorized to access Azure resources"

**Cause**: App registration lacks required permissions

**Solution**:
```bash
# Add Microsoft Graph permissions
az ad app permission add \
  --id "$APP_ID" \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope

# Add Cost Management permissions
az ad app permission add \
  --id "$APP_ID" \
  --api "https://management.azure.com" \
  --api-permissions user_impersonation=Scope
```

### Error: "Secret not found"

**Cause**: Secret not set in GitHub environment

**Solution**:
```bash
# Set missing secret
echo "$VALUE" | gh secret set SECRET_NAME --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production

# Verify it was set
gh secret view SECRET_NAME --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
```

## 📚 References

- [Azure Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation)
- [GitHub Actions: Azure Login](https://github.com/Azure/login)
- [GitHub Actions: Using OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Cost Center Dashboard: MIGRATION_PLAN.md](./MIGRATION_PLAN.md)

## ✅ Verification Checklist

- [ ] Azure app registration exists with client ID
- [ ] Azure OIDC federated credential created (ID: 3446b1f1-be9f-4f57-a3fe-f29dc5bd2008)
- [ ] GitHub secrets configured:
  - [ ] AZURE_OIDC_CLIENT_ID
  - [ ] AZURE_TENANT_ID
  - [ ] AZURE_SUBSCRIPTION_ID
  - [ ] TENANTS_CONFIG (base64 encoded)
  - [ ] AZURE_STATIC_WEB_APPS_API_TOKEN (optional)
- [ ] Repository environment set to "production"
- [ ] cost-center-audit.yml workflow exists
- [ ] Manual workflow execution successful
- [ ] Cost data collected from Azure
- [ ] Dashboard updated with latest costs

## 🎯 Next Steps

1. Run setup script: `./scripts/setup-github-secrets.sh`
2. Verify secrets with: `gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production`
3. Test workflow: `gh workflow run cost-center-audit.yml --repo HTT-BRANDS/code_puppy-HTT-INFRA`
4. Monitor execution and logs
5. Validate cost data in dashboard
