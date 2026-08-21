import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/shared/widgets/app_fields.dart';
import 'package:money_manager/shared/widgets/financial_workflow_widgets.dart';
import 'package:money_manager/shared/widgets/form_dialog_widgets.dart';

void main() {
  late TextEditingController amountController;

  setUp(() {
    amountController = TextEditingController();
  });

  tearDown(() {
    amountController.dispose();
  });

  Widget host({required Size size, required Widget child, double inset = 0}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          viewInsets: EdgeInsets.only(bottom: inset),
        ),
        child: child,
      ),
    );
  }

  AdaptiveFinancialFormDialog form() {
    return AdaptiveFinancialFormDialog(
      title: 'Add transaction',
      content: AppFormColumn(
        children: [
          AppMoneyField(label: 'Amount', controller: amountController),
          const AppTextField(label: 'Money Holder'),
          const AppTextArea(label: 'Note'),
        ],
      ),
      actions: const [
        DialogFormActions(
          primaryLabel: 'Add transaction',
          onPrimaryPressed: _noop,
          onCancelPressed: _noop,
        ),
      ],
    );
  }

  testWidgets('mobile financial form uses a centered modal card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(size: const Size(390, 844), child: form()));
    await tester.pump();

    expect(find.byType(Scaffold), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.text('Add transaction'), findsWidgets);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop financial form uses a bounded dialog shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(size: const Size(1280, 800), child: form()));
    await tester.pump();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(Scaffold), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard insets do not overflow the mobile form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      host(size: const Size(390, 844), inset: 320, child: form()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
