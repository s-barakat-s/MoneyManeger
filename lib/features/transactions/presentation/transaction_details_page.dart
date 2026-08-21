import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/readable_date_formatter.dart';
import '../../../shared/models/audit_metadata.dart';
import '../../../shared/models/transaction.dart' as money;
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_status.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../owners/presentation/owner_stream_providers.dart';
import 'transaction_stream_providers.dart';

class TransactionDetailsPage extends ConsumerWidget {
  const TransactionDetailsPage({
    required this.transactionId,
    required this.currentLocation,
    super.key,
  });

  final String transactionId;
  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsStreamProvider);
    final owners = ref.watch(ownersStreamProvider);
    final actorNames = ref.watch(transactionActorNamesProvider);

    return AppShell(
      title: 'Transaction details',
      currentLocation: currentLocation,
      secondaryParent: AppRoute.transactions,
      child: transactions.when(
        loading: () => const LoadingSkeleton(itemCount: 3),
        error: (error, stackTrace) => const ErrorState(
          title: 'Transaction unavailable',
          message: 'We could not load this transaction right now.',
        ),
        data: (values) {
          final transaction = _findTransaction(values, transactionId);
          if (transaction == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoute.transactions.path);
            });
            return const Center(child: CircularProgressIndicator());
          }
          final ownerName = owners.value
              ?.where((owner) => owner.id == transaction.ownerId)
              .map((owner) => owner.name)
              .firstOrNull;
          return _TransactionDetailsContent(
            transaction: transaction,
            ownerName: ownerName ?? 'Unknown owner',
            actorNames: actorNames,
          );
        },
      ),
    );
  }
}

class _TransactionDetailsContent extends StatelessWidget {
  const _TransactionDetailsContent({
    required this.transaction,
    required this.ownerName,
    required this.actorNames,
  });

  final money.Transaction transaction;
  final String ownerName;
  final AsyncValue<Map<String, String>> actorNames;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == money.TransactionType.income;
    final tokens = context.appTheme;
    final textTheme = Theme.of(context).textTheme;
    final note = transaction.note?.trim();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppContentWidth.form),
        child: ListView(
          padding: AppLayout.pagePaddingFor(MediaQuery.sizeOf(context).width),
          children: [
            AppStatusChip(
              label: isIncome ? 'Income' : 'Expense',
              tone: isIncome ? AppStatusTone.success : AppStatusTone.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${isIncome ? '+' : '-'}${formatEgpCurrency(transaction.amount)}',
              style: textTheme.headlineMedium?.copyWith(
                color: isIncome ? tokens.income : tokens.expense,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Details', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(label: 'Money Holder', value: ownerName),
            _DetailRow(label: 'Date', value: _formatDate(transaction.date)),
            if (note != null && note.isNotEmpty)
              _DetailRow(label: 'Note', value: note),
            const SizedBox(height: AppSpacing.xl),
            _AuditSection(audit: transaction.audit, actorNames: actorNames),
          ],
        ),
      ),
    );
  }
}

money.Transaction? _findTransaction(
  List<money.Transaction> transactions,
  String id,
) {
  for (final transaction in transactions) {
    if (transaction.id == id) return transaction;
  }
  return null;
}

class _AuditSection extends StatelessWidget {
  const _AuditSection({required this.audit, required this.actorNames});

  final AuditMetadata audit;
  final AsyncValue<Map<String, String>> actorNames;

  @override
  Widget build(BuildContext context) {
    final showUpdater = _hasMeaningfulUpdate(audit);
    final tokens = context.appTheme;

    return AppCard(
      variant: AppCardVariant.subtle,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: tokens.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Created by',
            value: _resolvedName(audit.createdBy),
          ),
          if (audit.createdAt != null)
            _DetailRow(
              label: 'Created',
              value: _formatDateTime(audit.createdAt!),
            ),
          if (showUpdater) ...[
            _DetailRow(
              label: 'Updated by',
              value: _resolvedName(audit.updatedBy),
            ),
            if (audit.updatedAt != null)
              _DetailRow(
                label: 'Updated',
                value: _formatDateTime(audit.updatedAt!),
              ),
          ],
        ],
      ),
    );
  }

  String _resolvedName(String? uid) {
    if (uid == null) return 'Unknown member';
    return actorNames.when(
      data: (names) => names[uid] ?? 'Unknown member',
      loading: () => 'Loading member...',
      error: (error, stackTrace) => 'Unknown member',
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasMeaningfulUpdate(AuditMetadata audit) {
  if (audit.updatedBy == null) return false;
  if (audit.updatedBy != audit.createdBy) return true;
  final createdAt = audit.createdAt;
  final updatedAt = audit.updatedAt;
  return createdAt != null && updatedAt != null && updatedAt.isAfter(createdAt);
}

String _formatDate(DateTime value) {
  return formatReadableDate(value);
}

String _formatDateTime(DateTime value) {
  return formatReadableDateTime(value);
}
