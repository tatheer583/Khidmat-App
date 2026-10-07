# Verification record

Khidmat 2.0.0, Android build 5003. Date: 2026-10-07.

This version removes Supabase and stores profiles, worker contacts and appointment records in a private JSON file on the phone. The application has no network requests, no Internet permission in its Android release, and no server readiness gate.

## Application checks

[Mobile verification](https://github.com/tatheer583/Khidmat-App/actions/runs/37613616389) passed for application commit `d1a5b33`.

- Flutter analysis passed without issues. All 21 behavior tests passed.
- Tests cover persistence, serialized concurrent writes, failed writes without lost data, backup validation/restore, damaged-file recovery, deleted contacts, duplicate appointments, role-specific records and legacy-token cleanup.
- Widget tests enter a profile, worker and appointment, exercise worker/work giver dashboards, retain Urdu with right-to-left layout, and open forms on a 320-pixel phone with the keyboard visible.
- The Android 15 emulator installed the release build, disabled Wi-Fi and mobile data, created a profile, saved a worker and appointment, restarted the process and reopened the saved job. English/Urdu switching and preference persistence passed.
- The iOS unsigned physical-device and simulator builds passed on macOS. The simulator installed and launched the app. This proves compilation and startup; it does not provide a signed, installable iPhone release.

## Signed Android package

[Signed APK build](https://github.com/tatheer583/Khidmat-App/actions/runs/37613620779) passed with the retained private Khidmat signing key. GitHub Actions stores signing values as encrypted repository secrets; private signing files are excluded from source and artifacts.

Windows application control blocked the local Flutter x86-64 compiler. The release was therefore built on GitHub’s Linux runner. Windows package verification independently passed afterward.

- Package: `com.khidmat.khidmat`; version 2.0.0; version code 5003.
- Minimum Android API 24 (Android 7.0).
- File: `khidmat-universal.apk`; 55,735,587 bytes.
- APK SHA-256: `d87d91806d8bb1efb105119c62c89709f3f28be0f20fe04f99bdf5000a192fc4`.
- Signing certificate SHA-256: `7c680b76c6d8ba235ebc72b68b05038ecaddb0d38e7d776f977695db2cdacebd`.
- ARM64, ARM32 and x86-64 Flutter engines and compiled Dart application libraries are present.
- ZIP integrity, APK signature, package/version parsing and 16 KB native-library alignment passed.
- The release manifest has no Internet permission. No backend keys or configuration are embedded.

The single APK and exact metadata/checksum are distributed through the GitHub release. An independent anonymous download of the complete published APK matched the size and SHA-256 above.

[Published APK verification](https://github.com/tatheer583/Khidmat-App/actions/runs/37625620405) passed on Android 7.0 (API 24) and Android 15 (API 35). Both emulators installed the previous signed version 1.4.0, updated to the downloaded 2.0.0 APK without uninstalling, retained Urdu, created a profile, worker contact and appointment with networking disabled, then reopened the saved appointment after a process restart. On API 24, where the emulator image has no Wi-Fi service, the test disables mobile data and the emulator radio.

## Source and limits

The source package excludes backend files, old APK variants, generated build caches and private signing files. See [README](../README.md) for installation, backup and build instructions.

No physical Android or iOS phone is connected locally. Calls, carrier SMS, file destinations and third-party sharing apps need a final check on the owner’s phone.

Data is local. These checks do not establish shared realtime behavior between phones, identity verification, OTP delivery or hosted marketplace functionality.

Apple signing credentials, an Apple Developer team and provisioning are needed to distribute an iPhone release. Uninstalling or clearing app storage deletes local records; export a backup first.
