import 'package:get/get.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/pricing.dart';
import '../../../data/models/resource.dart';
import '../../../data/models/time_range.dart';
import '../../../data/repositories/booking/booking_repository.dart';
import '../../../data/rules/booking_rules.dart';

/// What the booking form submits. The service turns it into a [Booking] (fee, id, timestamps).
class BookingDraft {
  const BookingDraft({
    required this.customerName,
    required this.phone,
    this.email = '',
    this.notes = '',
    required this.resourceType,
    required this.resourceId,
    required this.date,
    required this.slots,
    this.pricing = PricingMode.hourly,
    this.hourlyRate = 0,
    this.price = 0,
    this.discount = 0,
    required this.advancePaid,
  });

  final String customerName;
  final String phone;
  final String email;
  final String notes;
  final ResourceType resourceType;
  final String resourceId;
  final DateTime date;
  final List<TimeRange> slots;
  final PricingMode pricing;
  final int hourlyRate; // hourly pricing only
  final int price; // manual pricing only: what the owner typed
  final int discount;
  final int advancePaid;

  int get totalMinutes => slots.fold(0, (sum, s) => sum + s.durationMinutes);
  int get totalFee => switch (pricing) {
    PricingMode.hourly => Booking.feeFor(totalMinutes, hourlyRate),
    PricingMode.manual => price,
  };
  int get payable => totalFee - discount;

  /// The rate saved on the booking: 0 for a manual price, so no "@ rate/hr" is ever shown for it.
  int get savedRate => pricing == PricingMode.hourly ? hourlyRate : 0;
}

/// Thrown when a booking can't be saved; [message] is safe to show to the user.
class BookingException implements Exception {
  BookingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Single source of truth for bookings. Every screen reads [bookings] inside Obx, so a change made
/// anywhere (create, edit, pay, cancel) refreshes Home, Bookings, Pending and Calendar together.
///
/// Writes are saved to the repository first and only then shown, so the UI never shows unsaved data.
class BookingService extends GetxService {
  BookingService(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static BookingService get to => Get.find();

  final BookingRepository _repository;
  final DateTime Function() _clock;

  final bookings = <Booking>[].obs;

  /// Bumped every minute (and on app resume) by the shell. [now] reads it, so any Obx that asks
  /// for the time rebuilds by itself: the 9AM slot turns "Past" at 9:00, "Today" rolls at midnight.
  final _tick = 0.obs;

  DateTime now() {
    _tick.value; // subscribe the calling Obx
    return _clock();
  }

  void tick() => _tick.value++;

  Future<BookingService> init() async {
    final loaded = await _repository.loadAll();
    bookings.assignAll(_sorted(loaded));
    return this;
  }

  Booking? byId(String id) => bookings.firstWhereOrNull((b) => b.id == id);

  Future<Booking> create(BookingDraft draft) async {
    _validate(draft);
    final now = _clock();
    final booking = Booking(
      id: await _repository.nextId(),
      customerName: draft.customerName.trim(),
      phone: BookingRules.digitsOnly(draft.phone),
      email: draft.email.trim(),
      notes: draft.notes.trim(),
      resourceType: draft.resourceType,
      resourceId: draft.resourceId,
      date: dateOnly(draft.date),
      slots: [...draft.slots]..sort(),
      pricing: draft.pricing,
      hourlyRate: draft.savedRate,
      totalFee: draft.totalFee,
      discount: draft.discount,
      advancePaid: BookingRules.clampAdvance(draft.advancePaid, draft.payable),
      createdAt: now,
      updatedAt: now,
    );
    await _persist(booking);
    return booking;
  }

  /// Replaces the details of an existing booking. The advance entered in the form becomes the
  /// amount received, so a previous "Mark Paid" is re-evaluated against the new total.
  Future<Booking> update(String id, BookingDraft draft) async {
    final existing = byId(id);
    if (existing == null) throw BookingException('Booking #$id no longer exists');
    if (existing.isCancelled) throw BookingException('Cancelled bookings cannot be edited');
    _validate(draft, existing: existing);

    final updated = existing.copyWith(
      customerName: draft.customerName.trim(),
      phone: BookingRules.digitsOnly(draft.phone),
      email: draft.email.trim(),
      notes: draft.notes.trim(),
      resourceType: draft.resourceType,
      resourceId: draft.resourceId,
      date: dateOnly(draft.date),
      slots: [...draft.slots]..sort(),
      pricing: draft.pricing,
      hourlyRate: draft.savedRate,
      totalFee: draft.totalFee,
      discount: draft.discount,
      advancePaid: BookingRules.clampAdvance(draft.advancePaid, draft.payable),
      clearBalanceSettledAt: true,
      updatedAt: _clock(),
    );
    await _persist(updated);
    return updated;
  }

  Future<Booking> markPaid(String id) async {
    final existing = byId(id);
    if (existing == null) throw BookingException('Booking #$id no longer exists');
    if (existing.isCancelled) throw BookingException('Booking #$id is cancelled');
    if (existing.balanceDue == 0) return existing;
    final paid = existing.settle(_clock());
    await _persist(paid);
    return paid;
  }

  Future<Booking> cancel(String id, {required String reason, required bool advanceReturned}) async {
    final existing = byId(id);
    if (existing == null) throw BookingException('Booking #$id no longer exists');
    if (existing.isCancelled) return existing;
    if (reason.trim().isEmpty) throw BookingException('Please enter a cancellation reason');
    final cancelled = existing.cancel(reason: reason.trim(), advanceReturned: advanceReturned, now: _clock());
    await _persist(cancelled);
    return cancelled;
  }

  /// Slots already taken on a resource/day, ignoring [excludeBookingId] (the booking being edited).
  List<TimeRange> occupied({required DateTime date, required String resourceId, String? excludeBookingId}) =>
      BookingRules.occupied(bookings, date: date, resourceId: resourceId, excludeBookingId: excludeBookingId);

  // ─────────────── internals ───────────────

  void _validate(BookingDraft draft, {Booking? existing}) {
    final error =
        BookingRules.validateName(draft.customerName) ??
        BookingRules.validatePhone(draft.phone) ??
        BookingRules.validateEmail(draft.email) ??
        (draft.notes.trim().length > BookingRules.maxNotesLength ? 'Notes can be at most ${BookingRules.maxNotesLength} characters' : null) ??
        BookingRules.validatePrice(draft.pricing, hourlyRate: draft.hourlyRate, price: draft.price) ??
        BookingRules.validateDiscount(draft.discount, draft.totalFee) ??
        BookingRules.validateSlots(
          draft.slots,
          date: draft.date,
          now: _clock(),
          occupied: occupied(date: draft.date, resourceId: draft.resourceId, excludeBookingId: existing?.id),
          // An edited booking may keep slots that already started today (e.g. fixing a phone number mid-game).
          keepPastSlots: existing != null && isSameDay(existing.date, draft.date) ? existing.slots.toSet() : const {},
        );
    if (error != null) throw BookingException(error);
  }

  Future<void> _persist(Booking booking) async {
    await _repository.save(booking);
    final index = bookings.indexWhere((b) => b.id == booking.id);
    final next = [...bookings];
    index == -1 ? next.add(booking) : next[index] = booking;
    bookings.assignAll(_sorted(next));
  }

  /// Chronological: earliest day and start time first.
  static List<Booking> _sorted(Iterable<Booking> list) => list.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}
