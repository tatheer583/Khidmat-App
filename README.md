# Khidmat — خدمت

Khidmat connects people in Pakistan with local workers for household services. The Flutter app uses Supabase for authentication, profiles, bookings, private photo storage and Realtime updates, with separate worker and work giver dashboards in English and Urdu.

**[Download Android APK for modern phones (arm64)](https://github.com/tatheer583/Khidmat-App/raw/refs/heads/main/release/khidmat-arm64-v8a.apk)** · Version 1.2.0 (build 3) · Android 7.0 or later · about 19 MiB

[Download the older 32-bit Android build (armeabi-v7a)](https://github.com/tatheer583/Khidmat-App/raw/refs/heads/main/release/khidmat-armeabi-v7a.apk) if your phone is 32-bit. The arm64 build is the recommended, faster install. The repository also keeps the universal build script for local distribution.

**Deployment status:** the signed APK has been built and verified. The supplied Supabase project still needs its database setup applied, and phone OTP needs an enabled SMS provider. Complete the setup below before testing live accounts and bookings. Physical device and two-account Realtime testing remain pending. See [verification results](docs/VERIFICATION.md).

## Features

- Phone number login with SMS OTP, or email/password registration and login; saved sessions.
- Worker or work giver selection and required profile onboarding: name, city, address, profession, experience and work details.
- Worker dashboard for service listings, availability and incoming jobs; work giver dashboard for discovering and booking services.
- Public worker profiles with service details, experience, prices and verified customer reviews.
- Persistent English/Urdu switching, translated controls and right-to-left Urdu layout.
- Account editing and profile photo uploads.
- Service matching from English, Roman Urdu and Urdu keywords across eight categories.
- Server-priced quotes, booking requests, status updates and customer cancellation.
- Realtime booking history, private chat and photo attachments.
- One customer review per completed booking.
- Database access policies, participant-only booking data, private storage and server-enforced pricing.

Each worker account supports one service listing. An operator approves listings in Supabase before customers can find them. Quotes expire after ten minutes, and duplicate requests or identical provider/date/time reservations are rejected. Payment is cash after service completion; additional work or materials must be agreed separately.

## Supabase setup

1. Create or open your [Supabase project](https://supabase.com/dashboard). For the supplied project, follow [the activation guide](docs/ACTIVATE-SUPABASE.md).
2. Open **SQL Editor** and run [supabase/setup.sql](supabase/setup.sql) once in a fresh project. It creates the tables, onboarding functions, booking operations, access policies, private storage buckets and Realtime publication entries. If the base migration was already applied, run only [the profile migration](supabase/migrations/202610060002_profiles_languages.sql).
3. Enable email signup and configure confirmation email delivery under **Authentication**. Phone login also requires enabling phone authentication and configuring an [SMS provider](https://supabase.com/docs/guides/auth/phone-login).
4. Copy the public configuration example:

   ```powershell
   Copy-Item config/supabase.example.json config/supabase.json
   ```

5. Fill in your project URL and **publishable key**, or a legacy **anon** key:

   ```json
   {
     "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
     "SUPABASE_ANON_KEY": "YOUR_PUBLISHABLE_OR_ANON_KEY"
   }
   ```

The configuration file is excluded from Git. Use only public client credentials; a service-role or secret key must never be embedded in the app. The build script embeds this configuration when present. Without it, the app asks for the connection details on first launch. The downloadable APK already contains the supplied project's public connection details.

The local [supabase/config.toml](supabase/config.toml) disables confirmation emails only for disposable local tests; it does not change hosted authentication settings.

### Add your first worker

Sign up in the app, select **Worker**, complete the profile and create a service listing. In Supabase **Table Editor → providers**, set that worker's `is_approved` to `true`. Customers in the same city can then discover the listing. App users cannot approve their own listings or change reputation scores. Production data is created by real accounts; there are no seeded demonstration providers.

## Run and build

The verified toolchain is Flutter **3.47.6**, Dart **3.13.5**, Java **17**, Android SDK **36** and NDK **28.2.13676358**.

Clone the repository:

```powershell
git clone https://github.com/tatheer583/Khidmat-App.git
cd Khidmat-App
```

### Windows APK build

Use PowerShell 7. Install the toolchain, configure Supabase as above, then build:

```powershell
.\scripts\Install-Toolchain.ps1
.\scripts\Build-Android.ps1
```

The installer downloads tools into `.tools` and prompts for Android SDK license acceptance. The build script prepares Android, installs dependencies, runs analysis and Flutter tests, and produces **`release/khidmat-live.apk`**.

For a smaller phone download, build one APK for each processor architecture:

```powershell
.\scripts\Build-Android.ps1 -SplitPerAbi
```

This produces `release/khidmat-arm64-v8a.apk` for most current phones, `release/khidmat-armeabi-v7a.apk` for older 32-bit phones, and an x86_64 build for emulators. A universal APK includes all three native engines and is about 55 MiB, so it takes longer to transfer and install.

For an Android App Bundle:

```powershell
.\scripts\Build-Android.ps1 -AppBundle
```

### Release signing

The downloadable APK uses a release signing key retained privately by the project owner. Future updates to that APK must use the same key.

For a new distribution, create a key before its first release:

```powershell
.\scripts\New-SigningKey.ps1
.\scripts\Build-Android.ps1
```

Back up `config/khidmat-upload.jks`, `config/signing-password.txt` and `android/key.properties` privately. They are excluded from Git and source packages. Builds without a signing configuration use a development signing key.

### Development

With Flutter and Android tools on your PATH:

```powershell
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
flutter analyze
flutter test
```

## GitHub Actions

[Build Khidmat Android](https://github.com/tatheer583/Khidmat-App/actions) runs on main-branch pushes, pull requests and manual dispatch. It analyzes the app, runs Flutter tests and uploads arm64, armeabi-v7a and x86_64 installable APKs as **khidmat-live-apks**. A separate job starts disposable local Supabase and runs the database security tests.

Optional repository **variables** `SUPABASE_URL` and `SUPABASE_ANON_KEY` configure the CI app automatically. Otherwise, the app uses first-launch connection setup. CI APKs use a development signing key; use the project's private signing configuration for distribution updates.

## Tests and live checks

Validation passed:

| Check | Result |
| --- | --- |
| Flutter analysis | No issues |
| Flutter tests | 11 passed |
| PostgreSQL/pgTAP assertions through PGlite | 33 passed |
| Full local Supabase database tests in GitHub Actions | 33 passed |
| Android release build | Successful locally and in GitHub Actions |
| APK signature | Android Signature Scheme v2 verified |

[GitHub Actions verification](https://github.com/tatheer583/Khidmat-App/actions/runs/37469884873) completed successfully for the earlier app changes. The CI APKs are development-signed artifacts; the download links above are release-signed APKs.

Database assertions cover profile permissions, onboarding validation, server pricing, duplicate reservations, booking transitions, private chat/storage and verified reviews.

Run SQL tests without Docker:

```powershell
cd supabase/tests/pglite
npm ci
npm test
```

The PGlite harness applies both actual migrations in PostgreSQL with minimal Auth and Storage schemas. Hosted authentication, HTTP Storage, Realtime delivery and concurrent transactions still need Supabase integration checks.

With Supabase CLI and Docker installed, run from the repository root against a disposable local database:

```powershell
supabase start
supabase db reset
supabase test db
```

Before distribution, use two real accounts on separate devices:

1. Create and approve a worker listing in the customer's city.
2. Switch each dashboard between English and Urdu; confirm saved preferences after restart.
3. Request a booking as the customer and accept it as the worker.
4. Verify status changes, chat and photo attachments arrive on the other device.
5. Confirm unrelated accounts cannot access the booking or its photos.
6. Complete the job and submit one customer review.
7. Restart the app and confirm booking and conversation persistence.
8. Request the same provider/date/time again and confirm the conflicting request fails.

### Android installation troubleshooting

The app package is `com.khidmat.khidmat` and the release APK is signed. If an older prototype version is already installed, uninstall that one first: the prototype used a different debug certificate and Android will reject an update with a signature-mismatch error. Future updates built with this repository's private release key install normally over version 1.2.0.

If Android says the package is invalid, download the arm64 APK again over a stable connection and confirm that **Install unknown apps** is allowed for the browser or file manager. Use the armeabi-v7a download only on a 32-bit phone; do not install both split APKs together.

## Project layout

| Path | Purpose |
| --- | --- |
| [lib/screens](lib/screens) | Authentication, onboarding, dashboards, bookings and chat |
| [lib/services](lib/services) | Supabase session, repository and app state |
| [lib/localization](lib/localization) | Saved language preference and Urdu translations |
| [supabase/migrations](supabase/migrations) | Database schema, functions and access policies |
| [supabase/tests](supabase/tests) | Database security tests and PGlite harness |
| [scripts](scripts) | Android toolchain, builds, signing and source packaging |
| [docs](docs) | Hosted setup instructions and verification evidence |

## Current scope

Realtime updates work while the app is open. Background push notifications, GPS tracking, voice recognition, generative AI, online payments and a standalone administrator dashboard are not implemented. Search uses local keyword matching. Provider approval uses the Supabase dashboard.

Booking history displays the latest 100 bookings; chat displays the latest 200 messages. Android is the tested build target. Existing iOS scaffolding needs permissions, signing and device testing on macOS.

References: [Supabase Dart client](https://supabase.com/docs/reference/dart/introduction) · [Flutter Android releases](https://docs.flutter.dev/deployment/android)
