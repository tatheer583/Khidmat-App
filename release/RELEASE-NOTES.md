# Khidmat 1.3.0 — mobile startup and installation repair

Download `khidmat-arm64-v8a.apk` for most current Android phones. If you do not know your phone architecture, use `khidmat-universal.apk`. Older 32-bit phones use `khidmat-armeabi-v7a.apk`. These are complete signed APKs; download the entire file before opening it from Files/Downloads.

All APKs use build 5001 and the retained Khidmat signing certificate. This fixes the previous mismatch between split/universal Android version codes. The original prototype had a different debug certificate; a conflicting prototype installation must be removed once before installing a Khidmat-signed release.

Changes include visible startup progress and recovery, bounded network requests, native email confirmation/password-reset callbacks, password recovery, validated profile saves, date-specific available times, private photo synchronization and Realtime resynchronization after subscription readiness/reconnection. English/Urdu and separate worker/customer dashboards remain available.

**Hosted activation is required:** the supplied Supabase project has no app tables installed yet and phone authentication is disabled. Apply the database migrations, allow the native auth callback, configure email/SMS delivery and approve real worker listings using [the activation guide](https://github.com/tatheer583/Khidmat-App/blob/main/docs/ACTIVATE-SUPABASE.md). The app displays a clear retry/setup message until services are ready. No demonstration providers or bookings are substituted for real data.

Android requires 7.0 or later. iOS source and simulator/device build checks are included; physical iPhone distribution still requires your Apple signing team and provisioning. An APK does not install on iOS.

`SHA256SUMS` and `artifacts.json` record the release file hashes and package checks. [Verification evidence](https://github.com/tatheer583/Khidmat-App/blob/main/docs/VERIFICATION.md) distinguishes emulator checks, disposable-backend tests and pending hosted/device activation.

The [published-download verification](https://github.com/tatheer583/Khidmat-App/actions/runs/37509777306) passed all four APK checks and actual installation/upgrades on Android 7 and Android 15. Saved Urdu preferences survived upgrades from the previous signed release to the new split APK and then to the universal APK. The [application/backend workflow](https://github.com/tatheer583/Khidmat-App/actions/runs/37507029594) also passed, including iOS compilation/simulator launch and real backend protocol tests on a disposable Supabase stack.
