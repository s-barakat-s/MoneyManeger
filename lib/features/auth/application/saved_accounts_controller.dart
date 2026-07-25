import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_account_repository.dart';
import '../domain/saved_account.dart';
import 'auth_providers.dart';

final savedAccountRepositoryProvider = Provider<SavedAccountRepository>((ref) {
  return const SharedPreferencesSavedAccountRepository();
});

final savedAccountsControllerProvider =
    AsyncNotifierProvider<SavedAccountsController, List<SavedAccount>>(
      SavedAccountsController.new,
    );

String? savedUsernameForUpsert({
  required String? profileUsername,
  required String? existingUsername,
}) {
  final cleanProfileUsername = profileUsername?.trim();
  if (cleanProfileUsername != null && cleanProfileUsername.isNotEmpty) {
    return cleanProfileUsername;
  }
  final cleanExistingUsername = existingUsername?.trim();
  return cleanExistingUsername == null || cleanExistingUsername.isEmpty
      ? null
      : cleanExistingUsername;
}

class SavedAccountsController extends AsyncNotifier<List<SavedAccount>> {
  Future<void> _pendingSave = Future<void>.value();

  @override
  Future<List<SavedAccount>> build() {
    return ref.watch(savedAccountRepositoryProvider).load();
  }

  Future<void> saveAuthenticatedUser(User user, {String? username}) {
    final operation = _pendingSave.then(
      (_) => _saveAuthenticatedUser(user, username: username),
    );
    _pendingSave = operation.catchError((_) {});
    return operation;
  }

  Future<void> _saveAuthenticatedUser(User user, {String? username}) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return;
    final providerIds =
        user.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final repository = ref.read(savedAccountRepositoryProvider);
    SavedAccount? existing;
    for (final account in await repository.load()) {
      if (account.uid == user.uid) {
        existing = account;
        break;
      }
    }
    await repository.upsert(
      SavedAccount(
        uid: user.uid,
        email: email,
        username: savedUsernameForUpsert(
          profileUsername: username,
          existingUsername: existing?.username,
        ),
        displayName: user.displayName,
        photoUrl: user.photoURL,
        provider: providerIds.join(','),
        lastUsedAt: DateTime.now(),
      ),
    );
    state = AsyncData(await repository.load());
  }

  Future<void> updateUsername(String uid, String username) async {
    final repository = ref.read(savedAccountRepositoryProvider);
    final accounts = await repository.load();
    SavedAccount? existing;
    for (final account in accounts) {
      if (account.uid == uid) {
        existing = account;
        break;
      }
    }
    if (existing == null) return;
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || existing.username == cleanUsername) return;
    await repository.upsert(existing.copyWith(username: cleanUsername));
    state = AsyncData(await repository.load());
  }

  Future<void> remove(String uid, {required String? currentUid}) async {
    if (uid == currentUid) return;
    final repository = ref.read(savedAccountRepositoryProvider);
    await repository.remove(uid);
    state = AsyncData(await repository.load());
  }

  Future<void> clearAll() async {
    await ref.read(savedAccountRepositoryProvider).clear();
    state = const AsyncData([]);
  }
}

final savedAccountSynchronizationProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState is AsyncData<User?> ? authState.value : null;
  if (user == null) return;

  final profile = ref.watch(userProfileProvider(user.uid));
  final username = profile is AsyncData<AppUserProfile>
      ? profile.value.username
      : null;
  unawaited(
    ref
        .read(savedAccountsControllerProvider.notifier)
        .saveAuthenticatedUser(user, username: username),
  );
});
