/// A time window inside one day, stored as minutes since midnight (0..1440).
///
/// Comparing numbers instead of strings like "08:00 PM - 09:00 PM" is what makes
/// overlap checks correct: 20:30-21:30 overlaps both the 20:00 and the 21:00 hourly slot.
class TimeRange implements Comparable<TimeRange> {
  const TimeRange(this.startMinute, this.endMinute) : assert(startMinute >= 0 && endMinute <= minutesPerDay && endMinute > startMinute);

  factory TimeRange.hour(int startHour) => TimeRange(startHour * 60, (startHour + 1) * 60);

  static const minutesPerDay = 24 * 60;

  /// Returns null instead of throwing, for values coming from user input or storage.
  static TimeRange? tryCreate(int startMinute, int endMinute) {
    if (startMinute < 0 || endMinute > minutesPerDay || endMinute <= startMinute) return null;
    return TimeRange(startMinute, endMinute);
  }

  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;

  /// Touching ranges (09:00-10:00 and 10:00-11:00) do NOT overlap.
  bool overlaps(TimeRange other) => startMinute < other.endMinute && other.startMinute < endMinute;

  DateTime startOn(DateTime day) => DateTime(day.year, day.month, day.day).add(Duration(minutes: startMinute));
  DateTime endOn(DateTime day) => DateTime(day.year, day.month, day.day).add(Duration(minutes: endMinute));

  /// Concise label: "9AM - 10AM", "1:30PM - 2:30PM".
  String get label => '${formatMinute(startMinute)} - ${formatMinute(endMinute)}';

  static String formatMinute(int minute) {
    final h24 = (minute ~/ 60) % 24;
    final m = minute % 60;
    final suffix = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return m == 0 ? '$h12$suffix' : '$h12:${m.toString().padLeft(2, '0')}$suffix';
  }

  Map<String, dynamic> toJson() => {'start': startMinute, 'end': endMinute};

  static TimeRange? fromJson(Map json) => tryCreate((json['start'] as num).toInt(), (json['end'] as num).toInt());

  @override
  int compareTo(TimeRange other) => startMinute != other.startMinute ? startMinute.compareTo(other.startMinute) : endMinute.compareTo(other.endMinute);

  @override
  bool operator ==(Object other) => other is TimeRange && other.startMinute == startMinute && other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(startMinute, endMinute);

  @override
  String toString() => 'TimeRange($label)';
}
