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
flutter run                      # default client (demo); same as --flavor demo
flutter run --flavor <client>    # or pick the client in VS Code's Run and Debug list
flutter test                     # unit + widget tests
```

## Clients

One codebase, one app per client. The **flavor is the client id**: `--flavor demo` sets the app id
(`com.devcatstudios.arenabook.demo`) *and* compiles in that client's config. Nothing is copied or linked
before a build, so the native app and the Dart config can never disagree.

| What | Where |
|---|---|
| Business profile (wording, time rules, pricing), resource types (sports) and resources (courts), default rates, currency, WhatsApp country code, discount on/off | `lib/app/config/clients/<client>.dart` |
| Client's own images | `assets/clients/<client>/` (see below) |
| Client's launcher icon (optional) | `android/app/src/<client>/res/`, `ios/Runner/Assets.xcassets/AppIcon-<client>.appiconset` |
| Trial switch URL (one Gist for all clients) | `lib/app/config/app_client_config.dart` → `accessConfigUrl` |
| App name, version, developer contact (same for every client) | `lib/app/config/app_strings.dart` |
| Logo (1024×1024, white on transparent) | `assets/images/logo.png` |

Never change a client id, sport id or court id once used. Turn a sport off with `enabled: false`.

### Build a client

```bash
scripts\build.bat <client> [apk|appbundle]        # Windows
bash scripts/build.sh <client> [apk|appbundle|ipa] # macOS / Linux (ipa needs a Mac)
```

The output goes to `dist/ArenaBook-<client>-<version>.<apk|aab|ipa>`. Extra arguments are passed to `flutter build`.

### Add a client

Use a lowercase id with letters, digits or `_` (e.g. `champions`). It becomes the flavor, the app id suffix and the Gist key.

```bash
dart run tool/clients.dart add champions
```

This copies `demo.dart` to `lib/app/config/clients/champions.dart` and registers the client in `ClientConfig.all`,
the Android flavors, the iOS Podfile, the Xcode configurations and scheme, and `.vscode/launch.json`. It works on
Windows too, with no Xcode needed. Then edit the new config file, add the client to the Gist, and run `flutter test`.
`clients_config_test.dart` fails if anything is out of step.

### Client images

Each client's own images (logo, banners, etc.) go in `assets/clients/<id>/`. Only that client's build bundles the folder.

```bash
# put the files in assets/clients/champions/, then:
dart run tool/clients.dart assets champions   # declares the folder in pubspec.yaml for that flavor only
```

Use them in code through the current client, never with a hard-coded id:

```dart
Image.asset(AppClientConfig.client.asset('logo.png'))
```

A screen shared by all clients must handle a client that doesn't have the file: give every client the same file names, or use `errorBuilder`.
Subfolders aren't bundled, so keep the files directly in the client's folder.

### Client launcher icon (optional)

Without a custom icon, every client uses the ArenaBook icon.

- **Android:** put the client's icons in `android/app/src/<id>/res/`, using the same folders and names as `src/main/res`
  (`mipmap-*/ic_launcher*.png`, `mipmap-anydpi-v26/ic_launcher.xml`). Android replaces the default for that flavor automatically.
- **iOS:** add `ios/Runner/Assets.xcassets/AppIcon-<id>.appiconset` (same layout as `AppIcon.appiconset`), then run
  `dart run tool/clients.dart ios-icon <id>`.

### Trial switch (GitHub Gist)

One Gist file controls every client. Each build reads only its own entry, keyed by client id:

```json
{
  "clients": {
    "demo":      { "DataEntryStatus": 1, "IsAppEnable": true,  "AppDisableAfterDate": "" },
    "champions": { "DataEntryStatus": 1, "IsAppEnable": false, "AppDisableAfterDate": "2026-11-30" }
  }
}
```

- `DataEntryStatus` other than 1: the entry is ignored and the app runs.
- `IsAppEnable: false`: the app is blocked now, or after `AppDisableAfterDate` when one is set (the drawer counts the days down).
- **Every client must have an entry.** A client with no entry, or a file that isn't valid JSON, shows an
  "App Not Activated" dialog that can't be closed, on every phone that fetches it, until the Gist is fixed (blocked apps re-check every minute).
  Check the JSON (e.g. jsonlint.com) before saving the Gist. Extra keys (e.g. `"UserName"`, notes) are ignored.
- Only a real GitHub response counts. Offline, GitHub errors and Wi-Fi login pages keep the last fetched state.
  A fresh install that has never reached GitHub runs until its first successful check.


## Project layout

```
lib/
├── app/config/              # strings, theme (arena_theme.dart), cache keys, AppClientConfig
├── app/config/clients/      # one ClientConfig per client (flavor)
├── app/service/getx_service/# BookingService (single source of truth), AppAccessService (trial switch)
├── data/models/             # Booking, ResourceType/Resource, TimeRange, AppAccess
├── data/rules/              # pure booking rules and invoice text, unit-tested
├── data/repositories/       # Hive booking repository
└── presentation/arena/      # shell (tabs + drawer), home, booking_form, bookings, pending, calendar, invoice, dialogs
assets/clients/<client>/     # each client's own images (bundled only into that client's app)
tool/clients.dart            # add a client, declare its assets, switch its iOS icon
scripts/build.bat|.sh        # release build of one client into dist/
```

## Before release

- Set up release signing (Android still signs release builds with the debug key).
- Remove or restrict `AppHttpOverrides` (set in `InitBindings`). It accepts every SSL certificate.
- Keep `version:` in `pubspec.yaml` in sync with `kappVersionWithDate` / `kappBuildNumber` in `app_strings.dart`.
