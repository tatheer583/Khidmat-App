# Connect Khidmat to real accounts and workers

The current local checkout has **no `config/marketplace.json`**. The example has
blank connection values, so the app starts without a Supabase client. OTP,
online worker search and shared jobs cannot operate yet. Local migration files
do not deploy themselves. No live backend or SMS delivery has been verified.

The owner must complete the account/provider steps below. Keep database
passwords, SMS credentials, service keys and signing keys out of chat and Git.

## 1. Choose a Supabase project and inspect it

Sign in to the [Supabase dashboard](https://supabase.com/dashboard). Open your
existing project or create a development project. Keep its database password in
your password manager; it does not belong in Flutter.

Before applying initial migrations to an existing project, open **SQL Editor →
New query** and run this read-only inventory:

```sql
select to_regclass('public.profiles') as profiles,
       to_regclass('public.professions') as professions,
       to_regclass('public.worker_profiles') as worker_profiles,
       to_regclass('public.jobs') as jobs,
       to_regnamespace('khidmat_private') as private_schema;

select e.extname, n.nspname as extension_schema
from pg_extension e join pg_namespace n on n.oid=e.extnamespace
where e.extname='postgis';

select p.proname, pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('search_workers','save_profile','save_worker_profile',
                   'create_job','moderate_review')
order by p.proname;
```

If those marketplace names already exist, stop and compare the deployment with
the current schema. Preserve a backup. Never drop tables, reset the database or
blindly rerun initial migrations to fix a conflict. A separate development
project is the straightforward choice when old data must stay untouched.
PostGIS must be in `extensions`; review an existing different extension schema
without dropping its dependent data.

## 2. Apply the three files once, in order

For a clean development project, open each file in your editor, copy its
**entire contents**, paste into a new SQL Editor query, and click **Run**:

1. [202610090001_marketplace.sql](../supabase/migrations/202610090001_marketplace.sql)
   — accounts, workers, secure RPCs, geographic search, Storage and Realtime.
2. [202610090002_catalog.sql](../supabase/migrations/202610090002_catalog.sql)
   — 18 professions and configurable questions.
3. [202610090003_operations.sql](../supabase/migrations/202610090003_operations.sql)
   — moderation, export/deactivation and optional push operations.

Each file is transactional. Stop on an error and retain its code; do not remove
protections or delete conflicting objects. In **Project Settings → Data API**,
enable the Data API and expose `public`. Keep `khidmat_private` **unexposed** and
leave RLS enabled.

If the correct migration is deployed but the API still reports missing tables
or functions, run this cache refresh in SQL Editor, then retry:

```sql
NOTIFY pgrst, 'reload schema';
```

It refreshes metadata; it does not create a missing migration.
[Official schema refresh instructions](https://supabase.com/docs/guides/troubleshooting/refresh-postgrest-schema).

## 3. Configure photos and real SMS

Copy the project URL from **Connect**. Replace the example origin below with
that exact HTTPS origin and run in SQL Editor:

```sql
insert into khidmat_private.settings(key,value)
values('storage_origin','https://YOUR_PROJECT_REF.supabase.co')
on conflict(key) do update set value=excluded.value;
```

In **Storage**, confirm that `worker-media` exists. It is the public avatar/
portfolio bucket with owner policies and a 5 MiB image limit. Never place CNICs
or private documents there. Photos fail validation until the origin is set.

Open **Authentication → Sign In / Providers → Phone** (some versions label it
**Providers**). Enable phone sign-in, require phone confirmation, and allow new
signup if new customers/workers should join. Select and configure a real SMS
provider such as Twilio, MessageBird or Vonage. The owner must sign in to that
provider, arrange its sender/billing setup, and enable delivery to **Pakistan
`+92` mobile numbers**. Trial-recipient restrictions and sender approval are
handled in the provider dashboard. Store credentials in Supabase, never Flutter.

Keep fixed test codes and phone auto-confirmation disabled in production. Later,
request and verify a real OTP on your phone. Auth settings only report enabled
features; they cannot prove provider credentials, balance or carrier delivery.
[Official phone sign-in guide](https://supabase.com/docs/guides/auth/phone-login).

## 4. Connect the app and rebuild it

In **Connect** or **Project Settings → API Keys**, copy the project URL and its
**publishable** key. A legacy `anon` key is also supported. Never use a `secret`
or `service_role` key in the mobile app.
[Official API key guide](https://supabase.com/docs/guides/getting-started/api-keys).

From the project folder, copy the example without overwriting local configuration:

```powershell
if (-not (Test-Path -LiteralPath config/marketplace.json)) {
  Copy-Item -LiteralPath config/marketplace.example.json -Destination config/marketplace.json
}
```

Edit the ignored `config/marketplace.json` locally:

- `SUPABASE_URL`: HTTPS origin from the same project.
- `SUPABASE_PUBLISHABLE_KEY`: public publishable or legacy anon key.
- `KHIDMAT_SUPPORT_EMAIL`: a support inbox you actually operate.
- `ENABLE_PUSH`: keep `"false"` initially; Firebase is optional.

If using `SUPABASE_ANON_KEY` instead, remove an empty primary key property.
Flutter does not fall back when `SUPABASE_PUBLISHABLE_KEY` is explicitly empty.

Run the read-only preflight:

```powershell
node scripts/verify_marketplace_backend.mjs
```

It checks live Auth settings, the app's public profession API and a one-row
anonymous worker query. Search uses HTTP POST because PostgREST requires it for
this RPC; its checked-in anonymous branch performs only reads, without a session
or throttle write. The script never calls OTP or mutation endpoints, follows no
redirects, and does not print keys, tokens, project hosts, raw error bodies or
worker details. `--city Karachi` changes the test city.

Use `--static` for file-format checks without networking. Static success never
verifies deployment. A live pass verifies only these public probes; SMS,
authenticated booking, Storage and Realtime need real-device checks. Empty
worker results are legitimate; an empty catalog prevents worker onboarding.

For a normal development run with the configuration included:

```powershell
flutter run --dart-define-from-file=config/marketplace.json
```

For Android QA alongside an installed production app, explicitly build the
isolated **QA variant** (version 2.1.1, build 5005; release build shown):

```powershell
$env:KHIDMAT_TEST_BUILD = 'true'
try {
  flutter build apk --release --dart-define-from-file=config/marketplace.json
} finally {
  Remove-Item Env:KHIDMAT_TEST_BUILD -ErrorAction SilentlyContinue
}
```

This uses package `com.khidmat.khidmat.qa`, label **Khidmat QA**, and separate app
storage. It can install beside `com.khidmat.khidmat` without replacing that app's
saved records. The explicit QA flag applies to debug and release builds; a
default run without the flag retains the production package. QA builds are for
testing.

For production, clear the QA flag and retain the existing private signing key:

```powershell
Remove-Item Env:KHIDMAT_TEST_BUILD -ErrorAction SilentlyContinue
pwsh ./scripts/Build-Android.ps1 -ConfigurationFile config/marketplace.json
```

Production retains `com.khidmat.khidmat`. Do not replace its signing identity.
Placing JSON beside an installed APK does not change compiled configuration;
rebuild and install the configured app.

The existing GitHub signed-build workflow alternatively accepts public repository
variables `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `KHIDMAT_SUPPORT_EMAIL` and
`ENABLE_PUSH=false`, while retaining its existing private Android signing secrets.

## 5. Recruit real workers and complete one real booking

The catalog contains professions, not workers. Invite actual local workers to
register through OTP, enable Worker, complete/publish their profiles and set
availability. A worker declining device location can choose a city and
**Available later**. **Available now** requires a real recent location and
expires after 15 minutes. Never populate fake workers or distances.

Use two distinct verified accounts on two phones:

1. The worker publishes a profile, uploads a photo and sets availability.
2. The customer chooses the same area, finds that worker and requests future work.
3. The worker accepts, starts and requests completion.
4. The customer confirms completion and submits one review.
5. Reopen both apps and check jobs/in-app notifications, session restoration,
   logout and location-denial/manual-location behavior.

Configure trusted administrators and an actual verification/moderation process
using [the detailed backend setup](MARKETPLACE_SETUP.md). A verification badge
must represent real operator checks.

Firebase push is **optional**, not a blocker for discovery, OTP, booking or in-app
notifications. FCM/APNs secrets and the protected scheduler can be configured
later. If enabling Firebase for QA, register `com.khidmat.khidmat.qa` as a separate
Android app and use that app's matching public Firebase configuration. Store
distribution, Apple signing, final privacy/retention policies,
support staffing and worker recruitment require the operator.

## What was actually checked

The preflight was run against this checkout and returned **missing configuration**.
No live requests were attempted. Its HTTP-mocked tests cover public/legacy
headers, secret rejection, missing-schema guidance, safe search and redaction:

```powershell
node --test scripts/verify_marketplace_backend.test.mjs
```

Those tests do not establish a deployed Supabase service. The preflight does not
create accounts, apply migrations, send SMS, upload photos or dispatch push.
Live checks begin after the owner supplies public project configuration locally.
