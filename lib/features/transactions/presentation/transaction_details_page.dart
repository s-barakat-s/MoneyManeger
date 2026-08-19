import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/readable_date_formatter.dart';
import '../../../shared/models/audit_metadata.dart';
import '../../../shared/models/transaction.dart' as money;
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/app_card.dart';
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isIncome ? 'Income' : 'Expense',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              AmountText(
                amountText:
                    '${isIncome ? '+' : '-'}${formatEgpCurrency(transaction.amount)}',
                variant: isIncome
                    ? AmountTextVariant.income
                    : AmountTextVariant.expense,
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(label: 'Money holder', value: ownerName),
              _DetailRow(label: 'Date', value: _formatDate(transaction.date)),
              if (transaction.note?.trim() case final note?
                  when note.isNotEmpty)
                _DetailRow(label: 'Note', value: note),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _AuditCard(audit: transaction.audit, actorNames: actorNames),
      ],
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

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.audit, required this.actorNames});

  final AuditMetadata audit;
  final AsyncValue<Map<String, String>> actorNames;

  @override
  Widget build(BuildContext context) {
    final showUpdater = _hasMeaningfulUpdate(audit);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Audit', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _AuditLine(
            label: 'Created by',
            name: _resolvedName(audit.createdBy),
            timestamp: audit.createdAt,
          ),
          if (showUpdater) ...[
            const SizedBox(height: AppSpacing.md),
            _AuditLine(
              label: 'Last updated by',
              name: _resolvedName(audit.updatedBy),
              timestamp: audit.updatedAt,
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

class _AuditLine extends StatelessWidget {
  const _AuditLine({
    required this.label,
    required this.name,
    required this.timestamp,
  });

  final String label;
  final String name;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label $name', style: Theme.of(context).textTheme.bodyLarge),
        if (timestamp != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDateTime(timestamp!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
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
