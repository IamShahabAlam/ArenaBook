import '../../../data/models/booking_policy.dart';
import '../../../data/models/pricing.dart';
import '../../../data/models/time_range.dart';
import 'business_profile.dart';

// One profile per kind of business. A client picks one in its config (and may override its policy or pricing).

/// Indoor sports arenas: ArenaBook's original wording and time rules (30-minute steps, open 24 hours).
const sportsVenue = BusinessProfile(
  id: 'sports_venue',
  terms: Terms(
    subject: 'Ground',
    resource: 'Court',
    resources: 'Courts',
    resourceType: 'Sport',
    customer: 'Player',
    fee: 'Ground Fee',
    place: 'arena',
    passHint: 'Show at arena entry',
    receiptThanks: 'Thank you for playing at ArenaBook grounds! Present this receipt at entry.',
    cancelReasonHint: 'e.g. Player requested cancellation due to rain',
  ),
  policy: BookingPolicy(),
);

/// Anything rented by the hour: guest rooms, workspaces, meeting rooms, studios, shops.
/// Open 24 hours, 1 hour minimum, 2 hours by default, up to a full day; always priced by the hour.
const spaceRental = BusinessProfile(
  id: 'space_rental',
  terms: Terms(
    subject: 'Space',
    resource: 'Space',
    resources: 'Spaces',
    resourceType: 'Property',
    customer: 'Customer',
    fee: 'Rental Fee',
    place: 'property',
    passHint: 'Show at reception',
    receiptThanks: 'Thank you for booking with us! Show this receipt at reception.',
    cancelReasonHint: 'e.g. Customer changed their plans',
  ),
  policy: BookingPolicy(step: 60, minDuration: 60, defaultDuration: 120, offersFullDay: true),
);

/// Banquet halls, marquees and event lawns: whole sessions only, at a price the owner types per booking.
const eventVenue = BusinessProfile(
  id: 'event_venue',
  terms: Terms(
    subject: 'Event',
    resource: 'Hall',
    resources: 'Halls',
    resourceType: 'Venue',
    customer: 'Client',
    fee: 'Venue Fee',
    place: 'venue',
    passHint: 'Show at the venue entrance',
    receiptThanks: 'Thank you for choosing us for your event! Show this receipt at the venue.',
    cancelReasonHint: 'e.g. Client postponed the event',
  ),
  policy: BookingPolicy(
    step: 60,
    minDuration: 60,
    defaultDuration: 4 * 60,
    sessions: [
      BookingSession('Lunch', TimeRange(12 * 60, 18 * 60)),
      BookingSession('Dinner', TimeRange(19 * 60, 24 * 60)),
      BookingSession('Full Day', TimeRange(10 * 60, 23 * 60)),
    ],
  ),
  pricing: PricingMode.manual,
);

/// Car, bike and van hire: hourly, 1 hour minimum, any time of day (up to 24 hours per booking).
const vehicleRental = BusinessProfile(
  id: 'vehicle_rental',
  terms: Terms(
    subject: 'Rental',
    resource: 'Vehicle',
    resources: 'Vehicles',
    resourceType: 'Vehicle',
    customer: 'Customer',
    fee: 'Rental Fee',
    place: 'business',
    passHint: 'Show at vehicle pickup',
    receiptThanks: 'Thank you for renting with us! Show this receipt at pickup.',
    cancelReasonHint: 'e.g. Customer changed travel plans',
  ),
  policy: BookingPolicy(step: 60, minDuration: 60, defaultDuration: 120),
);

/// Every profile, for tests and a future setup screen.
const allProfiles = [sportsVenue, spaceRental, eventVenue, vehicleRental];
