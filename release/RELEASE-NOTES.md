# Khidmat 1.4.0 — clearer startup, new Khidmat branding

**For Android:** Download the one [universal Android APK](https://github.com/tatheer583/Khidmat-App/releases/download/v1.4.0/khidmat-universal.apk) (about 55 MiB). It supports all included Android device architectures. On your phone, open the link, wait for the download, tap it in Files/Downloads, then tap Install and Open.

**For iPhone:** An Android APK cannot be installed on an iPhone. The iOS app needs Apple signing before it is available through TestFlight or the App Store.

This Android update is version 1.4.0, build 5002, signed with the retained Khidmat release certificate. The original prototype had a different debug certificate; if Android reports a conflict, uninstall that prototype once before installing this release.

The launcher icon and opening screen now use Khidmat's home-service branding. The sign-in page uses the same mark. The connection screen separates phone network problems from missing app setup and links the owner to database instructions. It is translated into English and Urdu.

**Hosted activation is required:** the supplied Supabase project has no app tables installed yet and phone authentication is disabled. Apply the database migrations, allow the native auth callback, configure email/SMS delivery and approve real worker listings using [the activation guide](https://github.com/tatheer583/Khidmat-App/blob/main/docs/ACTIVATE-SUPABASE.md). The app displays a clear retry/setup message until services are ready. No demonstration providers or bookings are substituted for real data.

Android requires 7.0 or later. iOS source and simulator/device build checks are included; physical iPhone distribution still requires your Apple signing team and provisioning. An APK does not install on iOS.

`SHA256SUMS` and `artifacts.json` record the universal APK hash and package checks. [Verification evidence](https://github.com/tatheer583/Khidmat-App/blob/main/docs/VERIFICATION.md) explains Android installation, hosted service activation and the iOS signing requirement.

The [previous published release](https://github.com/tatheer583/Khidmat-App/actions/runs/37509777306) passed direct downloads and installation/upgrade checks on Android 7 and Android 15. The [application/backend workflow](https://github.com/tatheer583/Khidmat-App/actions/runs/37507029594) passed the Auth, Storage, Realtime and app-repository checks on a disposable Supabase stack. CI will run the same installation checks for this release after publication.
