import '../../../data/models/booking_policy.dart';
import '../../../data/models/pricing.dart';

/// How one kind of business works. Holds data only (strings, numbers), so a setup screen or database can store it later.
/// Optional features join it in a later phase (docs/EXPANSION_PLAN.md).
class BusinessProfile {
  const BusinessProfile({required this.id, required this.terms, required this.policy, this.pricing = PricingMode.hourly});

  /// Stable key for a future setup screen or database; never change once shipped.
  final String id;

  final Terms terms;

  /// Default time rules for this kind of business; a client can override them (ClientConfig.policy).
  final BookingPolicy policy;

  /// Default way to price a booking; a client can override it (ClientConfig.pricing).
  final PricingMode pricing;
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
