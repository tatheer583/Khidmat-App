# Verification record

Date: 2026-10-06. Application: Khidmat 1.3.0, Android build 5001.

## Application and backend checks

[The final application workflow](https://github.com/tatheer583/Khidmat-App/actions/runs/37507029594) checks the application code used for these APKs, commit `da5c6e2`.

- Flutter 3.47.6 / Dart 3.13.5 analysis passed without issues. All 16 application tests passed, including startup recovery, bounded HTTP requests, role routing and English/Urdu behavior.
- All three database migrations applied to a disposable full Supabase stack. All 40 pgTAP assertions passed, covering pricing, booking authorization, duplicate reservations, date availability, private data, profiles and readiness.
- All 17 HTTP/WebSocket checks passed against that stack: real authentication and session refresh, worker booking notifications, private chat, image upload/download, signed URLs, status updates, and logout.
- A separate integration test passed using the application's actual Flutter repository against Auth, PostgREST, Storage and Realtime. It also tests changes occurring immediately after the first data snapshot and subsequent chat/photo/status delivery.
- The Android CI release build installed and launched on an Android 15 emulator. The smoke check verifies a running process, usable UI, language switching and preference persistence after restart. CI builds use a separate test signer; the public release signer is checked below.
- The iOS unsigned device build and simulator build passed on macOS. The simulator installed and launched the app and captured its startup screen. This verifies compilation and simulator startup; it does not provide an installable, signed iPhone IPA.

The app now refreshes data when the database subscription is ready and after reconnection. A channel joining is insufficient evidence that Postgres change delivery has started; the integration tests wait for subscription readiness and verify delivery over actual WebSockets.

## Signed Android downloads

The release APKs were built locally from the checked application code using `config/app.public.json`. Each contains its compiled Dart application and Flutter engine. Android `apksigner`, package parsing and 16 KB ZIP alignment checks passed for every file.

- Package: `com.khidmat.khidmat`; version `1.3.0`; **all variants use version code 5001**.
- Minimum Android API 24 (Android 7.0), target API 36.
- Retained signing certificate SHA-256: `7c680b76c6d8ba235ebc72b68b05038ecaddb0d38e7d776f977695db2cdacebd`.

| File | Bytes | Architecture |
| --- | ---: | --- |
| khidmat-arm64-v8a.apk | 19,952,339 | Most current Android phones |
| khidmat-armeabi-v7a.apk | 17,672,349 | Older 32-bit ARM phones |
| khidmat-x86_64.apk | 21,452,498 | x86-64 devices/emulators |
| khidmat-universal.apk | 57,432,232 | All three supported architectures |

`release/SHA256SUMS` and `release/artifacts.json` contain the exact hashes, sizes and verification results. Download links are in [README.md](../README.md). Source packages exclude private signing keys, signing passwords and local connection files.

The earlier split APKs used architecture-dependent version codes, which could prevent switching to a universal APK during an update. Build 5001 removes that mismatch. The retained release certificate supports updates from the previous Khidmat-signed release. The original prototype used a different Android Debug certificate and must be uninstalled once if Android reports a signature conflict.

[The public-release verification workflow](https://github.com/tatheer583/Khidmat-App/actions/workflows/verify-release.yml) downloads all four APKs, verifies hashes and ZIP contents, checks signatures, and tests upgrades from the old signed x86 APK to the new split and universal APKs on Android API 24 and 35. Language preferences must survive both updates. Its results become available after publication; this source package was prepared before those public-download checks finished.

## Supplied hosted project

The project at `https://akgmokmwadflhzxallxf.supabase.co` responds to Auth settings requests with the supplied publishable key. **Email authentication is enabled; phone authentication is disabled.** The readiness RPC and application tables are absent, so hosted database/storage/realtime readiness currently fails.

No hosted migrations were applied in this session. A publishable key does not grant database administration. The successful backend checks above used a disposable Supabase stack and do not establish that the supplied production project is activated.

Follow [the activation guide](ACTIVATE-SUPABASE.md): apply `supabase/setup.sql` for a fresh project, or apply only the missing migrations in order; configure the native auth callback and email/SMS delivery; then approve real worker listings. Re-run `scripts/Check-Backend.ps1` and complete the two-account device checklist in README.

## Checks still requiring owner access or devices

- Activate the hosted database and storage, then verify email delivery and phone OTP with real recipients.
- Complete onboarding, booking, chat, photo upload and status updates with two real accounts on physical devices against that hosted project.
- Confirm installation on the user's own phone; no physical Android device was connected locally.
- Select an Apple signing team and provisioning, then produce and test a signed iPhone build/TestFlight release. The iOS project requires iOS 15 or later.

The app intentionally shows a translated connection/retry screen while backend services are unavailable. It does not replace missing data with demonstration bookings or claim successful operations when requests fail.
