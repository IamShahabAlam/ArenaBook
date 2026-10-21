import '../../../data/models/resource.dart';
import 'demo.dart';

/// Everything that differs between clients. One file per client in this folder; `--flavor <id>` picks it.
class ClientConfig {
  const ClientConfig({required this.id, required this.resourceTypes, this.currency = 'Rs', this.countryCode = '92', this.enableDiscount = true});

  /// Flavor name and this client's key in the access Gist. Lowercase letters, digits and `_`; never change once shipped.
  final String id;

  /// The client's resource types (e.g. sports) and their resources (e.g. courts); the whole app follows this list.
  final List<ResourceType> resourceTypes;

  /// Currency symbol until the owner changes it in Settings.
  final String currency;

  /// Dialling code for WhatsApp and call links, without '+'.
  final String countryCode;

  /// Discount field in the booking form and discount lines on invoices.
  final bool enableDiscount;

  /// Path of this client's own image or file in `assets/clients/<id>/`; only that client's build bundles the folder.
  String asset(String file) => 'assets/clients/$id/$file';

  /// Every client this codebase ships. Must match the flavors in android/app/build.gradle.kts (a test checks).
  static const all = [demo];

  /// No flavor (unit tests) means demo. An unknown flavor is a build mistake, so it fails loudly.
  static ClientConfig forFlavor(String? flavor) {
    if (flavor == null) return demo;
    return all.firstWhere((c) => c.id == flavor, orElse: () => throw StateError('No client config for flavor "$flavor". Add it to ClientConfig.all.'));
  }
}
