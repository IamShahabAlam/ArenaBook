import 'pricing.dart';
import 'resource.dart';
import 'time_range.dart';

enum BookingStatus { paid, pending, cancelled }

/// One ground booking. Immutable: every change goes through [copyWith] and is saved as a new version.
///
/// Money is always whole rupees (int). Only facts are stored; [balanceDue], [amountCollected] and
/// [status] are derived from them, so they can never disagree with each other.
class Booking {
  const Booking({
    required this.id,
    required this.customerName,
    required this.phone,
    this.email = '',
    this.notes = '',
    required this.resourceType,
    required this.resourceId,
    required this.date,
    required this.slots,
    this.pricing = PricingMode.hourly,
    required this.hourlyRate,
    required this.totalFee,
    this.discount = 0,
    required this.advancePaid,
    this.balanceSettledAt,
    this.cancelledAt,
    this.cancelReason = '',
    this.advanceReturned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Bump when the stored shape changes, and handle old versions in [fromJson].
  static const schemaVersion = 3; // v2: discount (v1 loads 0). v3: pricing (older loads hourly)

  final String id; // "TRF-1001", sequential so it is unique and readable
  final String customerName;
  final String phone; // digits only, max 11
  final String email; // '' when not given
  final String notes; // max 120 chars
  final ResourceType resourceType;
  final String resourceId; // see Resource.byId
  final DateTime date; // local calendar day (time part is always 00:00)
  final List<TimeRange> slots; // sorted, non-overlapping
  final PricingMode pricing; // how totalFee was worked out
  final int hourlyRate; // rate agreed at booking time (0 for manual pricing); later rate changes don't alter this booking
  final int totalFee; // full price before discount: minutes × rate, or the price the owner typed
  final int discount; // rupees off, 0..totalFee
  final int advancePaid; // received when booking / last edit
  final DateTime? balanceSettledAt; // set by "Mark Paid": the remaining balance was received
  final DateTime? cancelledAt;
  final String cancelReason;
  final bool advanceReturned; // only meaningful when cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─────────────── Derived values ───────────────

  bool get isCancelled => cancelledAt != null;

  /// What the customer owes in total.
  int get payable => totalFee - discount;

  bool get isSettled => balanceSettledAt != null || advancePaid >= payable;

  Resource get resource => Resource.byId(resourceId);

  int get totalMinutes => slots.fold(0, (sum, s) => sum + s.durationMinutes);

  /// Money the arena actually holds for this booking.
  int get amountCollected {
    if (isCancelled) return advanceReturned ? 0 : advancePaid;
    return isSettled ? payable : advancePaid;
  }

  int get balanceDue => isCancelled || isSettled ? 0 : payable - advancePaid;

  BookingStatus get status {
    if (isCancelled) return BookingStatus.cancelled;
    return balanceDue > 0 ? BookingStatus.pending : BookingStatus.paid;
  }

  DateTime get startsAt => slots.first.startOn(date);

  /// Same rule as the prototype: today and later count as upcoming.
  bool isUpcoming(DateTime now) => !date.isBefore(dateOnly(now));

  /// Only active bookings from today onward can be edited.
  bool canEdit(DateTime now) => !isCancelled && isUpcoming(now);

  String get slotsLabel => slots.map((s) => s.label).join(', ');

  // ─────────────── Business rules ───────────────

  /// Fee for [minutes] of play at [hourlyRate], rounded to whole rupees.
  static int feeFor(int minutes, int hourlyRate) => (minutes * hourlyRate / 60).round();

  Booking settle(DateTime now) => copyWith(balanceSettledAt: now, updatedAt: now);

  Booking cancel({required String reason, required bool advanceReturned, required DateTime now}) =>
      copyWith(cancelledAt: now, cancelReason: reason, advanceReturned: advanceReturned, updatedAt: now);

  Booking copyWith({
    String? customerName,
    String? phone,
    String? email,
    String? notes,
    ResourceType? resourceType,
    String? resourceId,
    DateTime? date,
    List<TimeRange>? slots,
    PricingMode? pricing,
    int? hourlyRate,
    int? totalFee,
    int? discount,
    int? advancePaid,
    DateTime? balanceSettledAt,
    bool clearBalanceSettledAt = false,
    DateTime? cancelledAt,
    String? cancelReason,
    bool? advanceReturned,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      date: date ?? this.date,
      slots: slots ?? this.slots,
      pricing: pricing ?? this.pricing,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalFee: totalFee ?? this.totalFee,
      discount: discount ?? this.discount,
      advancePaid: advancePaid ?? this.advancePaid,
      balanceSettledAt: clearBalanceSettledAt ? null : (balanceSettledAt ?? this.balanceSettledAt),
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      advanceReturned: advanceReturned ?? this.advanceReturned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─────────────── Serialization ───────────────

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'id': id,
    'customerName': customerName,
    'phone': phone,
    'email': email,
    'notes': notes,
    'sport': resourceType.id, // legacy key names ('sport', 'courtId') kept, so stored bookings need no migration
    'courtId': resourceId,
    'date': dateKey(date),
    'slots': slots.map((s) => s.toJson()).toList(),
    'pricing': pricing.name,
    'hourlyRate': hourlyRate,
    'totalFee': totalFee,
    'discount': discount,
    'advancePaid': advancePaid,
    'balanceSettledAt': balanceSettledAt?.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'cancelReason': cancelReason,
    'advanceReturned': advanceReturned,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Throws [FormatException] on corrupt data so the repository can skip that record instead of crashing.
  factory Booking.fromJson(Map json) {
    final slots = ((json['slots'] as List?) ?? const []).map((e) => TimeRange.fromJson(e as Map)).whereType<TimeRange>().toList()..sort();
    if (slots.isEmpty) throw FormatException('Booking ${json['id']} has no valid slots');

    DateTime? optionalDate(Object? value) => value == null ? null : DateTime.parse(value as String);

    return Booking(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      resourceType: ResourceType.byId(json['sport'] as String),
      resourceId: json['courtId'] as String,
      date: parseDateKey(json['date'] as String),
      slots: slots,
      pricing: PricingMode.fromName(json['pricing'] as String?), // absent before v3
      hourlyRate: (json['hourlyRate'] as num).toInt(),
      totalFee: (json['totalFee'] as num).toInt(),
      discount: (json['discount'] as num?)?.toInt() ?? 0, // absent in v1 records
      advancePaid: (json['advancePaid'] as num).toInt(),
      balanceSettledAt: optionalDate(json['balanceSettledAt']),
      cancelledAt: optionalDate(json['cancelledAt']),
      cancelReason: json['cancelReason'] as String? ?? '',
      advanceReturned: json['advanceReturned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// ─────────────── Calendar-day helpers ───────────────
// Bookings live on local calendar days. Never use toUtc()/toIso8601String() for a day:
// in Pakistan (UTC+5) that turns 00:00-05:00 "today" into yesterday (a bug in the prototype).

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "2026-10-01"
String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  if (parts.length != 3) throw FormatException('Invalid date key: $key');
  return DateTime(parts[0], parts[1], parts[2]);
}
