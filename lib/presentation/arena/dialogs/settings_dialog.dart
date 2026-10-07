import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/service/service_handler.dart/theme_store.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../data/models/sport.dart';
import '../widgets/arena_widgets.dart';
import 'arena_dialog.dart';

/// Theme, currency and hourly rates. Theme applies instantly; the rest on "Save & Close",
/// so a half-typed rate (the "1" of "1500") is never used for a booking.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show() => ArenaDialog.show(const SettingsDialog());

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _settings = SettingsStore.to;
  late final _currency = TextEditingController(text: _settings.currencySymbol.value);

  /// One rate field per offered sport.
  late final _rates = {for (final s in Sport.offered) s: TextEditingController(text: '${_settings.rateFor(s)}')};
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currency.dispose();
    for (final c in _rates.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _rateError(String? v) {
    final rate = int.tryParse(v ?? '');
    if (rate == null || rate <= 0) return 'Enter a rate above 0';
    if (rate > SettingsStore.maxHourlyRate) return 'Rate is too high';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _settings.saveCurrency(_currency.text);
    for (final e in _rates.entries) {
      await _settings.saveRate(e.key, int.parse(e.value.text));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ArenaToast.success('Settings saved');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final rateFormatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)];

    return ArenaDialog(
      title: 'App Settings',
      icon: Icons.settings_rounded,
      actions: [GradientButton(label: 'Save & Close', compact: true, onPressed: _save)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('App Color Theme', style: context.text.titleSmall),
                        Text('Switch Light Mode or Dark Mode', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Obx(() {
                    final dark = ThemeStore.to.isDarkMode.value;
                    return SoftButton(
                      label: dark ? 'Dark Mode' : 'Light Mode',
                      icon: dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      tone: dark ? SoftTone.success : SoftTone.warning,
                      onPressed: () => ThemeStore.to.isDarkMode.save(!dark),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const FieldLabel('Currency Symbol'),
            TextFormField(
              controller: _currency,
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              style: context.text.bodyMedium?.copyWith(color: c.cricketText, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(hintText: 'e.g. Rs, \$, AED', counterText: ''),
            ),
            const SizedBox(height: 12),
            // Two rate fields per row, one per offered sport.
            LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final e in _rates.entries)
                    SizedBox(
                      width: _rates.length == 1 ? box.maxWidth : (box.maxWidth - 10) / 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FieldLabel('${e.key.shortLabel} Rate / Hr'),
                          TextFormField(controller: e.value, keyboardType: TextInputType.number, inputFormatters: rateFormatters, validator: _rateError),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New rates apply to new bookings. Existing bookings keep the rate they were made with.',
              style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
