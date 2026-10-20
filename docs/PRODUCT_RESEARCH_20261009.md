# Khidmat product research and decisions — 9 October 2026

This review combines inspection of the actual Flutter application with primary-source research. Competitor descriptions are their own claims; they do not establish market size, customer satisfaction, demand, or Khidmat's future performance. No customer interviews or live marketplace launch have occurred.

## Why the previous Explore screen was empty

The previous APK was built without a Supabase URL or public client key. The controller also initialized its profession list to an empty list and returned early when the backend was absent. Service types, which are public catalogue information, consequently disappeared alongside unavailable live worker data. A configured backend whose catalogue request failed could produce the same result. A successful APK compilation did not validate this experience.

The correction separates a bundled service catalogue from genuine online accounts, workers, reviews and bookings. The bundled catalogue uses the same profession identifiers, skills and onboarding questions as the version-controlled database seed. A responding server remains authoritative. Offline browsing never invents a worker, price, distance, rating, availability, or booking confirmation.

## Relevant observations

- Mahir's published app guide describes categories, specific tasks, location, booking time and order history. This supports a short task-oriented discovery path rather than making people understand professional registration before finding help. Its claims about speed, warranties, verification and payment options are not promises made by Khidmat. [Mahir app guide](https://mahircompany.com/blog/how-to-use-the-mahir-company-app-a-complete-step-by-step-guide/).
- Karsaaz presents both urgent booking and an offers option, alongside familiar home-service categories. Khidmat's current implementation supports selecting an actual worker and requesting an appointment. Competitive bidding, instant dispatch and guaranteed arrival times remain outside the verified implementation. [Karsaaz](https://karsaaz.app/).
- Supabase phone sign-in needs an SMS provider to be enabled and configured. Displaying a phone field or accepting a made-up code cannot replace delivery, provider configuration and phone verification. [Supabase phone authentication](https://supabase.com/docs/guides/auth/phone-login).
- Supabase documents indexed PostGIS geography queries for scalable nearby searches. Khidmat keeps exact worker coordinates private and searches on the server. Permission denial must still allow manual city browsing, with no fabricated distance. [Supabase PostGIS](https://supabase.com/docs/guides/database/extensions/postgis).
- Flutter recommends checking accessibility, semantics, contrast, target sizes and larger text. The redesign must work on narrow phones and preserve Urdu right-to-left layout; attractive images alone do not establish usability. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility).

## Decisions for the current upgrade

1. Browse without signing in: show useful service types immediately, search professions and skills, open a service detail, then find actual workers in the chosen area.
2. Make the result state explicit: a missing backend, a failed request and a genuine search with no workers require different messages and actions.
3. Use a calm teal and cream marketplace with local worker cover photography, readable cards, clear navigation and practical preparation guidance. Keep the existing private organizer and records accessible.
4. Use generated photographs solely as category and cover illustrations. Public worker portraits, portfolio, ratings and verification indicators must come from authorized real records.
5. Display worker-provided pricing and its unit. Customers should agree the scope, visit/labour charges and materials with the worker; the app must not imply an arbitrary fixed price or a payment integration it does not provide.
6. Keep configuration and deployment checks separate from product screens. An operator can run a read-only backend preflight before distributing a configured build.

## Pilot proposal requiring real operating decisions

The following is a proposal, not a proven demand forecast: begin in one selected city and a limited service area, recruit consenting workers in a few trades, and test real customer-to-worker bookings before expanding coverage. The user must choose the city and provide or recruit actual workers. Existing private contacts must never be published automatically.

Track real searches with no matches, OTP delivery failures, submitted/accepted/completed appointments, cancellations and reported problems. Establish operational support and actual verification evidence before displaying verification badges. Do not present invented live counts, customers, ratings, testimonials or performance guarantees.

## Remaining launch dependencies

The operator must own a Supabase project, enable its supported SMS provider for Pakistan, apply the reviewed migrations, enter public build configuration and onboard genuine workers. SMS/provider credentials stay in provider/server secret storage. Optional push requires separate Firebase/APNs setup. A configured APK then needs real phone, location, cross-device appointment and authorization checks. See [GO_LIVE_CHECKLIST.md](GO_LIVE_CHECKLIST.md) and [MARKETPLACE_SETUP.md](MARKETPLACE_SETUP.md).
