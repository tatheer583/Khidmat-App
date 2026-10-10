# Baseline audit — 9 October 2026

Local project: `C:\Users\1\Downloads\Khidmat-App-main\Khidmat-App-main`.
Full-access inspection successfully read all original files under `lib` without
changing EFS encryption or filesystem permissions. Earlier restricted-identity
access failures were resolved by the supplied full-access environment.

## Baseline and GitHub comparison

The original 114 GitHub source files matched remote main commit
`5fb44af3097f2d2783834901d58674fbf6500557` byte for byte during the audit.
Remote main was checked again on 9 October and still pointed to that commit.
Repository: https://github.com/tatheer583/Khidmat-App .

The downloaded folder had no Git history. A local baseline was committed as
`491e882`, followed by `b1909bd` to capture the existing Gradle wrappers. The
baseline includes 27 Dart files: the 24 original files and three incomplete
marketplace drafts left by interrupted earlier work. Those drafts are the
important local-only difference from GitHub. Local generated caches/toolchain
files are excluded from the comparison. No remote push has been made.

Recoverable source snapshots are outside the working folder at
`..\Khidmat-backups\before-marketplace-20261009` and
`..\Khidmat-backups\baseline-20261009-0730`. Private signing/backend
configuration and production user data were not overwritten or deleted.

## Architecture found

- Flutter/Dart, Provider, GoRouter; entry points `lib/main.dart` and `lib/app.dart`.
- Reusable Material UI, persisted English/Urdu preference and RTL layout.
- `LocalStore` writes a phone-private JSON profile/contact/appointment database,
  queues writes, preserves a previous copy and supports backup restore.
- Worker/work-giver roles were organizer labels, not authenticated server roles.
- Calling, SMS, sharing, local appointment statuses and offline search worked.
- No active backend, OTP, shared directory, geographic service, RLS schema,
  cloud job synchronization, reviews, push or administration existed.
- Marketplace drafts referenced an absent controller and were disconnected from
  navigation. The initial complete-tree analyzer therefore could not pass.
- Android/iOS projects and release workflows existed; production signing files
  were not available locally. Native code and release checks assumed an offline app.

## Specification comparison

| Requirement | Baseline | Implementation now | Live validation |
| --- | --- | --- | --- |
| Offline contacts, appointments, backups, Urdu | Working | Preserved and regression tested | Device upgrade still required |
| Phone accounts, secure sessions, roles | Missing | Real Supabase OTP flow, secure migration, server authorization | Real SMS provider required |
| Dynamic worker onboarding and media | Disconnected drafts | Integrated forms, configurable catalog, private draft/public listing | Live Storage HTTP required |
| Geographic discovery and filters | Missing | Private PostGIS coordinates, indexed RPC, freshness, manual fallback | Real OS/GPS and deployed API required |
| Shared requests and appointments | Missing | Participant RLS, authorized state machine, Realtime subscriptions | Two-device connectivity test required |
| Reviews and moderation | Missing | Completed-job reviews, admin hide/restore, immutable history | Deployed role checks required |
| Notifications | Missing | Private history and optional FCM outbox/dispatch/opt-in | FCM/APNs and scheduler required |
| Server validation and abuse controls | Missing | Constraints, checked RPCs, RLS, rate limits, service-only push | Provider/gateway limits must be configured |
| Production release | Offline v2.0 workflow | Network permissions and secure signing checks updated | Production key and macOS signing required |

## Critical findings and resolution

1. Offline startup removed legacy Supabase preferences and cached sessions.
   Removed that deletion and added a preservation regression. Secure migration
   copies a matching session only after validation and confirmed storage write.
2. Main native manifests lacked marketplace networking/location configuration;
   release verification rejected Internet. Added required foreground permissions,
   retained backup restrictions, and changed release checks to require Internet
   while rejecting background location.
3. Local signing was absent. Production builds now fail explicitly rather than
   silently using a debug certificate. QA signing requires a deliberate flag.
4. Shared backup output contained personal data and could leave a temporary file.
   Added a privacy explanation and cleanup of only the newly created temporary
   export. User-selected backup destinations are untouched.
5. Existing private contacts could not safely become public workers or shared
   jobs. The new backend has separate records; no automatic publishing migration
   runs and the original local JSON schema remains compatible.
6. Exact worker coordinates, editable role/admin claims and stale online badges
   would be unsafe. Coordinates/admins are private, permissions are server-owned,
   and displayed availability/distance expires instead of being invented.

The original 21 tests passed before implementation. Final results and external
requirements are recorded separately in `VERIFICATION_MARKETPLACE.md`.
