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
        Resource(id: 'room-1', name: 'G Floor Room 1', description: 'Up to 20 seats · projector · step-free'),
        Resource(id: 'room-2', name: 'G Floor Room 2', description: 'Up to 8 seats · TV · whiteboard'),
        Resource(id: 'room-3', name: '1st Floor Room 1', description: 'Photo studio · backdrops · lights'),
        Resource(id: 'room-4', name: '1st Floor Room 2', description: 'Podcast booth · 2 mics · soundproof'),
        Resource(id: 'room-5', name: '2nd Floor Room 1', description: 'Up to 12 seats · daylight · balcony'),
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
      resources: [Resource(id: 'playstation-1', name: 'Playstation', description: 'PS5 · 4 controllers · 55" TV')],
    ),
  ],
);
