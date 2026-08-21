import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/activity_action.dart';
import '../../domain/activity_log_entry.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({required this.entry, super.key});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final description = _description(entry.action);
    final detail = _safeDetail(entry);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(
                _icon(entry.action),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.actorName ?? 'Unknown member'} · $description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatTimestamp(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String activityDescription(ActivityAction? action) => _description(action);

String _description(ActivityAction? action) {
  return switch (action) {
    ActivityAction.ownerCreated => 'Created a money holder',
    ActivityAction.ownerUpdated => 'Updated a money holder',
    ActivityAction.ownerArchived => 'Archived a money holder',
    ActivityAction.transactionCreated => 'Created a transaction',
    ActivityAction.transactionUpdated => 'Updated a transaction',
    ActivityAction.transactionArchived => 'Archived a transaction',
    ActivityAction.transferCreated => 'Created a transfer',
    ActivityAction.transferCorrected => 'Corrected a transfer',
    ActivityAction.transferArchived => 'Archived a transfer',
    ActivityAction.debtCreated => 'Created a debt',
    ActivityAction.debtUpdated => 'Updated a debt',
    ActivityAction.debtArchived => 'Archived a debt',
    ActivityAction.debtRestored => 'Restored a debt',
    ActivityAction.receivableCreated => 'Created a receivable',
    ActivityAction.receivableUpdated => 'Updated a receivable',
    ActivityAction.receivableArchived => 'Archived a receivable',
    ActivityAction.receivableRestored => 'Restored a receivable',
    ActivityAction.paymentCreated => 'Created a payment',
    ActivityAction.paymentUpdated => 'Updated a payment',
    ActivityAction.paymentArchived => 'Archived a payment',
    ActivityAction.assetCreated => 'Created a business asset',
    ActivityAction.assetUpdated => 'Updated a business asset',
    ActivityAction.assetArchived => 'Archived a business asset',
    ActivityAction.memberInvited => 'Invited a member',
    ActivityAction.memberRoleChanged => "Changed a member's role",
    ActivityAction.memberSuspended => 'Suspended a member',
    ActivityAction.memberReactivated => 'Reactivated a member',
    ActivityAction.memberRemoved => 'Removed a member',
    ActivityAction.memberActivated => 'Activated a member',
    ActivityAction.invitationRevoked => 'Revoked an invitation',
    ActivityAction.businessCreated => 'Created the business',
    null => 'Unknown activity',
  };
}

IconData _icon(ActivityAction? action) {
  return switch (action) {
    ActivityAction.memberInvited ||
    ActivityAction.memberRoleChanged ||
    ActivityAction.memberSuspended ||
    ActivityAction.memberReactivated ||
    ActivityAction.memberRemoved ||
    ActivityAction.memberActivated ||
    ActivityAction.invitationRevoked => Icons.groups_outlined,
    ActivityAction.businessCreated => Icons.business_outlined,
    ActivityAction.transferCreated ||
    ActivityAction.transferCorrected ||
    ActivityAction.transferArchived => Icons.swap_horiz_rounded,
    ActivityAction.debtCreated ||
    ActivityAction.debtUpdated ||
    ActivityAction.debtArchived ||
    ActivityAction.debtRestored ||
    ActivityAction.receivableCreated ||
    ActivityAction.receivableUpdated ||
    ActivityAction.receivableArchived ||
    ActivityAction.receivableRestored ||
    ActivityAction.paymentCreated ||
    ActivityAction.paymentUpdated ||
    ActivityAction.paymentArchived => Icons.payments_outlined,
    ActivityAction.assetCreated ||
    ActivityAction.assetUpdated ||
    ActivityAction.assetArchived => Icons.business_center_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

String? _safeDetail(ActivityLogEntry entry) {
  if (entry.action != ActivityAction.memberRoleChanged) return null;
  final fromRole = entry.metadata['fromRoleId'];
  final toRole = entry.metadata['toRoleId'];
  if (fromRole is! String || toRole is! String) return null;
  return '${_roleName(fromRole)} → ${_roleName(toRole)}';
}

String _roleName(String roleId) {
  return switch (roleId) {
    'owner' => 'Owner',
    'admin' => 'Admin',
    'accountant' => 'Accountant',
    'viewer' => 'Viewer',
    _ => 'Custom role',
  };
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final now = DateTime.now();
  final date = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  final prefix = date == today
      ? 'Today'
      : date == today.subtract(const Duration(days: 1))
      ? 'Yesterday'
      : '${_months[value.month - 1]} ${value.day}, ${value.year}';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '$prefix, $hour:$minute $period';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
