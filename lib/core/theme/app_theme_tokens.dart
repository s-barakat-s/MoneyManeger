import 'package:flutter/material.dart';

/// Money Manager semantics not represented by Material [ColorScheme].
///
/// Standard meanings stay canonical in ColorScheme: primary, background/
/// surface, text, outline, and error. This extension only adds financial and
/// supporting status roles that Material does not model.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.surfaceSubtle,
    required this.surfaceRaised,
    required this.textMuted,
    required this.borderStrong,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.income,
    required this.expense,
    required this.debt,
    required this.receivable,
  });

  final Color surfaceSubtle;
  final Color surfaceRaised;
  final Color textMuted;
  final Color borderStrong;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color income;
  final Color expense;
  final Color debt;
  final Color receivable;

  static const light = AppThemeTokens(
    surfaceSubtle: Color(0xFFEEF0F3),
    surfaceRaised: Color(0xFFFFFFFF),
    textMuted: Color(0xFF6F6B74),
    borderStrong: Color(0xFFAEB3BD),
    success: Color(0xFF087A4B),
    successContainer: Color(0xFFDDF5E8),
    onSuccessContainer: Color(0xFF075E3A),
    warning: Color(0xFF9A5B00),
    warningContainer: Color(0xFFFFF0D3),
    onWarningContainer: Color(0xFF714500),
    info: Color(0xFF1769AA),
    infoContainer: Color(0xFFE2F0FF),
    onInfoContainer: Color(0xFF124F82),
    income: Color(0xFF087A4B),
    expense: Color(0xFFB4232C),
    debt: Color(0xFFB4232C),
    receivable: Color(0xFF1769AA),
  );

  static const dark = AppThemeTokens(
    surfaceSubtle: Color(0xFF242229),
    surfaceRaised: Color(0xFF211F25),
    textMuted: Color(0xFFA9A3AE),
    borderStrong: Color(0xFF938F99),
    success: Color(0xFF96D5B3),
    successContainer: Color(0xFF075234),
    onSuccessContainer: Color(0xFFB2F0CE),
    warning: Color(0xFFF3BE62),
    warningContainer: Color(0xFF614000),
    onWarningContainer: Color(0xFFFFDEA5),
    info: Color(0xFF9CCAFF),
    infoContainer: Color(0xFF164A73),
    onInfoContainer: Color(0xFFCFE5FF),
    income: Color(0xFF96D5B3),
    expense: Color(0xFFFFB4AB),
    debt: Color(0xFFF3BE62),
    receivable: Color(0xFF9CCAFF),
  );

  @override
  AppThemeTokens copyWith({
    Color? surfaceSubtle,
    Color? surfaceRaised,
    Color? textMuted,
    Color? borderStrong,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? income,
    Color? expense,
    Color? debt,
    Color? receivable,
  }) {
    return AppThemeTokens(
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      textMuted: textMuted ?? this.textMuted,
      borderStrong: borderStrong ?? this.borderStrong,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      debt: debt ?? this.debt,
      receivable: receivable ?? this.receivable,
    );
  }

  @override
  AppThemeTokens lerp(covariant AppThemeTokens? other, double t) {
    if (other == null) return this;
    return AppThemeTokens(
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      debt: Color.lerp(debt, other.debt, t)!,
      receivable: Color.lerp(receivable, other.receivable, t)!,
    );
  }
}

extension AppThemeTokensContext on BuildContext {
  AppThemeTokens get appTheme => Theme.of(this).extension<AppThemeTokens>()!;
}
