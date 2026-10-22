import 'package:flutter/services.dart' show appFlavor;

import '../../data/models/booking_policy.dart';
import '../../data/models/pricing.dart';
import '../../data/models/resource.dart';
import 'business/business_profile.dart';
import 'clients/client_config.dart';

class AppClientConfig {
  // Base URLs ------------------- (fill these per project)
  static String baseUrl = '';
  static String stageBaseUrl = '';
  static String localBaseUrl = '';

  /// Remote trial switch for every client, keyed by client id (see AppAccess). Raw link without a revision id = always the latest version.
  static const accessConfigUrl = 'https://gist.githubusercontent.com/IamShahabAlam/017400e59bb8e4b791864f7971aa42fe/raw/ArenaBookConfig.json';

  // Client -------------------
  /// The client this build is for, picked by `--flavor <id>` (configs live in clients/).
  static final client = ClientConfig.forFlavor(appFlavor);

  /// Discount field in the booking form and discount lines on invoices. (Not final: tests toggle it.)
  static bool enableDiscount = client.enableDiscount;

  /// The client's resource types and their resources; the whole app follows this list. (Not final: tests swap it.)
  static List<ResourceType> resourceTypes = client.resourceTypes;

  /// The client's kind of business: wording now, time policy and features later. (Not final: tests swap it.)
  static BusinessProfile profile = client.profile;

  /// What this business calls its bookings, resources, customers and fee.
  static Terms get terms => profile.terms;

  /// Time rules: the client's own, else its profile's. (Not final: tests swap it.)
  static BookingPolicy policy = client.policy ?? client.profile.policy;

  /// Pricing for new bookings: the client's own, else its profile's. (Not final: tests swap it.)
  static PricingMode pricing = client.pricing ?? client.profile.pricing;
}
