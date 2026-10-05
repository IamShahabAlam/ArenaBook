import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';
import '../../../data/models/time_range.dart';
import '../../../data/rules/booking_rules.dart';
import '../shell/booking_actions.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/motion.dart';
import 'booking_form_controller.dart';

class BookingFormView extends GetView<BookingFormController> {
  const BookingFormView({super.key});

  Future<void> _submit() async {
    final saved = await controller.submit();
    if (saved != null) await BookingActions.openInvoice(saved.id, afterSubmit: true);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: ListView(
        controller: controller.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          const _FormHeader(),
          const SizedBox(height: 16),
          const _SportPicker(),
          const SizedBox(height: 14),
          const _CourtPicker(),
          const SizedBox(height: 16),
          const _DatePicker(),
          const SizedBox(height: 16),
          const _SlotPicker(),
          const SizedBox(height: 16),
          const _CustomerCard(),
          const SizedBox(height: 14),
          const _PaymentCard(),
          const SizedBox(height: 18),
          Obx(
            () => GradientButton(
              label: controller.isEditing ? 'Save Changes & View Invoice' : 'Confirm & Generate Invoice',
              icon: Icons.check_circle_rounded,
              loading: controller.submitting.value,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormHeader extends GetView<BookingFormController> {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Obx(() {
      final editing = controller.isEditing;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(editing ? 'Edit Booking (#${controller.editingId.value})' : 'Create New Booking', style: context.text.titleLarge),
                const SizedBox(height: 2),
                Text(editing ? 'Modify timing, details or payments' : 'Select sport, timing, customer details & advance', style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ArenaBadge(label: editing ? 'Editing' : 'New Entry', color: editing ? c.padelText : c.textSecondary),
              if (editing)
                TextButton(
                  onPressed: controller.discardEdit,
                  style: TextButton.styleFrom(foregroundColor: c.dangerText, visualDensity: VisualDensity.compact),
                  child: const Text('Discard'),
                ),
            ],
          ),
        ],
      );
    });
  }
}

class _SportPicker extends GetView<BookingFormController> {
  const _SportPicker();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Select Sport Category'),
        Obx(() {
          final selected = controller.sport.value;
          // read rates so the labels update when settings change
          final settings = SettingsStore.to;
          return Row(
            children: [
              for (final s in Sport.values) ...[
                if (s != Sport.values.first) const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    selected: s == selected,
                    button: true,
                    child: ArenaCard(
                      onTap: () => controller.selectSport(s),
                      borderColor: s == selected ? s.fill(c) : null,
                      gradient: s == selected ? ArenaCard.tint(context, s.fill(c)) : null,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        children: [
                          SportAvatar(sport: s, size: 42, bordered: true),
                          const SizedBox(height: 8),
                          Text(s.label, style: context.text.titleSmall?.copyWith(color: s == selected ? c.textPrimary : c.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${ArenaFormat.money(s == Sport.cricket ? settings.cricketHourlyRate.value : settings.padelHourlyRate.value)} / Hr',
                            style: context.text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

class _CourtPicker extends GetView<BookingFormController> {
  const _CourtPicker();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Select Court / Pitch'),
        Obx(() {
          final courts = Court.forSport(controller.sport.value);
          return DropdownButtonFormField<String>(
            // Key by sport: the options change completely when the sport changes.
            key: ValueKey(controller.sport.value),
            initialValue: controller.courtId.value,
            isExpanded: true,
            dropdownColor: c.surface,
            borderRadius: BorderRadius.circular(14),
            icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
            style: context.text.bodyMedium,
            items: [
              for (final court in courts)
                DropdownMenuItem(
                  value: court.id,
                  child: Text(court.description, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) controller.selectCourt(id);
            },
          );
        }),
      ],
    );
  }
}

class _DatePicker extends GetView<BookingFormController> {
  const _DatePicker();

  Future<void> _pickCustom(BuildContext context) async {
    final today = dateOnly(BookingService.to.now());
    final current = controller.date.value;
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      initialDate: current.isBefore(today) ? today : current,
      helpText: 'Pick future booking date',
    );
    if (picked != null) controller.selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(
          'Date Selection',
          trailing: TextButton.icon(
            onPressed: () => _pickCustom(context),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            icon: const Icon(Icons.edit_calendar_rounded, size: 15),
            label: const Text('Custom Date'),
          ),
        ),
        SizedBox(
          height: 74,
          child: Obx(() {
            final today = dateOnly(BookingService.to.now());
            final selected = controller.date.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = DateTime(today.year, today.month, today.day + i);
                final active = isSameDay(day, selected);
                final top = i == 0 ? 'Today' : (i == 1 ? 'Tmrw' : ArenaFormat.weekdayShort(day));
                return Semantics(
                  button: true,
                  selected: active,
                  label: ArenaFormat.relativeDay(day, today),
                  excludeSemantics: true,
                  // No lift here: the fixed-height carousel would clip a scaled chip.
                  child: AnimatedTile(
                    color: active ? c.cricket : c.surfaceMuted,
                    borderColor: active ? c.cricket : c.border,
                    radius: 16,
                    onTap: () => controller.selectDate(day),
                    child: SizedBox(
                      width: 62,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(top.toUpperCase(), style: context.text.labelSmall?.copyWith(color: active ? c.onAccent : c.textSecondary)),
                          Text('${day.day}', style: context.text.titleLarge?.copyWith(color: active ? c.onAccent : c.textPrimary)),
                          Text(
                            ArenaFormat.monthShort(day).toUpperCase(),
                            style: context.text.labelSmall?.copyWith(color: active ? c.onAccent : c.textMuted, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final day = controller.date.value;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.cricket.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.cricket.withValues(alpha: 0.3)),
            ),
            child: Text.rich(
              TextSpan(
                text: 'Selected Date: ',
                children: [
                  TextSpan(
                    text: '${ArenaFormat.relativeDay(day, BookingService.to.now())} · ${ArenaFormat.longDate(day)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              style: context.text.labelMedium?.copyWith(color: c.cricketText),
            ),
          );
        }),
      ],
    );
  }
}

class _SlotPicker extends GetView<BookingFormController> {
  const _SlotPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Time Slot Mode', style: context.text.labelMedium?.copyWith(color: context.arena.textSecondary)),
            ),
            SizedBox(
              width: 210,
              child: Obx(
                () => ArenaSegmented<SlotMode>(
                  dense: true,
                  selected: controller.mode.value,
                  onChanged: controller.setMode,
                  options: const [SegmentOption(SlotMode.preset, 'Preset Slots'), SegmentOption(SlotMode.custom, 'Custom Range')],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() => controller.mode.value == SlotMode.preset ? const _PresetGrid() : const _CustomRange()),
      ],
    );
  }
}

class _PresetGrid extends GetView<BookingFormController> {
  const _PresetGrid();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Obx(() {
      // Touch the reactive inputs so this rebuilds when any of them change.
      controller.selectedSlots.length;
      controller.date.value;
      controller.courtId.value;
      BookingService.to.bookings.length;

      return GridView.count(
        crossAxisCount: 3,
        clipBehavior: Clip.none, // let a selected chip's 4% lift show at the grid edges
        padding: EdgeInsets.zero, // without it the grid inherits the nav bar inset (see home_view)
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.3,
        children: [
          for (final slot in BookingRules.presetSlots)
            Builder(
              builder: (context) {
                final state = controller.slotState(slot);
                final (bg, fg, border, tag) = switch (state) {
                  SlotState.selected => (c.cricket, c.onAccent, c.cricket, null),
                  SlotState.available => (c.surfaceMuted, c.textPrimary, c.border, null),
                  SlotState.booked => (c.danger.withValues(alpha: 0.08), c.dangerText, c.danger.withValues(alpha: 0.3), 'BOOKED'),
                  SlotState.past => (c.surfaceMuted.withValues(alpha: 0.5), c.textMuted, c.border.withValues(alpha: 0.5), 'PAST'),
                };
                final enabled = state == SlotState.available || state == SlotState.selected;
                return Semantics(
                  button: true,
                  enabled: enabled,
                  selected: state == SlotState.selected,
                  label: '${slot.label}${tag == null ? '' : ', ${tag.toLowerCase()}'}',
                  excludeSemantics: true,
                  child: Opacity(
                    opacity: state == SlotState.past ? 0.55 : 1,
                    child: AnimatedTile(
                      color: bg,
                      borderColor: border,
                      selected: state == SlotState.selected,
                      onTap: enabled
                          ? () {
                              HapticFeedback.selectionClick();
                              controller.toggleSlot(slot);
                            }
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TimeRange.formatMinute(slot.startMinute),
                            style: context.text.labelMedium?.copyWith(color: fg, fontWeight: state == SlotState.selected ? FontWeight.w800 : FontWeight.w600),
                          ),
                          if (tag != null)
                            Text(
                              tag,
                              style: context.text.labelSmall?.copyWith(color: fg, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      );
    });
  }
}

class _CustomRange extends GetView<BookingFormController> {
  const _CustomRange();

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final minute = start ? controller.customStart.value : controller.customEnd.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (minute ~/ 60) % 24, minute: minute % 60),
      helpText: start ? 'Start time' : 'End time',
    );
    if (picked == null) return;
    start ? controller.setCustomStart(picked) : controller.setCustomEnd(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    Widget timeBox(String label, int minute, VoidCallback onTap) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSmall),
          const SizedBox(height: 4),
          Material(
            color: c.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: c.cricketText),
                    const SizedBox(width: 8),
                    Text(TimeRange.formatMinute(minute), style: context.text.labelLarge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return ArenaCard(
      padding: const EdgeInsets.all(12),
      child: Obx(() {
        BookingService.to.bookings.length; // re-check conflicts when bookings change
        final error = controller.customRangeError;
        final range = controller.customRange;
        return Column(
          children: [
            Row(
              children: [
                timeBox('Start Time', controller.customStart.value, () => _pick(context, start: true)),
                const SizedBox(width: 10),
                timeBox('End Time', controller.customEnd.value, () => _pick(context, start: false)),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: c.border),
            const SizedBox(height: 8),
            Text(
              error ?? 'Duration: ${ArenaFormat.hours(range!.durationMinutes)} · Computed Fee: ${ArenaFormat.money(controller.totalFee)}',
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(color: error == null ? c.cricketText : c.dangerText),
            ),
          ],
        );
      }),
    );
  }
}

class _CustomerCard extends GetView<BookingFormController> {
  const _CustomerCard();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return ArenaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Customer Details', icon: Icons.person_rounded, iconColor: c.cricketText),
          const SizedBox(height: 12),
          const FieldLabel('Full Name *'),
          TextFormField(
            controller: controller.nameCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 60,
            autofillHints: const [AutofillHints.name],
            validator: (v) => BookingRules.validateName(v ?? ''),
            decoration: const InputDecoration(hintText: 'e.g. Zain Malik', counterText: ''),
          ),
          const SizedBox(height: 12),
          const FieldLabel('WhatsApp / Phone * (max 11 digits)'),
          TextFormField(
            controller: controller.phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(BookingRules.maxPhoneLength)],
            validator: (v) => BookingRules.validatePhone(v ?? ''),
            decoration: const InputDecoration(hintText: '03001234567'),
          ),
          const SizedBox(height: 12),
          const FieldLabel('Email (Optional)'),
          TextFormField(
            controller: controller.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) => BookingRules.validateEmail(v ?? ''),
            decoration: const InputDecoration(hintText: 'zain@example.com'),
          ),
          const SizedBox(height: 12),
          FieldLabel(
            'Notes / Remarks',
            trailing: Obx(
              () => Text('${controller.notesLength.value}/${BookingRules.maxNotesLength}', style: context.text.labelSmall?.copyWith(color: c.textMuted)),
            ),
          ),
          TextFormField(
            controller: controller.notesCtrl,
            minLines: 1,
            maxLines: 4, // grows with the text
            maxLength: BookingRules.maxNotesLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. Needs extra padel rackets', counterText: ''),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends GetView<BookingFormController> {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return ArenaCard(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final total = controller.totalFee;
        final rate = controller.hourlyRate;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Total Ground Fee', style: context.text.bodySmall)),
                AnimatedNumber(value: total, format: ArenaFormat.money, style: context.text.titleLarge),
              ],
            ),
            if (controller.totalMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${ArenaFormat.hours(controller.totalMinutes)} × ${ArenaFormat.money(rate)}/hr',
                  style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 10),
            Divider(color: c.border),
            const SizedBox(height: 10),
            const FieldLabel('Select Advance Preset'),
            Row(
              children: [
                for (final p in const [0, 25, 50, 100]) ...[
                  if (p != 0) const SizedBox(width: 6),
                  Expanded(
                    child: SoftButton(label: '$p%', onPressed: total == 0 && p != 0 ? null : () => controller.setAdvancePercent(p)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.isEditing ? 'Amount Received' : 'Advance Paid', style: context.text.labelSmall),
                      const SizedBox(height: 4),
                      TextField(
                        controller: controller.advanceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                        onChanged: controller.onAdvanceChanged,
                        style: context.text.labelLarge?.copyWith(color: c.cricketText),
                        decoration: InputDecoration(prefixText: '${SettingsStore.to.currencySymbol.value} '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remaining Balance', style: context.text.labelSmall),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.warning.withValues(alpha: 0.35)),
                        ),
                        child: AnimatedNumber(
                          value: controller.balance,
                          format: ArenaFormat.money,
                          style: context.text.labelLarge?.copyWith(color: c.warningText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
