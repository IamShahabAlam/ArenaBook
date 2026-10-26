import 'package:flutter/material.dart';

import '../../../data/models/resource.dart';
import '../business/profiles.dart';
import 'client_config.dart';

/// Demo arena: indoor cricket and padel, Pakistan.
const demo = ClientConfig(
  id: 'demo',
  name: 'Apex Arena',
  tagline: 'Premier Indoor Arena Facility',
  address: 'Sector F-11/1, Islamabad',
  phone: '+92 341 2757081',
  profile: sportsVenue,
  resourceTypes: [
    ResourceType(
      id: 'cricket',
      label: 'Indoor Cricket',
      shortLabel: 'Cricket',
      icon: Icons.sports_cricket_rounded,
      tone: ResourceTone.emerald,
      defaultRate: 3500,
      emoji: '🏏',
      resources: [
        Resource(id: 'cricket-1', name: 'Turf Pitch 1 (Main)', description: 'Turf Pitch 1 (Main Pitch)'),
        Resource(id: 'cricket-2', name: 'Turf Pitch 2 (Express)', description: 'Turf Pitch 2 (Express Lane)'),
        Resource(id: 'cricket-3', name: 'Turf Pitch 3 (VIP Indoor)', description: 'Turf Pitch 3 (VIP Indoor Enclosure)'),
      ],
    ),
    ResourceType(
      id: 'padel',
      label: 'Padel Court',
      shortLabel: 'Padel',
      icon: Icons.sports_tennis_rounded,
      tone: ResourceTone.blue,
      defaultRate: 3000,
      emoji: '🎾',
      resources: [
        Resource(id: 'padel-a', name: 'Court A Glass Panoramic', description: 'Court A Glass Panoramic'),
        Resource(id: 'padel-b', name: 'Court B Indoor Sky', description: 'Court B Indoor Sky'),
        Resource(id: 'padel-c', name: 'Court C Center Court', description: 'Court C Center Court'),
      ],
    ),
  ],
);
