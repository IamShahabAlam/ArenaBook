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
        Resource(id: 'cricket-1', name: 'Turf Pitch 1 (Main)', description: 'Full-length lane · floodlit · team matches'),
        Resource(id: 'cricket-2', name: 'Turf Pitch 2 (Express)', description: 'Short lane · bowling machine · net practice'),
        Resource(id: 'cricket-3', name: 'Turf Pitch 3 (VIP Indoor)', description: 'Private · air-conditioned · lounge seating'),
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
        Resource(id: 'padel-a', name: 'Court A Glass Panoramic', description: 'All-glass walls · spectator view'),
        Resource(id: 'padel-b', name: 'Court B Indoor Sky', description: 'Roofed · open in rain and heat'),
        Resource(id: 'padel-c', name: 'Court C Center Court', description: 'Main court · seating for matches'),
      ],
    ),
  ],
);
