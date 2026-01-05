# 🗑️ Old Repository Decommissioning Plan

**Current Date**: January 5, 2026  
**Old Repository**: https://github.com/microsoft/cost-center (TypeScript)  
**New Repository**: https://github.com/HTT-BRANDS/code_puppy-HTT-INFRA (Python)  
**Migration Status**: Complete  
**Decommissioning Status**: Pending execution

---

## 🎯 Objective

Completely retire the old Microsoft cost-center repository and consolidate all operations to the new HTT-BRANDS fork running Python backend with Azure OIDC authentication.

---

## 📋 Decommissioning Checklist

### Phase 1: Validation (Current) ✅
- [x] New repo code fully migrated and tested
- [x] All 75 integration tests passing
- [x] GitHub Actions workflows configured
- [x] Azure OIDC federated credential created
- [ ] Final validation with real cost data (IN PROGRESS)

### Phase 2: Cutover (Next)
- [ ] Run production workflow successfully
- [ ] Verify all cost data collected
- [ ] Confirm dashboard displays new data
- [ ] Monitor for 7 days for stability

### Phase 3: Sunset (After 7-day validation)
- [ ] Archive old repository
- [ ] Remove old app registration credentials
- [ ] Update team documentation
- [ ] Notify stakeholders

### Phase 4: Cleanup (1-2 weeks after archive)
- [ ] Delete old repository (if safe)
- [ ] Remove old deployment pipelines
- [ ] Archive old documentation backups

---

## 🔄 Current State Analysis

### Old Repository (microsoft/cost-center)
**Location**: https://github.com/microsoft/cost-center  
**Language**: TypeScript/Node.js  
**Status**: DEPRECATED (not used anymore)

**What needs to happen**:
```
1. Stop all deployments to old repo
2. Remove automation/CI/CD pipelines
3. Archive repository
4. Delete if no retention policy violation
```

### New Repository (HTT-BRANDS/code_puppy-HTT-INFRA)
**Location**: https://github.com/HTT-BRANDS/code_puppy-HTT-INFRA  
**Language**: Python 3.12  
**Status**: ACTIVE & PRODUCTION-READY

**What's configured**:
- ✅ All Python backend modules
- ✅ Azure OIDC authentication (NO stored credentials)
- ✅ Daily cost collection workflow
- ✅ GitHub production environment secrets
- ✅ Full CI/CD pipeline
- ✅ Comprehensive documentation

---

## 📊 Azure App Registration State

The **Cost Center Agent** app registration in Azure will be:

| Property | Current | After Decommission |
|----------|---------|-------------------|
| Client ID | `db9ae76-...` | SAME (still used) |
| Federated Credentials | 5 total | 1 only (code_puppy-HTT-INFRA) |
| Credentials Cleanup | Multiple origins | Only new repo |

### Federated Credentials to Remove:
```
❌ github-prod-htt
❌ github-dev
❌ github-test
❌ github-main-branch
✅ code_puppy-HTT-INFRA-main (KEEP THIS ONE)
```

**Action**: Remove 4 old credentials, keep only the one for new repo

---

## 🗂️ Files & Resources to Archive

Before deleting old repo, create backup archive:

```bash
# 1. Clone old repository for archive
git clone https://github.com/microsoft/cost-center.git cost-center-backup

# 2. Create backup archive
tar -czf cost-center-backup-2026-01-05.tar.gz cost-center-backup/

# 3. Store in safe location (e.g., Azure Blob Storage)
az storage blob upload \
  --account-name "<backup-storage>" \
  --container-name "repo-archives" \
  --name "cost-center-backup-2026-01-05.tar.gz" \
  --file cost-center-backup-2026-01-05.tar.gz

# 4. Cleanup local copy
rm -rf cost-center-backup
```

---

## 🔐 Credentials Cleanup

### Step 1: Remove Old Federated Credentials from Azure

List all federated credentials:
```bash
# Get app registration ID
APP_ID=$(az ad app list --display-name "cost-center" --query "[0].appId" -o tsv)

# List all credentials
az ad app credential list --id "$APP_ID" --query "[?type=='Assertion'].{name:displayName, id:keyId}" -o table
```

Remove old ones (keep code_puppy-HTT-INFRA-main):
```bash
# Remove github-prod-htt
az ad app credential delete --id "$APP_ID" --key-id "<KEY_ID_1>" --confirm

# Remove github-dev
az ad app credential delete --id "$APP_ID" --key-id "<KEY_ID_2>" --confirm

# Remove github-test
az ad app credential delete --id "$APP_ID" --key-id "<KEY_ID_3>" --confirm

# Remove github-main-branch
az ad app credential delete --id "$APP_ID" --key-id "<KEY_ID_4>" --confirm

# Verify only one remains
az ad app credential list --id "$APP_ID" --query "[?type=='Assertion'].displayName" -o table
# Output: code_puppy-HTT-INFRA-main
```

### Step 2: Remove Old GitHub Secrets

**In old repository** (github.com/microsoft/cost-center):
```bash
# List existing secrets
gh secret list --repo microsoft/cost-center

# Remove all cost-center related secrets
gh secret delete AZURE_CLIENT_ID --repo microsoft/cost-center --confirm
gh secret delete AZURE_TENANT_ID --repo microsoft/cost-center --confirm
gh secret delete AZURE_SUBSCRIPTION_ID --repo microsoft/cost-center --confirm
gh secret delete TENANTS_CONFIG --repo microsoft/cost-center --confirm
gh secret delete AZURE_STATIC_WEB_APPS_API_TOKEN --repo microsoft/cost-center --confirm
```

**In new repository** (github.com/HTT-BRANDS/code_puppy-HTT-INFRA):
```bash
# Verify secrets are set only in production environment
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
```

---

## 📝 Documentation Updates

### Files to Update:
1. **Main README.md**
   - Update repository URL to new repo
   - Remove references to old TypeScript version
   - Update setup instructions

2. **docs/MIGRATION_PLAN.md**
   - Mark migration as complete
   - Document what was changed

3. **docs/SUNSET_NOTES.md**
   - Update sunset timeline
   - Mark old repo as archived

4. **Team Documentation** (external)
   - Update all wiki/documentation pointing to old repo
   - Add migration guide for team members

### Update in README.md:
```markdown
# Cost Center Dashboard

**Status**: ✅ Production-ready (Python backend with Azure OIDC)

**Repository**: https://github.com/HTT-BRANDS/code_puppy-HTT-INFRA

## Migration Status
- TypeScript backend: ✅ Migrated to Python 3.12
- Azure authentication: ✅ OIDC federation (no stored credentials)
- Workflows: ✅ Configured for daily cost collection
- Tests: ✅ 75 integration tests (100% passing)
- Old repo: ✅ Archived (see SUNSET_NOTES.md)

[Previous repository](https://github.com/microsoft/cost-center) - ARCHIVED 2026-01-05
```

---

## 🏁 Final Steps - Archive Old Repository

### On GitHub Web UI:

1. Go to **github.com/microsoft/cost-center/settings**
2. Scroll to **Danger Zone**
3. Click **Archive this repository**
4. Confirm by typing repository name

### OR via GitHub CLI:

```bash
gh repo archive microsoft/cost-center --confirm
```

**Result**: Repository becomes read-only, forks are preserved, history is kept

---

## ✅ Decommissioning Validation

After completing all steps, verify:

```bash
# 1. Old repo is archived
gh repo view microsoft/cost-center --json isArchived -q '.isArchived'
# Output: true ✅

# 2. New repo is active
gh repo view HTT-BRANDS/code_puppy-HTT-INFRA --json isArchived -q '.isArchived'
# Output: false ✅

# 3. Only new repo has secrets
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production | wc -l
# Output: 5+ ✅

# 4. Old repo has no secrets (after cleanup)
gh secret list --repo microsoft/cost-center | wc -l
# Output: 0 ✅

# 5. Old federated credentials removed from Azure
az ad app credential list \
  --id $(az ad app list --display-name "cost-center" --query "[0].appId" -o tsv) \
  --query "[?type=='Assertion'].displayName" -o table
# Output: code_puppy-HTT-INFRA-main (only) ✅

# 6. New repo workflow runs successfully
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1 --json conclusion
# Output: "success" ✅
```

---

## 📅 Timeline

| Date | Action | Status |
|------|--------|--------|
| Jan 5, 2026 | Complete new repo setup | ✅ |
| Jan 5, 2026 | Run final validations | ⏳ IN PROGRESS |
| Jan 5-12, 2026 | Monitor production (7 days) | PENDING |
| Jan 12, 2026 | Archive old repo | PENDING |
| Jan 12, 2026 | Remove old credentials | PENDING |
| Jan 12, 2026 | Update documentation | PENDING |
| Jan 19, 2026 | Delete old repo (optional) | PENDING |

---

## 🎯 Success Criteria

All of the following confirm successful decommissioning:

- [ ] New repo running production workflows daily
- [ ] No errors in new repo workflows (7 days)
- [ ] All cost data collected successfully
- [ ] Dashboard displays current costs
- [ ] Old repo archived
- [ ] Old federated credentials removed (except code_puppy-HTT-INFRA-main)
- [ ] Old repository secrets removed
- [ ] Team documentation updated
- [ ] No references to old repository in active docs
- [ ] Backup archive created and stored safely

---

## 🚀 Next Steps

1. **Execute final validation**: Run setup script and test workflow
2. **Monitor production**: Watch for 7 days
3. **Archive old repo**: When confident new system is stable
4. **Clean credentials**: Remove old federated credentials from Azure
5. **Update docs**: Point everything to new repo

---

**Status**: Decommissioning plan ready | Awaiting validation completion

**Owner**: You (TypeGranlund)  
**Timeline**: 14 days from Jan 5 to complete cutover
