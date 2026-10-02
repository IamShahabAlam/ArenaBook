import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';
import '../../../data/models/time_range.dart';
import '../../../data/rules/booking_rules.dart';

enum SlotMode { preset, custom }

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
  final mode = SlotMode.preset.obs;
  final selectedSlots = <TimeRange>{}.obs;
  final customStart = (13 * 60 + 30).obs;
  final customEnd = (14 * 60 + 30).obs;
  final advance = 0.obs;
  final notesLength = 0.obs;
  final submitting = false.obs;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final advanceCtrl = TextEditingController(text: '0');
  final formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();

  /// Edit mode: the booking's own slots (may be kept even if started) and its agreed rate.
  Booking? _original;

  bool get isEditing => editingId.value != null;

  @override
  void onInit() {
    super.onInit();
    notesCtrl.addListener(() => notesLength.value = notesCtrl.text.length);
    // When the fee drops below the advance (fewer slots, rate change), cap the advance.
    everAll([selectedSlots, customStart, customEnd, mode, sport, _settings.cricketHourlyRate.rx, _settings.padelHourlyRate.rx], (_) => _capAdvance());
  }

  @override
  void onClose() {
    for (final c in [nameCtrl, phoneCtrl, emailCtrl, notesCtrl, advanceCtrl]) {
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

  TimeRange? get customRange => TimeRange.tryCreate(customStart.value, customEnd.value);

  List<TimeRange> get chosenSlots {
    if (mode.value == SlotMode.custom) {
      final range = customRange;
      return range == null ? const [] : [range];
    }
    return selectedSlots.toList()..sort();
  }

  int get totalMinutes => chosenSlots.fold(0, (sum, s) => sum + s.durationMinutes);
  int get totalFee => Booking.feeFor(totalMinutes, hourlyRate);
  int get balance => totalFee - BookingRules.clampAdvance(advance.value, totalFee);

  List<TimeRange> get occupied => _service.occupied(date: date.value, courtId: courtId.value, excludeBookingId: editingId.value);

  Set<TimeRange> get _keepPast => _original != null && isSameDay(_original!.date, date.value) ? _original!.slots.toSet() : const {};

  SlotState slotState(TimeRange slot) {
    final state = BookingRules.stateOf(slot, date: date.value, now: _service.now(), occupied: occupied, selected: selectedSlots);
    // Slots this booking already had stay selectable when editing, even after they started.
    if (state == SlotState.past && _keepPast.contains(slot)) return SlotState.available;
    return state;
  }

  /// Live problem with the custom range (null = fine).
  String? get customRangeError {
    if (customRange == null) return 'End time must be after start time';
    return BookingRules.validateSlots(chosenSlots, date: date.value, now: _service.now(), occupied: occupied, keepPastSlots: _keepPast);
  }

  // ─────────────── Inputs ───────────────

  void selectSport(Sport value) {
    if (sport.value == value) return;
    sport.value = value;
    courtId.value = Court.forSport(value).first.id;
    selectedSlots.clear();
  }

  void selectCourt(String id) {
    if (courtId.value == id) return;
    courtId.value = id;
    selectedSlots.clear();
  }

  void selectDate(DateTime value) {
    final day = dateOnly(value);
    if (isSameDay(day, date.value)) return;
    date.value = day;
    selectedSlots.clear();
  }

  void toggleSlot(TimeRange slot) {
    final state = slotState(slot);
    if (state == SlotState.selected) {
      selectedSlots.remove(slot);
    } else if (state == SlotState.available) {
      selectedSlots.add(slot);
    }
  }

  void setMode(SlotMode value) => mode.value = value;

  void setCustomStart(TimeOfDay t) => customStart.value = t.hour * 60 + t.minute;
  void setCustomEnd(TimeOfDay t) => customEnd.value = t.hour * 60 + t.minute;

  void onAdvanceChanged(String text) {
    final parsed = int.tryParse(BookingRules.digitsOnly(text)) ?? 0;
    final capped = BookingRules.clampAdvance(parsed, totalFee);
    advance.value = capped;
    if (capped != parsed) _writeAdvance(capped);
  }

  void setAdvancePercent(int percent) {
    final value = BookingRules.advanceForPercent(totalFee, percent);
    advance.value = value;
    _writeAdvance(value);
  }

  void _capAdvance() {
    final capped = BookingRules.clampAdvance(advance.value, totalFee);
    if (capped != advance.value) {
      advance.value = capped;
      _writeAdvance(capped);
    }
  }

  void _writeAdvance(int value) {
    final text = value.toString();
    advanceCtrl.value = TextEditingValue(
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
    advance.value = b.amountCollected;
    _writeAdvance(b.amountCollected);
  }

  /// Copies customer, sport and court to today, pre-selecting the same times when still free.
  /// Returns how many of the original slots could be pre-selected.
  int loadForRepeat(Booking b) {
    _clear();
    _fillCustomer(b);
    sport.value = b.sport;
    courtId.value = b.courtId;
    date.value = dateOnly(_service.now());
    final free = b.slots.where((s) => BookingRules.validateSlots([s], date: date.value, now: _service.now(), occupied: occupied) == null).toList();
    if (free.isNotEmpty) _applySlots(free);
    return free.length;
  }

  void _fillCustomer(Booking b) {
    nameCtrl.text = b.customerName;
    phoneCtrl.text = b.phone;
    emailCtrl.text = b.email;
    notesCtrl.text = b.notes;
  }

  void _applySlots(List<TimeRange> slots) {
    final allPreset = slots.every(BookingRules.presetSlots.contains);
    if (allPreset) {
      mode.value = SlotMode.preset;
      selectedSlots.assignAll(slots);
    } else {
      mode.value = SlotMode.custom;
      customStart.value = slots.first.startMinute;
      customEnd.value = slots.last.endMinute;
    }
  }

  void _clear() {
    _original = null;
    editingId.value = null;
    for (final c in [nameCtrl, phoneCtrl, emailCtrl, notesCtrl]) {
      c.clear();
    }
    selectedSlots.clear();
    mode.value = SlotMode.preset;
    customStart.value = 13 * 60 + 30;
    customEnd.value = 14 * 60 + 30;
    date.value = dateOnly(_service.now());
    advance.value = 0;
    _writeAdvance(0);
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
