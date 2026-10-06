# Verification record

Date: 2026-10-06

## Passed

- flutter pub get with Flutter 3.47.6 / Dart 3.13.5.
- flutter analyze: no issues found.
- flutter test: all eleven tests passed.
- Role routing: unfinished profiles enter onboarding; workers see jobs and listing controls; work givers see service discovery.
- English/Urdu switching, saved language preference, and Urdu right-to-left layout were checked in widget tests.
- Both SQL migrations applied successfully in local PostgreSQL using PGlite.
- All thirty-three pgTAP assertions passed: booking restrictions, server pricing, duplicate reservations, private chat and images, worker profile persistence and experience validation.
- Android SDK 36, build tools 36.0.0 and NDK 28.2.13676358 installed. The official command-line tools checksum was verified.
- PowerShell build/package/signing scripts parsed without syntax errors.
- A private RSA signing key is saved locally and excluded from source packages.

## Hosted project

The supplied project at https://akgmokmwadflhzxallxf.supabase.co responds successfully to authenticated-key Auth settings requests. Email signup is enabled. Phone signup is disabled.

The profiles and providers REST endpoints return PGRST205 (tables missing). The public publishable key is saved in config/supabase.json and is included by the release build. It does not grant database administration. No hosted migration has been applied from this session.

Run supabase/setup.sql once in the project SQL Editor, or apply the two migrations in order. If the first migration was already applied, run only 202610060002_profiles_languages.sql.

## Android artifact

- Built release/khidmat-live.apk successfully (57,415,252 bytes; 54.8 MiB).
- APK Signature Scheme v2 verified by Android apksigner.
- Release signer: CN=Khidmat, O=Khidmat, C=PK; RSA 2048.
- Application ID: com.khidmat.khidmat; version 1.1.0, build 2.
- Minimum Android API 24; target API 36; arm64-v8a, armeabi-v7a and x86_64 included.
- Both the supplied project URL and publishable key were found in the compiled arm64 application library.
- SHA256: 9b8155c01c8d520a5d021332bbfa167a9b29641afbf59a1ac564c9a939f2ae0f.

The first native build failed because Kotlin incremental caches tried to relativize plugin source files on drive A against the project on drive C. Incremental Kotlin compilation is disabled and the compiler runs in-process. The subsequent release build succeeded. Prepare-Android.ps1 preserves this configuration on Windows.

## Remaining live checks

- Apply the hosted migrations.
- Confirm email delivery and configure an SMS provider for phone OTP.
- Install the APK and complete the two-account device checklist in README.md.
- Check Realtime delivery, actual image upload/download and persistence across app restarts.
- Run the SQL tests against disposable full Supabase when Docker/CLI are available.

The local PGlite tests execute real PostgreSQL functions and RLS with minimal Auth/Storage schemas. They do not test hosted authentication, HTTP storage services, Realtime networking or concurrent transactions.

No Android device was present in adb devices. The repository README includes the required two-account device checklist.
