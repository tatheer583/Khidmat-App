# Verification record

Date: 2026-10-07. Application: Khidmat 1.4.0, Android build 5002.

This update refreshes the Khidmat logo, welcome screen and connection/setup recovery in English and Urdu, and removes unused Flutter dependencies. The Android release APK is built and locally verified. The GitHub Android/iOS/backend and published-release emulator workflows must finish successfully before their results are claimed below.

## Application and backend checks

[The previous application workflow](https://github.com/tatheer583/Khidmat-App/actions/runs/37507029594) passed for the 1.3.0 app baseline, commit `da5c6e2`. The 1.4.0 changes require a fresh GitHub workflow run; its Android, iOS and backend results are pending.

- Flutter 3.47.6 / Dart 3.13.5 analysis passed without issues. All 16 application tests passed, including startup recovery, bounded HTTP requests, role routing and English/Urdu behavior.
- All three database migrations applied to a disposable full Supabase stack. All 40 pgTAP assertions passed, covering pricing, booking authorization, duplicate reservations, date availability, private data, profiles and readiness.
- All 17 HTTP/WebSocket checks passed against that stack: real authentication and session refresh, worker booking notifications, private chat, image upload/download, signed URLs, status updates, and logout.
- A separate integration test passed using the application's actual Flutter repository against Auth, PostgREST, Storage and Realtime. It also tests changes occurring immediately after the first data snapshot and subsequent chat/photo/status delivery.
- The Android CI release build installed and launched on an Android 15 emulator. The smoke check verifies a running process, usable UI, language switching and preference persistence after restart. CI builds use a separate test signer; the public release signer is checked below.
- The iOS unsigned device build and simulator build passed on macOS. The simulator installed and launched the app and captured its startup screen. This verifies compilation and simulator startup; it does not provide an installable, signed iPhone IPA.

The app now refreshes data when the database subscription is ready and after reconnection. A channel joining is insufficient evidence that Postgres change delivery has started; the integration tests wait for subscription readiness and verify delivery over actual WebSockets.

## Signed Android download

The universal APK was built locally from the application code using `config/app.public.json`. It contains its compiled Dart application and Flutter engine. Android `apksigner`, package parsing and 16 KB ZIP alignment checks passed locally.

- Package: `com.khidmat.khidmat`; version `1.4.0`; version code `5002`.
- Minimum Android API 24 (Android 7.0), target API 36.
- Retained signing certificate SHA-256: `7c680b76c6d8ba235ebc72b68b05038ecaddb0d38e7d776f977695db2cdacebd`.

| File | Bytes | What it supports |
| --- | ---: | --- |
| khidmat-universal.apk | 57,447,550 | ARM64, ARM32 and x86-64 Android devices |

`release/SHA256SUMS` and `release/artifacts.json` contain the exact hash, size and verification results. The single Android download link is in [README.md](../README.md). Source packages exclude private signing keys, signing passwords and local connection files.

This release keeps the same version code across its universal package and retains the Khidmat release certificate, so prior Khidmat-signed versions can update. The original prototype used a different Android Debug certificate and must be uninstalled once if Android reports a signature conflict.

[The previous public-release verification run](https://github.com/tatheer583/Khidmat-App/actions/runs/37509777306) passed on Android API 24 and 35 for version 1.3.0. The version 1.4.0 public-download and install workflow is pending publication; no emulator result is claimed for it yet.

The 1.4.0 package has passed local signature, package/version and 16 KB alignment checks. Public download and emulator installation checks remain pending.

The previous API 24 and 35 screenshots show the 1.3.0 connection/retry screen in both languages. The supplied backend is still awaiting activation; installation success does not establish successful hosted login or booking. The corrected workflow explicitly installs available platform tools.

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
