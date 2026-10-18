// Client (flavor) setup. Run from the project root:
//   dart run tool/clients.dart add <id>       new client: Dart config, Android, iOS, VS Code
//   dart run tool/clients.dart assets <id>    bundle assets/clients/<id>/ into that client's build only
//   dart run tool/clients.dart ios-icon <id>  use ios/Runner/Assets.xcassets/AppIcon-<id> for that client
// Every edit is prepared first and written only if all steps succeed. test/clients_config_test.dart checks the result.
import 'dart:io';
import 'dart:math';

const bundlePrefix = 'com.devcatstudios.arenabook';
const configDir = 'lib/app/config/clients';
const pbxproj = 'ios/Runner.xcodeproj/project.pbxproj';
const schemesDir = 'ios/Runner.xcodeproj/xcshareddata/xcschemes';

final commands = <String, String Function(Directory root, String id)>{'add': addClient, 'assets': addAssets, 'ios-icon': useIosIcon};

void main(List<String> args) {
  final command = args.isEmpty ? null : commands[args.first];
  if (command == null || args.length != 2) {
    stderr.writeln('Usage: dart run tool/clients.dart <add|assets|ios-icon> <client id>');
    exit(64);
  }
  try {
    stdout.writeln(command(Directory.current, args[1]));
  } on ClientToolException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(1);
  }
}

class ClientToolException implements Exception {
  ClientToolException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Creates client [id]: a config copied from demo, plus every native list it must appear in.
String addClient(Directory root, String id) {
  _checkId(id);
  final f = _Files(root);
  if (f.exists('$configDir/$id.dart')) throw ClientToolException('Client "$id" already exists.');
  final name = _camelCase(id);
  if (_reserved.contains(name)) throw ClientToolException('"$id" is a Dart keyword; pick another id.');

  final demo = f.read('$configDir/demo.dart');
  f.write(
    '$configDir/$id.dart',
    _replaceOnce(
      _replaceOnce(demo, 'const demo = ClientConfig(', 'const $name = ClientConfig('),
      "id: 'demo',",
      "id: '$id',",
    ).replaceFirst(RegExp(r'^/// .*$', multiLine: true), '/// $id: copied from demo. Set its sports, courts, currency and switches.'),
  );

  var registry = f.read('$configDir/client_config.dart');
  final lastImport = RegExp(r'^import .*;\r?$', multiLine: true).allMatches(registry).last;
  registry = registry.replaceRange(lastImport.end, lastImport.end, "${_eol(registry)}import '$id.dart';");
  f.write('$configDir/client_config.dart', _appendToList(registry, RegExp(r'static const all = \[([^\]]*)\]'), name));

  const gradle = 'android/app/build.gradle.kts';
  f.write(gradle, _appendToList(f.read(gradle), RegExp(r'val clients = listOf\(([^)]*)\)'), '"$id"'));
  f.write('ios/Podfile', _appendToList(f.read('ios/Podfile'), RegExp(r'^clients = \[([^\]]*)\]', multiLine: true), "'$id'"));

  f.write(pbxproj, _addIosConfigurations(f.read(pbxproj), id));
  final scheme = f
      .read('$schemesDir/Runner.xcscheme')
      .replaceAllMapped(RegExp(r'buildConfiguration = "(Debug|Release|Profile)"'), (m) => 'buildConfiguration = "${m[1]}-$id"');
  f.write('$schemesDir/$id.xcscheme', scheme);

  const launch = '.vscode/launch.json';
  f.write(launch, _addLaunchEntries(f.read(launch), id));

  f.commit();
  return 'Added client "$id" ($bundlePrefix.$id). Next:\n'
      '  1. Edit $configDir/$id.dart (sports, courts, currency, switches).\n'
      '  2. Optional: images in assets/clients/$id/ then `dart run tool/clients.dart assets $id`;\n'
      '     launcher icon in android/app/src/$id/res/ and ios/Runner/Assets.xcassets/AppIcon-$id.appiconset (then `ios-icon $id`).\n'
      '  3. Add "$id" to the clients map in the access Gist if it needs a trial switch.\n'
      '  4. Run flutter test.';
}

/// Declares `assets/clients/<id>/` in pubspec.yaml for flavor [id] only.
String addAssets(Directory root, String id) {
  _checkId(id);
  final f = _Files(root);
  _requireClient(f, id);
  final folder = Directory('${root.path}/assets/clients/$id');
  if (!folder.existsSync() || folder.listSync().whereType<File>().isEmpty) {
    throw ClientToolException('Put the client\'s files in assets/clients/$id/ first.');
  }
  final pubspec = f.read('pubspec.yaml');
  if (pubspec.contains('assets/clients/$id/')) throw ClientToolException('assets/clients/$id/ is already declared.');

  final eol = _eol(pubspec);
  final lines = pubspec.split(eol);
  final start = lines.indexOf('  assets:');
  if (start == -1) throw ClientToolException('No "  assets:" list under flutter: in pubspec.yaml.');
  var end = start + 1;
  while (end < lines.length && lines[end].startsWith('    ')) {
    end++;
  }
  lines.insertAll(end, ['    - path: assets/clients/$id/', '      flavors: [$id]']);
  f.write('pubspec.yaml', lines.join(eol));
  f.commit();
  return 'Declared assets/clients/$id/ for "$id". Use it with AppClientConfig.client.asset(\'<file>\').';
}

/// Points client [id]'s iOS build configurations at its own `AppIcon-<id>` icon set.
String useIosIcon(Directory root, String id) {
  _checkId(id);
  final f = _Files(root);
  _requireClient(f, id);
  final iconSet = 'ios/Runner/Assets.xcassets/AppIcon-$id.appiconset';
  if (!Directory('${root.path}/$iconSet').existsSync()) {
    throw ClientToolException('Add $iconSet first (same layout as AppIcon.appiconset).');
  }
  var changed = 0;
  final project = f.read(pbxproj).replaceAllMapped(_configBlock('(?:Debug|Release|Profile)-$id'), (block) {
    final text = block[0]!;
    final updated = text.replaceFirst(RegExp(r'ASSETCATALOG_COMPILER_APPICON_NAME = [^;]+;'), 'ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-$id";');
    if (updated != text) changed++;
    return updated;
  });
  if (changed != 3) throw ClientToolException('Expected 3 Runner configurations for "$id", found $changed.');
  f.write(pbxproj, project);
  f.commit();
  return 'iOS builds of "$id" now use AppIcon-$id.';
}

// ─────────────── helpers ───────────────

final _idPattern = RegExp(r'^[a-z][a-z0-9_]*$');

void _checkId(String id) {
  if (!_idPattern.hasMatch(id)) throw ClientToolException('Client id must be lowercase letters, digits or _ and start with a letter.');
}

void _requireClient(_Files f, String id) {
  if (!f.exists('$configDir/$id.dart')) throw ClientToolException('Unknown client "$id". Add it first: dart run tool/clients.dart add $id');
}

String _camelCase(String id) =>
    id.split('_').where((p) => p.isNotEmpty).indexed.map((e) => e.$1 == 0 ? e.$2 : e.$2[0].toUpperCase() + e.$2.substring(1)).join();

const _reserved = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', 'default', 'do', 'else', 'enum', 'extends', 'false', 'final', //
  'finally', 'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super', 'switch', 'this', 'throw', 'true', 'try', 'var',
  'void', 'while', 'with',
};

String _eol(String text) => text.contains('\r\n') ? '\r\n' : '\n';

String _replaceOnce(String text, String from, String to) {
  if (from.allMatches(text).length != 1) throw ClientToolException('Expected exactly one "$from".');
  return text.replaceFirst(from, to);
}

/// Adds [item] to the comma-separated list captured by [list]'s first group.
String _appendToList(String text, RegExp list, String item) {
  final matches = list.allMatches(text).toList();
  if (matches.length != 1) throw ClientToolException('Expected exactly one ${list.pattern}.');
  final m = matches.single;
  final items = m[1]!.trim();
  final start = m.start + m[0]!.indexOf(RegExp(r'[\[(]')) + 1; // just after the opening bracket
  return text.replaceRange(start, start + m[1]!.length, items.isEmpty ? item : '$items, $item');
}

RegExp _configBlock(String name) => RegExp('\\t\\t([0-9A-F]{24}) /\\* ($name) \\*/ = \\{\\n[\\s\\S]*?\\n\\t\\t\\};\\n');

/// Copies the plain Debug/Release/Profile configurations of every target as `<mode>-<id>` with the client's bundle id.
String _addIosConfigurations(String project, String id) {
  if (project.contains('"Debug-$id"')) throw ClientToolException('iOS already has configurations for "$id".');
  final used = RegExp(r'[0-9A-F]{24}').allMatches(project).map((m) => m[0]!).toSet();
  final random = Random.secure();
  String newId() {
    String value;
    do {
      value = List.generate(24, (_) => random.nextInt(16).toRadixString(16)).join().toUpperCase();
    } while (!used.add(value));
    return value;
  }

  const end = '/* End XCBuildConfiguration section */';
  final section = project.substring(project.indexOf('/* Begin XCBuildConfiguration section */'), project.indexOf(end));
  final added = StringBuffer();
  final copies = <String, (String, String)>{}; // original id -> (copy id, mode)
  for (final m in _configBlock('Debug|Release|Profile').allMatches(section)) {
    final (original, mode, copy) = (m[1]!, m[2]!, newId());
    added.write(
      m[0]!
          .replaceFirst('$original /* $mode */', '$copy /* $mode-$id */')
          .replaceFirst('\t\t\tname = $mode;', '\t\t\tname = "$mode-$id";')
          .replaceFirst('PRODUCT_BUNDLE_IDENTIFIER = $bundlePrefix', 'PRODUCT_BUNDLE_IDENTIFIER = $bundlePrefix.$id'),
    );
    copies[original] = (copy, mode);
  }
  if (copies.length != 9) throw ClientToolException('Expected 9 base iOS build configurations, found ${copies.length}.');

  var result = project.replaceFirst(end, '$added$end');
  for (final MapEntry(key: original, value: (copy, mode)) in copies.entries) {
    final line = '\t\t\t\t$original /* $mode */,\n';
    if (!result.contains(line)) throw ClientToolException('iOS configuration $original is not in a configuration list.');
    result = result.replaceFirst(line, '$line\t\t\t\t$copy /* $mode-$id */,\n');
  }
  return result;
}

String _addLaunchEntries(String json, String id) {
  final eol = _eol(json);
  String entry(String name, {String? mode}) => [
    '        {',
    '            "name": "$name",',
    '            "request": "launch",',
    '            "type": "dart",',
    '            "program": "lib/main.dart",',
    if (mode != null) '            "flutterMode": "$mode",',
    '            "args": ["--flavor", "$id"]',
    '        }',
  ].join(eol);
  final last = json.lastIndexOf('}', json.lastIndexOf(']'));
  return json.replaceRange(last + 1, last + 1, ',$eol${entry(id)},$eol${entry('$id (release)', mode: 'release')}');
}

/// Reads through pending edits; [commit] writes them all at the end.
class _Files {
  _Files(this.root);
  final Directory root;
  final _pending = <String, String>{};

  File _file(String path) => File('${root.path}/$path');
  bool exists(String path) => _pending.containsKey(path) || _file(path).existsSync();
  String read(String path) => _pending[path] ?? _file(path).readAsStringSync();
  void write(String path, String text) => _pending[path] = text;

  void commit() {
    for (final MapEntry(key: path, value: text) in _pending.entries) {
      _file(path)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(text);
    }
  }
}
