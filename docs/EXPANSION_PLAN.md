# ArenaBook Expansion Plan

How ArenaBook grows from an arena booking app into a booking and payment ledger for any business that rents out
time on a resource (courts, studios, rooms, halls, cars), without becoming several apps.

Status: **agreed 2026-10-21**. Work happens phase by phase; each phase gets a short design note in chat before code.
The database comes **after** the in-app phases (1–6) are finished.

---

## 1. Decisions

| # | Decision | Consequence |
|---|---|---|
| D1 | **One build per client** (flavor), as today. The developer picks the client's business profile in `lib/app/config/clients/<id>.dart`; the owner never chooses a business type. | No setup wizard for now. |
| D2 | Core names: `Sport` → **`ResourceType`**, `Court` → **`Resource`**. | Stored ids (`cricket`, `padel-a`) and JSON keys (`sport`, `courtId`) stay unchanged, so no data migration for the rename. |
| D3 | **Capacity bookings** (pools, classes: N places per time) only if no drastic change is needed. | Assessed below as contained: Phase 5, with a go/no-go after its design note. |
| D4 | **No instalments.** A booking is paid as an advance plus the balance in one go. | The payment model stays `advancePaid` + Mark Paid. Overruns are handled by editing the booking (see §5). |
| D5 | **Future: self-service.** After the trial, a paying client may configure their own business. | Everything a profile and catalogue hold must be expressible as plain data later (no logic in config). |
| D6 | **Database after the app work.** | The app keeps the repository pattern so the backend is one more implementation (§4). |

## 2. The pattern: core + business profile + client

```
CLIENT            lib/app/config/clients/<id>.dart     one per customer: resources, prices, currency
  └ picks a       ↓ overrides values
BUSINESS PROFILE  lib/app/config/business/             one per industry
                    Terms     what things are called   (Court / Studio / Hall / Car)
                    Policy    how time works           (step, hours, sessions)
                    Features  optional parts           (discount, QR entry pass)
CORE              data/models, data/rules, BookingService, repositories
                    Resource, ResourceType, Booking, TimeRange, Pricing; knows no industry
```

Override order: **core default → profile → client config → owner's saved Settings.**

### Where a difference between businesses goes

| What differs | Where it goes | Example |
|---|---|---|
| A value (name, label, number) | Data in the profile or client config | "Studio", 60-minute step, opening hours |
| A behaviour (another calculation) | A strategy: a `sealed` class with one subclass per behaviour | Hourly vs fixed session price |
| Whether a part exists | A flag in `Features` | QR entry pass, discount |
| A whole new workflow | Its own module, only after customers ask for it repeatedly | Staff calendars |

**Never branch on the business type or client id** (`if (profile == eventVenue)`). Ask what the business needs (a value,
a behaviour or a flag) and add that instead.

### Profiles planned

| Profile | Resource term | Policy | Pricing | Features |
|---|---|---|---|---|
| `sportsVenue` (demo, today) | Court / Sport / Player | 30 min step, any hour | hourly | discount, QR pass |
| `studio` | Studio / Room | 60 min step, opening hours, min 1 h | hourly, half/full-day package | discount |
| `meetingRoom` | Room | 30–60 min step, opening hours | hourly | discount |
| `eventVenue` | Hall / Venue | named sessions (Lunch, Dinner, Full day) | fixed per session | discount |
| `vehicleRental` | Car / Vehicle | 60 min step, any hour, may run past midnight | hourly | discount |

Profiles are `const` Dart objects for now. Because of D5 they must hold **only data** (strings, numbers, enums, ids),
so they can later be stored and edited. Icons are the one exception today (`IconData`); in Phase 6 they move to an icon key.

## 3. Folder layout

```
lib/app/config/business/        business_profile.dart (BusinessProfile, Terms, BookingPolicy, Features)
                                profiles.dart (sportsVenue, studio, ...)
lib/app/config/clients/         ClientConfig + one file per client (profile + resource types)
lib/data/models/                resource.dart (ResourceType, Resource), booking.dart, time_range.dart, pricing.dart
lib/data/rules/                 BookingRules (reads BookingPolicy), BookingStats, InvoiceText (reads Terms)
lib/data/repositories/          booking/ now; catalog/ and settings/ in Phase 6
lib/presentation/arena/         unchanged folder name (product is still ArenaBook)
```

## 4. Ready for the database

| Rule | Status |
|---|---|
| Screens talk to services, services to repository interfaces; Hive is one implementation | done |
| Models are pure Dart: no Hive, Firebase or Supabase types | done; keep it |
| Every record has `updatedAt`; records are cancelled, never deleted | done for bookings; required for every new type |
| Stored JSON is versioned (`v`) and old versions load in `fromJson` | done; every bump adds a migration test on a stored sample |
| `TRF-1001` is a **display reference**, not a global key: nothing parses it or assumes it's unique across devices | rule from now; sync adds a random `uid` key |
| New record types get a random id (`Random.secure`, no package) | rule from now |
| Models don't look up global config while loading (`Booking.fromJson` → `Sport.fromName` today) | fix in Phase 6 |
| Business settings (rates, currency, catalogue) are separate from device settings (theme) | Phase 6 |

Sync later is **local-first**: Hive stays what the UI reads; a synced repository writes to Hive plus an outbox and a worker
pushes and pulls. `BookingService` and the screens don't change.

## 5. Payments (D4)

A booking has a payable amount (`totalFee − discount`), an advance, and a one-step settlement (Mark Paid). Nothing else.

**Overrun example (car rental):** booked 10:00–12:00 for 6,000, advance 3,000. The car comes back at 14:00. The owner
edits the booking to 10:00–14:00: the fee becomes 12,000, a discount can be given in the same edit, Balance Due updates,
and Mark Paid settles it. This already works for future bookings, but two rules must change first (Phase 2):

1. An edit may move the **end** of a booking that has already started (today `keepPastSlots` only accepts the exact same slots).
2. An edit is allowed for a booking that started yesterday and ran past midnight (today `canEdit` blocks any earlier date).

## 6. Phases

Each phase leaves the demo client working exactly as before unless stated, with every test green.

| Phase | Goal | Main changes | Data migration | Done when |
|---|---|---|---|---|
| **1. Neutral core** | No sports words in the core | 1a: rename `Sport`/`Court` and related names. 1b: `BusinessProfile` with `Terms`; every UI and invoice string with an industry word reads `Terms`; `sportsVenue` reproduces today's text | none | Existing widget tests pass without text edits; a test profile with "Studio" terms shows no court, ground, sport or player |
| **2. Booking policy** | Configurable time | `BookingPolicy`: step (15/30/60), min/max duration, opening hours, named sessions; slot picker grid built from it; the two overrun edit rules (§5) | none | Rule tests for each step, opening hours, sessions and overrun edits |
| **3. Pricing** | More than hourly | `Pricing` sealed class (hourly, fixed session/package), optional price per resource; booking stores a frozen price snapshot | schema v3: v2 `hourlyRate` → hourly snapshot | A stored v2 sample loads with identical totals |
| **4. Features and receipts** | Optional parts | `Features` (discount moves here, QR entry pass); receipt title and footer from the profile | none | Invoice tests with QR on and off |
| ✓ Checkpoint | Serve sports, studios, rooms, cars | Add a second real client with another profile | | Both clients pass tests and build |
| **5. Capacity** (go/no-go) | Pools, classes | `Resource.capacity` (default 1), `Booking.places` (default 1); a time is full when booked places reach capacity; price × places | schema v4: missing `places` = 1 | With capacity 1 every existing test still passes |
| **6. Catalogue as data** | Owner-editable resources; ground work for D5 and the database | `CatalogRepository` (Hive) seeded from the client config on first run; resource management in Settings; icon keys | seed once with the same ids | Edits survive restart; old bookings render |
| **7. Backend** | Database and sync | Separate plan, after Phase 6 | | |

Out of scope until customers prove the need: instalments (D4), staff calendars, bookings longer than 48 hours
(multi-day rentals, stays), setup wizard (D5, after Phase 6).

### Capacity assessment (D3)

Contained, not drastic: the conflict rule becomes "places booked at that time + new places ≤ capacity" in `BookingRules`,
the slot picker shows places left, the form gains a places field (hidden at capacity 1), and the fee is multiplied by places.
Default capacity 1 keeps today's behaviour exactly. Final go/no-go comes with the Phase 5 design note.

### Market gaps after each phase

- **Sports and recreation:** Phase 1 (+ Phase 5 for pools and group sessions).
- **Studios, meeting rooms, car rental:** Phases 1–3 (+ Phase 2 overrun edits for cars).
- **Event venues:** Phases 1–4 (sessions with a fixed price). The date picker already allows two years ahead.

## 7. Workflow for every phase

1. Design note in chat: model change, JSON before and after, migration. Agreed before code.
2. Tests first for rules and models; a stored sample record for every schema bump.
3. Core → service → UI, with `flutter analyze` and `flutter test` after each step.
4. `dart format -l 160` on touched files only; `git diff --stat` holds only the phase's files.
5. Update `CLAUDE.md`, `README.md` and this file when a rule or structure changes.
6. The owner reviews and commits; one phase per commit series.
