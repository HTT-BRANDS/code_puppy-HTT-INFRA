# 🚀 GitHub Secrets Setup - Execution Guide

**Objective**: Configure GitHub secrets for the NEW code_puppy-HTT-INFRA repository ONLY  
**Duration**: ~10 minutes  
**Status**: Ready to execute

---

## ⚠️ IMPORTANT: Repo Isolation

- ✅ New repo: **code_puppy-HTT-INFRA** (HTT-BRANDS fork) - Use THIS
- ❌ Old repo: **cost-center** (Microsoft) - Will be archived/deleted
- 🔒 Secrets tied to: NEW repo only (production environment)
- 🔑 Credentials tied to: Azure Cost Center Agent app registration (shared, but isolated via GitHub environment)

---

## Step 1: Run the Setup Script

Execute this command to configure all GitHub secrets:

```bash
cd /Users/tygranlund/code_puppy-HTT-INFRA
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

### What the script does:
1. Verifies `gh` CLI is installed and you're logged in
2. Prompts for Azure credentials:
   - `AZURE_OIDC_CLIENT_ID` - App registration client ID
   - `AZURE_TENANT_ID` - Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID` - Target subscription
   - `TENANTS_CONFIG` - Base64-encoded tenant configuration JSON
3. Creates GitHub secrets in production environment
4. Verifies all secrets are set

### Expected prompts:
```
✓ GitHub CLI is installed and authenticated
✓ Repository: HTT-BRANDS/code_puppy-HTT-INFRA

Enter AZURE_OIDC_CLIENT_ID: [paste from Azure]
Enter AZURE_TENANT_ID: [paste from Azure]
Enter AZURE_SUBSCRIPTION_ID: [paste from Azure]

Do you have a tenants.json file? (y/n): [choose]
  - If yes: provide file path
  - If no: enter JSON interactively

✓ Encoding configuration...
✓ Setting GitHub secrets in production environment...
✓ All secrets configured!

Next steps:
  1. Test workflow: gh workflow run cost-center-audit.yml --repo HTT-BRANDS/code_puppy-HTT-INFRA --ref main
  2. Monitor: gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 3
```

---

## Step 2: Verify Secrets Were Set

After script completes, verify all 5 secrets are configured:

```bash
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production
```

### Expected output:
```
AZURE_OIDC_CLIENT_ID          Updated 2026-01-05
AZURE_TENANT_ID               Updated 2026-01-05
AZURE_SUBSCRIPTION_ID         Updated 2026-01-05
TENANTS_CONFIG                Updated 2026-01-05
AZURE_STATIC_WEB_APPS_API_TOKEN Updated 2026-01-05 (optional)
```

✅ All 5 secrets visible = Setup succeeded

---

## Step 3: Test the Workflow

Trigger the cost collection workflow manually to verify OIDC authentication works:

```bash
gh workflow run cost-center-audit.yml \
  --repo HTT-BRANDS/code_puppy-HTT-INFRA \
  --ref main
```

Wait 2-3 seconds, then check the run:

```bash
gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 3
```

### Expected output:
```
STATUS  TITLE                   BRANCH  RUN ID    CREATED           ELAPSED
✓       cost-center-audit.yml   main    12345678  1 minute ago      1m 5s
```

Get the run ID and view detailed logs:

```bash
RUN_ID=$(gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1 --json databaseId -q '.[0].databaseId')
gh run view "$RUN_ID" --log
```

### Critical steps to verify in logs:
- ✅ `Azure Login via OIDC` - Should succeed (token exchange)
- ✅ `Python 3.12 setup` - Should complete
- ✅ `Install dependencies` - UV sync should complete
- ✅ `Copy tenant config` - Should succeed
- ✅ `Cost data collection` - Should collect from all APIs
- ✅ `Upload artifact` - Report should be created

### ❌ If you see authentication errors:
```
Error: AZURE_OIDC_CLIENT_ID not found in production environment
```

This means secrets weren't set. Go back to Step 2 and verify.

---

## Step 4: Validate Cost Data

Check that cost data was actually collected:

```bash
# Get the artifact
RUN_ID=$(gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1 --json databaseId -q '.[0].databaseId')
gh run download "$RUN_ID" --dir /tmp/cost-report/

# View the report
cat /tmp/cost-report/cost-report.json | jq . | head -50
```

### Expected report contains:
- Subscription costs by service
- Graph data (users, groups, etc.)
- Resource information
- Advisor recommendations

---

## Step 5: Verify Dashboard Update

If dashboard is configured, verify it displays the latest cost data:
- Visit dashboard URL
- Check "Last updated" timestamp = today
- Verify costs are populated

---

## 🔐 Security Verification

Confirm authentication is **ONLY** through NEW repo:

```bash
# Check GitHub repo environment has secrets
gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production

# Verify OIDC federated credential exists for NEW repo only
az ad app credential list \
  --id $(az ad app list --display-name "cost-center" --query "[0].appId" -o tsv) \
  --query "[?description=='GitHub'].displayName" -o table

# Should show: repo:HTT-BRANDS/code_puppy-HTT-INFRA:ref:refs/heads/main
```

---

## ⏭️ Next Actions

After successful validation:

1. **Schedule Daily Runs**
   - Workflow already scheduled for 10:00 UTC daily
   - Verify runs appear in Actions tab

2. **Monitor First Week**
   - Check daily workflow executions
   - Monitor for authentication failures
   - Verify cost data consistency

3. **Decommission Old Repo**
   - Remove old cost-center repo access
   - Archive Microsoft cost-center repository
   - Update team documentation

---

## 🆘 Troubleshooting

### Issue: "gh: command not found"
```bash
# Install GitHub CLI
brew install gh
gh auth login
```

### Issue: "Not authenticated to GitHub"
```bash
gh auth login --web
```

### Issue: "secrets not found in logs"
- Script may not have completed
- Re-run: `./scripts/setup-github-secrets.sh`
- Verify: `gh secret list --repo HTT-BRANDS/code_puppy-HTT-INFRA --env production`

### Issue: "OIDC token exchange failed"
- Verify federated credential exists in Azure
- Check subject matches exactly: `repo:HTT-BRANDS/code_puppy-HTT-INFRA:ref:refs/heads/main`

### Issue: "Cost data not collected"
- Check Azure permissions for service principal
- Verify tenant config is valid JSON and base64-encoded
- Check workflow logs for API errors

---

## ✅ Success Criteria

All of the following must be true:

- [ ] 5 GitHub secrets visible in production environment
- [ ] Workflow trigger succeeds (no "secrets not found" error)
- [ ] OIDC token exchange succeeds in logs
- [ ] Cost data is collected from all APIs
- [ ] Report artifact is created
- [ ] No errors in workflow logs
- [ ] Dashboard displays latest cost data (if configured)
- [ ] ONLY new repo has access to credentials

**Status**: Ready for execution

**Next**: Run `./scripts/setup-github-secrets.sh` and follow the prompts
