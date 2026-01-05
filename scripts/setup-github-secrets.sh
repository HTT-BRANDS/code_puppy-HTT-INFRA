#!/bin/bash
# GitHub Secrets Setup for Cost Center Dashboard
# This script helps configure all required GitHub secrets for the cost-center-audit workflow
# 
# Prerequisites:
# - GitHub CLI (gh) installed and authenticated: gh auth login
# - Azure subscription with appropriate permissions
# - Azure app registration created for OIDC authentication

set -e

REPO="HTT-BRANDS/code_puppy-HTT-INFRA"
ENV="production"

echo "🔐 GitHub Secrets Configuration for Cost Center Dashboard"
echo "=================================================="
echo "Repository: $REPO"
echo "Environment: $ENV"
echo ""

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    local env_flag=""
    
    if [ "$ENV" != "default" ]; then
        env_flag="--env $ENV"
    fi
    
    echo "Setting secret: $secret_name"
    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO" $env_flag
    echo "✓ $secret_name set successfully"
    echo ""
}

# Function to get secret (read-only)
get_secret() {
    local secret_name=$1
    echo "Retrieving secret: $secret_name"
    gh secret view "$secret_name" --repo "$REPO" 2>/dev/null || echo "NOT SET"
}

echo "📋 Step 1: Verify your Azure setup"
echo "======================================"
echo "Please ensure you have:"
echo "1. Azure app registration with OIDC federated credential"
echo "2. Azure subscription ID"
echo "3. Azure tenant ID"
echo "4. Azure Storage Account (for blob storage)"
echo "5. Azure Static Web Apps API token (optional, for dashboard deployment)"
echo ""

read -p "Press Enter to continue..."
echo ""

echo "🔑 Step 2: Collect Azure Credentials"
echo "======================================"

read -p "Enter AZURE_OIDC_CLIENT_ID (Application/Client ID): " AZURE_OIDC_CLIENT_ID
read -p "Enter AZURE_TENANT_ID (Directory/Tenant ID): " AZURE_TENANT_ID
read -p "Enter AZURE_SUBSCRIPTION_ID: " AZURE_SUBSCRIPTION_ID
read -p "Enter AZURE_STATIC_WEB_APPS_API_TOKEN (or press Enter to skip): " AZURE_STATIC_WEB_APPS_API_TOKEN

echo ""
echo "📝 Step 3: Create Tenant Configuration"
echo "======================================"
echo "You need to create a tenants.json configuration file."
echo "This file will be base64-encoded and stored as a GitHub secret."
echo ""
echo "Example tenants.json structure:"
echo '{
  "azureClientId": "'"$AZURE_OIDC_CLIENT_ID"'",
  "tenants": [
    {
      "name": "Tenant 1",
      "tenantId": "tenant-id-here",
      "subscriptions": ["sub-1", "sub-2"],
      "githubOrg": "HTT-BRANDS"
    }
  ]
}'
echo ""

read -p "Enter path to your tenants.json file (or press Enter for interactive mode): " TENANTS_FILE

if [ -z "$TENANTS_FILE" ]; then
    echo "Interactive tenants.json creation:"
    read -p "Tenant Name: " TENANT_NAME
    read -p "Tenant ID: " TENANT_ID
    read -p "Subscription IDs (comma-separated): " SUBSCRIPTIONS
    
    TENANTS_JSON=$(cat <<EOF
{
  "azureClientId": "$AZURE_OIDC_CLIENT_ID",
  "tenants": [
    {
      "name": "$TENANT_NAME",
      "tenantId": "$TENANT_ID",
      "subscriptions": [$(echo "$SUBSCRIPTIONS" | sed 's/,/", "/g' | sed 's/^/"/; s/$/"]/')],
      "githubOrg": "HTT-BRANDS"
    }
  ]
}
EOF
    )
else
    TENANTS_JSON=$(cat "$TENANTS_FILE")
fi

# Base64 encode the tenants configuration
TENANTS_CONFIG_B64=$(echo "$TENANTS_JSON" | base64)

echo ""
echo "🚀 Step 4: Set GitHub Secrets"
echo "======================================"

# Set all secrets
set_secret "AZURE_OIDC_CLIENT_ID" "$AZURE_OIDC_CLIENT_ID"
set_secret "AZURE_TENANT_ID" "$AZURE_TENANT_ID"
set_secret "AZURE_SUBSCRIPTION_ID" "$AZURE_SUBSCRIPTION_ID"

if [ -n "$AZURE_STATIC_WEB_APPS_API_TOKEN" ]; then
    set_secret "AZURE_STATIC_WEB_APPS_API_TOKEN" "$AZURE_STATIC_WEB_APPS_API_TOKEN"
fi

set_secret "TENANTS_CONFIG" "$TENANTS_CONFIG_B64"

echo ""
echo "✅ Step 5: Verify Secrets"
echo "======================================"
echo "Verifying secrets are set correctly..."
echo ""

get_secret "AZURE_OIDC_CLIENT_ID"
get_secret "AZURE_TENANT_ID"
get_secret "AZURE_SUBSCRIPTION_ID"
get_secret "AZURE_STATIC_WEB_APPS_API_TOKEN"
echo "TENANTS_CONFIG: (base64 encoded - use 'gh secret view TENANTS_CONFIG' to view)"

echo ""
echo "✨ Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Verify Azure OIDC federated credential is configured"
echo "2. Run workflow manually: gh workflow run cost-center-audit.yml"
echo "3. Monitor logs: gh run list --repo $REPO"
echo "4. Check cost-center-audit results in Actions tab"
echo ""
echo "For more details, see:"
echo "- Azure OIDC setup: https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/"
echo "- GitHub secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets"
