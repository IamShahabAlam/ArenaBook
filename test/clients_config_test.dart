import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:arenabook/app/config/clients/client_config.dart';
import 'package:arenabook/app/config/clients/demo.dart';

/// Quoted names inside the first `<prefix>...<close>` in [file], e.g. `listOf("a", "b")` -> [a, b].
List<String> quotedList(String file, String prefix, String close) {
  final text = File(file).readAsStringSync();
  final start = text.indexOf(prefix);
  expect(start, isNot(-1), reason: '$prefix not found in $file');
  final body = text.substring(start + prefix.length, text.indexOf(close, start));
  return RegExp('["\']([^"\']+)["\']').allMatches(body).map((m) => m.group(1)!).toList();
}

void main() {
  final ids = ClientConfig.all.map((c) => c.id).toList();

  test('client ids are unique and valid flavor names', () {
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id), isTrue, reason: id);
    }
  });

  test('no flavor means demo; an unknown flavor fails loudly', () {
    expect(ClientConfig.forFlavor(null), same(demo));
    expect(ClientConfig.forFlavor('demo'), same(demo));
    expect(() => ClientConfig.forFlavor('nope'), throwsStateError);
  });

  test('every client offers at least one sport, with unique sport and court ids', () {
    for (final client in ClientConfig.all) {
      expect(client.resourceTypes.where((s) => s.enabled), isNotEmpty, reason: client.id);
      final typeIds = client.resourceTypes.map((s) => s.id).toList();
      final resourceIds = [for (final s in client.resourceTypes) ...s.resources.map((c) => c.id)];
      expect(typeIds.toSet().length, typeIds.length, reason: client.id);
      expect(resourceIds.toSet().length, resourceIds.length, reason: client.id);
    }
  });

  // Each client is declared in several native files; these keep them in step with ClientConfig.all.
  group('every client is wired up natively', () {
    test('Android flavors', () => expect(quotedList('android/app/build.gradle.kts', 'val clients = listOf(', ')'), unorderedEquals(ids)));

    test('iOS Podfile', () => expect(quotedList('ios/Podfile', 'clients = [', ']'), unorderedEquals(ids)));

    test('iOS schemes and build configurations', () {
      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      for (final id in ids) {
        expect(File('ios/Runner.xcodeproj/xcshareddata/xcschemes/$id.xcscheme').existsSync(), isTrue, reason: '$id.xcscheme');
        for (final mode in ['Debug', 'Release', 'Profile']) {
          // Runner, RunnerTests and the project itself each need the configuration.
          expect('name = "$mode-$id";'.allMatches(project).length, 3, reason: '$mode-$id');
        }
      }
    });

    test('a config file per client (the build scripts list and check these)', () {
      for (final id in ids) {
        expect(File('lib/app/config/clients/$id.dart').existsSync(), isTrue, reason: id);
      }
    });

    test('VS Code launch entries', () {
      final json = File('.vscode/launch.json').readAsStringSync().replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
      final configs = (jsonDecode(json)['configurations'] as List).cast<Map<String, dynamic>>();
      final flavors = configs.map((c) => (c['args'] as List?)?.join(' ')).toSet();
      for (final id in ids) {
        expect(flavors, contains('--flavor $id'), reason: id);
      }
    });

    test('client asset folders are bundled for their own flavor only', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declared = {for (final m in RegExp(r'- path: assets/clients/(\w+)/\s*\n\s*flavors: \[([^\]]*)\]').allMatches(pubspec)) m[1]!: m[2]!.trim()};
      final folders = Directory('assets/clients').existsSync()
          ? Directory('assets/clients').listSync().whereType<Directory>().map((d) => d.uri.pathSegments.lastWhere((s) => s.isNotEmpty)).toSet()
          : <String>{};
      expect(folders, everyElement(isIn(ids)), reason: 'assets/clients/<folder> must be a client id');
      expect(declared.keys.toSet(), folders, reason: 'declare each folder: dart run tool/clients.dart assets <id>');
      declared.forEach((id, flavors) => expect(flavors, id, reason: 'assets/clients/$id/ must be flavored [$id] only'));
      expect(RegExp(r'^\s*- assets/clients/', multiLine: true).hasMatch(pubspec), isFalse, reason: 'an unflavored entry would ship every client');
    });

    test('Android source sets beyond main/debug/profile are client overrides', () {
      final sets = Directory('android/app/src').listSync().whereType<Directory>().map((d) => d.uri.pathSegments.lastWhere((s) => s.isNotEmpty));
      expect(sets.where((s) => !const {'main', 'debug', 'profile', 'release'}.contains(s)), everyElement(isIn(ids)));
    });

    test('a client with its own iOS icon set uses it in all its configurations', () {
      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      final sets = Directory('ios/Runner/Assets.xcassets').listSync().map((e) => e.uri.pathSegments.lastWhere((s) => s.isNotEmpty));
      final clientSets = sets.where((s) => s.startsWith('AppIcon-')).map((s) => s.substring('AppIcon-'.length).replaceAll('.appiconset', ''));
      expect(clientSets, everyElement(isIn(ids)));
      for (final id in clientSets) {
        expect('ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-$id";'.allMatches(project).length, 3, reason: 'run: dart run tool/clients.dart ios-icon $id');
      }
    });

    test('the default flavor is a known client', () {
      final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.trim().startsWith('default-flavor:'));
      expect(ids, contains(line.split(':').last.trim()));
    });
  });
}
