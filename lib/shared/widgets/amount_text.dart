import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

enum AmountTextVariant {
  income,
  expense,
  neutral,
}

class AmountText extends StatelessWidget {
  const AmountText({
    this.amount,
    this.amountText,
    this.variant = AmountTextVariant.neutral,
    super.key,
  }) : assert(amount != null || amountText != null);

  final double? amount;
  final String? amountText;
  final AmountTextVariant variant;

  @override
  Widget build(BuildContext context) {
    return Text(
      amountText ?? formatEgpCurrency(amount!),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _color(context),
            fontWeight: FontWeight.w800,
          ),
    );
  }

  Color _color(BuildContext context) {
    return switch (variant) {
      AmountTextVariant.income => AppColors.success,
      AmountTextVariant.expense => AppColors.danger,
      AmountTextVariant.neutral => Theme.of(context).colorScheme.onSurface,
    };
  }
}

typedef MoneyAmountText = AmountText;
