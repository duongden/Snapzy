# Researcher 01 — Polar API: License Validation, Rate Limits, Security

## Key Findings

### Polar Validate API

- **Endpoint**: `POST /v1/license-keys/validate` (or `/v1/customer-portal/license-keys/validate`)
- **Auth**: None required for customer-portal endpoints — safe for desktop apps
- **Request**: `{ key, organization_id, activation_id?, conditions?, increment_usage? }`
- **Response**: Full license key object with `status` field (`"granted"`, `"revoked"`, `"disabled"`)
- **`lastValidatedAt`**: Server-side timestamp — useful as anti-tamper anchor

### Rate Limits

- **3 req/sec** for unauthenticated license validation/activation/deactivation
- **300 req/min** per organization
- **429 Too Many Requests** with `Retry-After` header
- **Implication**: Background sync every 15 min = ~96 req/day per device. Well within limits even with thousands of users.

### Automatic Revocation

- Polar auto-revokes license keys when subscription is cancelled
- Manual revocation/disabling via dashboard is also supported
- Our app must detect `"revoked"` and `"disabled"` statuses

### Security Considerations

- No auth token needed → key itself is the credential
- Key should be stored in Keychain (already done in existing code)
- Validate endpoint doesn't expose sensitive customer data beyond what's in the key
- `lastValidatedAt` from server can be used as time anchor for anti-cheat

## Recommendations

1. Use `lastValidatedAt` from validate response as the `serverTime` anchor for the lease
2. Keep background sync at 15 min — 4 req/hour is negligible against 3/sec limit
3. Handle 429 with exponential backoff, don't invalidate lease on rate limit
4. On network error, fall back to cached lease (don't punish offline users)
