# Placeholder Replacement Reference

This document lists all the placeholders used in GraphQL queries and the dummy values the analysis script uses to replace them.

## Why Replace Placeholders?

The GraphQL queries in the codeunits contain placeholders like `{{CustomerId}}`, `{{Time}}`, etc. These are replaced at runtime in the actual application. However, Shopify's GraphQL API will reject queries with invalid placeholder values.

The analysis script automatically replaces these placeholders with **valid dummy values** so that:
1. Shopify accepts the query
2. The query executes successfully
3. We get accurate cost calculations

## Placeholder Mapping

### Resource IDs (Shopify GID Format)

These are replaced with valid Shopify Global ID (GID) format strings with dummy numeric IDs:

| Placeholder | Dummy Value | Example GID |
|-------------|-------------|-------------|
| `{{CustomerId}}` | `1234567890` | `gid://shopify/Customer/1234567890` |
| `{{CompanyId}}` | `1234567890` | `gid://shopify/Company/1234567890` |
| `{{CompanyContactId}}` | `1234567890` | `gid://shopify/CompanyContact/1234567890` |
| `{{ContactId}}` | `1234567890` | `gid://shopify/CompanyContact/1234567890` |
| `{{ContactRoleId}}` | `1234567890` | `gid://shopify/CompanyContactRole/1234567890` |
| `{{OrderId}}` | `1234567890` | `gid://shopify/Order/1234567890` |
| `{{ProductId}}` | `1234567890` | `gid://shopify/Product/1234567890` |
| `{{VariantId}}` | `1234567890` | `gid://shopify/ProductVariant/1234567890` |
| `{{LocationId}}` | `1234567890` | `gid://shopify/Location/1234567890` |
| `{{CatalogId}}` | `1234567890` | `gid://shopify/Catalog/1234567890` |
| `{{PriceListId}}` | `1234567890` | `gid://shopify/PriceList/1234567890` |
| `{{FulfillmentOrderId}}` | `1234567890` | `gid://shopify/FulfillmentOrder/1234567890` |
| `{{FulfillmentId}}` | `1234567890` | `gid://shopify/Fulfillment/1234567890` |
| `{{DraftOrderId}}` | `1234567890` | `gid://shopify/DraftOrder/1234567890` |
| `{{SubscriptionId}}` | `1234567890` | `gid://shopify/WebhookSubscription/1234567890` |
| `{{WebhookSubscription}}` | `1234567890` | `gid://shopify/WebhookSubscription/1234567890` |
| `{{DeliveryProfileId}}` | `1234567890` | `gid://shopify/DeliveryProfile/1234567890` |
| `{{DeliveryLocationGroupId}}` | `1234567890` | `gid://shopify/DeliveryLocationGroup/1234567890` |
| `{{BulkOperationId}}` | `1234567890` | `gid://shopify/BulkOperation/1234567890` |
| `{{InventoryItemId}}` | `1234567890` | `gid://shopify/InventoryItem/1234567890` |
| `{{ImageId}}` | `1234567890` | `gid://shopify/MediaImage/1234567890` |
| `{{CompanyLocationId}}` | `1234567890` | `gid://shopify/CompanyLocation/1234567890` |
| `{{Id}}` | `1234567890` | (context-dependent) |
| `{{SinceId}}` | `1234567890` | (numeric ID for filtering) |

### Text Values

| Placeholder | Dummy Value |
|-------------|-------------|
| `{{Title}}` | `Test Title` |
| `{{Name}}` | `Test Name` |
| `{{EMail}}` | `test@example.com` |
| `{{Phone}}` | `+1234567890` |
| `{{Barcode}}` | `123456789` |
| `{{SKU}}` | `TEST-SKU-123` |
| `{{TaxId}}` | `TAX123456` |
| `{{Filename}}` | `test-file.json` |
| `{{MimeType}}` | `application/json` |
| `{{BulkMutation}}` | `test mutation` |

### URLs

| Placeholder | Dummy Value |
|-------------|-------------|
| `{{ResourceUrl}}` | `https://example.com/resource` |
| `{{CallbackUrl}}` | `https://example.com/callback` |
| `{{NotificationUrl}}` | `https://example.com/notification` |

### Dates and Times (ISO 8601 Format)

| Placeholder | Dummy Value |
|-------------|-------------|
| `{{Time}}` | `2020-01-01T00:00:00Z` |
| `{{LastSync}}` | `2020-01-01T00:00:00Z` |

### Pagination Cursors

| Placeholder | Dummy Value | Note |
|-------------|-------------|------|
| `{{After}}` | `eyJsYXN0X2lkIjoxMjM0NTY3ODkwfQ==` | Base64-encoded cursor |

### Numbers

| Placeholder | Dummy Value |
|-------------|-------------|
| `{{NumberOfOrders}}` | `10` |
| `{{OrderLines}}` | `10` |

### GraphQL Enums (No Quotes)

| Placeholder | Dummy Value | Type |
|-------------|-------------|------|
| `{{Resource}}` | `BULK_MUTATION_VARIABLES` | StagedUploadTargetGenerateUploadResource |
| `{{HttpMethod}}` | `POST` | StagedUploadHttpMethodType |
| `{{Currency}}` | `USD` | CurrencyCode |
| `{{WebhookTopic}}` | `ORDERS_CREATE` | WebhookSubscriptionTopic |
| `{{OwnerType}}` | `PRODUCT` | MetafieldOwnerType |

### Complex Values

| Placeholder | Dummy Value |
|-------------|-------------|
| `{{Metafields}}` | `{ownerId: "gid://shopify/Product/1234567890", namespace: "test", key: "test_key", value: "test_value", type: "single_line_text_field"}` |
| `{{StaffMember}}` | `staffMember { id }` |

## Important Notes

### Cost Accuracy

The dummy values are chosen to be realistic enough that Shopify's cost calculator should return accurate costs. However:

- **Mutations**: Mutation costs are typically based on the operation complexity, not the actual data values
- **Queries**: Query costs are based on the requested fields and pagination limits
- **Pagination**: Using dummy cursor values doesn't affect cost calculation

### Why These Specific Values?

1. **IDs**: Using `1234567890` ensures:
   - Valid numeric format
   - Won't accidentally match real production data
   - Consistent across all queries

2. **Dates**: Using `2020-01-01` ensures:
   - Valid ISO 8601 format
   - Old enough to not affect filtering logic
   - Consistent for all time-based queries

3. **URLs**: Using `example.com`:
   - Reserved domain for examples (RFC 2606)
   - Valid URL format
   - Clearly indicates test data

4. **Enums**: Using valid enum values ensures:
   - Query passes GraphQL validation
   - Cost calculation is accurate
   - No runtime errors

### Updating Placeholder Values

If you need to customize the dummy values (for example, to test with specific IDs from your shop):

1. Open `Analyze-GraphQLCosts.ps1`
2. Find the `Replace-PlaceholdersWithDummyValues` function
3. Update the `$placeholders` hashtable with your values
4. Re-run the analysis

## Examples

### Before Replacement
```graphql
{
  customer(id: "gid://shopify/Customer/{{CustomerId}}") {
    firstName
    lastName
    email
  }
}
```

### After Replacement
```graphql
{
  customer(id: "gid://shopify/Customer/1234567890") {
    firstName
    lastName
    email
  }
}
```

---

### Before Replacement
```graphql
{
  customers(first:200, query: "updated_at:>'{{LastSync}}'") {
    edges {
      node {
        id
        updatedAt
      }
    }
  }
}
```

### After Replacement
```graphql
{
  customers(first:200, query: "updated_at:>'2020-01-01T00:00:00Z'") {
    edges {
      node {
        id
        updatedAt
      }
    }
  }
}
```

## Troubleshooting

### "Invalid ID format" errors

If you see errors about invalid IDs:
- Check that the GID format in the query matches Shopify's expected format
- Ensure the resource type in the GID matches the query context
- Some IDs might need to be valid existing resources in your shop

### "Field not found" errors

These errors are usually not related to placeholder values but to:
- API version differences
- Missing fields in your shop's data model
- Beta or deprecated fields

### Cost variations

If you notice costs varying significantly:
- Pagination limits affect cost (more items = higher cost)
- Nested queries multiply costs
- Some fields are more expensive than others

The script provides accurate costs for the query structure, regardless of the placeholder values used.
