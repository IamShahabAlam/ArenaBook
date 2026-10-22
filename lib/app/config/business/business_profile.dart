import '../../../data/models/booking_policy.dart';
import '../../../data/models/pricing.dart';

/// How one kind of business works. Holds data only (strings, numbers), so a setup screen or database can store it later.
/// A client picks one and may override its policy, pricing or features (ClientConfig).
class BusinessProfile {
  const BusinessProfile({required this.id, required this.terms, required this.policy, this.pricing = PricingMode.hourly, this.features = const Features()});

  /// Stable key for a future setup screen or database; never change once shipped.
  final String id;

  final Terms terms;

  /// Default time rules for this kind of business; a client can override them (ClientConfig.policy).
  final BookingPolicy policy;

  /// Default way to price a booking; a client can override it (ClientConfig.pricing).
  final PricingMode pricing;

  /// Optional parts this kind of business uses; a client can replace them (ClientConfig.features).
  final Features features;
}

/// The business's own words for the core concepts. Screens and receipts read these instead of literals.
class Terms {
  const Terms({
    required this.subject,
    required this.resource,
    required this.resources,
    required this.resourceType,
    required this.customer,
    required this.fee,
    required this.place,
    required this.passHint,
    required this.receiptThanks,
    required this.cancelReasonHint,
  });

  final String subject; // "Ground": qualifies bookings and the business ("Ground Booking", "Ground Management")
  final String resource; // "Court": one bookable unit
  final String resources; // "Courts"
  final String resourceType; // "Sport": what groups the resources
  final String customer; // "Player"
  final String fee; // "Ground Fee": the price before discount
  final String place; // "arena": lowercase, used mid-sentence ("not activated for your arena")
  final String passHint; // caption under the receipt's QR code
  final String receiptThanks; // closing line of the shared receipt
  final String cancelReasonHint; // example reason in the cancel dialog

  String get booking => '$subject Booking';
  String get bookings => '$subject Bookings';
}

/// Optional parts of the app a business may or may not use. Data only; the defaults are ArenaBook's original behaviour.
class Features {
  const Features({this.discount = true, this.entryPass = true});

  /// Discount field in the booking form and discount lines on invoices.
  final bool discount;

  /// QR entry pass on the receipt (with [Terms.passHint]), for places that check customers in.
  final bool entryPass;
}
