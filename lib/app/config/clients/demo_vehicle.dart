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
        Resource(id: 'hatchback-1', name: 'Alto Grey 2022', description: 'Hatchback 1'),
        Resource(id: 'hatchback-2', name: 'Mira White 2019', description: 'Hatchback 2'),
        Resource(id: 'hatchback-3', name: 'Cultus Black 2024', description: 'Hatchback 3'),
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
        Resource(id: 'sedan-1', name: 'Camry White 2022', description: 'Sedan 1'),
        Resource(id: 'sedan-2', name: 'Corolla Black 2019', description: 'Sedan 2'),
        Resource(id: 'sedan-3', name: 'Prius Green 2024', description: 'Sedan 3'),
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
        Resource(id: 'premium-1', name: 'Jaecoo J5 White 2021', description: 'Premium 1'),
        Resource(id: 'premium-2', name: 'Oshan x7 Black 2023', description: 'Premium 2'),
        Resource(id: 'premium-3', name: 'Hilux Silver 2026', description: 'Premium 3'),
      ],
    ),
  ],
);
