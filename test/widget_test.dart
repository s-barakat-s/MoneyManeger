import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/app.dart';

void main() {
  testWidgets('mounts account switch presentation inside MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => AccountSwitchPresentation(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('App content')),
        ),
      ),
    );

    expect(find.text('App content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
