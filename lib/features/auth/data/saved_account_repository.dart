import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/saved_account.dart';

abstract interface class SavedAccountRepository {
  Future<List<SavedAccount>> load();
  Future<void> upsert(SavedAccount account);
  Future<void> remove(String uid);
  Future<void> clear();
}

class SharedPreferencesSavedAccountRepository
    implements SavedAccountRepository {
  const SharedPreferencesSavedAccountRepository();

  static const _accountsKey = 'saved_google_accounts_v1';
  static const _legacyCurrentUidKey = 'saved_google_accounts_current_uid_v1';

  @override
  Future<List<SavedAccount>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_accountsKey);
    if (encoded == null) return const [];

    try {
      final values = jsonDecode(encoded);
      if (values is! List) return const [];
      final accounts = <SavedAccount>[];
      for (final value in values) {
        try {
          if (value is Map) {
            accounts.add(
              SavedAccount.fromJson(Map<String, Object?>.from(value)),
            );
          }
        } on Object {
          // Ignore only the corrupt record and retain other valid accounts.
        }
      }
      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return _normalizeByUid(accounts);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> upsert(SavedAccount account) async {
    final accounts = await load();
    final updated = [
      account,
      ...accounts.where((saved) => saved.uid != account.uid),
    ];
    await _write(updated);
  }

  @override
  Future<void> remove(String uid) async {
    final accounts = await load();
    await _write(accounts.where((account) => account.uid != uid).toList());
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accountsKey);
    await preferences.remove(_legacyCurrentUidKey);
  }

  Future<void> _write(List<SavedAccount> accounts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }
}

List<SavedAccount> _normalizeByUid(List<SavedAccount> accounts) {
  final normalized = <String, SavedAccount>{};
  for (final account in accounts) {
    final existing = normalized[account.uid];
    if (existing == null) {
      normalized[account.uid] = account;
      continue;
    }
    final providers = {...existing.providerIds, ...account.providerIds}.toList()
      ..sort();
    normalized[account.uid] = SavedAccount(
      uid: existing.uid,
      email: existing.email.isNotEmpty ? existing.email : account.email,
      username: _preferred(existing.username, account.username),
      displayName: _preferred(existing.displayName, account.displayName),
      photoUrl: _preferred(existing.photoUrl, account.photoUrl),
      provider: providers.join(','),
      lastUsedAt: existing.lastUsedAt,
    );
  }
  final values = normalized.values.toList(growable: false);
  values.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  return values;
}

String? _preferred(String? primary, String? fallback) {
  final normalizedPrimary = primary?.trim();
  if (normalizedPrimary != null && normalizedPrimary.isNotEmpty) {
    return normalizedPrimary;
  }
  final normalizedFallback = fallback?.trim();
  return normalizedFallback == null || normalizedFallback.isEmpty
      ? null
      : normalizedFallback;
}
