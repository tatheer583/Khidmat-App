# Verification record

Khidmat 2.0.0, Android build 5003. Date: 2026-10-07.

This version removes Supabase and stores phone-owned profiles, worker contacts and appointment records in a private JSON file. There are no network requests in the application and no server readiness gate.

## Checks for this release

The release is being verified. Final build details and workflow evidence will be added after the checks finish.

The behavior suite covers persistence across restarts, serialized concurrent writes, failed writes, backup validation/restore, damaged-file recovery, contact deletion, appointment conflicts, role-specific records, legacy-token cleanup, service matching, form entry and Urdu layout/persistence.

The Android release is checked for the package ID, version, complete compiled application/engine files, retained signing certificate and 16 KB native-library alignment. The public download workflow verifies checksums and installs the actual universal APK on Android API 24 and 35. Runtime checks disable Wi-Fi and mobile data, switch languages and save/reopen a profile, worker and appointment.

The iOS workflow compiles unsigned physical-device and simulator builds and installs/launches the simulator app. This does not supply an installable signed iPhone release.

## Limits

No physical Android or iOS phone is connected locally. Phone calls, carrier SMS, file destinations and third-party sharing apps need a final check on the owner’s phone.

Data is local. These checks do not establish shared realtime behavior between phones, identity verification, OTP delivery or hosted marketplace functionality.

Apple signing credentials, an Apple Developer team and provisioning are needed to distribute an iPhone release. Uninstalling or clearing app storage deletes local records; export a backup first.
