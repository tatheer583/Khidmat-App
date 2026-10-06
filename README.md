# Khidmat — خدمت

Find local workers, request services and follow jobs in English or Urdu. Flutter provides the Android/iOS app; Supabase provides authentication, profiles, bookings, private photos and Realtime conversations.

**Version 1.3.0, build 5001. Android 7.0+; iOS 15.0+.**

## Download Android

- [Download for most phones — arm64](https://github.com/tatheer583/Khidmat-App/releases/download/v1.3.0/khidmat-arm64-v8a.apk)
- [Download universal APK — if you do not know your phone architecture](https://github.com/tatheer583/Khidmat-App/releases/download/v1.3.0/khidmat-universal.apk)
- [Older 32-bit phones](https://github.com/tatheer583/Khidmat-App/releases/download/v1.3.0/khidmat-armeabi-v7a.apk)
- [Release notes and SHA-256 checksums](https://github.com/tatheer583/Khidmat-App/releases/tag/v1.3.0)

1. Open the link in your browser, rather than an in-app preview. Wait for the download to finish.
2. On Android, open **Files → Downloads**, select the `.apk`, and allow installation from that browser/file manager if Android requests it. Keep Play Protect enabled.
3. If Android reports a conflicting package, the original prototype used a different signing key. Uninstall that prototype once, then install this release. This removes local app preferences, but does not delete server records. Earlier builds signed by Khidmat should update in place.
4. If installation still fails, record the phone model, Android version, filename and exact installer error. A partial `.crdownload` file cannot install. APKs cannot install on iPhones.

Every APK variant now uses version code **5001**. Earlier splits had codes 1003/2003/4003 while the universal APK had code 3, so Android could reject switching APK types as a downgrade. The new build is above all previous variants and retains the Khidmat release certificate.

## Required service activation

**The supplied hosted Supabase project still needs database activation and phone/SMS setup.** Installing a complete APK cannot create tables or enable SMS. Until services are ready, the app displays a connection/setup message and retry button. It does not fabricate workers or bookings.

Follow [the activation guide](docs/ACTIVATE-SUPABASE.md):

1. Apply all three migrations, or run [setup.sql](supabase/setup.sql) once on a fresh database.
2. Allow the auth redirect `com.khidmat.khidmat://login-callback/` and configure confirmation/password-reset emails.
3. Enable phone authentication and connect an SMS provider. Until enabled, the app directs users to email.
4. Run `pwsh ./scripts/Check-Backend.ps1`, then tap **Try again** in the app.
5. Create and approve a worker listing, then book it from a separate customer account.

[config/app.public.json](config/app.public.json) contains the supplied public connection and is embedded in local and CI builds. Publishable keys are intended for clients; database policies enforce access. Signing keys, passwords and administrative credentials are excluded from Git.

## Features

- Phone OTP and email/password authentication, saved sessions, email confirmation callbacks and password recovery.
- Required name, city, role, profession, experience and description; separate worker/work giver dashboards.
- Persistent English/Urdu switching and Urdu right-to-left layout.
- Approved worker discovery across eight categories, public profiles, prices and availability.
- Server-authorized ten-minute quotes and date-specific appointment times, with duplicate reservation protection and idempotent booking retries.
- Participant-only Realtime booking status, private chat and photo attachments.
- Job acceptance, cancellation and progress; one verified customer review per completed booking.
- Visible startup progress, bounded network requests and retry/sign-out recovery.

Each worker has one listing, approved by an operator. Payment is cash after service. Push notifications while the app is closed, GPS tracking and online payments are not implemented. Service matching uses English, Urdu and Roman Urdu keywords.

## Build Android

Toolchain: Flutter **3.47.6**, Dart **3.13.5**, Java **17**, Android SDK **36**, NDK **28.2.13676358**. PowerShell scripts use `.tools` when present. Retain the existing private signing key for updates.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
pwsh ./scripts/Build-Android.ps1 -SplitPerAbi
pwsh ./scripts/Build-Android.ps1
pwsh ./scripts/Verify-Apk.ps1 -Apk release/khidmat-arm64-v8a.apk -SdkRoot C:/path/to/android-sdk
```

The script requires release signing and public connection settings. Use `-ConfigFile config/supabase.json` for a different project; this local override is ignored by Git. `-AllowUnconfigured` is only for an intentional developer setup build. `-AppBundle` produces a Play Store bundle, which is not a phone installer.

New developers can use [Install-Toolchain.ps1](scripts/Install-Toolchain.ps1) and [New-SigningKey.ps1](scripts/New-SigningKey.ps1). Do not replace an existing production key. CI build artifacts use a CI certificate and are separate from the signed downloadable releases.

## Build and distribute iOS

The project includes photo-library permission, auth URL handling, CocoaPods configuration and the Khidmat icon. iOS requires macOS/Xcode; an APK is never an iOS installer.

```sh
flutter pub get
flutter build ios --simulator --debug --dart-define-from-file=config/app.public.json
open ios/Runner.xcworkspace
```

In Xcode, select **Runner → Signing & Capabilities → Team**, choose your Apple team, register the bundle ID and select an iPhone. For TestFlight/App Store distribution, configure your Apple Developer account and run:

```sh
flutter build ipa --release --dart-define-from-file=config/app.public.json
```

Upload the signed archive using Xcode Organizer or Transporter. No Apple signing identity/provisioning profile has been supplied here, so no phone-installable IPA is claimed. CI checks unsigned device compilation and simulator installation separately. See [Flutter's iOS distribution instructions](https://docs.flutter.dev/deployment/ios).

## Verification

[Verification record](docs/VERIFICATION.md) distinguishes builds, emulator checks, disposable-backend tests and the hosted project.

The [application/backend checks](https://github.com/tatheer583/Khidmat-App/actions/runs/37507029594) passed analysis, 16 app tests, 40 database assertions, 17 HTTP/WebSocket checks and the actual Flutter repository integration test. The [signed public-download checks](https://github.com/tatheer583/Khidmat-App/actions/runs/37509777306) passed installation and retained-language upgrades on Android 7 and Android 15. These backend tests use a disposable stack; activate the supplied hosted project before live use.

- Flutter tests cover matching, phone normalization, role routing, Urdu, startup failures and password recovery routing.
- After `npm ci` in `supabase/tests/pglite`, `node run.mjs` executes 40 database assertions.
- CI starts a disposable Supabase stack and exercises real Auth, REST, Storage and Realtime WebSockets with separate accounts. These tests refuse production URLs.
- Android CI installs the release build, checks visible UI, switches to Urdu and restarts it. Release verification downloads the published APKs, checks hashes/signatures and tests upgrades on API 24 and 35.
- iOS CI compiles device/simulator builds and captures the simulator screen.

Before inviting customers, use two real phones/accounts: confirm registration, complete both roles, approve a listing, book, receive/accept the job, exchange text/photos, restart both apps, complete the work and leave a review. Also test connectivity failure/recovery. Hosted SMS delivery and physical-phone compatibility require these real device checks.

## Source

Download the [complete Android/iOS source package](https://github.com/tatheer583/Khidmat-App/releases/download/v1.3.0/Khidmat-Supabase-source.zip), or clone this repository. The source package includes the corrected verification workflow and activation instructions; private signing files are excluded.

`lib/` app; `android/` and `ios/` native projects; `supabase/migrations/` schema; `supabase/tests/` security/API tests; `scripts/` build/verification; `docs/` activation and evidence.
