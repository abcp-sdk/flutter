import 'package:flutter/material.dart';

import '../i18n.dart';

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
