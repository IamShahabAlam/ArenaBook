import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/config/app_strings.dart';
import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../booking_form/booking_form_view.dart';
import '../bookings/bookings_view.dart';
import '../calendar/calendar_view.dart';
import '../dialogs/info_dialogs.dart';
import '../dialogs/settings_dialog.dart';
import '../home/home_view.dart';
import '../pending/pending_view.dart';
import '../widgets/arena_widgets.dart';
import 'booking_actions.dart';
import 'shell_controller.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!controller.handleBack()) SystemNavigator.pop();
      },
      child: Scaffold(
        key: controller.scaffoldKey,
        extendBody: true, // content scrolls behind the translucent nav bar
        drawer: const _ArenaDrawer(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _ArenaHeader(),
              Expanded(
                child: Obx(
                  () => IndexedStack(
                    index: controller.tab.value.index,
                    children: const [HomeView(), BookingsView(), BookingFormView(), PendingView(), CalendarView()],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const _ArenaBottomNav(),
        backgroundColor: c.background,
      ),
    );
  }
}

class _ArenaHeader extends StatelessWidget {
  const _ArenaHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          HeaderIconButton(icon: Icons.menu_rounded, tooltip: 'Menu', onPressed: () => ShellController.to.scaffoldKey.currentState?.openDrawer()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Wordmark(size: 15),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: c.cricket, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Obx(() => Text(ArenaFormat.shortDay(BookingService.to.now()), style: context.text.labelSmall)),
                  ],
                ),
              ],
            ),
          ),
          HeaderIconButton(icon: Icons.tune_rounded, tooltip: 'Settings', onPressed: SettingsDialog.show),
          const SizedBox(width: 8),
          HeaderIconButton(icon: Icons.add_rounded, tooltip: 'New booking', accent: true, onPressed: BookingActions.newBooking),
        ],
      ),
    );
  }
}

/// "ARENA" + emerald "BOOK".
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final style = context.text.titleMedium?.copyWith(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: 0.4);
    return Text.rich(
      TextSpan(
        text: 'ARENA',
        children: [
          TextSpan(
            text: 'BOOK',
            style: TextStyle(color: c.cricketText),
          ),
        ],
      ),
      style: style,
    );
  }
}

class _ArenaBottomNav extends GetView<ShellController> {
  const _ArenaBottomNav();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 68 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: c.navBar,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Obx(() {
        final current = controller.tab.value;
        final hasDues = BookingService.to.bookings.any((b) => b.balanceDue > 0);
        Widget item(ArenaTab tab, IconData icon, IconData activeIcon, String label, {bool dot = false}) => Expanded(
          child: _NavItem(icon: current == tab ? activeIcon : icon, label: label, active: current == tab, dot: dot, onTap: () => controller.go(tab)),
        );
        return Row(
          children: [
            item(ArenaTab.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
            item(ArenaTab.bookings, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Bookings'),
            Expanded(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -14),
                  child: Semantics(
                    button: true,
                    label: 'New booking',
                    child: GestureDetector(
                      onTap: BookingActions.newBooking,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: ArenaColors.ctaGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.background, width: 4),
                          boxShadow: [BoxShadow(color: ArenaColors.emerald.withValues(alpha: 0.35), blurRadius: 18)],
                        ),
                        child: Icon(current == ArenaTab.addBooking ? Icons.edit_note_rounded : Icons.add_rounded, color: c.onAccent, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            item(ArenaTab.pending, Icons.history_rounded, Icons.history_rounded, 'Pending', dot: hasDues),
            item(ArenaTab.calendar, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendar'),
          ],
        );
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap, this.dot = false});

  final IconData icon;
  final String label;
  final bool active;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final color = active ? c.cricketText : c.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: dot ? '$label, payments due' : label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 23),
                if (dot)
                  Positioned(
                    right: -3,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.navBar, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaDrawer extends StatelessWidget {
  const _ArenaDrawer();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;

    Widget item(IconData icon, Color iconColor, String label, Future<void> Function() open) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(label, style: context.text.labelLarge),
          trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
          onTap: () {
            Navigator.of(context).pop(); // close drawer first
            open();
          },
        ),
      ),
    );

    return Drawer(
      width: 300,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(gradient: ArenaColors.ctaGradient, borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.emoji_events_rounded, color: c.onAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Wordmark(size: 16),
                        Text('Ground Management', style: context.text.labelSmall?.copyWith(color: c.cricketText)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: c.border),
              const SizedBox(height: 16),
              item(Icons.settings_rounded, c.cricketText, 'Settings & Preferences', SettingsDialog.show),
              item(Icons.info_rounded, c.padelText, 'About Us & Dev Details', AboutArenaDialog.show),
              item(Icons.support_agent_rounded, c.warningText, 'Contact Support', SupportDialog.show),
              const Spacer(),
              Divider(color: c.border),
              const SizedBox(height: 12),
              Center(
                child: Text('${AppStrings.appName} Platform', style: context.text.labelMedium?.copyWith(color: c.textSecondary)),
              ),
              Center(
                child: Text(
                  'App Version ${AppStrings.kappVersionWithDate} (Build ${AppStrings.kappBuildNumber})',
                  style: context.text.labelSmall?.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
