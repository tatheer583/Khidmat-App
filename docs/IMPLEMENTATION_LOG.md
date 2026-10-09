# Implementation and file-change record

All changes are measured against local preservation baseline `b1909bd`.
No original source file, production credential, database migration or user data
was deleted. Three earlier marketplace drafts were completed and integrated.
The previous README was preserved as `OFFLINE_GUIDE.md` before updating it.

## Stages and decisions

1. **Audit and preservation.** Read the complete local source, native projects,
   tests, workflows and documentation; compared the GitHub baseline; created
   recoverable snapshots and local Git history. Original 21 tests passed.
2. **Backend.** Added three version-controlled additive SQL migrations, seeded
   configurable professions, participant/owner RLS, private indexed geography,
   server validation/rate limits, reviewed roles, storage policies and API
   wrappers. PostgreSQL/PostGIS suite: 70 passed. No remote migration ran.
3. **Authentication and existing-data safety.** Restored real Supabase phone OTP
   and OS-secured session persistence without deleting legacy preferences.
   Removed destructive offline startup cleanup; preserved JSON schema/backups.
   Added session isolation for delayed operations and account changes.
4. **Accounts, workers and discovery.** Integrated existing Provider/GoRouter
   architecture with staged onboarding, configurable questions, sanitized media,
   consent-based contacts, manual/foreground location, freshness, filtering and
   paged geographic discovery. No public records were invented or imported from
   private contacts. Domain suite: 37 passed; configuration suite: 3 passed.
5. **Shared jobs, reviews and operations.** Added participant-only jobs,
   authorized transitions, customer-confirmed completion, eligible reviews,
   private notification history, optional FCM with cancellation-safe opt-in,
   reports and audited administrator account/review moderation. Edge suite:
   8 passed. Marketplace widgets: 12 passed, including review moderation.
6. **Localization, offline access and native integration.** Kept original
   English/Urdu translator and RTL layouts, added marketplace strings, preserved
   private organizer routes, added foreground permissions and iOS entitlements,
   and added explicit Android cloud/device-transfer exclusions. Secure storage
   fails without resetting credentials and keeps encrypted migration backups.
   Export warnings and temporary-file cleanup protect backup privacy.
   Full Flutter suite: 73 passed, 1 live test
   intentionally skipped without dedicated staging credentials.
7. **Build, release and documentation.** Updated Internet/release checks while
   preserving production signer verification; made QA signing explicit;
   added public CI configuration validation, backend CI and credential scans.
   Two additional security-script regression tests passed.
   PowerShell/native syntax checks and whole-project Flutter analysis passed.
   Actual Android artifact evidence is recorded in `VERIFICATION_MARKETPLACE.md`.

## Deployment and risky operations

Live credentials/providers were not available. No deployment, production
database write/reset, source push, release publication, production key creation,
legacy credential deletion or automatic private-data publishing was performed.

Before deployment, inventory existing schemas and extension placement. The
additive migrations stop on table/extension conflicts; resolve those through a
reviewed migration and recoverable backup instead of dropping existing data.
Use an isolated development project first. Restoring the existing production
signing key is necessary for published-app updates. Provider/dashboard secrets
must stay outside source and client builds.

Public media URLs remain public even for an unpublished profile. Deactivation
retains history; deletion and orphan-media retention require an operator policy.
Legacy auth preferences are retained for recovery and may remain in the old
preference store; current sessions use secure storage. An operator-reviewed
cleanup policy must follow validated migration rather than deleting them at
startup. iOS local-record backup behavior is unchanged.

## Complete changed-file inventory

The inventory below is generated from the baseline diff plus unignored new
files. Build caches, toolchains, local credentials and QA artifacts are excluded.

<!-- FILE_INVENTORY -->

A = created; M = modified. Deleted original files: **0**. Changed files: **80**.

| Status | Stage | File |
| --- | --- | --- |
| M | CI and release | `.github/workflows/android.yml` |
| A | Backend | `.github/workflows/backend.yml` |
| M | CI and release | `.github/workflows/signed-android.yml` |
| M | CI and release | `.github/workflows/verify-release.yml` |
| M | Configuration | `.gitignore` |
| M | Native | `android/app/build.gradle.kts` |
| M | Native | `android/app/src/main/AndroidManifest.xml` |
| A | Native | `android/app/src/main/res/xml/backup_rules.xml` |
| A | Native | `android/app/src/main/res/xml/data_extraction_rules.xml` |
| A | Configuration | `config/live-tests.example.json` |
| A | Configuration | `config/marketplace.example.json` |
| A | Audit and setup | `docs/AUDIT_BASELINE.md` |
| A | Audit and setup | `docs/IMPLEMENTATION_LOG.md` |
| A | Audit and setup | `docs/MARKETPLACE_SETUP.md` |
| A | Audit and setup | `docs/OFFLINE_GUIDE.md` |
| A | Audit and setup | `docs/VERIFICATION_MARKETPLACE.md` |
| M | Native | `ios/Podfile` |
| M | Native | `ios/Runner.xcodeproj/project.pbxproj` |
| M | Native | `ios/Runner/Info.plist` |
| A | Native | `ios/Runner/Runner.entitlements` |
| M | Navigation integration | `lib/app.dart` |
| M | Urdu | `lib/localization/app_language.dart` |
| A | Urdu | `lib/localization/marketplace_urdu_strings.dart` |
| M | Navigation integration | `lib/main.dart` |
| A | Accounts and notifications | `lib/marketplace/bootstrap.dart` |
| M | Marketplace and jobs | `lib/marketplace/models/marketplace_models.dart` |
| A | Accounts and notifications | `lib/marketplace/push_notifications.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_account_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_admin_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_auth_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_help_screen.dart` |
| M | Marketplace and jobs | `lib/marketplace/screens/marketplace_home_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_jobs_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_notifications_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_privacy_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_worker_form_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/screens/marketplace_worker_profile_screen.dart` |
| A | Marketplace and jobs | `lib/marketplace/services/device_location_service.dart` |
| A | Marketplace and jobs | `lib/marketplace/services/marketplace_controller.dart` |
| A | Marketplace and jobs | `lib/marketplace/services/marketplace_repository.dart` |
| A | Accounts and notifications | `lib/marketplace/services/secure_auth_storage.dart` |
| A | Marketplace and jobs | `lib/marketplace/services/worker_photo_service.dart` |
| M | Marketplace and jobs | `lib/marketplace/widgets/marketplace_ui.dart` |
| M | Navigation integration | `lib/screens/account_screen.dart` |
| M | Data preservation | `lib/screens/backup_screen.dart` |
| M | Navigation integration | `lib/screens/home_screen.dart` |
| M | Navigation integration | `lib/screens/welcome_screen.dart` |
| M | Data preservation | `lib/services/contact_actions.dart` |
| M | Data preservation | `lib/services/local_store.dart` |
| M | Dependencies | `pubspec.lock` |
| M | Dependencies | `pubspec.yaml` |
| M | Audit and setup | `README.md` |
| M | CI and release | `scripts/Build-Android.ps1` |
| A | CI and release | `scripts/check_security.mjs` |
| A | CI and release | `scripts/configure_release.mjs` |
| M | CI and release | `scripts/Install-Toolchain.ps1` |
| M | CI and release | `scripts/Package-Source.ps1` |
| M | CI and release | `scripts/smoke_android.py` |
| M | CI and release | `scripts/Verify-Apk.ps1` |
| A | Backend | `supabase/.env.example` |
| A | Backend | `supabase/config.toml` |
| A | Backend | `supabase/functions/dispatch-push/index_test.ts` |
| A | Backend | `supabase/functions/dispatch-push/index.ts` |
| A | Backend | `supabase/migrations/202610090001_marketplace.sql` |
| A | Backend | `supabase/migrations/202610090002_catalog.sql` |
| A | Backend | `supabase/migrations/202610090003_operations.sql` |
| A | Backend | `supabase/tests/marketplace.test.mjs` |
| A | Backend | `supabase/tests/package-lock.json` |
| A | Backend | `supabase/tests/package.json` |
| M | QA | `test/local_store_test.dart` |
| A | QA | `test/marketplace_configuration_test.dart` |
| A | QA | `test/marketplace_controller_test.dart` |
| A | QA | `test/marketplace_domain_test.dart` |
| A | QA | `test/marketplace_flows_test.dart` |
| A | QA | `test/marketplace_live_integration_test.dart` |
| A | QA | `test/marketplace_repository_test.dart` |
| A | QA | `test/push_notifications_test.dart` |
| A | QA | `test/secure_auth_storage_test.dart` |
| A | QA | `test/security_scripts_test.mjs` |
| A | QA | `test/worker_photo_service_test.dart` |
