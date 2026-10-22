import 'time_range.dart';

/// A named, fixed booking time (e.g. "Dinner", 7PM - 11PM). End may pass midnight.
class BookingSession {
  const BookingSession(this.label, this.time);

  final String label;
  final TimeRange time;
}

/// When and for how long a business can be booked. Data only (numbers, labels), so it can be stored later.
class BookingPolicy {
  const BookingPolicy({
    this.step = 30,
    this.minDuration = 30,
    this.maxDuration = TimeRange.minutesPerDay,
    this.defaultDuration = 60,
    this.openHours,
    this.sessions = const [],
    this.offersFullDay = false,
  }) : assert(step > 0 && 360 % step == 0, 'step must divide 6 hours (15, 30 or 60)'),
       assert(minDuration >= step && minDuration % step == 0 && maxDuration % step == 0),
       assert(maxDuration <= TimeRange.minutesPerDay && minDuration <= defaultDuration && defaultDuration <= maxDuration);

  /// Start times and durations move in steps of this many minutes.
  final int step;
  final int minDuration;
  final int maxDuration; // 24 h at most
  final int defaultDuration; // the form's starting duration

  /// null = open 24 hours. The end may pass midnight: 4PM - 2AM is TimeRange(960, 1560).
  final TimeRange? openHours;

  /// When set, only these whole sessions can be booked (no free start time or duration).
  final List<BookingSession> sessions;

  /// Shows a "Full day" shortcut next to the duration: 24 hours from the chosen start, priced like any other booking.
  final bool offersFullDay;

  bool get usesSessions => sessions.isNotEmpty;

  /// Open time on one day's timeline: today's hours plus the previous day's hours that run past midnight.
  List<TimeRange> get openWindows {
    final hours = openHours;
    if (hours == null) return const [TimeRange(0, TimeRange.maxMinute)];
    return [hours, ?hours.shift(1)]; // `?`: left out when the hours don't pass midnight
  }

  /// Parts of the day (0..24h) the business is closed, for greying out the day bar.
  List<TimeRange> get closedToday {
    if (openHours == null) return const [];
    final closed = <TimeRange>[];
    var from = 0;
    for (final w in [...openWindows]..sort()) {
      if (w.startMinute > from) closed.add(TimeRange(from, w.startMinute.clamp(from, TimeRange.minutesPerDay)));
      if (w.endMinute > from) from = w.endMinute;
    }
    if (from < TimeRange.minutesPerDay) closed.add(TimeRange(from, TimeRange.minutesPerDay));
    return closed;
  }

  /// Closing time for a booking that starts at [start], or null when closed then.
  int? closingFor(int start) {
    for (final w in openWindows) {
      if (w.startMinute <= start && start < w.endMinute) return w.endMinute;
    }
    return null;
  }

  /// A booking of at least [minDuration] can start here (on a step, inside opening hours).
  bool canStartAt(int start) {
    final closes = closingFor(start);
    return start % step == 0 && closes != null && start + minDuration <= closes;
  }

  /// Whether [range] is inside one opening window.
  bool isOpenFor(TimeRange range) => openWindows.any((w) => w.startMinute <= range.startMinute && range.endMinute <= w.endMinute);
}
