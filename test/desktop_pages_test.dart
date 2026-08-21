import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/transactions/presentation/transactions_page.dart';
import 'package:money_manager/features/transfers/presentation/transfers_page.dart';
import 'package:money_manager/features/debts/presentation/debts_page.dart';
import 'package:money_manager/features/receivables/presentation/receivables_page.dart';
import 'package:money_manager/features/company_assets/presentation/company_assets_page.dart';
import 'package:money_manager/features/owners/presentation/owners_page.dart';

void main() {
  testWidgets('desktop pages render test', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TransactionsPage(currentLocation: '/transactions'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
