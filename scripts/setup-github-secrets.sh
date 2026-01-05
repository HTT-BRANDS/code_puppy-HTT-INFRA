#!/bin/bash
# GitHub Secrets Setup for Cost Center Dashboard
# Uses Azure CLI with global admin credentials to automatically retrieve configuration
# 
# Prerequisites:
# - Azure CLI (az) authenticated with global admin: az login
# - GitHub CLI (gh) installed and authenticated: gh auth login
# - OIDC federated credential configured in Azure

set -e

REPO="HTT-BRANDS/code_puppy-HTT-INFRA"
ENV="production (repository-level secrets)"

echo "🔐 GitHub Secrets Configuration - Using Azure CLI"
echo "=================================================="
echo "Repository: $REPO"
echo "Scope: Repository-level secrets (accessible to all workflows)"
echo ""

# Function to set a secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo "Setting secret: $secret_name"
    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO"
    echo "✓ $secret_name set successfully"
}

# Function to validate command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Error: $1 is not installed or not in PATH"
        exit 1
    fi
}

# Validate prerequisites
echo "📋 Step 1: Validate Prerequisites"
echo "=================================="
check_command "az"
check_command "gh"
check_command "jq"
echo "✓ az CLI found"
echo "✓ gh CLI found"
echo "✓ jq found"
echo ""

# Verify Azure authentication
echo "🔐 Step 2: Verify Azure Authentication"
echo "======================================"
CURRENT_ACCOUNT=$(az account show --query 'name' -o tsv 2>/dev/null || echo "")
if [ -z "$CURRENT_ACCOUNT" ]; then
    echo "❌ Not authenticated to Azure. Run: az login"
    exit 1
fi
echo "✓ Authenticated as: $CURRENT_ACCOUNT"
echo ""

# Get current subscription
AZURE_SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
echo "✓ Current subscription: $AZURE_SUBSCRIPTION_ID"
echo ""

# Get current tenant
AZURE_TENANT_ID=$(az account show --query 'tenantId' -o tsv)
echo "✓ Current tenant: $AZURE_TENANT_ID"
echo ""

# Retrieve OIDC Client ID
echo "🔍 Step 3: Retrieve Azure App Registration Details"
echo "==================================================="
read -p "Enter the app registration name or client ID to use for OIDC: " APP_NAME_OR_ID

# Try to find app registration
APP_REG=$(az ad app list --query "[?displayName=='$APP_NAME_OR_ID' || appId=='$APP_NAME_OR_ID']" | jq '.[0]')

if [ "$APP_REG" == "null" ]; then
    echo "❌ App registration '$APP_NAME_OR_ID' not found"
    exit 1
fi

AZURE_OIDC_CLIENT_ID=$(echo "$APP_REG" | jq -r '.appId')
APP_DISPLAY_NAME=$(echo "$APP_REG" | jq -r '.displayName')
echo "✓ Found app registration: $APP_DISPLAY_NAME"
echo "✓ Client ID: $AZURE_OIDC_CLIENT_ID"
echo ""

# Verify OIDC federated credential exists
echo "🔐 Step 4: Verify OIDC Federated Credential"
echo "=========================================="
APP_OBJECT_ID=$(echo "$APP_REG" | jq -r '.id')
FEDERATED_CREDS=$(az ad app federated-credential list --id "$APP_OBJECT_ID" 2>/dev/null | jq '. | length')
echo "✓ Found $FEDERATED_CREDS federated credentials"

if [ "$FEDERATED_CREDS" -gt 0 ]; then
    echo "  Federated credentials:"
    az ad app federated-credential list --id "$APP_OBJECT_ID" | jq '.[] | {name: .name, issuer: .issuer, subject: .subject}' -C
fi
echo ""

# List available subscriptions
echo "📊 Step 5: List Available Subscriptions"
echo "====================================="
echo "Available subscriptions in current tenant:"
az account list --query "[].{Name:name, ID:id}" -o table
echo ""

read -p "Use all subscriptions in current tenant? (y/n): " USE_ALL_SUBS

if [ "$USE_ALL_SUBS" == "y" ]; then
    SUBSCRIPTIONS=$(az account list --query "[].id" -o tsv | tr '\n' ',' | sed 's/,$//')
else
    read -p "Enter subscription IDs (comma-separated): " SUBSCRIPTIONS
fi

echo ""
read -p "Enter tenant display name (for documentation): " TENANT_NAME

# Create tenants configuration
echo ""
echo "📝 Step 6: Create Tenant Configuration"
echo "====================================="

# Convert subscription string to JSON array
SUBS_JSON=$(echo "$SUBSCRIPTIONS" | tr ',' '\n' | sed 's/^/"/; s/$/"/' | jq -R -s 'split("\n")[:-1]')

TENANTS_JSON=$(cat <<EOF
{
  "azureClientId": "$AZURE_OIDC_CLIENT_ID",
  "tenants": [
    {
      "name": "$TENANT_NAME",
      "tenantId": "$AZURE_TENANT_ID",
      "subscriptions": $(echo "$SUBSCRIPTIONS" | tr ',' '\n' | jq -R . | jq -s .),
      "githubOrg": "HTT-BRANDS"
    }
  ]
}
EOF
)

echo "Generated configuration:"
echo "$TENANTS_JSON" | jq . -C
echo ""

# Base64 encode
TENANTS_CONFIG_B64=$(echo "$TENANTS_JSON" | base64)

# Confirm before setting
read -p "Set these secrets in GitHub production environment? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "❌ Aborted"
    exit 0
fi

echo ""
echo "🚀 Step 7: Set GitHub Secrets"
echo "============================="

# Set all secrets
set_secret "AZURE_OIDC_CLIENT_ID" "$AZURE_OIDC_CLIENT_ID"
set_secret "AZURE_TENANT_ID" "$AZURE_TENANT_ID"
set_secret "AZURE_SUBSCRIPTION_ID" "$AZURE_SUBSCRIPTION_ID"
set_secret "TENANTS_CONFIG" "$TENANTS_CONFIG_B64"

echo ""
echo "✅ Step 8: Verify Secrets"
echo "========================="
echo "GitHub secrets set in repository:"
gh secret list --repo "$REPO"

echo ""
echo "✨ Setup Complete!"
echo "=================================================="
echo ""
echo "Summary:"
echo "  ✓ Azure Client ID: $AZURE_OIDC_CLIENT_ID"
echo "  ✓ Azure Tenant ID: $AZURE_TENANT_ID"
echo "  ✓ Azure Subscription(s): $SUBSCRIPTIONS"
echo "  ✓ Tenant Name: $TENANT_NAME"
echo "  ✓ GitHub Secrets: 4 secrets set in repository"
echo ""
echo "Next steps:"
echo "1. Trigger workflow: gh workflow run cost-center-audit.yml --repo $REPO --ref main"
echo "2. Monitor: gh run list --repo $REPO"
echo "3. View logs: gh run view <RUN_ID> --log"
echo ""
echo "For validation guide, see: docs/VALIDATION_WITH_CODE_PUPPY.md"
