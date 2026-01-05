# 🔐 GitHub Secrets Quick Reference - Cost Center Dashboard

## 📝 Required Secrets for `code_puppy-HTT-INFRA`

Configure these secrets in GitHub under: **Settings → Environments → production → Environment secrets**

### Secrets List

| Secret Name | Type | Source | Required |
|------------|------|--------|----------|
| `AZURE_OIDC_CLIENT_ID` | Text | Azure App Registration Client/App ID | ✅ Yes |
| `AZURE_TENANT_ID` | Text | Azure Tenant ID | ✅ Yes |
| `AZURE_SUBSCRIPTION_ID` | Text | Azure Subscription ID | ✅ Yes |
| `TENANTS_CONFIG` | Base64 | Encoded tenants.json | ✅ Yes |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Text | Azure Static Web Apps API Token | ⚠️ Optional |

## 🚀 Quick Setup (Copy-Paste Method)

### 1. Get Azure Values

```bash
# Get Client ID
az ad app list --display-name "cost-center" --query "[0].appId" -o tsv

# Get Tenant ID
az account show --query tenantId -o tsv

# Get Subscription ID
az account show --query id -o tsv
```

### 2. Create Tenants Configuration

```bash
# Create tenants.json with your subscriptions
cat > tenants.json << 'EOF'
{
  "azureClientId": "YOUR_CLIENT_ID_HERE",
  "tenants": [
    {
      "name": "Production",
      "tenantId": "YOUR_TENANT_ID",
      "subscriptions": ["subscription-id-1", "subscription-id-2"],
      "githubOrg": "HTT-BRANDS"
    }
  ]
}
EOF

# Base64 encode it
cat tenants.json | base64 > tenants.json.b64
cat tenants.json.b64  # Copy this output
```

### 3. Set Secrets via GitHub CLI

```bash
REPO="HTT-BRANDS/code_puppy-HTT-INFRA"
ENV="production"

# Set each secret
gh secret set AZURE_OIDC_CLIENT_ID --repo "$REPO" --env "$ENV" < <(echo "YOUR_CLIENT_ID")
gh secret set AZURE_TENANT_ID --repo "$REPO" --env "$ENV" < <(echo "YOUR_TENANT_ID")
gh secret set AZURE_SUBSCRIPTION_ID --repo "$REPO" --env "$ENV" < <(echo "YOUR_SUBSCRIPTION_ID")
gh secret set TENANTS_CONFIG --repo "$REPO" --env "$ENV" < tenants.json.b64

# Optional: For dashboard deployment
# gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --repo "$REPO" --env "$ENV" < <(echo "YOUR_TOKEN")

# Verify
gh secret list --repo "$REPO" --env "$ENV"
```

### 4. Or Set Secrets via Web UI

1. Go to: https://github.com/HTT-BRANDS/code_puppy-HTT-INFRA/settings/environments/production
2. Click **"Add secret"**
3. Paste each value:
   - Name: `AZURE_OIDC_CLIENT_ID` → Value: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Name: `AZURE_TENANT_ID` → Value: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Name: `AZURE_SUBSCRIPTION_ID` → Value: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Name: `TENANTS_CONFIG` → Value: `eyJhemur...` (base64 encoded)

## 🧪 Test the Setup

```bash
# Trigger workflow manually
gh workflow run cost-center-audit.yml --repo HTT-BRANDS/code_puppy-HTT-INFRA --ref main

# Watch it run
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1

# View logs
gh run view <RUN_ID> --log
```

## ✅ Verification Checklist

```bash
REPO="HTT-BRANDS/code_puppy-HTT-INFRA"

# 1. Check secrets exist
gh secret list --repo "$REPO" --env production

# 2. Verify OIDC credential in Azure
az identity federated-credential list \
  --resource-group <your-rg> \
  --identity-name <your-identity>

# 3. Check app registration permissions
az ad app permission list --id <YOUR_CLIENT_ID>

# 4. Review workflow file
gh workflow view cost-center-audit --repo "$REPO"

# 5. Test Azure login locally
az login --service-principal -u <CLIENT_ID> -p <CLIENT_SECRET> --tenant <TENANT_ID>
```

## 🔑 OIDC Federated Credential Details

**Already Created**: ID `3446b1f1-be9f-4f57-a3fe-f29dc5bd2008`

- **Issuer**: `https://token.actions.githubusercontent.com`
- **Subject**: `repo:HTT-BRANDS/code_puppy-HTT-INFRA:ref:refs/heads/main`
- **Audience**: `api://AzureADTokenExchange`

## 🚨 Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| "Secret not found" | Run: `gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production` |
| "Invalid OIDC token" | Verify federated credential issuer and subject match |
| "Unauthorized to access Azure" | Add permissions to app registration |
| "TENANTS_CONFIG decode failed" | Ensure base64 encoding: `cat tenants.json \| base64` |
| "Auth mode 'app' not found" | Update cost_center/collectors/auth.py or use `deployment` mode |

## 📚 Full Documentation

See: [docs/AUTHENTICATION_SETUP.md](./AUTHENTICATION_SETUP.md)

## 🎯 Next Steps

1. ✅ Collect Azure credentials (Client ID, Tenant ID, Subscription ID)
2. ✅ Create and base64-encode tenants.json
3. ✅ Set all secrets in GitHub production environment
4. ✅ Run manual workflow test: `gh workflow run cost-center-audit.yml`
5. ✅ Monitor execution and verify data collection
6. ✅ Review dashboard for updated costs
7. ✅ Schedule automated daily runs (already configured for 10:00 UTC)

---

**Federated Credential ID**: `3446b1f1-be9f-4f57-a3fe-f29dc5bd2008`
**Workflow**: `.github/workflows/cost-center-audit.yml`
**Documentation**: `docs/AUTHENTICATION_SETUP.md`
