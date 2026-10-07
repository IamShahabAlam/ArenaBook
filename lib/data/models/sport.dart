import 'package:flutter/widgets.dart' show IconData;

import '../../app/config/app_client_config.dart';

/// Accent colour family of a sport (mapped to theme colours in the UI).
enum SportTone { emerald, blue, violet, orange }

/// A sport the arena offers, defined in [AppClientConfig.sports]. Bookings store [id], so never change it once used.
class Sport {
  const Sport({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.tone,
    required this.defaultRate,
    required this.emoji,
    required this.courts,
    this.enabled = true,
  });

  /// Placeholder for a booking whose sport was removed from the config, so it still renders.
  const Sport._unknown(this.id)
    : label = id,
      shortLabel = id,
      icon = null,
      tone = SportTone.emerald,
      defaultRate = 0,
      emoji = '🏟️',
      courts = const [],
      enabled = false;

  final String id;
  final String label; // "Indoor Cricket"
  final String shortLabel; // "Cricket" (filters)
  final IconData? icon; // null only for an unknown sport
  final SportTone tone;
  final int defaultRate; // per hour, until changed in Settings
  final String emoji; // shared receipts
  final List<Court> courts;
  final bool enabled; // false = hidden from forms, filters and Settings; its old bookings still show

  /// Every configured sport, on or off.
  static List<Sport> get all => AppClientConfig.sports;

  /// Sports offered now, i.e. enabled ones (forms, filters, Settings rates).
  static List<Sport> get offered => all.where((s) => s.enabled).toList();

  static Sport fromName(String id) => all.firstWhere((s) => s.id == id, orElse: () => Sport._unknown(id));

  @override
  bool operator ==(Object other) => other is Sport && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Sport($id)';
}

/// A bookable pitch / court. [id] is what bookings store, so it must never change once used.
class Court {
  const Court({required this.id, required this.name, required this.description});

  final String id;
  final String name; // short, shown on cards & invoices
  final String description; // longer, shown in the picker

  static List<Court> forSport(Sport sport) => sport.courts;

  /// Unknown ids (e.g. a court that was removed) still resolve, so old bookings keep rendering.
  static Court byId(String id) {
    for (final s in Sport.all) {
      for (final c in s.courts) {
        if (c.id == id) return c;
      }
    }
    return Court(id: id, name: id, description: id);
  }
}
