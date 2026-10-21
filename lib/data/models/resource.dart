import 'package:flutter/widgets.dart' show IconData;

import '../../app/config/app_client_config.dart';

/// Accent colour family of a resource type (mapped to theme colours in the UI).
enum ResourceTone { emerald, blue, violet, orange }

/// A kind of bookable resource (a sport, studio type, hall type...), defined in [AppClientConfig.resourceTypes]. Bookings store [id], so never change it once used.
class ResourceType {
  const ResourceType({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.tone,
    required this.defaultRate,
    required this.emoji,
    required this.resources,
    this.enabled = true,
  });

  /// Placeholder for a booking whose resource type was removed from the config, so it still renders.
  const ResourceType._unknown(this.id)
    : label = id,
      shortLabel = id,
      icon = null,
      tone = ResourceTone.emerald,
      defaultRate = 0,
      emoji = '🏟️',
      resources = const [],
      enabled = false;

  final String id;
  final String label; // "Indoor Cricket"
  final String shortLabel; // "Cricket" (filters)
  final IconData? icon; // null only for an unknown type
  final ResourceTone tone;
  final int defaultRate; // per hour, until changed in Settings
  final String emoji; // shared receipts
  final List<Resource> resources;
  final bool enabled; // false = hidden from forms, filters and Settings; its old bookings still show

  /// Every configured resource type, on or off.
  static List<ResourceType> get all => AppClientConfig.resourceTypes;

  /// Resource types offered now, i.e. enabled ones (forms, filters, Settings rates).
  static List<ResourceType> get offered => all.where((t) => t.enabled).toList();

  static ResourceType byId(String id) => all.firstWhere((t) => t.id == id, orElse: () => ResourceType._unknown(id));

  @override
  bool operator ==(Object other) => other is ResourceType && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ResourceType($id)';
}

/// One bookable unit (a court, studio, hall or car). [id] is what bookings store, so it must never change once used.
class Resource {
  const Resource({required this.id, required this.name, required this.description});

  final String id;
  final String name; // short, shown on cards & invoices
  final String description; // longer, shown in the picker

  static List<Resource> forType(ResourceType resourceType) => resourceType.resources;

  /// Unknown ids (e.g. a resource that was removed) still resolve, so old bookings keep rendering.
  static Resource byId(String id) {
    for (final t in ResourceType.all) {
      for (final r in t.resources) {
        if (r.id == id) return r;
      }
    }
    return Resource(id: id, name: id, description: id);
  }
}
