import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/app.dart';

void main() {
  testWidgets('shows the dashboard page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyManagerApp()));

    expect(find.text('Dashboard'), findsWidgets);
  });
}
