import 'package:flutter/material.dart';

import '../../../data/models/resource.dart';
import '../business/profiles.dart';
import 'client_config.dart';

/// demo_vehicle: vehicle rental client with hatchbacks, sedans and premium SUVs.
const demoVehicle = ClientConfig(
  id: 'demo_vehicle',
  name: 'Prime Drive Car Rental',
  tagline: 'Self-Drive & Chauffeur Fleet',
  address: 'Airport Avenue, Islamabad',
  phone: '+92 333 5551234',
  logoAsset: 'logo.png',
  profile: vehicleRental,
  resourceTypes: [
    ResourceType(
      id: 'hatchback',
      label: 'Hatchback',
      shortLabel: 'Hatchback',
      icon: Icons.directions_car,
      tone: ResourceTone.emerald,
      defaultRate: 2500,
      emoji: '🚘',
      resources: [
        Resource(id: 'hatchback-1', name: 'Alto Grey 2022', description: 'Manual · 4 seats · fuel saver'),
        Resource(id: 'hatchback-2', name: 'Mira White 2019', description: 'Automatic · 4 seats · fuel saver'),
        Resource(id: 'hatchback-3', name: 'Cultus Black 2024', description: 'Manual · 5 seats · AC'),
      ],
    ),
    ResourceType(
      id: 'sedan',
      label: 'Sedan',
      shortLabel: 'Sedan',
      icon: Icons.local_taxi_outlined,
      tone: ResourceTone.blue,
      defaultRate: 3500,
      emoji: '🚗',
      resources: [
        Resource(id: 'sedan-1', name: 'Camry White 2022', description: 'Automatic · 5 seats · leather interior'),
        Resource(id: 'sedan-2', name: 'Corolla Black 2019', description: 'Automatic · 5 seats · AC'),
        Resource(id: 'sedan-3', name: 'Prius Green 2024', description: 'Automatic · 5 seats · hybrid'),
      ],
    ),
    ResourceType(
      id: 'premium',
      label: 'Premium',
      shortLabel: 'Premium',
      icon: Icons.fire_truck_outlined,
      tone: ResourceTone.orange,
      defaultRate: 5000,
      emoji: '🚙',
      resources: [
        Resource(id: 'premium-1', name: 'Jaecoo J5 White 2022', description: 'Automatic · 5 seats · panoramic roof'),
        Resource(id: 'premium-2', name: 'Oshan x7 Black 2023', description: 'Automatic · 7 seats · family SUV'),
        Resource(id: 'premium-3', name: 'Hilux Silver 2026', description: 'Automatic · 5 seats · 4x4 pickup'),
      ],
    ),
  ],
);
