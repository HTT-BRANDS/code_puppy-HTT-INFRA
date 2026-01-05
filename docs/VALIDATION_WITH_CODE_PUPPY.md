# 🐶 Validate Cost Data Collection Using Code Puppy

**Goal**: After GitHub secrets setup, use Code Puppy agents to analyze and validate cost data collection, verify dashboard updates, and confirm authentication flow.

---

## Overview

Once you've configured GitHub secrets in the NEW repo and triggered the `cost-center-audit.yml` workflow, use Code Puppy's agent system to:

1. **Analyze cost data** - Parse and validate JSON reports
2. **Verify API integration** - Check Graph, Cost Management, Resource Manager responses
3. **Validate dashboard** - Inspect HTML/CSS and verify updates
4. **Check authentication flow** - Review workflow logs for OIDC success
5. **Generate validation report** - Create comprehensive status report

---

## Prerequisites

✅ GitHub secrets configured in `code_puppy-HTT-INFRA` production environment  
✅ `cost-center-audit.yml` workflow executed successfully  
✅ Cost report artifact downloaded  
✅ Dashboard deployed to Azure Static Web Apps  

---

## Step 1: Download and Inspect Cost Report

### Download Workflow Artifact

```bash
# Get latest run ID
RUN_ID=$(gh run list --repo HTT-BRANDS/code_puppy-HTT-INFRA --limit 1 --json databaseId -q '.[0].databaseId')

# Download artifact
gh run download $RUN_ID --dir /tmp/cost-report/

# List contents
ls -lah /tmp/cost-report/
```

Expected output:
```
cost-report.json          # Main cost data
cost-report-metadata.json # Collection metadata
```

---

## Step 2: Launch Code Puppy for Validation

```bash
cd /Users/tygranlund/code_puppy-HTT-INFRA
code-puppy -i
```

You should see the Code Puppy interactive prompt.

---

## Step 3: Use Code Puppy to Analyze Cost Data

### Prompt 1: Validate JSON Structure

```
/agent code-puppy

Analyze the cost report JSON at /tmp/cost-report/cost-report.json and validate:

1. Structure: Does it have required fields (subscriptions, costs, metadata)?
2. Data types: Are costs numeric? Are dates ISO format?
3. Completeness: Are all subscriptions included?
4. Anomalies: Are there any zero values or missing data?

Return a validation report with:
- ✅ PASS/❌ FAIL for each check
- Any issues found
- Recommended actions if needed
```

**Expected Response:**
Code Puppy should analyze the JSON and output:
```json
{
  "validation_results": {
    "structure": "PASS",
    "data_types": "PASS",
    "completeness": "PASS",
    "anomalies": "PASS"
  },
  "issues": [],
  "recommendations": []
}
```

---

### Prompt 2: Compare API Responses

```
I'm validating Azure cost collection. Compare the data in /tmp/cost-report/cost-report.json with what I expect:

1. Cost Management API - Should show costs by service (compute, storage, network, etc.)
2. Microsoft Graph API - Should show users and their subscription assignments
3. Resource Manager API - Should show all resources deployed

For each API integration, tell me:
- Is the data present?
- Does it look complete?
- Are there any suspicious patterns?

Also check: Did the collection happen at the right time?
```

**Expected Response:**
Code Puppy validates each data source and confirms:
- ✅ Cost data aggregated by service
- ✅ User data includes licenses and assignments
- ✅ Resource inventory complete
- ✅ Timestamps align with workflow execution

---

### Prompt 3: Generate Validation Checklist

```
Create a comprehensive validation checklist for this cost center dashboard implementation.

For each item, check the /tmp/cost-report/ files and verify:

1. **Authentication**
   - [ ] OIDC token exchange successful (no errors in logs)
   - [ ] No long-lived credentials exposed
   - [ ] Azure login succeeded

2. **Data Collection**
   - [ ] Cost Management API returned data
   - [ ] Graph API returned user data
   - [ ] Resource Manager API returned resource list
   - [ ] All subscriptions included

3. **Data Quality**
   - [ ] No null/undefined costs
   - [ ] All dates are ISO format
   - [ ] Costs sum correctly
   - [ ] No duplicate entries

4. **Dashboard Integration**
   - [ ] Report saved successfully
   - [ ] Dashboard can read JSON
   - [ ] Last Updated timestamp is today
   - [ ] Charts render without errors

Generate this as a markdown checklist with Pass/Fail status for each item.
```

**Expected Response:**
```markdown
# Cost Center Dashboard Validation Checklist

## Authentication ✅
- [x] OIDC token exchange successful
- [x] No long-lived credentials exposed
- [x] Azure login succeeded

## Data Collection ✅
- [x] Cost Management API returned data
- [x] Graph API returned user data
- [x] Resource Manager API returned resource list
- [x] All subscriptions included

## Data Quality ✅
- [x] No null/undefined costs
- [x] All dates are ISO format
- [x] Costs sum correctly
- [x] No duplicate entries

## Dashboard Integration ✅
- [x] Report saved successfully
- [x] Dashboard can read JSON
- [x] Last Updated timestamp is today
- [x] Charts render without errors
```

---

## Step 4: Verify Dashboard Updates

### Prompt 4: Inspect Dashboard Code

```
I need to verify the dashboard is reading from the correct cost report. 

Can you:
1. Read the dashboard HTML/JavaScript files at docs/dashboard/index.html
2. Check that the JavaScript loads the JSON from the correct path
3. Verify the charts are configured correctly
4. Confirm the last-updated timestamp logic works

Show me:
- The file paths it's trying to load
- Any error handling for missing files
- How it formats the dates
- The chart configuration
```

**Expected Response:**
Code Puppy shows:
- ✅ Dashboard loads `/cost-report.json` correctly
- ✅ Error handling for missing data
- ✅ Date formatting matches ISO format
- ✅ Chart.js configured for all data types

---

### Prompt 5: Test Dashboard Rendering Logic

```
Create a simple test script that verifies the dashboard rendering:

1. Load the cost report JSON from /tmp/cost-report/
2. Simulate the dashboard's data processing
3. Verify charts would render correctly
4. Check for any data transformation issues

Save this as a validation test in /tmp/validate-dashboard.py

The test should verify that:
- Data loads without errors
- Costs are aggregated correctly
- Dates display properly
- All subscriptions appear in charts
```

**Expected Response:**
Code Puppy creates `/tmp/validate-dashboard.py` with:
```python
import json
from datetime import datetime

# Load cost report
with open('/tmp/cost-report/cost-report.json') as f:
    data = json.load(f)

# Validate structure
assert 'subscriptions' in data
assert 'timestamp' in data
print(f"✅ Report loaded: {len(data['subscriptions'])} subscriptions")

# Validate each subscription
for sub in data['subscriptions']:
    assert 'name' in sub
    assert 'costs' in sub
    print(f"✅ {sub['name']}: ${sub['costs']}")

print("✅ All validation checks passed!")
```

---

## Step 5: Verify Repository Isolation

### Prompt 6: Confirm NEW Repo Only

```
I need to verify that ONLY the NEW repository (code_puppy-HTT-INFRA) has access and that the OLD repository (microsoft/cost-center) is completely isolated.

Can you:
1. Check the cost_center/collectors/auth.py file to see what credentials it uses
2. Verify it only uses the AZURE_OIDC_CLIENT_ID environment variable
3. Confirm there's NO fallback to stored credentials
4. Check for any references to the old repository

List any findings and confirm complete isolation.
```

**Expected Response:**
Code Puppy confirms:
- ✅ Authentication uses ONLY environment variables
- ✅ No hardcoded credentials
- ✅ No references to old repo
- ✅ OIDC token exchange is the only auth method
- ✅ Credential cleanup would not affect NEW repo

---

## Step 6: Generate Final Validation Report

### Prompt 7: Create Summary Report

```
Based on all the validations we've run, create a comprehensive production readiness report for the cost center dashboard.

Include:

1. **Authentication Status**
   - OIDC implementation working correctly
   - No security vulnerabilities
   - Credentials properly isolated to NEW repo

2. **Data Collection Status**
   - All APIs responding correctly
   - Data quality verified
   - No missing subscriptions

3. **Dashboard Status**
   - Rendering correctly
   - Updates working
   - Performance acceptable

4. **Repository Status**
   - NEW repo (code_puppy-HTT-INFRA): ✅ ACTIVE
   - OLD repo (microsoft/cost-center): Ready for archival

5. **Next Steps**
   - Monitor for 7 days
   - Archive old repo on Day 8
   - Update documentation

Format as a markdown report suitable for stakeholder communication.
```

**Expected Response:**
Detailed report confirming all systems operational and ready for production.

---

## Step 7: Save Validation Record

```bash
# Save Code Puppy validation session
cp ~/.code_puppy/sessions/* /tmp/validation-session-$(date +%Y%m%d).json

# Archive all validation artifacts
tar -czf /tmp/cost-center-validation-$(date +%Y%m%d).tar.gz \
  /tmp/cost-report/ \
  /tmp/validate-dashboard.py \
  /tmp/validation-session-*.json
```

---

## Success Criteria

✅ **Code Puppy Successfully Validated:**
- JSON structure and data types correct
- All three Azure APIs returning data
- Dashboard loading and rendering properly
- OIDC authentication working without errors
- NEW repo completely isolated from OLD repo
- No security vulnerabilities detected
- All timestamps and data formatting correct

---

## Troubleshooting with Code Puppy

### If cost data is incomplete:

```
The cost report seems incomplete. Can you:
1. Check for any error messages in the JSON
2. Verify all subscriptions are included
3. Look for any API failures or timeouts
4. Suggest which collectors might have failed
```

### If dashboard won't update:

```
The dashboard isn't showing updated data. Can you:
1. Check the file path the dashboard is looking for
2. Verify the JSON is valid and readable
3. Look for any JavaScript errors in the rendering logic
4. Suggest debugging steps
```

### If authentication fails:

```
Let me show you the workflow logs. Can you analyze them for:
1. OIDC token exchange success
2. Azure credential issues
3. Timeout or rate limiting
4. API permission problems
```

---

## Advantages of Using Code Puppy for Validation

✅ **Comprehensive Analysis** - Analyzes code, JSON, and logs simultaneously  
✅ **Smart Validation** - Understands data structures and relationships  
✅ **Automated Checklists** - Generates comprehensive validation checklists  
✅ **Problem Detection** - Catches edge cases and anomalies  
✅ **Documentation** - Auto-generates validation reports  
✅ **Learning** - Explains issues and recommends fixes  

---

## Next Phase: Production Monitoring

After validation passes, use Code Puppy to:
- Generate daily validation reports
- Monitor cost trends
- Alert on anomalies
- Generate compliance reports

---

**Ready to validate?** Start with `code-puppy -i` and use the prompts above! 🐶✨
