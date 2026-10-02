/// Central settings for the offline API response cache (see ResponseCacheService & APIProvider).
/// Change them here only; everything else reads from this class.
class AppResponseCacheConfig {
  /// Master switch.
  /// false -> nothing is cached or read from cache, every request behaves as CachePolicy.networkOnly
  ///          (whatever policy the repository asks for), and any previously cached data is wiped on app start.
  /// true  -> requests marked CachePolicy.networkFirst are cached and used as offline fallback.
  static const bool enableResponseCache = false;

  /// Max disk space for cached responses. Least recently used entries are evicted beyond this.
  /// 20 MB ≈ hundreds to thousands of typical JSON responses (1–100 KB each).
  static const int maxCacheSizeBytes = 20 * 1024 * 1024;

  /// Cached data older than this is never shown and is wiped automatically.
  static const Duration maxAge = Duration(days: 7);
}
