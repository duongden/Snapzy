# L10n Catalogs

Split runtime source-of-truth for app localization lives here under `Resources/L10n/`.

## Rules

- Edit the owning `.xcstrings` fragment here when possible
- Keep keys inside the fragment that owns their prefix in `manifest.json`
- These catalogs are the runtime resources used by the app. No monolith merge step.

## Commands

```bash
# Check fragment ownership and L10n drift
swift -module-cache-path build/swift-module-cache tools/localization/catalog-tool.swift verify
```
