# CLAUDE.md — ArenaBook

Guide for every Claude session in this repo. Read it fully before changing anything.
`README.md` has the product overview and the per-client config table; this file covers how to work here.

## What this app is

ArenaBook is an **offline, single-phone booking ledger for indoor cricket / padel arena OWNERS** (not players).
The owner books courts by the half hour, tracks advances and dues, and shares invoices with customers on WhatsApp.
All data stays on the device. Flutter 3.38 / Dart 3.10, GetX (state, routing, DI), Hive CE (bookings),
SharedPreferences (settings). Built by DevCat Studios on the in-house GetX starter (`starter_proj_getx`).

**It is being generalised** into a booking ledger for any business that rents time on a resource (studios, rooms, halls, cars).
`docs/EXPANSION_PLAN.md` holds the agreed decisions, the core + business profile + client pattern, and the phases.
Read it before any structural change. The core uses neutral names: `ResourceType` (was `Sport`) and `Resource` (was `Court`).

## Working rules (from the owner: follow these exactly)

1. **Never commit.** Don't `git commit`, amend, push, or rewrite history unless the user asks in that message.
   Leave every change in the working tree; the user reviews each file before committing.
2. **Mentor mode.** Act as a senior engineer and mentor: explain *why*, flag bad practice honestly, and work in
   small, verified steps (analyze and test after each one).
3. **Format only the files you touched:** `dart format -l 160 <file> ...`. Never format `lib/` or `test/` as a whole;
   the starter files were never auto-formatted, and reformatting them floods the review diff.
   Before finishing, run `git diff --stat`. Every file listed must belong to the task (`git checkout HEAD -- <file>` restores one that doesn't).
4. **Short comments.** One-line `///` docs and short inline notes that say *why*. Long reasoning goes in chat, not code.
5. **Disable, don't delete.** When asked to turn a feature off, comment it out with a one-line note saying when
   to re-enable it (e.g. the no-internet dialog in `network_service.dart` / `app_alerts.dart`), unless told to delete it.
6. **"Just check and tell me" means read-only.** Answer, don't edit.
7. **Design questions: show before building.** For visual work (logos, icons, layouts), present options or
   previews first, and implement only the one the user picks.
8. **No clutter.** Don't add new packages, generator dependencies, or extra asset files without asking.
   Keep one-off scripts and generated drafts in the session scratchpad, not the repo.
9. **Keep tests green.** Add or update tests for every behaviour change, and update widget tests when UI text
   changes. Run tests before you say something is done.
10. **Keep this file current.** If you change architecture, conventions, or a domain rule, update CLAUDE.md in the same task.

## Commands

```bash
flutter pub get
flutter analyze                 # add no new issues (existing infos are in untouched starter utils)
flutter test                    # all unit + widget tests
flutter test test/booking_rules_test.dart   # a single file
flutter test --flavor demo_space test/arena_app_test.dart --plain-name "all tabs"   # run as another client (demo-wording tests will fail)
dart format -l 160 <files you changed>
flutter run --flavor demo       # plain `flutter run` = demo (pubspec default-flavor)
flutter build apk --debug --flavor demo     # verifies native plugins compile
scripts\build.bat demo apk      # release build to dist/ (build.sh on macOS; adds ipa)
dart run tool/clients.dart add <id>   # new client (also: assets <id>, ios-icon <id>)
```

Windows dev machine, so iOS is never built locally. If the build fails with a `FormatException` in `dart_build`,
`.dart_tool/hooks_runner` is corrupt: delete it and rebuild.

## Architecture

```
lib/
├── main.dart                     # awaits InitBindings, then GetMaterialApp (ArenaTheme light/dark)
├── routes/                       # app_pages.dart (PageNames) + app_routes.dart (GetPage list)
├── app/config/                   # AppClientConfig, AppStrings, AppCache keys, arena_theme.dart, AppAssets
├── app/config/business/          # BusinessProfile (Terms + BookingPolicy + PricingMode + Features); profiles.dart: sportsVenue, spaceRental, eventVenue, vehicleRental
├── app/config/clients/           # ClientConfig + one file per client (flavor); each picks a profile
├── app/service/getx_service/     # BookingService, AppAccessService, + starter services
├── app/service/service_handler.dart/  # prefs-backed stores: SettingsStore, ThemeStore, CacheField
├── app/utils/                    # ArenaToast, ArenaFormat, ArenaLogo, Logger, starter widgets
├── data/models/                  # Booking, ResourceType/Resource, TimeRange, BookingPolicy, PricingMode, AppAccess (pure Dart + JSON)
├── data/rules/                   # BookingRules, BookingStats, InvoiceText: pure, unit-tested logic
├── data/repositories/booking/    # BookingRepository interface + Hive and in-memory implementations
└── presentation/
    ├── general/                  # splash, init_bindings (+ unused starter login/dashboard)
    └── arena/                    # the app: shell, home, booking_form, bookings, pending, calendar,
                                  # invoice, dialogs, widgets (shared UI + motion)
```

**Data flow:** View → Controller → `BookingService` → `BookingRepository` (Hive).
- `BookingService` is the **single source of truth**. Its `bookings` RxList is read inside `Obx` by every tab, so one
  write refreshes Home, Bookings, Pending, and Calendar together. It saves to the repository first and only then
  updates the list. All validation happens in the service (via `BookingRules`) and throws `BookingException`
  with a user-safe message.
- Screens never touch Hive directly. The repository interface exists so a cloud backend can replace Hive later.
- **Time is injectable:** `BookingService(clock:)`, `AppAccessService(clock:, fetch:)`. Read "now" via
  `BookingService.to.now()` (it subscribes the Obx to the per-minute tick). Never call `DateTime.now()` in rules,
  controllers, or views.
- **Shell:** `/arena` is a single route with an `IndexedStack` of tabs (`ArenaTab`); tabs keep their state.
  `ShellBinding` creates all tab controllers. Navigation between tabs uses `ShellController.to.go(...)`.
  Booking actions (new, edit, repeat, invoice, mark paid, cancel) go through `BookingActions` in `shell/booking_actions.dart`.
- **Startup order matters** (`InitBindings`): StorageService → stores → AppAccessService → SettingsStore → Hive → BookingService.
  Any `CacheField` needs StorageService ready first.

**Clients (flavors):** one codebase ships a separate app per arena client. **The flavor name is the client id.**
- `AppClientConfig.client` = `ClientConfig.forFlavor(appFlavor)`. Flutter compiles the flavor in, so there are no copy or symlink
  steps. No flavor (unit tests) means `demo`; an unknown flavor throws.
- Per-client values (business `name` (required), `tagline`, `address`, `phone`, `logoAsset`, business profile, resource types and resources,
  currency, WhatsApp country code, optional `features`) live in `lib/app/config/clients/<id>.dart`. `tool/clients.dart add` names the copy
  from its id and drops demo's tagline, logo and contacts, so no client ships another's business details.
  Read them through `AppClientConfig` (`.client`, `.profile`, `.terms`, `.policy`, `.pricing`, `.features`, `.resourceTypes`), never by importing a client file.
- `profile` is required: the developer picks the client's kind of business when setting the client up. A new kind of business
  gets a new profile in `business/profiles.dart` (add it to `allProfiles`; the tests check every one). A client can override the
  profile's time rules with `ClientConfig.policy` (e.g. its own opening hours), its pricing with `ClientConfig.pricing`, and
  its `Features` (discount, QR entry pass; both on by default) with `ClientConfig.features`, which replaces them as a whole.
  Profiles hold data only, so a setup screen or database can store them later.
- Every client must be listed in each of these places: `ClientConfig.all`, `val clients` in `android/app/build.gradle.kts`,
  `clients` in `ios/Podfile`, the iOS `Debug-/Release-/Profile-<id>` configurations plus a `<id>.xcscheme`, and `.vscode/launch.json`.
  **Use `dart run tool/clients.dart add <id>`**, never hand edits; `test/clients_config_test.dart` fails when the lists drift.
- Client images live in `assets/clients/<id>/`, each declared in pubspec with `flavors: [<id>]` (`tool/clients.dart assets <id>`),
  so a build bundles only its own client's files. Reference them as `AppClientConfig.client.asset('file.png')`, never with a literal id.
  Never add an unflavored `assets/clients/` entry: it would ship every client's files to everyone.
- Launcher icon per client (optional): Android flavor source set `android/app/src/<id>/res/`; iOS `AppIcon-<id>.appiconset` and
  `tool/clients.dart ios-icon <id>`. Without one, the client uses the ArenaBook icon.
- App ids are `com.devcatstudios.arenabook.<id>` (Android `applicationIdSuffix`; iOS per-configuration bundle id). The launcher name is "ArenaBook" for all.
- Something only some clients get is a `ClientConfig` field (default = today's behaviour), never an `if (client.id == ...)`.
- No symlinks or copy scripts for client files (the old `mobile-ecommerce` approach): they break on Windows and can mix up clients.

## Conventions

**GetX**
- A controller extends `GetxController`; an app-wide service extends `GetxService`. Singletons expose `static X get to => Get.find();`.
- A new screen needs three things: a `PageNames` entry, a `GetPage` in `appRoutes()`, and a `Binding` class at the bottom of its controller file.
  New *tabs* or sheets inside the shell don't get routes.
- Reactive state uses `.obs` / `Rxn<T>()`, read in `Obx`. Derived lists are getters on the controller (see `BookingsController.filtered`).
- Dispose `TextEditingController`s in `onClose`.

**UI and theme**
- Read colours only through `context.arena` (`ArenaColors` ThemeExtension) and text through `context.text`.
  Never hard-code colours in widgets. `*Text` tokens are for text/icons on surfaces; plain accents are for fills.
  Any UI must look right in **both light and dark** mode.
- Resource-type colours come from `ResourceTone` via the `ResourceTypeVisuals` extension (`type.fill(c)`, `type.text(c)`, `type.onAvatar(c)`).
- Reuse the shared widgets in `presentation/arena/widgets/arena_widgets.dart` (`ArenaCard`, `GradientButton`, `SoftButton`,
  `ArenaSegmented`, `ResourceTypeAvatar`, `ArenaBadge`, `SectionTitle`, `EmptyState`, `FieldLabel`), plus `BookingCard`/`BookingList` and `ResourceTypeFilter`.
- Dialogs: `ArenaDialog.show(...)`, and `ConfirmDialog.ask(...)` for confirmations. Toasts: `ArenaToast.success/error/show`
  (never `Get.snackbar`).
- Motion: `.entrance(context, index:)`, `.popIn(context)`, `AnimatedNumber`, `TabFade` from `widgets/motion.dart`.
  Animation stays subtle, and every animation must honour reduce-motion (`context.reduceMotion` / `context.motion(...)`).
- Logo: two marks. The **client's** business (header, drawer, Home banner, invoice) uses `ClientLogo` (its `logoAsset`, else a
  monogram) with `client.name`. The **ArenaBook** brand (splash, About, loaders) uses `ArenaLogo` (tints and sizes
  `assets/images/logo.png`; design locked, "Square Arena"). Receipt contact lines come from `client.contactLine()`.
- Fonts: Outfit (display) and Plus Jakarta Sans (body), bundled with OFL licences registered in `main.dart`.
- Portrait only. Edge-to-edge system bars are set in `MyApp.builder`.
- Keyboard: `KeyboardDismisser` (in `MyApp.builder`) closes it on any tap or drag outside the focused field, app-wide.
  Don't add per-screen `GestureDetector`/`unfocus()` wrappers for this. Scroll views with fields also set `keyboardDismissBehavior: onDrag`.
- Numeric text fields that show a placeholder `0` must clear or select it on focus, so typing replaces the value.
- **Industry words come from `AppClientConfig.terms`**, never literals: court(s), ground, sport, player, fee name, arena
  (e.g. `'All ${AppClientConfig.terms.resources}'`). The brand ("ArenaBook", "ARENABOOK") stays literal.
  `business_profile_test.dart` fails if a sports word shows up under a studio profile.

**Formatting and data**
- Money is an `int` in whole currency units. Format it with `ArenaFormat.money(...)`, which uses the currency from `SettingsStore`.
  Dates use the `ArenaFormat.*` helpers.
- Time slots are `TimeRange` in **minutes from the booking day's midnight**. Never use time strings for logic.
- Prefs keys live in `AppCache` (add a group per feature). Persist a value with `CacheField<T>(key, default)`.
- User-facing constants and contact info go in `AppStrings`. Per-client switches go in `AppClientConfig`.
- Logging: `Logger.logs(...)`, never `print`.
- ArenaBook code under `lib/` uses relative imports (some starter files use `package:arenabook/...`; leave them). Tests import `package:arenabook/...`.

## Domain rules (invariants: don't break them)

- **Resource types and resources are config-driven:** `AppClientConfig.resourceTypes` (from the client's config) drives forms, filters,
  Settings rates, the calendar, stats, and the tagline. Use `ResourceType.offered` (enabled) for pickers and filters, and `ResourceType.all` for lookups.
  `ResourceType.byId(id)` / `Resource.byId(id)` fall back to placeholders, so old bookings still render.
  **Never change a resource type or resource `id` once used**: bookings and prefs keys (`arena_<id>_hourly_rate`) store it.
  Stored booking JSON keeps the legacy keys `sport` and `courtId`; don't rename them.
  A resource's `name` is what every screen and receipt shows; its optional `description` is extra detail shown under the
  name in the booking form's picker only (`Resource.detail` hides it when empty or the same as the name).
  Never hard-code "cricket" or "padel" outside the config and the tests.
- **Never branch on the business type or client id.** A difference between businesses is a value (config), a behaviour
  (a sealed strategy class) or a flag (`Features`); see `docs/EXPANSION_PLAN.md`.
- **No instalments:** a booking is paid as an advance plus the balance in one go. Past time is never edited: for an overrun
  the owner edits the amount received and explains the extra charge in the notes.
- **No double booking** on the same court. Overlap is half-open: 9–10 and 10–11 don't clash. A different court at
  the same time is allowed.
- **Booking time:** one continuous range, start + duration, following the client's `BookingPolicy` (`AppClientConfig.policy` =
  the client's override, else its profile's): `step` (15/30/60), `minDuration`/`maxDuration` (24 h max), `defaultDuration`,
  `openHours` (null = 24 h; may pass midnight), or fixed `sessions` (whole sessions only). The sports venue default is
  today's rule: 30-minute steps, any of the 24 hours. Bookings may cross midnight: a booking is stored on its **start date**,
  and `endMinute` can reach 2880. `BookingRules.occupied` projects the previous and next day onto the timeline, so conflicts
  are caught from either date. Past slots can't be booked, except that an edit may keep slots it already had (even if the
  policy changed since). Every `BookingRules` time function takes an optional `policy:` (tests pass one; the app uses the client's).
- **Pricing mode** (`PricingMode`, `AppClientConfig.pricing` = the client's override, else its profile's):
  `hourly` = minutes × the rate frozen at booking time (Settings rates); `manual` = the owner types the price of each
  booking (required; Settings hides the rates). Each booking stores its own `pricing` (schema v3; older records load as hourly),
  so changing a client's mode never re-prices old bookings, and an edit keeps the booking's mode. Manual bookings save `hourlyRate` 0.
- **Money:** `totalFee` = the hourly fee or the typed price. Discount is 0..totalFee and only exists while
  `AppClientConfig.features.discount` is on (form and invoices). Advance is clamped to the payable amount.
  `balanceDue` = payable − advance. Editing a booking re-evaluates a previous Mark Paid.
- Booking ids are `TRF-1001`, `TRF-1002`, …, from `BookingRepository.nextId()`.
- Cancelling requires a reason and records whether the advance was returned. Cancelled bookings can't be edited.
- Mark Paid asks for confirmation. After a submit, closing the invoice returns to Home.
- The receipt's QR entry pass shows only while `AppClientConfig.features.entryPass` is on.
- **Invoice sharing:** *Share via WhatsApp* captures the existing invoice widget as an image (contact buttons
  excluded) and shares it. *Copy Text* copies `InvoiceText.plain`. The two actions stay independent.
- **Remote trial switch** (`AppAccessService` + `AppAccess`, config in a GitHub Gist at `AppClientConfig.accessConfigUrl`):
  - One Gist file for every client: `{ "clients": { "<id>": { ... } } }`. Each build reads only its own entry.
  - **Fail closed on a bad Gist:** invalid JSON, no `clients` map, or no valid entry for this client blocks the app as
    "App Not Activated" (`AppAccess.unconfigured`, `notActivated`) until the Gist is fixed. Every client must therefore be listed.
  - Only a `200` response that carries GitHub's `x-github-request-id` header counts (`AppAccessService.gistResult`), so a
    Wi-Fi login page or proxy can't block the app. Other statuses and network errors keep the cached body.
  - Only `DataEntryStatus == 1` is honoured (0 means ignore the config and run).
  - If `IsAppEnable` is false, the app is blocked immediately, or after `AppDisableAfterDate` when one is set.
  - While a dated trial runs, the drawer shows "days remaining".
  - The last Gist body from GitHub is cached, so a block holds offline. The service fails open only before the first fetch,
    and time never goes backwards (GitHub's `Date` header plus the latest time seen).
  - The dialog only appears after the splash (`startGuarding()`).
- **Offline-first:** the no-internet dialog and the redirect to login are intentionally commented out. Don't re-enable
  them until an online database exists.

## Starter leftovers (keep them, don't use them)

The API layer (`data/providers`, `api_utility`), login and dashboard screens, response cache, and dev-mode services come from
the starter and are kept for a future online version. Don't delete or refactor them as drive-by cleanup, and don't route the
app through them.

## Tests (`test/`)

- `booking_rules_test.dart` / `booking_service_test.dart`: pure logic. Use `InMemoryBookingRepository` and a fixed `clock`.
- `arena_app_test.dart`: widget tests for the arena screens. `business_profile_test.dart` (wording, every profile),
  `booking_policy_test.dart` (time rules, opening hours, sessions, full day), `pricing_test.dart` (hourly vs typed price, v2 records),
  `resource_types_config_test.dart`, `app_access_test.dart`,
  `splash_and_logo_test.dart`, `keyboard_dismisser_test.dart`, `cache_field_test.dart`, `response_cache_test.dart`.
- Helpers: `test/helpers/resource_types.dart` (`cricket`, `padel` from config) and `temp_dir.dart` (Hive temp dirs with
  retries for Windows file locks).
- `AppClientConfig.features`, `.resourceTypes`, `.profile`, `.policy` and `.pricing` are deliberately not `final`, so tests can toggle them. Restore them in `tearDown`.
- `clients_config_test.dart` checks that every client is wired into the native files, launch.json and pubspec, and that client
  assets and icons are flavored correctly. `clients_tool_test.dart` runs `tool/clients.dart` on a temp copy of those files.
- Put new pure logic in `data/rules` or a model, so it can be unit tested without widgets.

## Known open items (don't fix unasked; mention when relevant)

- Release builds are signed with the debug key (no upload keystore yet).
- iOS flavors were set up without a Mac: the first `flutter build ios --flavor demo` on a Mac is their real test.
- The native launch screen is still Flutter's default white (`launch_background.xml`), which flashes before the dark splash.
- `AppHttpOverrides` (set in `InitBindings`) accepts every SSL certificate. Remove or restrict it before release.
- There's no backup or export: data is lost if the phone is lost. The user postponed this, so don't push it.
- There's no in-app court management (courts come from config only).
- Keep `version:` in `pubspec.yaml` in sync with `kappVersionWithDate` / `kappBuildNumber` in `app_strings.dart`.
