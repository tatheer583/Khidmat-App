# Activate the hosted backend

The APK is configured for https://akgmokmwadflhzxallxf.supabase.co using the public publishable key supplied by the project owner. The key cannot install a database schema.

1. Open https://supabase.com/dashboard/project/akgmokmwadflhzxallxf/sql/new while signed in to the account that owns this project.
2. Copy the entire contents of ../supabase/setup.sql into a new SQL query and run it once. It includes both migrations: bookings/security and role/profile onboarding. If the first migration was already applied, run only migrations/202610060002_profiles_languages.sql. If a query reports an error, retain that error and resolve it before testing the app.
3. Create a real provider account in the app, fill in its city, service, rates and appointment times, then submit its listing.
4. In the Supabase Table Editor, find that account's providers row and set is_approved to true. Create a separate customer account to search and book the provider.

Email signup is currently enabled. Confirm the account through the confirmation email if required by the project. Phone signup is currently disabled; enable it and configure an SMS provider before using phone login. Authentication delivery and two-device Realtime behavior still require a live test.

The migration creates private avatars and booking-media buckets, participant access policies and Realtime publication entries. Approval and computed reputation cannot be edited by ordinary app accounts. No fictitious providers are installed.

Alternatively, connect the suggested Supabase integration so the migration can be applied through the authorized project connection.
