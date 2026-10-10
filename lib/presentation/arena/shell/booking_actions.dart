import 'package:flutter/material.dart';

import '../../../app/service/getx_service/app_access_service.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../booking_form/booking_form_controller.dart';
import '../dialogs/arena_dialog.dart';
import '../dialogs/cancel_booking_dialog.dart';
import '../invoice/invoice_sheet.dart';
import 'shell_controller.dart';

/// Every booking action goes through here, so cards, invoice and pending list behave identically.
class BookingActions {
  BookingActions._();

  // newBooking/edit/repeat re-check the trial switch, in case the blocking dialog was ever bypassed.
  static void newBooking({DateTime? onDate}) {
    if (!AppAccessService.to.allows()) return;
    BookingFormController.to.startNew(onDate: onDate);
    ShellController.to.go(ArenaTab.addBooking);
  }

  static void edit(String id) {
    if (!AppAccessService.to.allows()) return;
    final b = BookingService.to.byId(id);
    if (b == null) return;
    if (!b.canEdit(BookingService.to.now())) {
      ArenaToast.error('Only upcoming, active bookings can be edited');
      return;
    }
    BookingFormController.to.loadForEdit(b);
    ShellController.to.go(ArenaTab.addBooking);
    ArenaToast.show('Editing booking #${b.id}');
  }

  static void repeat(String id) {
    if (!AppAccessService.to.allows()) return;
    final b = BookingService.to.byId(id);
    if (b == null) return;
    final kept = BookingFormController.to.loadForRepeat(b);
    ShellController.to.go(ArenaTab.addBooking);
    ArenaToast.show(
      kept
          ? 'Refilled ${b.customerName} for today, same time. Please confirm.'
          : 'Refilled details for ${b.customerName}. Please choose an available time slot.',
    );
  }

  /// [afterSubmit]: the spec sends the owner back to Home once the new invoice is closed.
  /// Opened from a list, closing returns to that list so filters and scroll are kept.
  static Future<void> openInvoice(String id, {bool afterSubmit = false}) async {
    await InvoiceSheet.show(id);
    if (afterSubmit) ShellController.to.go(ArenaTab.home);
  }

  /// Asks first: recording money as received can't be undone, and a stray tap would skew revenue.
  static Future<bool> markPaid(String id) async {
    final current = BookingService.to.byId(id);
    if (current == null || current.balanceDue == 0) return false;
    final confirmed = await ConfirmDialog.ask(
      title: 'Mark as Paid?',
      message: 'Record ${ArenaFormat.money(current.balanceDue)} received from ${current.customerName} for #${current.id}?',
      confirmLabel: 'Mark Paid',
      icon: Icons.done_all_rounded,
    );
    if (!confirmed) return false;
    try {
      final b = await BookingService.to.markPaid(id);
      ArenaToast.success('Marked #${b.id} as Paid in Full');
      return true;
    } on BookingException catch (e) {
      ArenaToast.error(e.message);
    } catch (_) {
      ArenaToast.error('Could not update the payment. Please try again.');
    }
    return false;
  }

  static Future<void> cancel(String id) async {
    final b = BookingService.to.byId(id);
    if (b == null || b.isCancelled) return;
    await CancelBookingDialog.show(b);
  }
}
