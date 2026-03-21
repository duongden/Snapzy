# Security Policy

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.**

Instead, report them privately using one of these methods:

1. **GitHub Security Advisory** — open a draft advisory at [github.com/duongductrong/Snapzy/security/advisories/new](https://github.com/duongductrong/Snapzy/security/advisories/new)
2. **Email** — contact the maintainer at the email address listed on the [GitHub profile](https://github.com/duongductrong)

Please include as much of the following information as possible:

- Description of the vulnerability
- Steps to reproduce or a proof-of-concept
- Affected version(s) and macOS version
- Potential impact

You should receive an initial acknowledgment within **72 hours**. A fix or mitigation will be communicated before public disclosure.

## Supported Versions

| Version | Supported |
| ------- | --------- |
| Latest release | ✅ |
| Older releases | ❌ — please upgrade |

Only the latest release receives security updates. If a critical vulnerability is confirmed, a patch release will be published as soon as possible.

## App Sandbox & Permissions

Snapzy runs inside the **macOS App Sandbox**. The entitlements it requests and why:

| Entitlement | Purpose |
| --- | --- |
| `com.apple.security.app-sandbox` | Sandboxed execution — limits access to system resources |
| `com.apple.security.network.client` | Outbound network for Sparkle update checks |
| `com.apple.security.files.user-selected.read-write` | Read/write files the user explicitly picks (save dialogs, drag-to-app) |
| `com.apple.security.device.audio-input` | Microphone access for screen recordings with voice |
| `com.apple.security.temporary-exception.shared-preference.read-only` | Read `com.apple.symbolichotkeys` to detect system shortcut conflicts |
| `com.apple.security.temporary-exception.mach-lookup.global-name` | IPC with Sparkle updater (`-spks`, `-spki` services) |

### Permissions requested at runtime

| Permission | Required | Why |
| --- | --- | --- |
| Screen Recording | Yes | Core functionality — capturing the screen via ScreenCaptureKit |
| Microphone | Optional | Recording system audio + voice in screen recordings |
| Accessibility | Optional | Keystroke overlays and mouse click highlights during recording |

All permissions are requested through standard macOS prompts and can be revoked at any time in **System Settings → Privacy & Security**.

## Data Handling

- **Local-only** — Snapzy does not upload captures, recordings, or any user content to external servers.
- **No telemetry** — No analytics, tracking, or usage data is collected.
- **No accounts** — No sign-in, registration, or user accounts.
- **Network usage** — The only outbound network request is the Sparkle update check against the project's GitHub releases (appcast). This can be disabled in Preferences.

## Auto-Updates (Sparkle)

Snapzy uses [Sparkle](https://sparkle-project.org/) for in-app updates:

- Update checks are made over HTTPS against a signed appcast
- Downloaded updates are verified with EdDSA signatures before installation
- Users can disable automatic update checks in Preferences

## Third-Party Dependencies

| Dependency | Purpose | Source |
| --- | --- | --- |
| [Sparkle](https://sparkle-project.org/) | In-app updates | Swift Package Manager |

Snapzy has minimal third-party dependencies. The codebase relies primarily on Apple frameworks (SwiftUI, AppKit, ScreenCaptureKit, Vision, AVFoundation).

## Security Best Practices for Contributors

- Do not hard-code secrets, keys, or tokens in the source code.
- Do not introduce new entitlements without documenting the reason.
- Do not disable or weaken the App Sandbox.
- Follow Apple's [Secure Coding Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/) for any new platform integrations.

## License

This security policy is part of the [Snapzy](https://github.com/duongductrong/Snapzy) project, licensed under the [BSD 3-Clause License](LICENSE).
