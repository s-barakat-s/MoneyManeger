import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/shared/widgets/app_button.dart';
import 'package:money_manager/shared/widgets/app_card.dart';
import 'package:money_manager/shared/widgets/app_fields.dart';
import 'package:money_manager/shared/widgets/app_status.dart';
import 'package:money_manager/shared/widgets/empty_state.dart';
import 'package:money_manager/shared/widgets/error_state.dart';
import 'package:money_manager/shared/widgets/loading_skeleton.dart';
import 'package:money_manager/shared/widgets/page_header.dart';

void main() {
  testWidgets('loading button preserves its label and disables submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppButton(label: 'Save', onPressed: null, isLoading: true),
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
    testWidgets('shared primitives mount in ${theme.brightness.name}', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ListView(
              children: [
                AppTextField(label: 'Name', controller: controller),
                const AppStatusChip(
                  label: 'Active',
                  tone: AppStatusTone.success,
                ),
                const AppCard(child: Text('Card content')),
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Nothing here',
                  description: 'Add an item to begin.',
                  density: AppStateDensity.compact,
                ),
                const ErrorState(
                  title: 'Could not load',
                  message: 'Try again.',
                  density: AppStateDensity.compact,
                ),
                const LoadingSkeleton(
                  itemCount: 1,
                  density: AppSkeletonDensity.compact,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Card content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('content-owned page header receives shell back action', (
    tester,
  ) async {
    var backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppPageHeaderScope(
            onBack: () => backPressed = true,
            child: const PageHeader(title: 'Activity'),
          ),
        ),
      ),
    );

    expect(find.text('Activity'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    expect(backPressed, isTrue);
  });
}
