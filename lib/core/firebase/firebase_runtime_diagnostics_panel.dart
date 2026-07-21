import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class FirebaseRuntimeDiagnosticsPanel extends StatefulWidget {
  const FirebaseRuntimeDiagnosticsPanel({super.key});

  @override
  State<FirebaseRuntimeDiagnosticsPanel> createState() =>
      _FirebaseRuntimeDiagnosticsPanelState();
}

class _FirebaseRuntimeDiagnosticsPanelState
    extends State<FirebaseRuntimeDiagnosticsPanel> {
  bool _isChecking = false;
  String? _checkResult;
  DateTime? _lastSuccessfulServerWrite;
  DateTime? _lastSuccessfulServerRead;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final app = Firebase.app();
    final options = app.options;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final authType = user == null
        ? 'Signed out'
        : user.isAnonymous
            ? 'Anonymous'
            : 'Email/password';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Data Safety / Sync Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _DiagnosticRow(label: 'projectId', value: options.projectId),
            _DiagnosticRow(label: 'appId', value: options.appId),
            _DiagnosticRow(label: 'uid', value: uid ?? 'Not signed in'),
            _DiagnosticRow(label: 'auth type', value: authType),
            _DiagnosticRow(
              label: 'anonymous',
              value: user?.isAnonymous.toString() ?? 'Not signed in',
            ),
            _DiagnosticRow(label: 'email', value: user?.email ?? 'No email'),
            const _DiagnosticRow(
              label: 'cache',
              value: 'Persistent Firestore cache disabled',
            ),
            _DiagnosticRow(
              label: 'server write',
              value: _formatDateTime(_lastSuccessfulServerWrite),
            ),
            _DiagnosticRow(
              label: 'server read',
              value: _formatDateTime(_lastSuccessfulServerRead),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _isChecking || uid == null ? null : _runFirestoreCheck,
              icon: _isChecking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_rounded),
              label: const Text('Run Firestore check'),
            ),
            if (uid == null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in or protect an anonymous user to test '
                'users/{uid}/_debug/runtime_check.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_checkResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                _checkResult!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runFirestoreCheck() async {
    final app = Firebase.app();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      setState(() => _checkResult = 'No current UID. Firestore check skipped.');
      return;
    }

    setState(() {
      _isChecking = true;
      _checkResult = null;
    });

    try {
      final doc = FirebaseFirestore.instanceFor(app: app)
          .collection('users')
          .doc(uid)
          .collection('_debug')
          .doc('runtime_check');

      await doc.set(
        {
          'projectId': app.options.projectId,
          'appId': app.options.appId,
          'uid': uid,
          'isAnonymous': user?.isAnonymous,
          'email': user?.email,
          'checkedAt': FieldValue.serverTimestamp(),
          'checkedAtLocal': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      final writeFinishedAt = DateTime.now();
      final snapshot = await doc.get(const GetOptions(source: Source.server));

      setState(() {
        _checkResult = snapshot.exists
            ? 'Server read/write OK at users/$uid/_debug/runtime_check'
            : 'Write finished, but the server read did not find the document.';
        if (snapshot.exists) {
          _lastSuccessfulServerWrite = writeFinishedAt;
          _lastSuccessfulServerRead = DateTime.now();
        }
      });
    } on FirebaseException catch (error) {
      setState(() {
        _checkResult = _friendlyFirebaseError(error);
      });
    } catch (error) {
      setState(() => _checkResult = 'Firestore check failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Not checked yet';
    }

    return value.toLocal().toIso8601String();
  }

  String _friendlyFirebaseError(FirebaseException error) {
    final detail = error.message == null ? '' : ' ${error.message}';

    return switch (error.code) {
      'permission-denied' =>
        'Firestore check failed: permission denied. Check Firestore rules for users/{uid}.',
      'unavailable' =>
        'Firestore check failed: server unavailable or network offline.',
      'not-found' =>
        'Firestore check failed: Firestore database may not be created for this project.',
      'unauthenticated' =>
        'Firestore check failed: no authenticated Firebase user.',
      _ => 'Firestore check failed: ${error.code}$detail',
    };
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
