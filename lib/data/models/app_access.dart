import 'dart:convert';

/// Remote trial switch, read from the config Gist. Pure Dart so the rules are unit-tested.
///
/// ```json
/// { "DataEntryStatus": 1, "IsAppEnable": false, "AppDisableAfterDate": "2026-10-20" }
/// ```
class AppAccess {
  const AppAccess({required this.active, required this.enabled, this.blockFrom});

  /// `DataEntryStatus == 1`. Anything else means the config is switched off and ignored.
  final bool active;

  /// `IsAppEnable`.
  final bool enabled;

  /// When the block starts; null = immediately. A date-only value blocks once that day has passed.
  final DateTime? blockFrom;

  bool isBlocked(DateTime now) {
    if (!active || enabled) return false;
    final from = blockFrom;
    return from == null || !now.isBefore(from);
  }

  /// Days left of a dated trial that is still running, today included ("2026-10-20" on the 20th = 1); else null.
  int? trialDaysLeft(DateTime now) {
    final from = blockFrom;
    if (!active || enabled || from == null || !now.isBefore(from)) return null;
    return (from.difference(now).inMicroseconds / Duration.microsecondsPerDay).ceil();
  }

  /// Null when the body isn't a JSON object, so a broken Gist edit never changes the app's state.
  static AppAccess? tryParse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;
      return AppAccess(
        active: _int(json['DataEntryStatus']) == 1,
        enabled: _bool(json['IsAppEnable']) ?? true, // missing = enabled
        blockFrom: _blockFrom(json['AppDisableAfterDate']),
      );
    } catch (_) {
      return null;
    }
  }

  // Tolerant readers: the Gist is edited by hand, so "1" and "false" are accepted too.
  static int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v'.trim());

  static bool? _bool(Object? v) => switch (v) {
    bool() => v,
    num() => v != 0,
    String() => switch (v.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    },
    _ => null,
  };

  /// "2026-10-20" -> 21 Oct 00:00 local (the whole day still runs). A full timestamp is used as is.
  /// An unreadable date counts as "no date" (block now): IsAppEnable=false already states the intent.
  static DateTime? _blockFrom(Object? v) {
    final text = v?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    final dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
    return dateOnly ? DateTime(parsed.year, parsed.month, parsed.day + 1) : parsed;
  }
}
