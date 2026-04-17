---
description: App Store submission readiness checklist.
---

Walk through App Store submission readiness for this app. Check each item and report ✅ / ❌ / ⚠️ with action needed.

## 1. Metadata
- App name, subtitle (30 chars), promotional text (170 chars)
- Description (4000 chars), keywords (100 chars)
- Support URL, marketing URL (optional), privacy policy URL (required)
- Age rating questionnaire complete and accurate

## 2. Screenshots
Required device sizes for current App Store submission:
- 6.9" iPhone (iPhone 16 Pro Max) — required
- 6.5" iPhone (iPhone 11 Pro Max / XS Max) — required
- 13" iPad — required if iPad supported
- 12.9" iPad — required if iPad supported

List which sizes are already prepared and which are still missing.

## 3. App icon
- 1024x1024 master icon present in `Assets.xcassets/AppIcon`
- All required sizes generated (Xcode auto-generates from master)
- No alpha channel, no transparency
- No rounded corners (iOS adds these)

## 4. Privacy
- `PrivacyInfo.xcprivacy` privacy manifest file present
- Required Reason APIs declared (e.g., `NSPrivacyAccessedAPICategoryUserDefaults`)
- Tracking domains listed if any analytics/ads SDKs used
- Privacy policy URL live and matches the in-app data collection
- App Tracking Transparency prompt implemented if tracking

## 5. Build settings
- Bundle identifier matches App Store Connect listing
- Marketing version (e.g. 1.0.0) and build number (incremented from last upload)
- Deployment target matches `CLAUDE.md` (default iOS 17.0)
- Required device capabilities accurate
- Capabilities (Push, Sign in with Apple, IAP, etc.) match entitlements file

## 6. Legal & store listing
- EULA — using Apple's standard or custom? Custom EULA URL required if custom.
- Privacy policy live and accessible
- Age rating appropriate for content
- Export compliance (encryption usage) declared in Info.plist (`ITSAppUsesNonExemptEncryption`)

## 7. TestFlight
- At least one external TestFlight round completed
- Crash-free rate acceptable (>99% recommended)
- Critical user flows manually tested on physical device

## 8. Final checks
- App launches without crashing on minimum supported iOS version
- No `print()` statements or debug-only UI visible in Release builds
- No hardcoded staging/dev URLs in Release configuration
- All analytics events and feature flags configured for production

## Output

For each section, list the status of every item and the action required for any ❌. End with a one-line verdict:

- ✅ **Ready to submit**
- ⚠️ **Submit with caveats** (list them)
- ❌ **Not ready** (list blockers)
