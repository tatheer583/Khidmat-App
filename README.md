# Khidmat — خدمت

Flutter service marketplace for Pakistan, with the existing private offline worker-contact and appointment organizer preserved. English and Urdu share the same flows; Urdu uses right-to-left layouts.

**Development version 2.1.0+5004.** The marketplace implementation is integrated, but it has **not been deployed or verified with live SMS/push providers**. An unconfigured build explains that the online service is unavailable and still opens the private organizer. No worker accounts, reviews, distances or successful OTP responses are fabricated.

## What is implemented

- Supabase phone OTP, Pakistani number normalization, secure session storage, customer/worker/both roles, suspension handling and separate worker onboarding.
- Configurable professions, skills and questions; editable draft/public profiles, privacy settings, sanitized photos, portfolio, pricing and working hours.
- Foreground location permissions with manual city/neighbourhood selection; server-side indexed PostGIS search, filters, pagination and expiring availability.
- Consent-based phone/SMS/WhatsApp contacts, shared job requests, authorized status transitions, customer-confirmed completion and eligible reviews.
- In-app notifications and optional FCM push; reports, administrator-only account and review moderation, genuine operator verification and private audit records.
- Local profiles, contacts, appointments, backup/restore and corruption recovery remain separate from online accounts. They are never automatically published.

## Configure and run

Use the existing Flutter 3.47.6 / Dart 3.13.5 toolchain. Install dependencies:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
node scripts/check_security.mjs
```

For a configured marketplace, follow [the backend and provider setup instructions](docs/MARKETPLACE_SETUP.md), starting with an isolated Supabase development project. Inventory existing remote tables before applying migrations. Copy `config/marketplace.example.json` to the ignored `config/marketplace.json` and enter only public client configuration:

```powershell
flutter run --dart-define-from-file=config/marketplace.json
```

Supabase SMS credentials and Firebase service accounts belong in server/provider secret storage. Never put them in Dart defines, source control or chat. Phone OTP requires a real provider enabled for Pakistani numbers. Push is disabled until configured and the signed-in user explicitly opts in. Set a real `KHIDMAT_SUPPORT_EMAIL` before public distribution.

Without backend configuration, run `flutter run` and select **Private organizer**. Your local records do not require an online account. Shared marketplace writes require connectivity; an unsent request is never presented as synchronized.

## Backend verification

```powershell
Set-Location supabase/tests
npm ci --no-audit --no-fund
npm test
Set-Location ../..
deno check supabase/functions/dispatch-push/index.ts
deno test --allow-env supabase/functions/dispatch-push/index_test.ts
```

SQL tests execute PostgreSQL/PostGIS in an isolated PGlite process with Supabase service-schema fixtures. Edge tests mock HTTP; neither replaces live deployment verification. An opt-in staging customer/worker test is provided in `test/marketplace_live_integration_test.dart`. Copy the ignored staging configuration from `config/live-tests.example.json`, use dedicated verified test accounts, and run:

```powershell
flutter test test/marketplace_live_integration_test.dart --dart-define-from-file=config/live-tests.json
```

This creates retained staging history. It uses test-account password sessions to exercise the deployed API and does **not** verify SMS delivery, OS permissions, FCM delivery or cross-device Realtime. Leave its opt-in flag false in production.

## Android and iOS

Android requires Java 17, SDK 36, NDK 28.2.13676358 and CMake 3.22.1. Production updates require the existing private signing key; debug signing is never selected silently. After restoring the ignored signing configuration:

```powershell
pwsh ./scripts/Build-Android.ps1 -ConfigurationFile config/marketplace.json
pwsh ./scripts/Verify-Apk.ps1 -Apk release/khidmat-universal.apk -SdkRoot C:/path/to/android-sdk
```

For an **undistributed QA build only**, explicitly set `KHIDMAT_TEST_BUILD=true` before `flutter build apk --release`. This produces a debug-certificate-signed APK and cannot replace the published production-signed app as an update. Clear that flag before production builds.

The signed Android workflow requires public repository variables matching the example configuration, an operational support email, and the existing encrypted Android signing secrets. It validates public configuration, scans source for server credentials, and retains signer/version/alignment checks. Internet is required; background location remains prohibited. CI test builds exercise the offline organizer without backend credentials.

iOS builds require macOS, Xcode, CocoaPods and Apple provisioning. Configure the same bundle identifier and, for push, APNs credentials/capability in Firebase and Apple. Foreground location rationale and push entitlements are included. Compile with `flutter build ios --release --no-codesign` on macOS, then use the actual Apple team to produce and validate a signed archive. iOS cannot be built on this Windows workstation.

## Preservation and audit

The previous published v2.0 download is an offline release, not this marketplace build. Its historical guide and verification record are retained in [OFFLINE_GUIDE.md](docs/OFFLINE_GUIDE.md) and [VERIFICATION.md](docs/VERIFICATION.md). No new release has been published by this development session.

See [the baseline comparison](docs/AUDIT_BASELINE.md), [implementation/file-change record](docs/IMPLEMENTATION_LOG.md), and [current verification and remaining requirements](docs/VERIFICATION_MARKETPLACE.md). Existing legacy preferences and authentication tokens are no longer deleted by offline startup. Secure session migration copies only matching valid legacy data and leaves the original intact. Local backup files contain private names, phones, addresses and notes; they exclude online session credentials and remain unencrypted.
