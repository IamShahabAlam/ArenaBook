# ArenaBook

Ground booking app for arena owners, built for indoor cricket and padel. One phone runs the whole arena:
book courts by the half hour, track advances and dues, and send customers a receipt on WhatsApp.
Works fully offline, and all data stays on the device.

Developed by **DevCat Studios**.

## Features

- **No double bookings:** every court is checked for clashes before a booking is saved.
- **Slot picker:** 30-minute slots grouped by Night / Morning / Afternoon / Evening. Booked and past times are blocked.
- **Payments:** advance, optional discount and remaining balance. **Pending** lists every booking with dues, with one-tap *Mark Paid*.
- **Invoices:** receipt with a QR entry pass. *Share via WhatsApp* sends a picture of the receipt, and *Copy Text* copies it as text.
- **Contact the customer:** Call, SMS or WhatsApp from the invoice.
- **Bookings:** search by name, phone or reference; filter by sport, date range and upcoming / past. Edit, repeat or cancel (with a reason and whether the advance was returned).
- **Calendar:** one coloured dot per sport booked on each day.
- **Dashboard:** total slots, pending dues, amount collected and total value, per sport or for all courts.
- **Settings:** light / dark theme, currency symbol, hourly rate per sport.
- **Remote trial switch:** the app can be time-limited or disabled from a GitHub Gist (see below).

## Tech

Flutter 3.38 (Dart 3.10), GetX for state, routing and DI, Hive CE for bookings, SharedPreferences for settings.
The app is built on the in-house GetX starter. Its API layer, login and response cache are kept for a future online
version but are not used yet.

## Run

```bash
flutter pub get
flutter run
flutter test        # unit + widget tests
```

## Configure per client

| What | Where |
|---|---|
| Sports, courts, default rates (turn a sport off with `enabled: false`; never change an `id` once used) | `lib/app/config/app_client_config.dart` → `sports` |
| Discount field on/off | `app_client_config.dart` → `enableDiscount` |
| Trial switch URL | `app_client_config.dart` → `accessConfigUrl` |
| App name, version, developer contact (shown in Support and the trial dialog) | `lib/app/config/app_strings.dart` |
| Logo (1024×1024, white on transparent) | `assets/images/logo.png` |


## Project layout

```
lib/
├── app/config/              # client config, strings, theme (arena_theme.dart), cache keys
├── app/service/getx_service/# BookingService (single source of truth), AppAccessService (trial switch)
├── data/models/             # Booking, Sport/Court, TimeRange, AppAccess
├── data/rules/              # pure booking rules and invoice text, unit-tested
├── data/repositories/       # Hive booking repository
└── presentation/arena/      # shell (tabs + drawer), home, booking_form, bookings, pending, calendar, invoice, dialogs
```

## Before release

- Set the real Android `applicationId` / iOS bundle id and release signing.
- Remove or restrict `AppHttpOverrides` (set in `InitBindings`). It accepts every SSL certificate.
- Keep `version:` in `pubspec.yaml` in sync with `kappVersionWithDate` / `kappBuildNumber` in `app_strings.dart`.
