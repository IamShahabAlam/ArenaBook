import 'package:flutter/material.dart';

import '../../../data/models/resource.dart';
import '../business/profiles.dart';
import 'client_config.dart';

/// demo_event: event venue with banquet halls.
const demoEvent = ClientConfig(
  id: 'demo_event',
  name: 'Grand Imperial Banquet',
  tagline: 'Luxury Halls & Event Spaces',
  address: 'Club Road, Civil Lines, Karachi',
  phone: '+92 321 9876543',
  profile: eventVenue,

  resourceTypes: [
    ResourceType(
      id: 'banquet',
      label: 'Banquet Hall',
      shortLabel: 'Banquet',
      icon: Icons.event_rounded,
      tone: ResourceTone.emerald,
      defaultRate: 150000,
      emoji: '💒',
      resources: [
        Resource(id: 'banquet-a', name: 'Main Banquet Hall', description: 'Main Banquet Hall'),
        Resource(id: 'banquet-b', name: 'Small Banquet Hall', description: 'Small Banquet Hall'),
        Resource(id: 'banquet-c', name: 'Banquet Hall', description: 'Banquet Hall'),
      ],
    ),
  ],
);
