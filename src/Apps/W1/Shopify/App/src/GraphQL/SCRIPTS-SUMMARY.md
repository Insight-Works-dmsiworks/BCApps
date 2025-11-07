# GraphQL Cost Analysis Scripts - Summary

## What Was Created

I've created a complete solution to analyze and update GraphQL query costs in your Shopify Connector codeunits. Here's what you now have:

### 📄 Files Created

1. **Analyze-GraphQLCosts.ps1** - Main analysis script
   - Reads all GraphQL codeunits in the `Codeunits/` folder
   - Extracts GraphQL queries and expected costs
   - Sends queries to Shopify API to get actual costs
   - Generates a CSV report comparing expected vs actual costs

2. **Update-GraphQLCosts.ps1** - Automated update script
   - Reads the CSV report from the analysis
   - Updates codeunit files with correct costs
   - Creates automatic backups before any changes
   - Provides detailed progress and summary

3. **README.md** - Comprehensive documentation
   - Detailed usage instructions for both scripts
   - Workflow guide
   - Troubleshooting tips
   - Security best practices

4. **run-analysis.template.ps1** - Quick start template
   - Copy this to `run-analysis.ps1` and fill in your credentials
   - Makes it easy to run the analysis

5. **.gitignore** - Security protection
   - Prevents accidentally committing credentials
   - Excludes CSV reports and backups from git

## How It Works

### The Problem
Each GraphQL query has a `GetExpectedCost()` method that returns an integer representing the query's complexity cost. Over time, these values can become inaccurate as queries evolve or Shopify's cost calculation changes.

### The Solution

**Step 1: Analysis**
```
GraphQL Codeunit → Extract Query → Send to Shopify → Get Actual Cost → Compare → CSV Report
```

**Step 2: Update**
```
CSV Report → Parse → Update Codeunits → Create Backups → Verify → Summary
```

## Quick Start Guide

### 1. Setup (First Time Only)

```powershell
# Navigate to the GraphQL folder
cd "C:\depot\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\GraphQL"

# Copy the template and edit with your credentials
Copy-Item run-analysis.template.ps1 run-analysis.ps1
notepad run-analysis.ps1  # Fill in your shop URL and access token
```

### 2. Run Analysis

```powershell
# Run the analysis (using your configured script)
.\run-analysis.ps1

# OR run directly with parameters
.\Analyze-GraphQLCosts.ps1 `
    -ShopUrl "https://your-shop.myshopify.com" `
    -AccessToken "shpat_xxxxx"
```

**Output**: `graphql-costs-analysis.csv` with all cost comparisons

### 3. Review Results

Open the CSV file to see:
- ✅ **Match**: No update needed
- ⚠️ **Overestimated**: Can be decreased (lower priority)
- 🔴 **Underestimated**: Should be increased (important!)
- ❌ **Error**: Manual review needed

### 4. Update Codeunits

```powershell
# Review what will be updated
Get-Content graphql-costs-analysis.csv

# Run the update (with confirmation prompt)
.\Update-GraphQLCosts.ps1 -CsvPath "graphql-costs-analysis.csv"

# OR run without confirmation
.\Update-GraphQLCosts.ps1 -CsvPath "graphql-costs-analysis.csv" -Force
```

**Output**: 
- Updated codeunit files
- Backup folder with original versions
- Summary of changes

### 5. Verify and Commit

```powershell
# Check what changed
git status
git diff

# Build and test (use your normal AL build process)
# ...

# Commit the changes
git add src/GraphQL/Codeunits/*.al
git commit -m "Update GraphQL query costs based on Shopify API analysis"
```

## Technical Details

### How Costs Are Extracted

The scripts use regex patterns to extract:

**From AL Files:**
```al
internal procedure GetGraphQL(): Text
begin
    exit('{"query":"..."}');  // ← Extracted query
end;

internal procedure GetExpectedCost(): Integer
begin
    exit(68);  // ← Extracted cost
end;
```

**Placeholder Replacement:**
Before sending to Shopify, the script replaces placeholders with valid dummy values:
```
{{CustomerId}}      → 1234567890
{{Time}}            → 2020-01-01T00:00:00Z
{{EMail}}           → test@example.com
{{ResourceUrl}}     → https://example.com/resource
{{After}}           → eyJsYXN0X2lkIjoxMjM0NTY3ODkwfQ==
... and many more
```

**From Shopify API:**
```json
{
  "extensions": {
    "cost": {
      "requestedQueryCost": 68,  // ← Actual cost
      "actualQueryCost": 68
    }
  }
}
```

### Shopify API Details

- **Endpoint**: `https://{shop}/admin/api/2025-07/graphql.json`
- **Method**: POST
- **Headers**: 
  - `X-Shopify-Access-Token: {token}`
  - `Content-Type: application/json`
- **Body**: The GraphQL query from the codeunit

### Safety Features

1. **Backups**: Automatic backups before any file modifications
2. **Validation**: Verifies old cost matches before updating
3. **Confirmation**: Prompts user before making changes (unless `-Force`)
4. **Restore**: Automatically restores from backup if update fails
5. **Git Ignore**: Prevents credentials from being committed

## Example Output

### Analysis Script Output
```
Starting GraphQL cost analysis...
Found 140 GraphQL codeunit files

[1/140] Processing: ShpfyGQLCustomer.Codeunit.al
  Expected Cost: 15
  Querying Shopify...
  Actual Cost: 15
  Status: Match (Difference: 0)

[2/140] Processing: ShpfyGQLOrderHeader.Codeunit.al
  Expected Cost: 68
  Querying Shopify...
  Actual Cost: 72
  Status: Underestimated (Difference: 4)

...

=== SUMMARY ===
Total Files:     140
Matches:         125
Underestimated:  10
Overestimated:   3
Errors:          2
```

### Update Script Output
```
GraphQL Cost Updater
====================

Found 13 files that need cost updates

Files to be updated:
  ShpfyGQLOrderHeader.Codeunit.al: 68 -> 72

Creating backups in: Backup_20241106_143022

Processing: ShpfyGQLOrderHeader.Codeunit.al
  Current Cost: 68
  New Cost:     72
  Creating backup...
  Updating cost...
  Successfully updated!

=== UPDATE SUMMARY ===
Total files processed:  13
Successfully updated:   13
Failed:                 0
```

## Maintenance

### When to Run These Scripts

- After significant query modifications
- When updating to a new Shopify API version
- As part of quarterly maintenance
- Before major releases

### Updating for New API Versions

When Shopify releases a new API version:

1. Update `VersionTok` in `ShpfyCommunicationMgt.Codeunit.al`
2. Update `$ApiVersion` in `Analyze-GraphQLCosts.ps1` (line 25)
3. Re-run the analysis

## Security Reminders

⚠️ **IMPORTANT**: Never commit credentials to source control!

- Use the template file and copy it to `run-analysis.ps1`
- The `.gitignore` file protects you, but be careful
- Consider using environment variables for automation
- Revoke tokens after use or use dedicated test tokens

## Troubleshooting

### Common Issues

**"CSV file not found"**
- Make sure you run the analyze script first
- Check the file path is correct

**"File not found" during update**
- Ensure you're in the correct directory
- Verify the CSV has correct file names

**"Authentication failed"**
- Verify your access token is correct
- Check your shop URL format
- Ensure the app has correct API scopes

**Rate limit errors**
- The script includes delays, but you may need to wait
- Consider running in smaller batches for large updates

## Support

If you encounter issues:
1. Check the README.md for detailed documentation
2. Review script output for specific error messages
3. Verify your Shopify credentials and permissions
4. Check that AL file structure hasn't changed

## Credits

These scripts were created to automate the maintenance of GraphQL query costs in the Shopify Connector for Business Central.

**Script Version**: 1.0  
**API Version**: 2025-07  
**Created**: November 2024
