import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

enum UnauthenticatedDestination { savedAccounts, login }

class UnauthenticatedEntryState {
  const UnauthenticatedEntryState({this.forceShowLogin = false});

  final bool forceShowLogin;
}

UnauthenticatedDestination unauthenticatedDestination(
  List<Object> accounts,
  UnauthenticatedEntryState entry,
) {
  if (!entry.forceShowLogin && accounts.isNotEmpty) {
    return UnauthenticatedDestination.savedAccounts;
  }
  return UnauthenticatedDestination.login;
}

final unauthenticatedEntryControllerProvider =
    NotifierProvider<UnauthenticatedEntryController, UnauthenticatedEntryState>(
      UnauthenticatedEntryController.new,
    );

class UnauthenticatedEntryController
    extends Notifier<UnauthenticatedEntryState> {
  @override
  UnauthenticatedEntryState build() => const UnauthenticatedEntryState();

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    showSavedAccounts();
  }

  void showLogin() {
    state = const UnauthenticatedEntryState(forceShowLogin: true);
  }

  void showSavedAccounts() {
    state = const UnauthenticatedEntryState();
  }

  void resetForAppRestart() {
    state = const UnauthenticatedEntryState();
  }
}
