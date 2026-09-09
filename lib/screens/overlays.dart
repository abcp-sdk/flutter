import 'package:flutter/material.dart';

import '../i18n.dart';

import '../models.dart';
import '../store.dart';
import '../theme/app_theme.dart';

class MailboxOverlay extends StatefulWidget {
  final AppStore store;
  const MailboxOverlay({super.key, required this.store});

  @override
  State<MailboxOverlay> createState() => _MailboxOverlayState();
}

class _MailboxOverlayState extends State<MailboxOverlay> {
  AppStore get store => widget.store;
  List<MailboxEntry> _entries = [];
  int _rev = -1;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _load();
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (store.sessionRevision != _rev) {
      _rev = store.sessionRevision;
      _load();
    }
  }

  Future<void> _load() async {
    final sid = store.activeSessionId;
    if (sid == null) return;
    try {
      final e = await store.api.mailbox(sid);
      if (mounted) setState(() => _entries = e);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    if (_entries.isEmpty) {
      return Center(
          child: Text(context.l10n.noMessages,
              style: TextStyle(color: colors.mutedForeground)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _entries.length,
      itemBuilder: (_, i) {
        final e = _entries[i];
        final consumed = e.consumedAt != null;
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(e.msgType,
                        style: text.meta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary)),
                    const Spacer(),
                    Text(
                      consumed ? context.l10n.consumed : context.l10n.pending,
                      style: text.micro.copyWith(
                          color: consumed ? colors.success : colors.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                    e.payload.length > 500
                        ? '${e.payload.substring(0, 500)}…'
                        : e.payload,
                    style: text.mono.copyWith(
                        fontSize: 11, color: colors.mutedForeground)),
              ],
            ),
          ),
        );
      },
    );
  }
}
