# Khidmat — خدمت

Khidmat keeps your worker contacts, service appointments and work records on your phone, in English or Urdu. Choose **Worker** to organize client jobs or **Work giver** to plan services with people you know.

**Version 2.0.0, build 5003. Android 7.0+; iOS 15.0+.**

## Download on Android

[**Download Khidmat for Android**](https://github.com/tatheer583/Khidmat-App/releases/download/v2.0.0/khidmat-universal.apk)

1. Open this link in your phone’s browser and let the download finish.
2. Open **Files → Downloads**, then tap **khidmat-universal.apk**.
3. If prompted, allow installation from that browser, then tap **Install → Open**.

There is one Android APK. It supports ARM64, older ARM32 phones and x86-64 devices. The release keeps the existing Khidmat signing key and uses a higher version code, so previous Khidmat-signed releases can update. If an old prototype has a different signature, back up anything you need before uninstalling it.

**iPhone:** An iPhone download needs Apple signing and TestFlight/App Store distribution. The iOS project is included; an installable iPhone release has not been provided. An Android APK cannot install on iPhone.

## Start using the app

1. Tap **Get started**, choose **Worker** or **Work giver**, and save your name and city. Workers can add profession, experience and work details. A phone number is optional for your own profile.
2. In **Workers**, add actual people you know, with their phone number and service. Search your saved contacts by name, city, English, Urdu or Roman Urdu service words.
3. Tap a worker to call, open SMS, share their details or plan an appointment. Agree on the time and price directly with that person.
4. In **Jobs**, save the appointment, address, amount and notes. Update its status as the work progresses.
5. Use the **اردو / English** button to change language. Urdu uses right-to-left layout and your choice survives restart.

Your profile and job records are saved before the app reports success. Switching roles keeps records for both roles and shows the appropriate dashboard.

## What removing the backend means

**No Supabase account, server, database activation, login or connection setup is required.** The app’s records work without Wi-Fi or mobile data. Calling and SMS use your phone’s own apps and service. Sharing opens the phone’s sharing menu.

Worker contacts are entered by you. Appointment statuses are your own records; saving or confirming one does not notify another phone. This version has no shared public worker directory, OTP/email authentication, in-app live chat, automatic booking acceptance or cross-phone synchronization. Those features require an online service.

The Supabase client, schema, setup screens, chat/authentication code and backend tests have been removed. Old connection preferences and cached Supabase login tokens are removed when this version opens. This change does not delete the remote Supabase project or import its records.

## Backup and restore

Open **Profile → Backup and restore → Save backup** and save **khidmat-backup.json** to Files, Drive or another destination. Restore that file on another phone through **Restore backup**. The app validates the file and asks before replacing existing records.

**Back up before uninstalling or clearing app storage.** Both actions remove local records. A backup includes names, phone numbers, addresses and notes; choose where to share it.

The app uses a private JSON file, with queued writes and a previous copy for recovery. An unreadable primary file is preserved when recovery succeeds. If both copies are unreadable, the app provides retry and backup restore rather than erasing records.

## Build Android

Use Flutter **3.47.6**, Dart **3.13.5**, Java **17**, Android SDK **36** and NDK **28.2.13676358**. Retain the existing private signing key when building updates.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
pwsh ./scripts/Build-Android.ps1
pwsh ./scripts/Verify-Apk.ps1 -Apk release/khidmat-universal.apk -SdkRoot C:/path/to/android-sdk
```

The build script produces one signed universal APK. `-AppBundle` creates a Play Store bundle. No backend keys or Dart defines are needed.

[Install-Toolchain.ps1](scripts/Install-Toolchain.ps1) installs the Windows tools. [New-SigningKey.ps1](scripts/New-SigningKey.ps1) is for a new developer’s first private signing key; keep the production key for published updates. CI uses its own test signing certificate.

## Build iOS

Use macOS with Xcode and CocoaPods:

```sh
flutter pub get
flutter build ios --simulator --debug
open ios/Runner.xcworkspace
```

Select **Runner → Signing & Capabilities → Team** in Xcode and configure your Apple Developer team and provisioning. Then build and distribute a signed archive:

```sh
flutter build ipa --release
```

Upload it through Xcode Organizer for TestFlight/App Store distribution. No Apple signing identity has been supplied for this project. See [Flutter’s iOS distribution instructions](https://docs.flutter.dev/deployment/ios).

## Verification and source

[Verification record](docs/VERIFICATION.md) records the tests, signed package checks and device limitations. The mobile workflow checks Android and iOS builds. Android runtime verification disables Wi-Fi/mobile data, creates a profile, saves a worker and appointment, and verifies the appointment after restarting the app. Public release checks install the downloaded APK on Android API 24 and 35 and test updates with the retained release signer.

Download the [Android/iOS source package](https://github.com/tatheer583/Khidmat-App/releases/download/v2.0.0/Khidmat-source.zip), or clone this repository. Private signing keys and generated build caches are excluded.

`lib/` contains the app, `android/` and `ios/` the native projects, `test/` the behavior tests, and `scripts/` the build and release verification tools.
