import 'package:flutter/material.dart';

import '../i18n.dart';

/// The single duration used by EVERY transient bottom message (success, info,
/// and error alike) so the app behaves consistently. Longer than a blink but
/// short enough never to linger.
const Duration kToastDuration = Duration(milliseconds: 2200);

/// Show a short, self-replacing bottom toast. Clears any queued/visible snack
/// bars first so repeated confirmations never pile up and linger.
void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(content: Text(message), duration: kToastDuration),
  );
}

/// Show an error toast with the SAME [kToastDuration] as every other bottom
/// message (unified timing).
void showErrorToast(BuildContext context, String message) {
  showToast(context, message);
}

/// Shared confirm dialog. [confirmText] defaults to the localized 'Delete'.
Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String description,
    String? confirmText}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText ?? ctx.l10n.delete),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Small text-input dialog (recreates NewItemDialog). [confirmText]
/// defaults to the localized 'Create'.
Future<String?> promptDialog(BuildContext context,
    {required String title,
    String label = '',
    String? confirmText}) async {
  final ctrl = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(confirmText ?? ctx.l10n.create),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return r;
}
