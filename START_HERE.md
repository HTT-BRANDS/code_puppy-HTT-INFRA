# 🚀 START HERE - Cost Center Dashboard Setup

Welcome! This guide will get you from zero to production-ready cost center dashboard in 3 steps.

## 📋 What You Have

✅ **Python Backend** - 8 production-ready modules collecting from Azure  
✅ **GitHub Workflows** - Automated CI/CD with daily cost audits  
✅ **75 Tests** - 100% passing integration test suite  
✅ **Azure OIDC** - Secure authentication (no stored credentials)  
✅ **Full Documentation** - Comprehensive guides for every step  

## 🎯 Your Next 3 Steps

### Step 1: Configure GitHub Secrets (5 minutes)

GitHub secrets enable the workflow to authenticate with Azure using OIDC.

**Run this:**
```bash
cd code_puppy-HTT-INFRA
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

**What it does:**
- Prompts for Azure credentials (client ID, tenant ID, subscription ID)
- Creates or loads your tenants.json configuration
- Base64-encodes the config for secure storage
- Sets all required GitHub secrets via GitHub CLI

**Verify it worked:**
```bash
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
```

You should see 5 secrets listed.

---

### Step 2: Test the Workflow (5 minutes)

Manually trigger the cost collection workflow to verify everything works.

**Run this:**
```bash
gh workflow run cost-center-audit.yml \
  --repo HTT-BRANDS/code_puppy-HTT-INFRA \
  --ref main
```

**Monitor the run:**
```bash
# Get the run ID
RUN_ID=$(gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1 --json databaseId -q '.[0].databaseId')

# Watch the logs
gh run view "$RUN_ID" --log
```

**Look for:**
- ✅ Azure Login via OIDC succeeds (NOT using stored secrets)
- ✅ Python 3.12 setup completes
- ✅ Dependencies install successfully
- ✅ Cost data collection runs
- ✅ Report artifact is created

---

### Step 3: Validate Production (5 minutes)

Check that the cost data made it to your storage and dashboard.

**Run this:**
```bash
# List recent reports in blob storage
az storage blob list \
  --container-name "cost-reports" \
  --account-name "<your-storage-account>" \
  --query "[].name" -o table

# Check the dashboard displays current costs
# Visit your dashboard URL and verify today's date
```

**Done!** The workflow is now:
- ✅ Running daily at 10:00 UTC
- ✅ Collecting costs via secure Azure OIDC authentication
- ✅ Persisting reports to blob storage
- ✅ Updating your dashboard automatically

---

## 📚 Need More Details?

| Question | Document |
|----------|----------|
| What secrets do I need? | [GITHUB_SECRETS_QUICK_REFERENCE.md](docs/GITHUB_SECRETS_QUICK_REFERENCE.md) |
| How does OIDC work? | [AUTHENTICATION_SETUP.md](docs/AUTHENTICATION_SETUP.md) |
| What's next after setup? | [IMPLEMENTATION_CHECKLIST.md](docs/IMPLEMENTATION_CHECKLIST.md) |
| How do I troubleshoot errors? | [AUTHENTICATION_SETUP.md#troubleshooting](docs/AUTHENTICATION_SETUP.md) |
| What changed from the old system? | [MIGRATION_PLAN.md](docs/MIGRATION_PLAN.md) |

---

## ⚡ Quick Commands

```bash
# Setup GitHub secrets
chmod +x scripts/setup-github-secrets.sh && ./scripts/setup-github-secrets.sh

# Run local tests
uv run pytest tests/cost_center/ -v

# Trigger workflow
gh workflow run cost-center-audit.yml --repo HTT-BRANDS/code_puppy-HTT-INFRA --ref main

# View workflow runs
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA

# Check secrets are configured
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production

# Local linting
uv run ruff check .

# Type checking
uv run mypy cost_center/
```

---

## 🔐 Security Notes

- **No long-lived credentials** - Uses Azure OIDC for token exchange
- **GitHub environment secrets** - Stored securely in production environment
- **Base64 encoding** - Tenant config encoded for safe transmission
- **RBAC** - Least-privilege Azure service principal permissions

---

## 🆘 Troubleshooting

### "gh: command not found"
Install GitHub CLI: https://cli.github.com

### "AZURE_OIDC_CLIENT_ID not set"
Run the setup script: `./scripts/setup-github-secrets.sh`

### "Azure Login failed"
Check that the OIDC federated credential exists:
```bash
az ad app credential list --id <CLIENT_ID> --query "[?customKeyIdentifier=='<KEY_ID>'].displayName"
```

### "Workflow shows no credentials error"
Verify secrets are in production environment:
```bash
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
```

See [AUTHENTICATION_SETUP.md](docs/AUTHENTICATION_SETUP.md) for more troubleshooting.

---

## 📞 Support

- Review: [docs/](docs/)
- Scripts: [scripts/](scripts/)
- Code: [cost_center/](cost_center/)

---

**Status**: Phase 1 Complete ✅ | Ready for production setup

**Next**: Run `./scripts/setup-github-secrets.sh` to get started!
