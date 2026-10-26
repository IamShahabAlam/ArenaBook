import 'package:flutter/material.dart';

import '../../../data/models/resource.dart';
import '../business/business_profile.dart';
import '../business/profiles.dart';
import 'client_config.dart';

/// demo_space: space rental client with rooms and gaming consoles.
const demoSpace = ClientConfig(
  id: 'demo_space',
  name: 'The Loft Workspaces & Studio',
  tagline: 'Creative Rooms, Studios & Gaming Lounge',
  address: 'Main Boulevard, Gulberg III, Lahore',
  phone: '+92 300 1234567',
  profile: spaceRental,
  features: Features(discount: true, entryPass: false),
  resourceTypes: [
    ResourceType(
      id: 'room',
      label: 'Hall Rooms',
      shortLabel: 'Rooms',
      icon: Icons.meeting_room_outlined,
      tone: ResourceTone.emerald,
      defaultRate: 4000,
      emoji: '🛏️',
      resources: [
        Resource(id: 'room-1', name: 'G Floor Room 1', description: 'Ground Room 1'),
        Resource(id: 'room-2', name: 'G Floor Room 2', description: 'Ground Room 2'),
        Resource(id: 'room-3', name: '1st Floor Room 1', description: '1st Floor Room 1'),
        Resource(id: 'room-4', name: '1st Floor Room 2', description: '1st Floor Room 2'),
        Resource(id: 'room-5', name: '2nd Floor Room 1', description: '2nd Floor Room 1'),
      ],
    ),
    ResourceType(
      id: 'playstation',
      label: 'Playstation',
      shortLabel: 'Playstation',
      icon: Icons.videogame_asset_rounded,
      tone: ResourceTone.blue,
      defaultRate: 2000,
      emoji: '🎮',
      resources: [Resource(id: 'playstation-1', name: 'Playstation', description: 'Playstation Gaming Console')],
    ),
  ],
);
