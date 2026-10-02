// ignore_for_file: library_private_types_in_public_api

// All endpoint paths, grouped by backend controller/module.
// Usage: ApiEndPoint.user.loginUrl
// Add one private class per module and expose it through a static getter below.
class ApiEndPoint {
  static _User get user => _User();
}

class _User {
  final String loginUrl = '';
  final String logoutUrl = '';
  final String updatePasswordUrl = '';
  final String resetPassUrl = '';
}
