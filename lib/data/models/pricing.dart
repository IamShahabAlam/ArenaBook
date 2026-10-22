/// How a booking's fee is worked out. Each booking stores its own mode, so changing a client's mode never re-prices old bookings.
enum PricingMode {
  /// Minutes × the hourly rate (Settings), as ArenaBook always did.
  hourly,

  /// The owner types the price for each booking (required in the form).
  manual;

  /// Unknown or missing (bookings saved before v3) = hourly.
  static PricingMode fromName(String? name) => values.firstWhere((m) => m.name == name, orElse: () => hourly);
}
