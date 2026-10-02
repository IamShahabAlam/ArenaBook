/// The sports an arena can host. Stored by [name] ('cricket' / 'padel'), so never rename a value.
enum Sport {
  cricket(label: 'Indoor Cricket', shortLabel: 'Cricket'),
  padel(label: 'Padel Court', shortLabel: 'Padel');

  const Sport({required this.label, required this.shortLabel});

  final String label;
  final String shortLabel;

  static Sport fromName(String name) => Sport.values.firstWhere((s) => s.name == name, orElse: () => Sport.cricket);
}

/// A bookable pitch / court. [id] is what bookings store, so it must never change once used.
class Court {
  const Court({required this.id, required this.sport, required this.name, required this.description});

  final String id;
  final Sport sport;
  final String name; // short, shown on cards & invoices
  final String description; // longer, shown in the picker

  /// Courts of the arena. Edit here until court management gets its own screen.
  static const all = <Court>[
    Court(id: 'cricket-1', sport: Sport.cricket, name: 'Turf Pitch 1 (Main)', description: 'Turf Pitch 1 (Main Pitch)'),
    Court(id: 'cricket-2', sport: Sport.cricket, name: 'Turf Pitch 2 (Express)', description: 'Turf Pitch 2 (Express Lane)'),
    Court(id: 'cricket-3', sport: Sport.cricket, name: 'Turf Pitch 3 (VIP Indoor)', description: 'Turf Pitch 3 (VIP Indoor Enclosure)'),
    Court(id: 'padel-a', sport: Sport.padel, name: 'Court A Glass Panoramic', description: 'Court A Glass Panoramic'),
    Court(id: 'padel-b', sport: Sport.padel, name: 'Court B Indoor Sky', description: 'Court B Indoor Sky'),
    Court(id: 'padel-c', sport: Sport.padel, name: 'Court C Center Court', description: 'Court C Center Court'),
  ];

  static List<Court> forSport(Sport sport) => all.where((c) => c.sport == sport).toList();

  /// Unknown ids (e.g. a court that was removed) still resolve, so old bookings keep rendering.
  static Court byId(String id) => all.firstWhere(
    (c) => c.id == id,
    orElse: () => Court(id: id, sport: Sport.cricket, name: id, description: id),
  );
}
