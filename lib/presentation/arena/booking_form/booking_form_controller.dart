import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/app_client_config.dart';
import '../../../app/service/getx_service/app_access_service.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/booking_policy.dart';
import '../../../data/models/pricing.dart';
import '../../../data/models/resource.dart';
import '../../../data/models/time_range.dart';
import '../../../data/rules/booking_rules.dart';

/// State of the New / Edit booking form. Lives as long as the shell, so a half-filled form
/// survives a quick look at another tab.
class BookingFormController extends GetxController {
  static BookingFormController get to => Get.find();

  BookingService get _service => BookingService.to;
  SettingsStore get _settings => SettingsStore.to;

  // ─────────────── State ───────────────
  final editingId = RxnString();
  final resourceType = ResourceType.offered.first.obs;
  final resourceId = ResourceType.offered.first.resources.first.id.obs;
  // Always from the service clock (never DateTime.now()), so tests and the app agree on "today".
  late final date = dateOnly(_service.now()).obs;
  final startMinute = RxnInt(); // chosen start time, null = not picked yet
  late final duration = policy.defaultDuration.obs; // minutes, in policy steps
  late final period = _defaultPeriod(date.value).obs; // which 6-hour block of start times is shown
  final price = 0.obs; // manual pricing: what the owner typed
  final advance = 0.obs;
  final discount = 0.obs;
  final notesLength = 0.obs;
  final submitting = false.obs;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final priceCtrl = TextEditingController();
  final advanceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();

  /// Edit mode: the booking's own slots (may be kept even if started) and its agreed rate.
  Booking? _original;

  bool get isEditing => editingId.value != null;

  @override
  void onInit() {
    super.onInit();
    notesCtrl.addListener(() => notesLength.value = notesCtrl.text.length);
    // When the fee drops (fewer slots, rate change), cap the discount and advance to it.
    everAll([startMinute, duration, resourceType, price, ..._settings.rateStreams], (_) => _capMoney());
  }

  @override
  void onClose() {
    for (final c in [nameCtrl, phoneCtrl, emailCtrl, notesCtrl, priceCtrl, advanceCtrl, discountCtrl]) {
      c.dispose();
    }
    scrollController.dispose();
    super.onClose();
  }

  // ─────────────── Derived (read inside Obx) ───────────────

  /// The client's time rules: steps, durations, opening hours or fixed sessions.
  BookingPolicy get policy => AppClientConfig.policy;

  /// Resource types to choose from: the offered ones, plus an edited booking's type if it was switched off since.
  List<ResourceType> get formResourceTypes {
    final offered = ResourceType.offered;
    final own = _original?.resourceType;
    return own == null || offered.contains(own) ? offered : [...offered, own];
  }

  /// Agreed rate when editing the same resource type, otherwise today's configured rate.
  int get hourlyRate {
    final original = _original;
    if (original != null && original.resourceType == resourceType.value) return original.hourlyRate;
    return _settings.rateFor(resourceType.value);
  }

  /// One continuous range: start + duration.
  List<TimeRange> get chosenSlots {
    final start = startMinute.value;
    final range = start == null ? null : TimeRange.tryCreate(start, start + duration.value);
    return range == null ? const [] : [range];
  }

  /// An edited booking keeps the pricing it was made with; new ones follow the client's.
  PricingMode get pricing => _original?.pricing ?? AppClientConfig.pricing;

  bool get isManualPrice => pricing == PricingMode.manual;

  int get totalMinutes => chosenSlots.fold(0, (sum, s) => sum + s.durationMinutes);
  int get totalFee => isManualPrice ? price.value : Booking.feeFor(totalMinutes, hourlyRate);

  /// Field error for the typed price (manual pricing only).
  String? get priceError => isManualPrice ? BookingRules.validatePrice(pricing, hourlyRate: 0, price: price.value) : null;

  bool get discountEnabled => AppClientConfig.enableDiscount;

  /// Feature off: an edited booking keeps the discount it was saved with, so its price doesn't change.
  int get effectiveDiscount => BookingRules.clampDiscount(discountEnabled ? discount.value : (_original?.discount ?? 0), totalFee);

  int get payable => totalFee - effectiveDiscount;
  int get balance => payable - BookingRules.clampAdvance(advance.value, payable);

  List<TimeRange> get occupied => _service.occupied(date: date.value, resourceId: resourceId.value, excludeBookingId: editingId.value);

  Set<TimeRange> get _keepPast => _original != null && isSameDay(_original!.date, date.value) ? _original!.slots.toSet() : const {};

  /// Chip state of the start time [start]: inside the chosen range = selected, else booked / past / free.
  SlotState cellState(int start) {
    final chosen = chosenSlots.firstOrNull;
    if (chosen != null && start >= chosen.startMinute && start < chosen.endMinute) return SlotState.selected;
    final state = BookingRules.cellState(start, date: date.value, now: _service.now(), occupied: occupied);
    // Editing: the booking's own time stays selectable even after it started.
    final cell = TimeRange(start, start + policy.step);
    if (state == SlotState.past && _keepPast.any(cell.overlaps)) return SlotState.available;
    return state;
  }

  /// Parts of the day with at least one start time inside opening hours (a studio open 9AM-11PM has no Night tab).
  List<DayPart> get visibleParts => DayPart.values.where((p) => BookingRules.startsIn(p).isNotEmpty).toList();

  List<int> startsIn(DayPart part) => BookingRules.startsIn(part);

  /// Session card state: the chosen session = selected, else booked / past / free.
  SlotState sessionState(BookingSession session) {
    if (chosenSlots.firstOrNull == session.time) return SlotState.selected;
    final state = BookingRules.sessionState(session, date: date.value, now: _service.now(), occupied: occupied);
    if (state == SlotState.past && _keepPast.contains(session.time)) return SlotState.available;
    return state;
  }

  /// Longest duration from the chosen start before the next booking (or midnight).
  int get maxDuration {
    final start = startMinute.value;
    return start == null ? 0 : BookingRules.maxDuration(start, occupied: occupied);
  }

  /// "Full day" fits: the policy offers it and 24 hours are free from the chosen start.
  bool get canBookFullDay => policy.offersFullDay && startMinute.value != null && maxDuration >= TimeRange.minutesPerDay;

  bool get isFullDay => duration.value == TimeRange.minutesPerDay;

  /// Live problem with the chosen time (null = fine or nothing picked).
  String? get timeError => startMinute.value == null
      ? null
      : BookingRules.validateSlots(chosenSlots, date: date.value, now: _service.now(), occupied: occupied, keepPastSlots: _keepPast);

  /// Today: the period we're in now. Other days: evening, the busiest time. A closed period moves to the next open one.
  DayPart _defaultPeriod(DateTime day) {
    final now = _service.now();
    final wanted = isSameDay(day, now) ? DayPart.of(now.hour * 60 + now.minute) : DayPart.evening;
    final open = visibleParts;
    if (open.isEmpty || open.contains(wanted)) return wanted;
    return open.firstWhere((p) => p.index > wanted.index, orElse: () => open.last);
  }

  // ─────────────── Inputs ───────────────

  void selectResourceType(ResourceType value) {
    if (resourceType.value == value) return;
    resourceType.value = value;
    resourceId.value = Resource.forType(value).first.id;
    startMinute.value = null;
  }

  void selectResource(String id) {
    if (resourceId.value == id) return;
    resourceId.value = id;
    startMinute.value = null;
  }

  void selectDate(DateTime value) {
    final day = dateOnly(value);
    if (isSameDay(day, date.value)) return;
    date.value = day;
    startMinute.value = null;
    period.value = _defaultPeriod(day);
  }

  void selectPeriod(DayPart value) {
    if (visibleParts.contains(value)) period.value = value; // the day bar can be tapped on closed hours
  }

  /// Tap a free start time to pick it (tap the chosen start again to clear).
  /// The duration shrinks if the next booking leaves less room.
  void selectStart(int start) {
    if (startMinute.value == start) {
      startMinute.value = null;
      return;
    }
    final state = cellState(start);
    if (state != SlotState.available && state != SlotState.selected) return;
    startMinute.value = start;
    final room = maxDuration;
    if (duration.value > room) duration.value = room;
  }

  /// Tap a free session to pick it (tap it again to clear).
  void selectSession(BookingSession session) {
    if (chosenSlots.firstOrNull == session.time) {
      startMinute.value = null;
      return;
    }
    if (sessionState(session) != SlotState.available) return;
    startMinute.value = session.time.startMinute;
    duration.value = session.time.durationMinutes;
  }

  /// +/- one step; stays within the policy's minimum .. the room before the next booking or closing.
  void changeDuration(int steps) {
    final next = duration.value + steps * policy.step;
    final max = startMinute.value == null ? policy.maxDuration : maxDuration;
    if (next >= policy.minDuration && next <= max) duration.value = next;
  }

  /// Sets 24 hours from the chosen start (priced by the hour like any other booking).
  void selectFullDay() {
    if (canBookFullDay) duration.value = TimeRange.minutesPerDay;
  }

  void onPriceChanged(String text) => price.value = int.tryParse(BookingRules.digitsOnly(text)) ?? 0; // _capMoney follows via everAll

  void onAdvanceChanged(String text) {
    final parsed = int.tryParse(BookingRules.digitsOnly(text)) ?? 0;
    final capped = BookingRules.clampAdvance(parsed, payable);
    advance.value = capped;
    if (capped != parsed) _writeAdvance(capped);
  }

  void onDiscountChanged(String text) {
    final parsed = int.tryParse(BookingRules.digitsOnly(text)) ?? 0;
    final capped = BookingRules.clampDiscount(parsed, totalFee);
    discount.value = capped;
    if (capped != parsed) _write(discountCtrl, capped);
    _capMoney(); // a bigger discount can push the advance above what's payable
  }

  void _capMoney() {
    final cappedDiscount = BookingRules.clampDiscount(discount.value, totalFee);
    if (cappedDiscount != discount.value) {
      discount.value = cappedDiscount;
      _write(discountCtrl, cappedDiscount);
    }
    final cappedAdvance = BookingRules.clampAdvance(advance.value, payable);
    if (cappedAdvance != advance.value) {
      advance.value = cappedAdvance;
      _writeAdvance(cappedAdvance);
    }
  }

  void _writeAdvance(int value) => _write(advanceCtrl, value);

  void _writePrice(int value) {
    price.value = value;
    _write(priceCtrl, value);
  }

  void _write(TextEditingController ctrl, int value) {
    final text = value == 0 ? '' : value.toString(); // 0 shows as the field's hint
    ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // ─────────────── Entry points (called via BookingActions) ───────────────

  /// "+" button: a new booking. Editing state is always dropped (the prototype kept it, so a
  /// "new" booking could overwrite the one being edited); an unsent new draft is kept.
  void startNew({DateTime? onDate}) {
    if (isEditing) _clear();
    // App left open past midnight: a kept draft must not point at a day that has passed.
    final today = dateOnly(_service.now());
    if (date.value.isBefore(today)) selectDate(today);
    if (onDate != null) selectDate(onDate);
  }

  void loadForEdit(Booking b) {
    _clear();
    _original = b;
    editingId.value = b.id;
    _fillCustomer(b);
    resourceType.value = b.resourceType;
    resourceId.value = b.resourceId;
    date.value = b.date;
    _applySlots(b.slots);
    if (b.pricing == PricingMode.manual) _writePrice(b.totalFee);
    discount.value = b.discount;
    _write(discountCtrl, b.discount);
    advance.value = b.amountCollected;
    _writeAdvance(b.amountCollected);
  }

  /// Copies customer, resource type and resource to today, pre-selecting the same time when still free.
  /// Returns true when the time could be kept.
  bool loadForRepeat(Booking b) {
    _clear();
    _fillCustomer(b);
    resourceType.value = b.resourceType;
    resourceId.value = b.resourceId;
    date.value = dateOnly(_service.now());
    final range = TimeRange(b.slots.first.startMinute, b.slots.last.endMinute);
    final free = BookingRules.validateSlots([range], date: date.value, now: _service.now(), occupied: occupied) == null;
    if (free) _applySlots(b.slots);
    if (isManualPrice && b.pricing == PricingMode.manual) _writePrice(b.totalFee); // same service, same price (editable)
    return free;
  }

  void _fillCustomer(Booking b) {
    nameCtrl.text = b.customerName;
    phoneCtrl.text = b.phone;
    emailCtrl.text = b.email;
    notesCtrl.text = b.notes;
  }

  /// Shows a saved booking's time (first start to last end) as start + duration.
  void _applySlots(List<TimeRange> slots) {
    startMinute.value = slots.first.startMinute;
    duration.value = slots.last.endMinute - slots.first.startMinute;
    period.value = DayPart.of(slots.first.startMinute);
  }

  void _clear() {
    _original = null;
    editingId.value = null;
    for (final c in [nameCtrl, phoneCtrl, emailCtrl, notesCtrl]) {
      c.clear();
    }
    startMinute.value = null;
    duration.value = policy.defaultDuration;
    date.value = dateOnly(_service.now());
    period.value = _defaultPeriod(date.value);
    _writePrice(0);
    advance.value = 0;
    _writeAdvance(0);
    discount.value = 0; // also not copied by Repeat: a discount is a one-off
    _write(discountCtrl, 0);
    formKey.currentState?.reset();
  }

  /// Leaves edit mode without saving.
  void discardEdit() => _clear();

  // ─────────────── Submit ───────────────

  /// Saves the booking and returns it, or null when validation failed (a toast explains why).
  Future<Booking?> submit() async {
    if (submitting.value) return null; // double-tap guard: never create two bookings
    if (!AppAccessService.to.allows()) return null; // trial switch, re-checked right before saving
    final fieldsOk = formKey.currentState?.validate() ?? false;
    if (!fieldsOk) {
      ArenaToast.error('Please fix the highlighted fields');
      return null;
    }

    final draft = BookingDraft(
      customerName: nameCtrl.text,
      phone: phoneCtrl.text,
      email: emailCtrl.text,
      notes: notesCtrl.text,
      resourceType: resourceType.value,
      resourceId: resourceId.value,
      date: date.value,
      slots: chosenSlots,
      pricing: pricing,
      hourlyRate: hourlyRate,
      price: price.value,
      discount: effectiveDiscount,
      advancePaid: advance.value,
    );

    submitting.value = true;
    try {
      final id = editingId.value;
      final saved = id == null ? await _service.create(draft) : await _service.update(id, draft);
      ArenaToast.success(id == null ? 'Booking created! ID: #${saved.id}' : 'Updated booking #${saved.id}');
      final keepType = resourceType.value;
      _clear();
      resourceType.value = keepType;
      resourceId.value = Resource.forType(keepType).first.id;
      return saved;
    } on BookingException catch (e) {
      ArenaToast.error(e.message);
      return null;
    } catch (e) {
      ArenaToast.error('Could not save the booking. Please try again.');
      return null;
    } finally {
      submitting.value = false;
    }
  }
}
