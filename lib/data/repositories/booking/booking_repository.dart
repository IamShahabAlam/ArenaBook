import 'package:hive_ce/hive.dart';

import '../../../app/utils/custom_functions/logger.dart';
import '../../models/booking.dart';

/// Where bookings are persisted. The app only talks to this interface, so a cloud implementation
/// (Supabase / Firebase / own API) can replace [HiveBookingRepository] without touching any screen.
abstract class BookingRepository {
  Future<List<Booking>> loadAll();

  /// Inserts or replaces the booking with the same id.
  Future<void> save(Booking booking);

  /// Next unique, human-readable reference: TRF-1001, TRF-1002, ...
  Future<String> nextId();
}

/// Local, offline storage (Hive). Each booking is one JSON map keyed by its id.
class HiveBookingRepository implements BookingRepository {
  HiveBookingRepository._(this._bookings, this._meta);

  static const bookingsBoxName = 'bookings';
  static const metaBoxName = 'bookings_meta';
  static const _lastNumberKey = 'lastBookingNumber';
  static const _firstNumber = 1000;

  final Box<Map> _bookings;
  final Box _meta;

  /// Hive must already be initialised (InitBindings does it).
  static Future<HiveBookingRepository> open() async {
    final bookings = await Hive.openBox<Map>(bookingsBoxName);
    final meta = await Hive.openBox(metaBoxName);
    return HiveBookingRepository._(bookings, meta);
  }

  @override
  Future<List<Booking>> loadAll() async {
    final result = <Booking>[];
    for (final key in _bookings.keys) {
      try {
        result.add(Booking.fromJson(_bookings.get(key)!));
      } catch (e) {
        // One corrupt record must not take the whole ledger down; it stays on disk for recovery.
        Logger.logs('Skipping unreadable booking $key: $e');
      }
    }
    return result;
  }

  @override
  Future<void> save(Booking booking) => _bookings.put(booking.id, booking.toJson());

  @override
  Future<String> nextId() async {
    var number = (_meta.get(_lastNumberKey) as int?) ?? _firstNumber;
    String id;
    do {
      number++;
      id = 'TRF-$number';
    } while (_bookings.containsKey(id)); // guards against a lost counter (e.g. restored backup)
    await _meta.put(_lastNumberKey, number);
    return id;
  }
}

/// In-memory implementation for tests and previews.
class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository([Iterable<Booking> initial = const []]) {
    for (final b in initial) {
      _store[b.id] = b;
    }
  }

  final _store = <String, Booking>{};
  var _last = 1000;

  @override
  Future<List<Booking>> loadAll() async => _store.values.toList();

  @override
  Future<void> save(Booking booking) async => _store[booking.id] = booking;

  @override
  Future<String> nextId() async {
    String id;
    do {
      id = 'TRF-${++_last}';
    } while (_store.containsKey(id));
    return id;
  }
}
