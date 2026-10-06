# Activate Khidmat services

Project: **akgmokmwadflhzxallxf**. The app contains its URL and publishable key. That key cannot apply migrations or configure authentication. Use your Supabase owner account, or connect the Supabase integration with project access. Do not paste passwords, access tokens or service-role keys into chat.

## 1. Create the backend

1. Open [this project's SQL Editor](https://supabase.com/dashboard/project/akgmokmwadflhzxallxf/sql/new).
2. If the app tables do not exist, paste the full [setup.sql](../supabase/setup.sql) and run once. It includes all three migrations and retains existing authentication accounts.
3. If migrations were applied earlier, run only the missing files from [migrations](../supabase/migrations), in filename order. Do not rerun initial table creation on an existing installation.
4. Run `select public.app_health();`. Expect `schema_version: 3` and `ready: true`.

The migrations install profiles, providers, quotes, bookings, events, messages, reviews, secure functions, private `avatars`/`booking-media` buckets, participant policies and Realtime publication entries. No demonstration workers are inserted.

## 2. Configure authentication

1. Open **Authentication → URL Configuration**. Add the exact additional redirect URL: `com.khidmat.khidmat://login-callback/`.
2. Under **Sign In / Providers → Email**, enable registration. Configure production SMTP and test confirmation/password-reset delivery. Enabled email auth alone does not establish that public users can receive mail; the default delivery service has restrictions.
3. Under **Phone**, enable authentication and configure your SMS provider. It must support your users' destinations, including Pakistan. Provider credentials belong in Supabase, never the app.
4. Request and verify a real OTP. Trial SMS accounts may restrict recipients; inspect the provider delivery logs if a code is missing.

References: [native auth callbacks](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter), [SMTP setup](https://supabase.com/docs/guides/auth/auth-smtp), [phone providers](https://supabase.com/docs/guides/auth/phone-login).

## 3. Check the connection

From the repository, run:

```powershell
pwsh ./scripts/Check-Backend.ps1
```

DatabaseStorageRealtimeReady must be True. EmailEnabled must be True for email; PhoneEnabled must be True for SMS. Open the app and tap **Try again**. Activating services does not require another APK download.

## 4. Test worker and customer

1. Register a worker, confirm the account, choose **Worker**, and complete name, city, profession, experience and description.
2. In **Edit service listing**, set category, service area, prices and daily times, then submit.
3. As the owner, open **Table Editor → providers**, identify the worker and set `is_approved` to `true`. Users cannot approve themselves.
4. On another phone/account, choose **Work giver** and the same city spelling. Find the worker, choose a date and available time, enter an address and book.
5. On the worker phone, open **My jobs**, accept and progress the job. Observe live changes on the customer's open booking screen.
6. Exchange text/photos, restart both apps to confirm persistence, complete the service and leave one customer review.

If a step fails, record its screen/error and inspect **Supabase → Logs**. An installation failure happens before these service steps; diagnosing it requires the phone model, OS version, APK filename and exact installer error.
