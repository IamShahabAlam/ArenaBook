class AppStrings {
  // App Identity ------------------- (fill these per project)
  static const appName = 'ArenaBook';
  static const appTagline = 'Indoor Cricket Pitch & Padel Court Management System';
  static const developerName = 'ArenaBook Eng Team';
  static String kappVersionWithDate = 'v1.0.0'; // keep in sync with `version:` in pubspec.yaml
  static const kappBuildNumber = 1; // must match the build number on Play Console & App Store Connect
  // Support contact shown in the drawer (local or international format, e.g. 03001234567). '' hides the buttons.
  static const supportPhone = '+92 3412757081';
  static String webApiVersion = ''; // compatible backend/web API version (ask backend team)
  static const appStoreAddress = '';
  static const playStoreAddress = '';
  static const websiteURL = 'https://shahab-alam.web.app/';

  // General -------------------
  static const nullString = '--';
  static const poweredBy = 'Powered by';
  static const noImage = 'No Image';
  static const ok = 'Okay';
  static const submit = 'Submit';
  static const yes = 'Yes';
  static const no = 'No';
  static const noData = 'NO DATA';
  static const alert = 'Alert';
  static const exit = 'Exit';
  static const proceed = 'Proceed';
  static const goBack = 'Go Back';
  static const address = 'Address';
  static const remarks = 'Remarks';
  static const total = 'Total';
  static const subTotal = 'Subtotal';

  static var kStartDate = '1990-01-01T00:00:00';
  static var kEndDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59, 00).toString();
  static const int splashTime = 1500;

  // API Error Messages -------------------
  static const String noInternetConnectionErrorMsg = 'No Network Connection'; // connection Error when no connectivity Found. 510 , Artificial
  static const String youAreOfflineMsg = 'You are Offline'; // Connection found but No internet service 503
  static const String apiServerErrorMsg = 'Server Error'; // 500 , Artificial
  static const String apiServerOffErrorMsg = 'Server Offline'; // No Server found , 523
  static const String apiUnauthorizeErrorMsg = 'Unauthorize'; // 401
  static const String apiNotFoundErrorMsg = 'Not Found'; // 404
  static const String apiInvalidDataErrorMsg = 'Invalid Data'; // 422
  static const String apiTimeoutErrorMsg = 'Request Timeout, Please try again'; // 524
  static const String apiUnknownErrorMsg = 'Unknown Error'; // For other than these s.c
  static const String somethingWRMsg = 'Something went wrong'; // catch of each request , 511 , Artificial
  static const String showingCachedDataMsg = 'Showing saved data'; // network failed, cached response shown instead

  static List<Map<String, String>> monthsMap = [
    {'name': 'Jan', 'num': '01'},
    {'name': 'Feb', 'num': '02'},
    {'name': 'Mar', 'num': '03'},
    {'name': 'Apr', 'num': '04'},
    {'name': 'May', 'num': '05'},
    {'name': 'Jun', 'num': '06'},
    {'name': 'Jul', 'num': '07'},
    {'name': 'Aug', 'num': '08'},
    {'name': 'Sep', 'num': '09'},
    {'name': 'Oct', 'num': '10'},
    {'name': 'Nov', 'num': '11'},
    {'name': 'Dec', 'num': '12'},
  ];

  static List<Map<String, String>> weekMap = [
    {'name': 'Mon', 'num': '01'},
    {'name': 'Tue', 'num': '02'},
    {'name': 'Wed', 'num': '03'},
    {'name': 'Thu', 'num': '04'},
    {'name': 'Fri', 'num': '05'},
    {'name': 'Sat', 'num': '06'},
    {'name': 'Sun', 'num': '07'},
  ];
}
