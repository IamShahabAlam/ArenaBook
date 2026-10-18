import 'package:flutter/services.dart' show appFlavor;

import '../../data/models/sport.dart';
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

  /// The arena's sports and their courts; the whole app follows this list. (Not final: tests swap it.)
  static List<Sport> sports = client.sports;
}
