import 'package:flutter/material.dart';

import '../../data/models/sport.dart';

class AppClientConfig {
  // Base URLs ------------------- (fill these per project)
  static String baseUrl = '';
  static String stageBaseUrl = '';
  static String localBaseUrl = '';

  // Features -------------------
  /// Discount field in the booking form and discount lines on invoices. (Not const: tests toggle it.)
  static bool enableDiscount = true;

  // Sports -------------------
  /// The arena's sports and their courts; the whole app follows this list.
  /// Turn one off with `enabled: false`; add one by adding an entry. Never change an `id` once used.
  /// (Not const: tests swap it.)
  static List<Sport> sports = const [
    Sport(
      id: 'cricket',
      label: 'Indoor Cricket',
      shortLabel: 'Cricket',
      icon: Icons.sports_cricket_rounded,
      tone: SportTone.emerald,
      defaultRate: 1500,
      emoji: '🏏',
      courts: [
        Court(id: 'cricket-1', name: 'Turf Pitch 1 (Main)', description: 'Turf Pitch 1 (Main Pitch)'),
        Court(id: 'cricket-2', name: 'Turf Pitch 2 (Express)', description: 'Turf Pitch 2 (Express Lane)'),
        Court(id: 'cricket-3', name: 'Turf Pitch 3 (VIP Indoor)', description: 'Turf Pitch 3 (VIP Indoor Enclosure)'),
      ],
    ),
    Sport(
      id: 'padel',
      label: 'Padel Court',
      shortLabel: 'Padel',
      icon: Icons.sports_tennis_rounded,
      tone: SportTone.blue,
      defaultRate: 2000,
      emoji: '🎾',
      courts: [
        Court(id: 'padel-a', name: 'Court A Glass Panoramic', description: 'Court A Glass Panoramic'),
        Court(id: 'padel-b', name: 'Court B Indoor Sky', description: 'Court B Indoor Sky'),
        Court(id: 'padel-c', name: 'Court C Center Court', description: 'Court C Center Court'),
      ],
    ),
  ];
}
