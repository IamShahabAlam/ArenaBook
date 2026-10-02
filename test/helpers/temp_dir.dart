import 'dart:io';

/// Deletes a test's temp folder. On Windows the OS can keep a file locked for a moment after
/// Hive.close() returns, so a single delete fails intermittently (a flaky test). Retry briefly;
/// cleanup is not what the tests verify, so a leftover temp folder is not a failure.
Future<void> deleteTempDir(Directory dir) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
