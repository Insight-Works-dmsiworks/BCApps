<#
.SYNOPSIS
    Analyzes GraphQL queries and compares actual costs with expected costs defined in codeunits.

.DESCRIPTION
    This script:
    1. Reads all GraphQL codeunits from the Codeunits folder
    2. Extracts the GraphQL query and expected cost from each file
    3. Sends the query to Shopify GraphQL API with cost analysis
    4. Compares the actual cost from Shopify with the expected cost in the file
    5. Generates a CSV report with the findings

.PARAMETER ShopUrl
    The Shopify shop URL (e.g., "https://your-shop.myshopify.com")

.PARAMETER AccessToken
    The Shopify Admin API access token

.PARAMETER OutputCsv
    Path to the output CSV file (default: "graphql-costs-analysis.csv")

.EXAMPLE
    .\Analyze-GraphQLCosts.ps1 -ShopUrl "https://your-shop.myshopify.com" -AccessToken "shpat_xxxxx"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ShopUrl,
    
    [Parameter(Mandatory = $true)]
    [string]$AccessToken,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputCsv = "graphql-costs-analysis.csv"
)

# Shopify API version (matching the AL codeunit)
$ApiVersion = "2025-07"

# GraphQL endpoint
$GraphQLEndpoint = "$ShopUrl/admin/api/$ApiVersion/graphql.json"

# Function to extract GraphQL query from AL file content
function Get-GraphQLFromFile {
    param([string]$Content)
    
    # Find the GetGraphQL procedure and extract the query
    # The pattern captures everything between exit(' and ');
    if ($Content -match "exit\('(.+?)'\s*\)\s*;") {
        $queryJson = $matches[1]
        
        # The string in AL is already valid JSON!
        # AL escape sequences: \/ for / and \" for "
        # These are ALSO valid JSON escape sequences
        # So we DON'T need to unescape anything - just return as-is
        
        return $queryJson
    }
    return $null
}

# Function to extract expected cost from AL file content
function Get-ExpectedCostFromFile {
    param([string]$Content)
    
    # Find the GetExpectedCost procedure and extract the cost
    # Use (?s) for single-line mode to match across newlines
    if ($Content -match "(?s)GetExpectedCost\(\).*?exit\s*\((\d+)\)") {
        return [int]$matches[1]
    }
    return 0
}

# Function to replace placeholders in GraphQL query with dummy values
function Replace-PlaceholdersWithDummyValues {
    param([string]$Query)
    
    # Define dummy values for common placeholders
    $placeholders = @{
        # IDs (use valid GID format with realistic numbers)
        'CustomerId'              = '1234567890'
        'CompanyId'               = '1234567890'
        'CompanyContactId'        = '1234567890'
        'ContactId'               = '1234567890'
        'ContactRoleId'           = '1234567890'
        'OrderId'                 = '1234567890'
        'ProductId'               = '1234567890'
        'VariantId'               = '1234567890'
        'LocationId'              = '1234567890'
        'CatalogId'               = '1234567890'
        'PriceListId'             = '1234567890'
        'FulfillmentOrderId'      = '1234567890'
        'FulfillmentId'           = '1234567890'
        'DraftOrderId'            = '1234567890'
        'SubscriptionId'          = '1234567890'
        'WebhookSubscription'     = '1234567890'
        'DeliveryProfileId'       = '1234567890'
        'DeliveryLocationGroupId' = '1234567890'
        'BulkOperationId'         = '1234567890'
        'InventoryItemId'         = '1234567890'
        'ImageId'                 = '1234567890'
        'CompanyLocationId'       = '1234567890'
        'Id'                      = '1234567890'
        'SinceId'                 = '1234567890'
        
        # Text values
        'Title'                   = 'Test Title'
        'Name'                    = 'Test Name'
        'EMail'                   = 'test@example.com'
        'Phone'                   = '+1234567890'
        'Barcode'                 = '123456789'
        'SKU'                     = 'TEST-SKU-123'
        'TaxId'                   = 'TAX123456'
        'Filename'                = 'test-file.json'
        'MimeType'                = 'application/json'
        'BulkMutation'            = 'test mutation'
        
        # URLs
        'ResourceUrl'             = 'https://example.com/resource'
        'CallbackUrl'             = 'https://example.com/callback'
        'NotificationUrl'         = 'https://example.com/notification'
        
        # Dates and times (use ISO 8601 format)
        'Time'                    = '2020-01-01T00:00:00Z'
        'LastSync'                = '2020-01-01T00:00:00Z'
        
        # Cursor for pagination
        'After'                   = 'eyJsYXN0X2lkIjoxMjM0NTY3ODkwfQ=='
        
        # Numbers
        'NumberOfOrders'          = '10'
        'OrderLines'              = '10'
        
        # Enums (GraphQL enum values without quotes)
        'Resource'                = 'BULK_MUTATION_VARIABLES'
        'HttpMethod'              = 'POST'
        'Currency'                = 'USD'
        'WebhookTopic'            = 'ORDERS_CREATE'
        'OwnerType'               = 'PRODUCT'
        
        # Complex values
        'Metafields'              = '{ownerId: \"gid://shopify/Product/1234567890\", namespace: \"test\", key: \"test_key\", value: \"test_value\", type: \"single_line_text_field\"}'
        'StaffMember'             = 'staffMember { id }'
    }
    
    # Replace each placeholder in the query
    foreach ($key in $placeholders.Keys) {
        $placeholder = "{{$key}}"
        if ($Query -match [regex]::Escape($placeholder)) {
            $Query = $Query -replace [regex]::Escape($placeholder), $placeholders[$key]
        }
    }
    
    return $Query
}

# Function to send GraphQL query to Shopify and get actual cost
function Get-ActualCostFromShopify {
    param(
        [string]$Query,
        [string]$Endpoint,
        [string]$Token
    )
    
    try {
        # Parse the JSON to extract the GraphQL query
        $queryObject = $Query | ConvertFrom-Json
        $graphqlQuery = $queryObject.query
        
        # Replace placeholders with dummy values in the GraphQL query
        $graphqlQuery = Replace-PlaceholdersWithDummyValues -Query $graphqlQuery
        
        # Rebuild the JSON body
        $bodyObject = @{
            query = $graphqlQuery
        }
        
        # Add variables if they exist
        if ($queryObject.variables) {
            $bodyObject.variables = $queryObject.variables
        }
        
        $body = $bodyObject | ConvertTo-Json -Depth 10 -Compress
        
        $headers = @{
            "X-Shopify-Access-Token" = $Token
            "Content-Type"           = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $body -ErrorAction Stop
        
        # Extract actual cost from response
        if ($response.extensions.cost.requestedQueryCost) {
            return $response.extensions.cost.requestedQueryCost
        }
        elseif ($response.extensions.cost.actualQueryCost) {
            return $response.extensions.cost.actualQueryCost
        }
        
        return $null
    }
    catch {
        Write-Warning "Error querying Shopify for cost: $($_.Exception.Message)"
        # For debugging, show more details
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Warning "Response body: $responseBody"
        }
        return $null
    }
}

# Main script
Write-Host "Starting GraphQL cost analysis..." -ForegroundColor Green
Write-Host "Shop URL: $ShopUrl" -ForegroundColor Cyan
Write-Host "API Version: $ApiVersion" -ForegroundColor Cyan

# Get all GraphQL codeunit files
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$codeunitsPath = Join-Path $scriptPath "Codeunits"

if (-not (Test-Path $codeunitsPath)) {
    Write-Error "Codeunits folder not found at: $codeunitsPath"
    exit 1
}

$alFiles = Get-ChildItem -Path $codeunitsPath -Filter "*.al" | Where-Object { $_.Name -match "^ShpfyGQL.+\.Codeunit\.al$" }

Write-Host "Found $($alFiles.Count) GraphQL codeunit files" -ForegroundColor Cyan

# Prepare results array
$results = @()

# Process each file
$counter = 0
foreach ($file in $alFiles) {
    $counter++
    $fileName = $file.Name
    Write-Host "[$counter/$($alFiles.Count)] Processing: $fileName" -ForegroundColor Yellow
    
    try {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Extract query and expected cost
        $query = Get-GraphQLFromFile -Content $content
        $expectedCost = Get-ExpectedCostFromFile -Content $content
        
        if ($null -eq $query) {
            Write-Warning "  Could not extract GraphQL query from $fileName"
            $results += [PSCustomObject]@{
                FileName     = $fileName
                ExpectedCost = $expectedCost
                ActualCost   = "N/A"
                Status       = "Query Not Found"
                Difference   = "N/A"
            }
            continue
        }
        
        Write-Host "  Expected Cost: $expectedCost" -ForegroundColor Gray
        
        # Query Shopify for actual cost
        Write-Host "  Querying Shopify..." -ForegroundColor Gray
        $actualCost = Get-ActualCostFromShopify -Query $query -Endpoint $GraphQLEndpoint -Token $AccessToken
        
        if ($null -eq $actualCost) {
            Write-Warning "  Could not retrieve actual cost from Shopify"
            $results += [PSCustomObject]@{
                FileName     = $fileName
                ExpectedCost = $expectedCost
                ActualCost   = "Error"
                Status       = "Query Failed"
                Difference   = "N/A"
            }
            continue
        }
        
        Write-Host "  Actual Cost: $actualCost" -ForegroundColor Gray
        
        # Compare costs
        $difference = $actualCost - $expectedCost
        $status = if ($difference -eq 0) { "Match" } 
        elseif ($difference -gt 0) { "Underestimated" } 
        else { "Overestimated" }
        
        $statusColor = switch ($status) {
            "Match" { "Green" }
            "Underestimated" { "Red" }
            "Overestimated" { "Yellow" }
            default { "White" }
        }
        
        Write-Host "  Status: $status (Difference: $difference)" -ForegroundColor $statusColor
        
        $results += [PSCustomObject]@{
            FileName     = $fileName
            ExpectedCost = $expectedCost
            ActualCost   = $actualCost
            Status       = $status
            Difference   = $difference
        }
        
        # Add a small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Error "  Error processing $fileName : $($_.Exception.Message)"
        $results += [PSCustomObject]@{
            FileName     = $fileName
            ExpectedCost = "Error"
            ActualCost   = "Error"
            Status       = "Processing Error"
            Difference   = "N/A"
        }
    }
}

# Export results to CSV
$outputPath = Join-Path $scriptPath $OutputCsv
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "`nAnalysis complete!" -ForegroundColor Green
Write-Host "Results exported to: $outputPath" -ForegroundColor Cyan

# Display summary
$totalFiles = $results.Count
$matchCount = ($results | Where-Object { $_.Status -eq "Match" }).Count
$underestimated = ($results | Where-Object { $_.Status -eq "Underestimated" }).Count
$overestimated = ($results | Where-Object { $_.Status -eq "Overestimated" }).Count
$errors = ($results | Where-Object { $_.Status -match "Error|Failed|Not Found" }).Count

Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host "Total Files:     $totalFiles" -ForegroundColor Cyan
Write-Host "Matches:         $matchCount" -ForegroundColor Green
Write-Host "Underestimated:  $underestimated" -ForegroundColor Red
Write-Host "Overestimated:   $overestimated" -ForegroundColor Yellow
Write-Host "Errors:          $errors" -ForegroundColor Magenta

# Show files that need updates (non-matches)
$needsUpdate = $results | Where-Object { $_.Status -eq "Underestimated" -or $_.Status -eq "Overestimated" }
if ($needsUpdate.Count -gt 0) {
    Write-Host "`nFiles needing cost updates:" -ForegroundColor Yellow
    foreach ($item in $needsUpdate) {
        Write-Host "  $($item.FileName): $($item.ExpectedCost) -> $($item.ActualCost) (Diff: $($item.Difference))" -ForegroundColor Gray
    }
}
