# Khidmat marketplace setup and backend contract

The Flutter app preserves existing phone-owned profiles, contacts and appointments.
The marketplace is a separate Supabase-backed service. No existing local records
are silently published. A missing configuration is reported as unavailable; it
does not create demo accounts, sample workers, arbitrary OTP acceptance or fake
distances.

No remote database migration, SMS delivery, push dispatch or deployment was
performed during development. The checked-in SQL and function need the operator's
development Supabase project and provider configuration.

## Start in an isolated development project

1. Create a development Supabase project or development branch. Inventory any
   existing backend before applying these migrations. The old offline app's
   README says its previous Supabase integration was removed; it does not prove
   that the previous remote database was deleted or empty.
2. Apply the three files under `supabase/migrations/` in filename order through
   the SQL Editor, or link a development project with the Supabase CLI and run
   `supabase db push`. SQL creates additive marketplace tables. Existing tables
   with conflicting names intentionally stop migration; never drop existing
   tables, migrations, users or data to get past a conflict.
3. PostGIS is installed in `extensions`. If it already exists in another schema,
   migration stops with instructions to review it. Do not drop a live extension
   or its dependent data. Keep `khidmat_private` outside the API's exposed schema
   list. `public` is the only application API schema.
4. Set the trusted public Storage origin as an operator, substituting the real
   HTTPS origin from this development project's settings:

   ```sql
   insert into khidmat_private.settings(key,value)
   values('storage_origin','https://YOUR_PROJECT_REF.supabase.co')
   on conflict(key) do update set value=excluded.value;
   ```

   This value is public service configuration, not a key. Media validation fails
   closed until configured. A custom domain must be the exact origin the app's
   Supabase Storage client uses. URL prefixes, owner folders and actual uploaded
   object existence are validated; arbitrary remote image origins are rejected.
5. In Authentication, enable phone sign-in and configure a supported real SMS
   provider, such as Twilio, MessageBird or Vonage. Verify the provider permits
   SMS delivery to Pakistani `+92` mobile numbers and complete its sender setup.
   Keep SMS credentials in the provider/Supabase dashboard, never in Flutter.
   Configure OTP expiration, resend limits, abuse controls and signup policy.
   Production must not enable fixed test phone codes or disable verification.
6. Copy `config/marketplace.example.json` to the ignored
   `config/marketplace.json`. Set `SUPABASE_URL` and
   `SUPABASE_PUBLISHABLE_KEY` (or the backwards-compatible anonymous public
   key). Build using `--dart-define-from-file=config/marketplace.json`.
   These are public client configuration; never substitute a service-role key,
   database password, SMS credential or Firebase service account.

Example local run, after Flutter dependencies are installed:

```powershell
flutter run --dart-define-from-file=config/marketplace.json
```

Phone OTP is also the supported account recovery route for someone retaining
access to the same number. Recovery after losing that number requires an
operator's verified support procedure; the app does not provide an invented
identity-verification bypass. Configure `KHIDMAT_SUPPORT_EMAIL` for a real
operator support address before public distribution.

## Accounts, catalog and workers

Supabase Auth creates a private `profiles` row. Its phone is synchronized from
Auth, never accepted from a profile request. Writes require a confirmed Pakistani
mobile number and an active account. A new account can save only name, city and
one or both roles; professional details are a separate draft/publish process.

`professions` is configurable data: category, profession, Urdu name, skill names,
questions, display order and active state. The seed contains 18 professions and
no worker records. Operators can add or edit catalog entries through a reviewed
database change without adding a separate registration system. Question types
are `text`, `select`, `multiselect`, `boolean` and `number`. Skill membership,
question keys, types and options are enforced on the server. Required questions
are enforced when publishing, while incomplete drafts can be saved.

Worker fields include skill names, experience, description, languages, working
days/hours, service radius, pricing (`hour`, `day`, `visit`, `job`), portfolio,
photo and contact-sharing consent. Rates are PKR, up to 1,000,000; a published
profile needs a positive rate, description, skills, working days and required
profession answers. Compare the displayed price unit when comparing rates.
The app does not imply that an hourly rate equals a daily or per-visit rate.

`worker-media` is a public image bucket intended only for a worker's chosen
public avatar and portfolio. It accepts JPEG, PNG or WebP up to 5 MiB per object;
maximum eight portfolio images per profile. Paths are
`<authenticated uid>/<uuid>.<extension>`. Only an active worker owner may upload
or replace images. Active owners may delete their objects after removing a role.
No identity documents or private images belong in this public bucket. Public
images may remain accessible after unpublishing; deleting the uploaded object
removes it. The upload client uses unique filenames and does not overwrite
another user's images. Database verification is not image-content moderation.

## Geographic search and privacy

Exact worker coordinates live only in `khidmat_private.worker_locations`, with
a PostGIS geography column and GiST index. No client has SELECT access to that
relation. Workers refresh location explicitly; there is no background tracking.
Clients never download the worker population to calculate distances.

`search_workers` filters profession, skill, text, price, experience, rating,
availability and radius on the server. A geographic result requires a location
updated within 15 minutes and falls inside both the customer's requested radius
and the worker's service radius. Coordinates are restricted to Pakistan's
bounding region. Results return approximate distance rounded to 0.5 km, with a
0.5 km floor; they never return exact coordinates or a home address. Rounded
distance reduces precision but does not eliminate all inference from repeated
geographic queries. Apply gateway abuse controls before public launch.

Without device location, search uses a manually entered city and optional
neighbourhood and returns `distance_km: null`. `p_neighbourhood` filters the
selected city's neighbourhood with a case-insensitive substring match; empty
means city-wide. Text search also matches neighbourhood. Such a result does
not imply that the worker is within a kilometre radius. Workers who decline
location can publish a city/service area and choose `available_later`; they
cannot claim `available_now` nearby without a recent location.

Effective availability is derived on the server:

- `available_now`: both availability and location were refreshed within 15 min.
- `available_later` and `busy`: availability was refreshed within 24 hours.
- Stale or missing required freshness becomes `unknown`.
- `offline` remains explicitly offline.

Only published profiles of active, verified-phone worker accounts and active
professions are discoverable. Safe search and public profile RPCs permit
anonymous browsing. A signed-in suspended/unverified account cannot use these
RPCs to evade account restrictions. Contact access requires verified sign-in and
the worker's explicit `share_contact` consent. No phone appears in search rows.

Search uses deterministic ordering and bounded pages of 1–50 rows, with offset
0–10,000. Stable IDs break sorting ties. Concurrent profile changes can move
items between offset pages. Signed-in search is limited to 120 requests per
15-minute window. Anonymous IP limits need a trusted API gateway/Edge policy;
the database does not pretend that caller-supplied headers are a trusted IP.
Other database limits include 20 contact reads/hour, 15 job requests/hour,
60 job transitions/hour and 5 account reports/day. Configure platform limits
for anonymous discovery, OTP sending and Storage uploads as well.

## Jobs, reviews, moderation and Realtime

Only a customer can create a future request to another worker accepting work.
Only the selected worker can accept/decline a pending request or start accepted
work. After doing the work, the worker requests completion; the customer
confirms it. Reviews require the customer, confirmed completion and no existing
review. Ratings and verification badges are computed/server-owned, not accepted
from client profile data.

Allowed state changes:

| Current | Next | Who |
|---|---|---|
| pending | accepted / declined | selected worker |
| pending | cancelled | customer |
| accepted | in_progress | worker |
| accepted / in_progress | cancelled | either participant |
| in_progress | completion_requested | worker |
| completion_requested | completed | customer |
| completion_requested | in_progress | either participant |

Terminal jobs cannot be reopened. A row lock and partial unique index prevent
accepting two jobs for the same worker at the exact same scheduled instant.
This does not model job duration or prevent time ranges from overlapping;
participants must agree on scope and duration. Price offers are recorded,
not charged: no payment processor or escrow is configured.

Job addresses, notifications and reports have owner/participant RLS. Jobs,
notifications and own profile changes are added to `supabase_realtime` when that
publication exists. Realtime preserves SELECT RLS. The client also reloads
records through authorized queries; push is not the source of truth.

An operator grants administrator access through SQL to an existing verified
account, for example:

```sql
insert into khidmat_private.account_admins(user_id)
values('REPLACE_WITH_EXISTING_OPERATOR_USER_UUID');
```

Do not grant this through signup metadata, the client or a public write policy.
`moderation_reports` lists reports only for administrators. `moderate_account`
supports `suspend`, `reactivate`, `verify_worker`, `revoke_verification`, requires
a reason, and records a private audit entry. The operator must define and carry
out the actual verification procedure; the badge is never automatically granted
for merely creating an account. Identity documents are not collected by this
implementation. Suspended workers disappear from discovery and all account
writes fail. Existing jobs and records are preserved.

Review content moderation is separate from account suspension:

- `moderation_reviews(p_worker_id uuid default null, p_limit integer default 30,
  p_offset integer default 0)` lists original reviews, including hidden ones,
  only for active verified administrators. It returns review `id`, `job_id`,
  `customer_id`, `worker_id`, `rating`, `comment`, `hidden` and `created_at`.
- `moderate_review(p_review_id uuid, p_hidden boolean, p_reason text)` changes
  visibility only. It requires a reason of 10–1,000 characters and writes a
  private audit record. An administrator involved in that job cannot moderate
  its review; another administrator must handle it.

Hidden reviews disappear from public profile lists, review counts, average
ratings and rating-filtered search results. Unhiding restores their contribution.
The original text and rating are never rewritten or deleted. The completed job
remains reviewed, so hiding cannot allow duplicate replacement reviews. Clients,
including administrators, have no direct review UPDATE grant. Establish an
operator content/appeal policy and review reports against it; hiding a review is
an audited moderation action, not an automatic response to a low rating.

`export_my_account` returns the caller's marketplace records through verified
authorization. It is separate from offline backup. `deactivate_account` hides
the public profile, removes push tokens and location, and cancels pending
requests. It requires accepted/in-progress work to be resolved first. Records
remain retained; deactivation is explicitly not a data-deletion promise. Define
and implement an operator retention/deletion policy before public launch.

## Optional FCM push delivery

In-app notifications work independently of Firebase. Push stays disabled until
explicitly configured. Flutter's `ENABLE_PUSH`, Firebase API key, app ID, sender
ID, project ID and iOS bundle ID are public app configuration. Register the real
Android/iOS apps in Firebase; iOS requires APNs configuration and signing
capabilities in the operator's Apple/Firebase projects. Request the phone's
notification permission through the app.

`FIREBASE_APP_ID` must belong to the platform being built. Use separate ignored
Android/iOS configuration files when their Firebase app IDs differ; only the
`.example.json` templates are intended for Git. See the current official
[Firebase Flutter messaging setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
for APNs, swizzling and device requirements. The pinned Firebase SDK still
supports registration tokens; reassess API migrations before upgrading it.

The service account private key belongs only in the Edge Function secret
`FCM_SERVICE_ACCOUNT_JSON`. Enable the FCM HTTP v1 API and grant this account the
Firebase messaging permission for the same project as the client apps. Create
a separate cryptographically random `PUSH_DISPATCH_SECRET`, at least 32
characters, and store it in the Edge secret manager and a trusted scheduler.
Do not put either secret in Dart defines, Git, logs, notifications or a client.
`supabase/.env.example` lists these server variables with empty values. Copy it
only to an ignored server-local environment file when developing the function.

Deploy `supabase/functions/dispatch-push` to the development project only after
reviewing its credentials and RLS. `supabase/config.toml` disables gateway JWT
verification only for this scheduler endpoint; the handler itself verifies the
dedicated secret and fails closed if any provider configuration is missing.
User JWTs cannot dispatch pushes. Supabase provides the server's
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` environment values.

Configure a trusted scheduler to POST to the deployed function approximately
once per minute with an `X-Dispatch-Secret` header. No scheduler or remote
function has been deployed automatically. Never place a literal dispatch secret
in a checked-in cron SQL file or command history. Use the scheduler's secret
store or Supabase Vault according to your hosting arrangement.

Each database notification transaction enqueues one outbox record. Service-only
RPCs lease five records per dispatcher invocation. Each lease expires after two
minutes. Successful/invalid device deliveries get per-device receipts so retries
skip already acknowledged devices. Transient failure backs off exponentially
and reaches a dead-letter state after eight attempts. Explicit FCM
`UNREGISTERED` errors remove expired device tokens; other errors do not.
Tokens inactive for 90 days are skipped. Operators should monitor pending/dead
outbox records and provider errors.

Delivery is **at least once**: a process crash after FCM accepts a message and
before the database stores its receipt can cause a repeat. Notification IDs and
FCM collapse/tag identifiers limit duplicate displays; exactly-once delivery
cannot be promised across an external provider. Push text is generic and excludes
names, addresses, exact positions and job details. The app fetches full content
only through authorized database queries.

## Tests and deployment limits

Run the backend suite with Node 22 or newer:

```powershell
Set-Location supabase/tests
npm ci --no-audit --no-fund
npm test
```

It executes actual PostgreSQL and PostGIS through PGlite WASM, including the
checked-in migrations, geographic queries, indexes, function grants and RLS.
Only Supabase's Auth and Storage service schemas are isolated test fixtures.
The test does not contact a remote project or claim to verify SMS delivery,
Storage HTTP processing, cross-phone Realtime, or the hosted provider setup.
`package-lock.json` pins the test dependencies. `npm ci` affects only test tools.

Run Edge Function checks with Deno:

```powershell
deno check supabase/functions/dispatch-push/index.ts
deno test --allow-env supabase/functions/dispatch-push/index_test.ts
```

Edge tests use real RSA signing and mocked HTTP responses; they never dispatch
external messages. `.github/workflows/backend.yml` runs both suites without
production credentials. Flutter tests, device checks and build instructions
are recorded separately by the application's verification documents.

Before deployment, exercise two real development accounts across two phones:
OTP delivery/session restoration/logout, location grant/deny/manual fallback,
photo upload, stale availability, customer request, worker accept/start/finish
request, customer confirmation, single review, notification delivery and
suspension. Check Realtime authorization and actual provider retry behavior in
the development project. Hosted backups do not necessarily include Storage
objects; include media and credential rotation in your operator runbook.

Migrations must be backed up/reviewed before touching a previous production
backend. Roll back the application separately if needed; do not drop marketplace
tables or users as a routine rollback. Existing offline records remain in their
original phone store and backup format throughout this work.

Official references checked during this audit:
[Supabase phone providers](https://supabase.com/docs/guides/auth/phone-login),
[PostGIS geographic queries](https://supabase.com/docs/guides/database/extensions/postgis),
and [Firebase Flutter messaging setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started).

References: [Supabase database functions](https://supabase.com/docs/guides/database/functions),
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security),
[PostGIS](https://supabase.com/docs/guides/database/extensions/postgis),
[phone sign-in](https://supabase.com/docs/guides/auth/phone-login),
[FCM HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api),
[PGlite extensions](https://pglite.dev/extensions/).
