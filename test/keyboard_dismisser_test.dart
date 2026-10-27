import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arenabook/app/utils/custom_widgets/keyboard_dismisser.dart';

/// Two fields at the top of a long scrollable page, like the booking form.
Widget page(FocusNode a, FocusNode b, {bool dismisser = true}) => MaterialApp(
  builder: (context, child) => dismisser ? KeyboardDismisser(child: child!) : child!,
  home: Scaffold(
    body: ListView(
      children: [
        TextField(key: const ValueKey('a'), focusNode: a),
        TextField(key: const ValueKey('b'), focusNode: b),
        const SizedBox(height: 2000),
      ],
    ),
  ),
);

void main() {
  late FocusNode a, b;
  setUp(() {
    a = FocusNode();
    b = FocusNode();
  });
  tearDown(() {
    a.dispose();
    b.dispose();
  });

  const blank = Offset(200, 400); // empty space below the fields

  testWidgets('a tap outside the field closes the keyboard', (tester) async {
    await tester.pumpWidget(page(a, b));
    await tester.tap(find.byKey(const ValueKey('a')));
    await tester.pump();
    expect(a.hasFocus, isTrue);

    await tester.tapAt(blank);
    await tester.pump();
    expect(a.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a drag that starts outside the field closes the keyboard', (tester) async {
    await tester.pumpWidget(page(a, b));
    await tester.tap(find.byKey(const ValueKey('a')));
    await tester.pump();

    await tester.dragFrom(blank, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(a.hasFocus, isFalse);
  });

  testWidgets('tapping another field moves focus there without closing the keyboard', (tester) async {
    await tester.pumpWidget(page(a, b));
    await tester.tap(find.byKey(const ValueKey('a')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('b')));
    await tester.pump();
    expect(b.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('without it, Flutter keeps the keyboard open on phones (why the app needs it)', (tester) async {
    await tester.pumpWidget(page(a, b, dismisser: false));
    await tester.tap(find.byKey(const ValueKey('a')));
    await tester.pump();

    await tester.tapAt(blank);
    await tester.pump();
    expect(a.hasFocus, isTrue);
  });
}
