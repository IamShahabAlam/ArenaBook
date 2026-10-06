class AppClientConfig {
  // Base URLs ------------------- (fill these per project)
  static String baseUrl = '';
  static String stageBaseUrl = '';
  static String localBaseUrl = '';

  // Features -------------------
  /// Discount field in the booking form and discount lines on invoices. (Not const: tests toggle it.)
  static bool enableDiscount = true;
}
