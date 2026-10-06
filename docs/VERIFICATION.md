# Verification record

Date: 2026-10-06

## Passed

- flutter pub get with Flutter 3.47.6 / Dart 3.13.5.
- flutter analyze: no issues found.
- flutter test: all eleven tests passed.
- Role routing: unfinished profiles enter onboarding; workers see jobs and listing controls; work givers see service discovery.
- English/Urdu switching, saved language preference, and Urdu right-to-left layout were checked in widget tests.
- Both SQL migrations applied successfully in local PostgreSQL using PGlite.
- GitHub Actions also passed Flutter analysis, all eleven app tests, the Android release build and all thirty-three database assertions against full disposable Supabase. Evidence: [workflow run for commit 49c2c13](https://github.com/tatheer583/Khidmat-App/actions/runs/37469884873).
- All thirty-three pgTAP assertions passed: booking restrictions, server pricing, duplicate reservations, private chat and images, worker profile persistence and experience validation.
- Android SDK 36, build tools 36.0.0 and NDK 28.2.13676358 installed. The official command-line tools checksum was verified.
- PowerShell build/package/signing scripts parsed without syntax errors.
- A private RSA signing key is saved locally and excluded from source packages.
- The split APK build completed for arm64-v8a (19,951,747 bytes), armeabi-v7a (17,655,373 bytes) and x86_64 (21,451,910 bytes). Each package contains only its target native ABI and verifies with APK Signature Scheme v2.

## Hosted project

The supplied project at https://akgmokmwadflhzxallxf.supabase.co responds successfully to authenticated-key Auth settings requests. Email signup is enabled. Phone signup is disabled.

The profiles and providers REST endpoints return PGRST205 (tables missing). The public publishable key is saved in config/supabase.json and is included by the release build. It does not grant database administration. No hosted migration has been applied from this session.

Run supabase/setup.sql once in the project SQL Editor, or apply the two migrations in order. If the first migration was already applied, run only 202610060002_profiles_languages.sql.

## Android artifact

- Built release/khidmat-live.apk successfully (54.8 MiB universal fallback) and release/khidmat-arm64-v8a.apk (19.0 MiB recommended phone download).
- APK Signature Scheme v2 verified by Android apksigner.
- Release signer: CN=Khidmat, O=Khidmat, C=PK; RSA 2048.
- Application ID: com.khidmat.khidmat; version 1.2.0, build 3.
- Minimum Android API 24; target API 36. The universal fallback includes arm64-v8a, armeabi-v7a and x86_64; split downloads contain one ABI each.
- Both the supplied project URL and publishable key were found in the compiled arm64 application library.
- Universal APK SHA256: ae691d9c77cf35226e17536c57bee00d117f9a1a129297092f2d971f399f269f.
- Current split APK checksums are stored beside each download in `release/*.sha256`.

The original prototype APK used the Android Debug certificate. Because Android protects installed packages from certificate changes, uninstall the old prototype once before installing version 1.2.0. Future updates built with the retained Khidmat release key can update in place.

The first native build failed because Kotlin incremental caches tried to relativize plugin source files on drive A against the project on drive C. Incremental Kotlin compilation is disabled and the compiler runs in-process. The subsequent release build succeeded. Prepare-Android.ps1 preserves this configuration on Windows.

## Remaining live checks

- Apply the hosted migrations.
- Confirm email delivery and configure an SMS provider for phone OTP.
- Install the APK and complete the two-account device checklist in README.md.
- Check Realtime delivery, actual image upload/download and persistence across app restarts.

The local PGlite tests execute real PostgreSQL functions and RLS with minimal Auth/Storage schemas. They do not test hosted authentication, HTTP storage services, Realtime networking or concurrent transactions.

No Android device was present in adb devices. The repository README includes the required two-account device checklist.
