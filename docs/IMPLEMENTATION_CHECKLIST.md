# 🎯 Cost Center Dashboard Implementation Checklist

## Phase 1: Authentication & Credentials ✅ COMPLETE

This phase ensures proper OIDC authentication and GitHub secrets configuration.

### Completed Tasks
- [x] Azure OIDC federated credential created
  - **ID**: `3446b1f1-be9f-4f57-a3fe-f29dc5bd2008`
  - **Issuer**: `https://token.actions.githubusercontent.com`
  - **Subject**: `repo:HTT-BRANDS/code_puppy-HTT-INFRA:ref:refs/heads/main`

- [x] Cost-center-audit workflow created
  - Location: `.github/workflows/cost-center-audit.yml`
  - Schedule: Daily at 10:00 UTC
  - Manual trigger: Available via GitHub Actions UI

- [x] Authentication documentation created
  - `docs/AUTHENTICATION_SETUP.md` - Complete setup guide
  - `docs/GITHUB_SECRETS_QUICK_REFERENCE.md` - Quick reference
  - `scripts/setup-github-secrets.sh` - Interactive setup script

### Next: Configure GitHub Secrets

**Choose one method:**

#### Method 1: Interactive Script (Recommended)
```bash
cd code_puppy-HTT-INFRA
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

#### Method 2: Manual CLI
```bash
REPO="HTT-BRANDS/code_puppy-HTT-INFRA"
ENV="production"

# Get Azure values
CLIENT_ID=$(az ad app list --display-name "cost-center" --query "[0].appId" -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_ID=$(az account show --query id -o tsv)

# Set secrets
echo "$CLIENT_ID" | gh secret set AZURE_OIDC_CLIENT_ID --repo "$REPO" --env "$ENV"
echo "$TENANT_ID" | gh secret set AZURE_TENANT_ID --repo "$REPO" --env "$ENV"
echo "$SUB_ID" | gh secret set AZURE_SUBSCRIPTION_ID --repo "$REPO" --env "$ENV"

# Create and set tenants config
cat tenants.json | base64 | gh secret set TENANTS_CONFIG --repo "$REPO" --env "$ENV"

# Verify
gh secret list --repo "$REPO" --env "$ENV"
```

#### Method 3: GitHub Web UI
1. Go to: https://github.com/HTT-BRANDS/code_puppy-HTT-INFRA/settings/environments/production
2. Click **"Add secret"** for each:
   - `AZURE_OIDC_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `TENANTS_CONFIG` (base64 encoded)

---

## Phase 2: CI/CD Validation

After secrets are configured, validate the complete CI/CD pipeline.

### Prerequisites
- [ ] All GitHub secrets configured in production environment
- [ ] Cost-center module complete with tests passing
- [ ] Workflow files in `.github/workflows/`

### Tasks

#### Step 1: Verify Workflow Configuration
```bash
# Check workflow is recognized
gh workflow list --repo HTT-BRANDS/code_puppy-HTT-INFRA

# View workflow details
gh workflow view cost-center-audit --repo HTT-BRANDS/code_puppy-HTT-INFRA

# Check file syntax
yamllint .github/workflows/cost-center-audit.yml
```

#### Step 2: Test OIDC Authentication
```bash
# Run workflow manually
gh workflow run cost-center-audit.yml \
  --repo HTT-BRANDS/code_puppy-HTT-INFRA \
  --ref main

# Monitor execution
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 3

# View detailed logs
RUN_ID=$(gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1 --json databaseId -q '.[0].databaseId')
gh run view "$RUN_ID" --log

# Expected successful steps:
# ✅ Checkout code
# ✅ Set up Python 3.12
# ✅ Install UV
# ✅ Install dependencies
# ✅ Azure Login via OIDC (exchanges GitHub token for Azure access token)
# ✅ Copy tenant configuration
# ✅ Run cost center data collection
# ✅ Upload report as artifact
# ✅ Deploy to Static Web Apps (if enabled)
```

#### Step 3: Validate Cost Data Collection
Monitor workflow logs for:
- [ ] Successful Azure authentication (OIDC token exchange)
- [ ] Cost Management API queries completed
- [ ] Microsoft Graph API queries completed
- [ ] Azure Resource Manager queries completed
- [ ] Report generated and uploaded
- [ ] Dashboard deployment successful (if enabled)

#### Step 4: Check CI Workflow
The standard `ci.yml` should also run on push:
```bash
# View CI workflow runs
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --workflow ci.yml --limit 5

# Check for:
# ✅ Python linting (ruff)
# ✅ Unit tests pass
# ✅ Type checking (mypy)
# ✅ Coverage report
# ✅ CodeQL security scan
```

### Success Indicators
- [ ] cost-center-audit workflow runs successfully
- [ ] OIDC authentication succeeds (no secret errors)
- [ ] Cost data collected from Azure subscriptions
- [ ] Report uploaded to blob storage
- [ ] Dashboard displays latest costs
- [ ] CI workflow passes all checks
- [ ] No authentication failures in logs

---

## Phase 3: Production Validation

Deploy and validate in production with real Azure data.

### Prerequisites
- [ ] Phase 1: Authentication configured ✅
- [ ] Phase 2: CI/CD validation complete ✅
- [ ] Real Azure subscriptions configured
- [ ] Blob storage account ready
- [ ] Dashboard URL accessible

### Tasks

#### Step 1: Run Daily Audit Manually
```bash
# Trigger workflow
gh workflow run cost-center-audit.yml \
  --repo HTT-BRANDS/code_puppy-HTT-INFRA \
  --ref main \
  -f upload_to_blob=true

# Monitor and verify cost data is collected
```

#### Step 2: Verify Cost Data in Azure
```bash
# Check blob storage for reports
az storage blob list \
  --container-name "cost-reports" \
  --account-name "<your-storage-account>"

# Download latest report
LATEST=$(az storage blob list \
  --container-name "cost-reports" \
  --account-name "<your-storage-account>" \
  --query "sort_by([],&properties.creationTime)[-1].name" -o tsv)

az storage blob download \
  --container-name "cost-reports" \
  --name "$LATEST" \
  --account-name "<your-storage-account>" \
  --file latest-report.json

cat latest-report.json | jq . | head -50
```

#### Step 3: Verify Dashboard Updates
- [ ] Visit dashboard URL
- [ ] Check data is from today
- [ ] Verify cost breakdown by service
- [ ] Check month-to-date costs
- [ ] Verify subscription information

#### Step 4: Validate Scheduled Runs
- [ ] Workflow runs automatically at 10:00 UTC
- [ ] Daily cost collection completes
- [ ] Report artifacts retained for 30 days
- [ ] Dashboard stays current

### Success Indicators
- [ ] Daily workflow executions succeed
- [ ] Cost data updated in blob storage
- [ ] Dashboard shows current costs
- [ ] No authentication errors in logs
- [ ] All collectors provide data
- [ ] Reports generated consistently

---

## Phase 4: Old Repository Sunset

Archive and sunset the old cost-center TypeScript repository.

### Timeline
- **Deadline**: January 26, 2026 (3 weeks)

### Tasks

#### Step 1: Prepare Archive
```bash
# Clone old repository for archival
git clone <old-repo-url> old-cost-center-backup

# Create archive
tar -czf cost-center-old-backup.tar.gz old-cost-center-backup/

# Store archive in secure location
# (e.g., Azure Blob Storage with retention policy)
```

#### Step 2: Documentation
- [ ] Update README.md in main repo to reference new Python-based dashboard
- [ ] Archive old repository documentation
- [ ] Create migration notes for team
- [ ] Update any links pointing to old repo

#### Step 3: Notification
- [ ] Notify team of migration completion
- [ ] Share new dashboard URL and documentation
- [ ] Provide support for any issues
- [ ] Schedule knowledge transfer sessions if needed

#### Step 4: Archive Old Repository
```bash
# On old repository
# 1. Go to Settings → General → Danger Zone
# 2. Click "Archive this repository"
# OR use GitHub CLI:
gh repo archive <old-repo> --confirm
```

### Success Indicators
- [ ] Old repository archived
- [ ] New repository fully operational
- [ ] All documentation updated
- [ ] Team notified and trained
- [ ] Daily cost audits running successfully

---

## 📊 Overall Progress

```
Phase 1: Authentication & Credentials     ████████████████████ COMPLETE ✅
Phase 2: CI/CD Validation                 ░░░░░░░░░░░░░░░░░░░░ IN PROGRESS
Phase 3: Production Validation            ░░░░░░░░░░░░░░░░░░░░ PENDING
Phase 4: Old Repository Sunset            ░░░░░░░░░░░░░░░░░░░░ PENDING
```

---

## 🔗 Key Resources

### Documentation
- [AUTHENTICATION_SETUP.md](./docs/AUTHENTICATION_SETUP.md) - Complete auth guide
- [GITHUB_SECRETS_QUICK_REFERENCE.md](./docs/GITHUB_SECRETS_QUICK_REFERENCE.md) - Quick ref
- [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) - Technical migration details
- [SUNSET_NOTES.md](./SUNSET_NOTES.md) - Old repo sunset timeline

### Workflows
- `.github/workflows/cost-center-audit.yml` - Daily cost collection
- `.github/workflows/ci.yml` - Continuous integration
- `.github/workflows/codeql.yml` - Security scanning

### Scripts
- `scripts/setup-github-secrets.sh` - Interactive secrets setup

### Modules
- `cost_center/collectors/auth.py` - Authentication methods
- `cost_center/collectors/cost.py` - Cost Management API
- `cost_center/collectors/graph.py` - Microsoft Graph API
- `cost_center/collectors/resources.py` - Resource Manager API
- `cost_center/collectors/main.py` - Main orchestrator

---

## ✅ Implementation Checklist

### Before Starting Phase 2

- [ ] All Phase 1 tasks complete
- [ ] GitHub secrets configured:
  - [ ] `AZURE_OIDC_CLIENT_ID`
  - [ ] `AZURE_TENANT_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID`
  - [ ] `TENANTS_CONFIG`
- [ ] Secrets verified: `gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production`
- [ ] Workflow file exists: `.github/workflows/cost-center-audit.yml`
- [ ] Local tests pass: `uv run pytest tests/cost_center/`

### Commands Quick Reference

```bash
# Setup
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh

# Test
gh workflow run cost-center-audit.yml --repo HTT-BRANDS/code_puppy-HTT-INFRA --ref main
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 3
gh run view <RUN_ID> --log

# Verify
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
gh workflow list --repo HTT-BRANDS/code_puppy-HTT-INFRA

# Local tests
uv run pytest tests/cost_center/ -v
uv run ruff check .
uv run mypy cost_center/
```

---

## 🆘 Support

For issues during implementation:

1. **Check logs**: `gh run view <RUN_ID> --log`
2. **Review docs**: See [AUTHENTICATION_SETUP.md](./docs/AUTHENTICATION_SETUP.md)
3. **Troubleshoot**: See troubleshooting section in authentication guide
4. **Verify setup**: Run setup script again: `./scripts/setup-github-secrets.sh`

---

**Last Updated**: January 5, 2026
**Repository**: https://github.com/HTT-BRANDS/code_puppy-HTT-INFRA
**Federated Credential ID**: `3446b1f1-be9f-4f57-a3fe-f29dc5bd2008`
