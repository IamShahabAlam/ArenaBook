# ArenaBook

Built on the in-house Flutter + GetX starter (`starter_proj_getx`).

## Architecture

```
lib/
├── main.dart                     # awaits InitBindings, then GetMaterialApp (theme, routes, error widget)
├── app/
│   ├── config/                   # app-wide constants
│   │   ├── app_strings.dart      # app name/version (EMPTY: fill per project), API error messages
│   │   ├── app_client_config.dart# base URLs (EMPTY: fill per project)
│   │   ├── app_cache.dart        # SharedPreferences keys, grouped per feature
│   │   ├── app_assets.dart       # asset names (resolve with Utils.getImagePath/getLottiePath/getSvgFilePath)
│   │   ├── app_colors.dart, app_color_schemes.dart, app_textstyle.dart, app_fontweights.dart,
│   │   ├── app_paddings.dart, app_border_radius.dart, app_box_shadow.dart
│   │   ├── app_screens.dart      # menu-name → icon map
│   │   └── app_size_config.dart  # responsive helpers (w, h, .ph/.pw, .sw/.sh/.sp) + widget/animation extensions
│   ├── service/
│   │   ├── getx_service/         # long-lived services
│   │   │   ├── storage_service.dart        # SharedPreferences wrapper (StorageService.to)
│   │   │   ├── network_service.dart        # connectivity listener (GetXNetworkManager.to)
│   │   │   ├── theme_manager.dart          # builds light/dark ThemeData from a seed color
│   │   │   ├── app_dev_mode_service.dart   # hidden Developer Mode: in-app API log, copy as cURL
│   │   │   └── developer_mode_service.dart # detects Android developer options (for blocking)
│   │   ├── service_handler.dart/ # "stores": reactive state backed by prefs
│   │   │   ├── user_store.dart   # profile, loginId, token, isLoggedIn
│   │   │   ├── urls_store.dart   # runtime api url (falls back to AppClientConfig.baseUrl)
│   │   │   └── theme_store.dart  # dark mode + theme color
│   │   └── migration/            # prefs key migration helper
│   └── utils/
│       ├── api_utility/          # headers, status-code → message, cURL generators, controllersCatch
│       ├── custom_functions/     # Dialogs (app_alerts), Functions, DateTimeFunctions + Pickers, PickFiles, Logger
│       ├── custom_widgets/       # reusable widgets (CommonText, CustomTextField, GradeBtn, CustomAppBar, …)
│       ├── date_utlity/
│       └── utils.dart            # asset path helpers
├── data/
│   ├── models/
│   ├── providers/
│   │   ├── api_provider.dart     # THE http layer: retry, failure classification, dev logging
│   │   ├── connection_provider.dart # internet / server reachability probes
│   │   └── api_endpoints.dart    # endpoint paths grouped per module (EMPTY: fill per project)
│   └── repositories/             # one repo per module, calls APIProvider, returns http.Response
│       ├── auth_repository/auth_repo.dart  # login / logout / updatePassword + clearSession()
│       └── connection/
├── presentation/
│   └── general/
│       ├── init_bindings/        # app-wide DI (order matters!)
│       ├── splash/               # routes to dashboard or login based on UserStore.isLoggedIn
│       ├── auth_views/login/
│       └── dashboard/            # placeholder home (theme toggle + logout)
└── routes/
    ├── app_pages.dart            # PageNames (route name constants)
    └── app_routes.dart           # GetPage list
```

**Data flow:** `View → Controller → Repository → APIProvider → http`.
Views never call repositories, and repositories never touch UI (apart from APIProvider's toasts).

## Starting a new project from this starter

1. Copy or clone the folder, then rename the package:
   - `pubspec.yaml` → `name:`
   - Find and replace `package:starter_proj_getx/` with `package:<new_name>/` across `lib/` and `test/`
   - Android `applicationId` / namespace, iOS bundle id
2. Fill in `lib/app/config/app_strings.dart`: `appName`, `kappVersionWithDate`, `kappBuildNumber`, store links.
3. Fill in `lib/app/config/app_client_config.dart`: `baseUrl` (and `stageBaseUrl` if you have one).
4. Fill in `lib/data/providers/api_endpoints.dart`: at least `loginUrl` / `logoutUrl`.
5. Map your login response in `LoginController.login()` (token / userId / profile keys).
6. Adjust `ApiUtility.requestHeaders()` to your backend's auth header names.
7. Replace `assets/images/logo.png` with the project logo (1024x1024, white on transparent; drawn via `ArenaLogo`, which tints it).
8. Optional: change the default palette in `app_color_schemes.dart`, or set a seed color through `ThemeManager.saveThemeData(...)`.

## Adding a feature (the pattern)

```
lib/presentation/<module>/<feature>/
    <feature>_controller.dart   // GetxController + <Feature>Binding at the bottom
    <feature>_view.dart         // GetView<FeatureController>
    components/                 // widgets used only by this feature
lib/data/repositories/<module>/<feature>_repo.dart
```

1. Add the endpoint to `ApiEndPoint` (new private class per module).
2. Create the repo method: `APIProvider.instance.request(endpoint: ..., method: ..., bodyMap: ...)`.
3. In the controller: call the repo, check `response.statusCode == 200`, wrap it in `try/catch` and use
   `ApiUtility.controllersCatch(e, methodName: '...')` in the catch block.
4. Add a `PageNames` constant plus a `GetPage` in `app_routes.dart`.
5. If it caches anything: add a key to `AppCache`, then add a `CacheField` to a store (see below).
   For a new store: register it in `InitBindings` and clear it in `AuthRepo.clearSession()`.

## Caching with `CacheField`

Each cached value is one line in a store. It keeps the SharedPreferences key and a reactive variable in sync:

```dart
final token = CacheField<String>(AppCache.user.token, '');   // key, default

token.value          // read (inside Obx() the widget rebuilds when it changes)
token.save('abc')    // update the variable + the cache
token.delete()       // remove from cache, back to the default
```

String, bool, int and `List<String>` are stored natively; a `Map` (or anything else) is stored as JSON.
Rules: the default is never `null`, and a Map is replaced with `save({...old, 'k': v})`, never mutated in place.
`test/cache_field_test.dart` has runnable examples.

## APIProvider cheat sheet

| `authHeaders` | Effect |
|---|---|
| `null` (default) | `ApiUtility.requestHeaders()` (authenticated) |
| `{}` | no headers |
| `{...}` | exactly these headers |

The provider returns these artificial status codes, so controllers only ever check `statusCode`:
`510` no network interface · `503` online but no internet · `523` server unreachable · `524` timeout · `511` unknown failure.

Only GET/PUT/DELETE are retried (twice, with backoff). POST is never retried, so a flaky connection can't create duplicate records.

## Offline response cache (network-first)

Successful GET responses can be saved (encrypted, in Hive) and shown when the network fails,
so screens show the last data instead of an empty state.

**Settings (one place):** `lib/app/config/app_response_cache_config.dart`

| Setting | Default | Meaning |
|---|---|---|
| `enableResponseCache` | `false` | Master switch. `false` → nothing is cached, every request is network-only, old cache is wiped on start |
| `maxCacheSizeBytes` | 20 MB | Least recently used entries are evicted beyond this |
| `maxAge` | 7 days | Older entries are never shown and are wiped automatically |

**Per request (in the repository):**

```dart
APIProvider.instance.request(
  endpoint: ApiEndPoint.sales.orders,
  urlParams: filters,
  cachePolicy: CachePolicy.networkFirst,   // default is CachePolicy.networkOnly
);
```

- **One cache entry per endpoint** (per user). Every successful hit replaces the old entry (data + params).
- The cached copy is returned **only if the request params match the saved ones exactly**;
  any other params get the normal error (no cached data).
- Values are AES-encrypted with a random per-install key kept in SharedPreferences
  (keeps the files unreadable to casual inspection; not bank-grade security).
- Only GET is cached, only 200 responses, and entries are per user (users never see each other's data).
- On network failure the cached copy is returned as a normal **200**, so controllers don't change,
  and the user sees "<error> · Showing saved data (date)". Use `ResponseCacheService.isFromCache(response)`
  and `savedAtOf(response)` if a screen wants its own "offline" banner.
- Refresh when the internet comes back: `class XController extends GetxController with OfflineAware`
  and implement `onReconnect()`.
- Logout wipes the whole cache. See what's cached with `ResponseCacheService.to.logEntries()`
  or `ResponseCacheService.to.entries`.

## Developer Mode

On the login logo (wrapped in `DevGestureDetector`), **double-tap → swipe up → swipe right**.
Failed requests (>300) then open a log dialog with method, URL, headers, payload and response,
plus Copy / Save / **Copy cURL**. A long press over 3s enables *core* mode, which logs every request.

## Intentionally NOT included (add per project)

- **Firebase / push notifications.** These need per-project `google-services.json` / `GoogleService-Info.plist`
  (`flutterfire configure`). Add `firebase_core`, `firebase_messaging` and `flutter_local_notifications`, then initialize them in `main()` after `InitBindings`.
- Printing / Bluetooth, camera, maps, webviews, charts: add them when a project needs them.

## Before shipping to production

- `AppHttpOverrides` (in `api_provider.dart`, set in `InitBindings`) **accepts every SSL certificate**.
  Remove it, or restrict it to your own host, for production builds.
- Some copied widgets still use the deprecated `WillPopScope`. Migrate them to `PopScope` so Android predictive back works.
