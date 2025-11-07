# GraphQL Cost Analysis - Configuration Template
# 
# Copy this file to 'run-analysis.ps1' and fill in your credentials
# DO NOT commit the file with actual credentials to source control!

# ============================================
# CONFIGURATION - FILL IN YOUR VALUES HERE
# ============================================

# Your Shopify shop URL (e.g., "https://my-shop.myshopify.com")
$ShopUrl = ""

# Your Shopify Admin API Access Token
# To get this:
# 1. Go to Shopify Admin → Settings → Apps and sales channels → Develop apps
# 2. Create a new app or select existing
# 3. Configure Admin API scopes (grant necessary read permissions)
# 4. Install the app and copy the Admin API access token
$AccessToken = ""

# Optional: Custom output file name
$OutputFile = "graphql-costs-analysis.csv"

# ============================================
# RUN THE ANALYSIS
# ============================================

Write-Host "Starting GraphQL Cost Analysis..." -ForegroundColor Green
Write-Host "Shop: $ShopUrl" -ForegroundColor Cyan
Write-Host ""

# Run the analysis script
.\Analyze-GraphQLCosts.ps1 -ShopUrl $ShopUrl -AccessToken $AccessToken -OutputCsv $OutputFile

# ============================================
# NEXT STEPS
# ============================================

Write-Host ""
Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "1. Review the generated CSV file: $OutputFile" -ForegroundColor White
Write-Host "2. If costs need updating, run: .\Update-GraphQLCosts.ps1 -CsvPath '$OutputFile'" -ForegroundColor White
Write-Host "3. Review the changes in your version control system" -ForegroundColor White
Write-Host "4. Build and test the application" -ForegroundColor White
Write-Host "5. Commit the changes" -ForegroundColor White
