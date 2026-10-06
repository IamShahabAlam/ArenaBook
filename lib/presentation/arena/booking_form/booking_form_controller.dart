import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/app_client_config.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';
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
  final sport = Sport.cricket.obs;
  final courtId = Court.forSport(Sport.cricket).first.id.obs;
  // Always from the service clock (never DateTime.now()), so tests and the app agree on "today".
  late final date = dateOnly(_service.now()).obs;
  final startMinute = RxnInt(); // chosen start time, null = not picked yet
  final duration = 60.obs; // minutes, in BookingRules.slotStep steps
  late final period = _defaultPeriod(date.value).obs; // which 6-hour block of start times is shown
  final advance = 0.obs;
  final discount = 0.obs;
  final notesLength = 0.obs;
  final submitting = false.obs;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

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
    everAll([startMinute, duration, sport, _settings.cricketHourlyRate.rx, _settings.padelHourlyRate.rx], (_) => _capMoney());
  }

  @override
  void onClose() {
    for (final c in [nameCtrl, phoneCtrl, emailCtrl, notesCtrl, advanceCtrl, discountCtrl]) {
      c.dispose();
    }
    scrollController.dispose();
    super.onClose();
  }

  // ─────────────── Derived (read inside Obx) ───────────────

  /// Agreed rate when editing the same sport, otherwise today's configured rate.
  int get hourlyRate {
    final original = _original;
    if (original != null && original.sport == sport.value) return original.hourlyRate;
    return _settings.rateFor(sport.value);
  }

  /// One continuous range: start + duration.
  List<TimeRange> get chosenSlots {
    final start = startMinute.value;
    final range = start == null ? null : TimeRange.tryCreate(start, start + duration.value);
    return range == null ? const [] : [range];
  }

  int get totalMinutes => chosenSlots.fold(0, (sum, s) => sum + s.durationMinutes);
  int get totalFee => Booking.feeFor(totalMinutes, hourlyRate);

  bool get discountEnabled => AppClientConfig.enableDiscount;

  /// Feature off: an edited booking keeps the discount it was saved with, so its price doesn't change.
  int get effectiveDiscount => BookingRules.clampDiscount(discountEnabled ? discount.value : (_original?.discount ?? 0), totalFee);

  int get payable => totalFee - effectiveDiscount;
  int get balance => payable - BookingRules.clampAdvance(advance.value, payable);

  List<TimeRange> get occupied => _service.occupied(date: date.value, courtId: courtId.value, excludeBookingId: editingId.value);

  Set<TimeRange> get _keepPast => _original != null && isSameDay(_original!.date, date.value) ? _original!.slots.toSet() : const {};

  /// Chip state of the start time [start]: inside the chosen range = selected, else booked / past / free.
  SlotState cellState(int start) {
    final chosen = chosenSlots.firstOrNull;
    if (chosen != null && start >= chosen.startMinute && start < chosen.endMinute) return SlotState.selected;
    final state = BookingRules.cellState(start, date: date.value, now: _service.now(), occupied: occupied);
    // Editing: the booking's own time stays selectable even after it started.
    final cell = TimeRange(start, start + BookingRules.slotStep);
    if (state == SlotState.past && _keepPast.any(cell.overlaps)) return SlotState.available;
    return state;
  }

  /// Longest duration from the chosen start before the next booking (or midnight).
  int get maxDuration {
    final start = startMinute.value;
    return start == null ? 0 : BookingRules.maxDuration(start, occupied: occupied);
  }

  /// Live problem with the chosen time (null = fine or nothing picked).
  String? get timeError => startMinute.value == null
      ? null
      : BookingRules.validateSlots(chosenSlots, date: date.value, now: _service.now(), occupied: occupied, keepPastSlots: _keepPast);

  /// Today: the period we're in now. Other days: evening, the busiest time.
  DayPart _defaultPeriod(DateTime day) {
    final now = _service.now();
    return isSameDay(day, now) ? DayPart.of(now.hour * 60 + now.minute) : DayPart.evening;
  }

  // ─────────────── Inputs ───────────────

  void selectSport(Sport value) {
    if (sport.value == value) return;
    sport.value = value;
    courtId.value = Court.forSport(value).first.id;
    startMinute.value = null;
  }

  void selectCourt(String id) {
    if (courtId.value == id) return;
    courtId.value = id;
    startMinute.value = null;
  }

  void selectDate(DateTime value) {
    final day = dateOnly(value);
    if (isSameDay(day, date.value)) return;
    date.value = day;
    startMinute.value = null;
    period.value = _defaultPeriod(day);
  }

  void selectPeriod(DayPart value) => period.value = value;

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

  /// +/- one step; stays within 30 min .. the room before the next booking.
  void changeDuration(int steps) {
    final next = duration.value + steps * BookingRules.slotStep;
    final max = startMinute.value == null ? TimeRange.minutesPerDay : maxDuration;
    if (next >= BookingRules.slotStep && next <= max) duration.value = next;
  }

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
    sport.value = b.sport;
    courtId.value = b.courtId;
    date.value = b.date;
    _applySlots(b.slots);
    discount.value = b.discount;
    _write(discountCtrl, b.discount);
    advance.value = b.amountCollected;
    _writeAdvance(b.amountCollected);
  }

  /// Copies customer, sport and court to today, pre-selecting the same time when still free.
  /// Returns true when the time could be kept.
  bool loadForRepeat(Booking b) {
    _clear();
    _fillCustomer(b);
    sport.value = b.sport;
    courtId.value = b.courtId;
    date.value = dateOnly(_service.now());
    final range = TimeRange(b.slots.first.startMinute, b.slots.last.endMinute);
    final free = BookingRules.validateSlots([range], date: date.value, now: _service.now(), occupied: occupied) == null;
    if (free) _applySlots(b.slots);
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
    duration.value = 60;
    date.value = dateOnly(_service.now());
    period.value = _defaultPeriod(date.value);
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
      sport: sport.value,
      courtId: courtId.value,
      date: date.value,
      slots: chosenSlots,
      hourlyRate: hourlyRate,
      discount: effectiveDiscount,
      advancePaid: advance.value,
    );

    submitting.value = true;
    try {
      final id = editingId.value;
      final saved = id == null ? await _service.create(draft) : await _service.update(id, draft);
      ArenaToast.success(id == null ? 'Booking created! ID: #${saved.id}' : 'Updated booking #${saved.id}');
      final keepSport = sport.value;
      _clear();
      sport.value = keepSport;
      courtId.value = Court.forSport(keepSport).first.id;
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
