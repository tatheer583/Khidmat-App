# Marketplace verification — 9 October 2026

This record covers the local development version 2.1.0+5004. The previous
offline release's evidence remains in `VERIFICATION.md`; it is not evidence that
this marketplace has been deployed or that its live provider flows work.

## Executed baseline checks

- All 24 original Dart files were readable; the current integrated `lib` contains
  44 readable files with zero read failures.
- All 21 original Flutter tests passed before implementation.
- Original GitHub source matched main `5fb44af3097f2d2783834901d58674fbf6500557`.
- Existing missing-controller drafts were identified rather than removed.

## Executed implementation checks

| Check | Result and scope |
| --- | --- |
| PostgreSQL/PostGIS tests | **70 passed** in actual PostgreSQL/PostGIS through PGlite; Supabase Auth/Storage schemas are test fixtures |
| Push Edge Function tests | **8 passed** with HTTP mocked; token expiry, retry, auth, leasing, failures and receipts exercised |
| Edge Function type check | Passed using Deno |
| Domain tests | **37 passed**: models, 15 controller cases, HTTP adapter, 3 secure-session cases, photo metadata and 9 push races |
| Marketplace widget tests | **12 passed**, including the later administrator review moderation flow |
| Configuration tests | **3 passed**; service keys rejected, HTTPS required, unconfigured push fails honestly |
| Existing persistence/matching regression | **15 passed** after startup deletion fix |
| Source security checks | Passed; checks source for server keys, native permissions, backup flag and explicit QA signing |
| Security script regression tests | **2 passed**; escaped JSON/PEM keys rejected without leakage, invalid release configuration preserves existing files |
| PowerShell script syntax | All scripts parsed successfully without changing Windows execution policy |
| Release configuration validation | Public fixture accepted in an isolated ignored directory; service keys and incomplete push rejected without overwriting existing configuration or logging keys |
| Native XML/plist syntax | Android manifest, iOS Info.plist and entitlements parsed successfully |
| Workflow YAML syntax | All **4** GitHub workflow files parsed successfully |
| Full Flutter analysis/suite | **No issues found; 73 passed, 1 live staging test skipped** in the final complete integrated run |
| Android QA compilation | **Universal release-mode APK compiled successfully**, 61.7 MB, explicitly QA debug-signed; final artifact checks below passed |

The Windows execution policy blocked direct execution of unsigned `.ps1`
helpers. The policy was preserved. Flutter/tool binaries were invoked directly,
and PowerShell scripts were syntax checked. This does not prove every packaging
helper has executed on this workstation.

Native dependency compilation emitted non-fatal deprecation messages and a
Firebase Kotlin-plugin migration warning for future Flutter versions. The current
pinned toolchain builds successfully; those dependencies require reassessment
before upgrading Flutter. The missing Cupertino font warning was resolved by
adding the compatible icon-font package; other dependency versions were kept.

## Final local Android artifact

- File: `release/qa/khidmat-marketplace-2.1.0-qa-final.apk` (64,749,296 bytes).
- SHA-256: `44c6aebaa55b0b77a1e6e06e19c34e6c3f414ac27ab6d78081619e780c31d1ba`.
- Package/version: `com.khidmat.khidmat`, `2.1.0`, build `5004`; minimum API 24.
- ARM32, ARM64 and x86-64 compiled Dart/Flutter libraries verified.
- APK signature and 16 KB native library alignment verified using Android tools.
- Internet permission present, background location absent, modern backup rules
  compiled into the manifest.
- **QA debug certificate**, not the published production certificate. Use a
  fresh test device/emulator; preserve the installed production app and its data.
  This signature cannot update the production-signed installation.
- Backend/provider configuration is absent in this artifact. It honestly shows
  online setup unavailable and provides the private organizer. A configured
  marketplace build must use the operator's ignored public configuration file.
- No authorized Android device was connected; runtime installation, OS permission
  prompts and real GPS were not executed. Metadata and checksums are beside the
  APK in the ignored `release/qa` directory. Existing release files are preserved.

## Security and upgrade coverage

SQL tests exercise anonymous/authenticated/unverified/suspended customers,
workers, administrators and service-role callers; private coordinate/contact
access; invalid role/profile claims; geographic filters/freshness; draft/public
visibility; rate limits; media owner/origin validation; participant job access;
status transitions; completed-job review eligibility/duplicates; audited review
hide/restore without changing original content; push service authorization;
account export/deactivation; and storage policy ownership.

Flutter tests exercise retained legacy preferences, JSON backup roundtrip and
corruption recovery, matching-server secure session migration, logout markers,
account-switch private-state isolation, delayed GPS/photo/job operations, OTP
provider failure, denied location/manual neighbourhood search, dynamic worker
forms, authorized job actions/server rejection and stale distance/availability.
Push race tests use injectable providers and deliberately delay consent, token
registration, token rotation, logout, account change and disposal.

Secure storage explicitly disables automatic reset on decryption errors and
enables encrypted migration backups. A regression checks that an OS-key failure
surfaces without clearing existing secure or legacy records. Android's cloud and
device-transfer exclusion rules are explicit, including modern manufacturer
behavior where `allowBackup=false` alone may not block transfer. See
[Android backup rules](https://developer.android.com/identity/data/autobackup).

## Not executed and required before production

1. Apply the migrations to an inventoried isolated Supabase project; verify
   actual PostgREST grants, Storage HTTP policies, Auth triggers, query plans and
   compatibility with any pre-existing remote schema. Fixtures do not certify
   Supabase's deployed infrastructure. No live database reset or migration ran.
2. Configure a real supported SMS provider for Pakistan and test delivery,
   expiration, resend limits, recovery, restart restoration and logout on actual
   phones. No OTP was invented or accepted by a production bypass.
3. Run the opt-in staging two-session journey using dedicated verified accounts.
   It is skipped by default and is not an SMS/device integration test. Test real
   customer/worker phones for cross-device Realtime, connection loss, concurrent
   requests, permission denial/retry and foreground GPS accuracy.
4. Configure FCM service-account secrets only on the server, APNs for iOS, a
   scheduler secret and scheduled dispatch. Verify delivery, denied permission,
   opt-out, revoked tokens and sign-out on physical Android/iOS devices. No
   device was connected to this workstation.
5. Restore the existing production Android key locally or use encrypted CI
   secrets. Test an update from the published production APK while retaining
   Urdu, contacts and appointments. A QA debug-signed build cannot perform that
   production-signature upgrade test.
6. Run macOS/Xcode unsigned compilation, signed iOS archive validation and
   native device testing. iOS builds cannot execute on Windows. CI workflows were
   updated locally; no Actions run or new release publication was performed.
7. Configure gateway/OTP abuse controls, monitoring, backup/restore and retention
   procedures, real support contact, privacy/store disclosures and operator
   evidence standards. Anonymous discovery requires gateway rate limiting.

## Product and operational limits

- Marketplace writes need connectivity and are not queued offline. The private
  organizer continues to work offline, without silently publishing records.
- Availability and approximate distance expire. Foreground refresh requires
  consent; no continuous background location tracking is implemented.
- Appointments have a scheduled instant, not a duration/capacity calendar.
  Identical active worker/time slots are protected; overlapping durations require
  a future duration model.
- Public worker media includes explicitly selected profile/portfolio photos,
  including uploaded draft photos whose URLs are unlisted but public. Removing
  listing visibility does not revoke an already shared public URL. EXIF metadata
  is stripped client-side; operators must define media retention/removal and
  content moderation procedures before production.
- Deactivation hides the account and retains history. Permanent erasure,
  retention exceptions and phone-number-loss recovery require an operator's
  verified procedure; no automatic irreversible account/data deletion is offered.
- Android automatic cloud backup and device-transfer exclusions are configured.
  Local exports are unencrypted and
  contain private contact/job details. iOS local records retain the operating
  system's backup behavior; session keychain items are restricted to this device.
- Push is optional and explicitly enabled per app session; notification history
  remains accessible through the backend. Push delivery is at least once, and
  server receipts reduce duplicates; it is not an emergency delivery guarantee.

Production acceptance remains open until the above live checks pass.
