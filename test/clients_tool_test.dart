import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/clients.dart';
import 'helpers/temp_dir.dart';

/// The files tool/clients.dart edits, copied into a temp project so the real one is untouched.
const _files = [
  'lib/app/config/clients/client_config.dart',
  'lib/app/config/clients/demo.dart',
  'android/app/build.gradle.kts',
  'ios/Podfile',
  'ios/Runner.xcodeproj/project.pbxproj',
  'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
  '.vscode/launch.json',
  'pubspec.yaml',
];

void main() {
  late Directory root;
  String read(String path) => File('${root.path}/$path').readAsStringSync();

  setUp(() {
    root = Directory.systemTemp.createTempSync('arenabook_clients_');
    for (final path in _files) {
      File('${root.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(File(path).readAsStringSync());
    }
  });
  tearDown(() => deleteTempDir(root));

  test('add wires a client into every list, and refuses to add it twice', () {
    addClient(root, 'royal_arena');

    final config = read('lib/app/config/clients/royal_arena.dart');
    expect(config, contains('const royalArena = ClientConfig('));
    expect(config, contains("id: 'royal_arena',"));
    final registry = read('lib/app/config/clients/client_config.dart');
    expect(registry, contains("import 'royal_arena.dart';"));
    // Appended after whatever clients already exist.
    expect(registry, matches(RegExp(r'static const all = \[demo, ([^\]]*, )?royalArena\];')));
    expect(read('android/app/build.gradle.kts'), matches(RegExp(r'val clients = listOf\("demo", ([^)]*, )?"royal_arena"\)')));
    expect(read('ios/Podfile'), matches(RegExp(r"clients = \['demo', ([^\]]*, )?'royal_arena'\]")));

    final project = read('ios/Runner.xcodeproj/project.pbxproj');
    for (final mode in ['Debug', 'Release', 'Profile']) {
      expect('name = "$mode-royal_arena";'.allMatches(project).length, 3, reason: mode);
      expect('/* $mode-royal_arena */,'.allMatches(project).length, 3, reason: '$mode in all 3 configuration lists');
    }
    expect('PRODUCT_BUNDLE_IDENTIFIER = com.devcatstudios.arenabook.royal_arena;'.allMatches(project).length, 3);
    expect('PRODUCT_BUNDLE_IDENTIFIER = com.devcatstudios.arenabook.royal_arena.RunnerTests;'.allMatches(project).length, 3);
    final ids = RegExp(r'^\t\t([0-9A-F]{24}) ', multiLine: true).allMatches(project).map((m) => m[1]).toList();
    expect(ids.toSet().length, ids.length, reason: 'object ids stay unique');
    expect(read('ios/Runner.xcodeproj/xcshareddata/xcschemes/royal_arena.xcscheme'), contains('buildConfiguration = "Release-royal_arena"'));

    final launch = jsonDecode(read('.vscode/launch.json').replaceAll(RegExp(r'^\s*//.*$', multiLine: true), ''));
    expect((launch['configurations'] as List).map((c) => c['name']), containsAll(['royal_arena', 'royal_arena (release)']));

    expect(() => addClient(root, 'royal_arena'), throwsA(isA<ClientToolException>()));
  });

  test('a failed add writes nothing', () {
    final before = read('ios/Podfile');
    File('${root.path}/.vscode/launch.json').deleteSync(); // last step fails
    expect(() => addClient(root, 'beta'), throwsA(isA<FileSystemException>()));
    expect(File('${root.path}/lib/app/config/clients/beta.dart').existsSync(), isFalse);
    expect(read('ios/Podfile'), before);
  });

  test('ids must be valid flavor names and not Dart keywords', () {
    for (final id in ['Champions', '1arena', 'my-arena', '']) {
      expect(() => addClient(root, id), throwsA(isA<ClientToolException>()), reason: id);
    }
    expect(() => addClient(root, 'switch'), throwsA(isA<ClientToolException>()));
  });

  test('assets declares the client folder for its flavor only', () {
    expect(() => addAssets(root, 'demo'), throwsA(isA<ClientToolException>()), reason: 'no folder yet');
    File('${root.path}/assets/clients/demo/logo.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([0]);
    addAssets(root, 'demo');
    expect(read('pubspec.yaml'), matches(RegExp(r'  assets:\r?\n(    .*\r?\n)*    - path: assets/clients/demo/\r?\n      flavors: \[demo\]')));
    expect(() => addAssets(root, 'demo'), throwsA(isA<ClientToolException>()), reason: 'already declared');
    expect(() => addAssets(root, 'nope'), throwsA(isA<ClientToolException>()), reason: 'unknown client');
  });

  test('ios-icon switches only that client\'s Runner configurations', () {
    addClient(root, 'beta');
    int defaultIcons() => 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;'.allMatches(read('ios/Runner.xcodeproj/project.pbxproj')).length;
    final before = defaultIcons();
    expect(() => useIosIcon(root, 'beta'), throwsA(isA<ClientToolException>()), reason: 'no icon set yet');
    Directory('${root.path}/ios/Runner/Assets.xcassets/AppIcon-beta.appiconset').createSync(recursive: true);
    useIosIcon(root, 'beta');
    final project = read('ios/Runner.xcodeproj/project.pbxproj');
    expect('ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-beta";'.allMatches(project).length, 3);
    expect(defaultIcons(), before - 3, reason: 'every other client keeps the default');
  });
}
