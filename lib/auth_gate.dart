import 'package:flutter/material.dart';

import 'i18n.dart';

/// Root-level auth-failure surface (protocol v2 multi-tenant servers).
///
/// Every agent RPC requires a bearer token. When a data loader gets a
/// 401/403 (missing / invalid / revoked token) the worst possible behavior is
/// swallowing it into a silently-empty list — the user sees "no tools, no
/// presets" with no clue why. Screens call [showAuthExpiredDialog] from their
/// catch blocks; the dialog offers a one-tap return to the connection setup
/// screen (via [onAuthExpired], registered by the app root state).

/// Root navigator key: root-level dialogs need a context BELOW MaterialApp.
final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

/// Invoked when the user picks "sign in again" (clears the active backend and
/// rebuilds to the setup screen). Registered by the app root state.
void Function()? onAuthExpired;

bool _dialogOpen = false;

/// Show the auth-expired dialog (at most one at a time).
void showAuthExpiredDialog() {
  final ctx = rootNavKey.currentContext;
  if (ctx == null || _dialogOpen) return;
  _dialogOpen = true;
  final l = I18n.now;
  showDialog<void>(
    context: ctx,
    builder: (c) => AlertDialog(
      title: Text(l.authExpiredTitle),
      content: Text(l.authExpiredBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(),
          child: Text(l.close),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(c).pop();
            onAuthExpired?.call();
          },
          child: Text(l.signInAgain),
        ),
      ],
    ),
  ).whenComplete(() => _dialogOpen = false);
}
