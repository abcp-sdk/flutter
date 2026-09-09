import 'package:flutter/material.dart';

import '../i18n.dart';
import '../navigation.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import 'chat_overlay_views.dart';
/// A session sub-page (mailbox), shown as its own page in the chat tab's
/// stack. It carries a close button to pop back.
class ChatOverlayPageWidget extends StatefulWidget {
  final AppStore store;
  final SessionOverlay overlay;
  const ChatOverlayPageWidget({super.key, required this.store, required this.overlay});

  @override
  State<ChatOverlayPageWidget> createState() => _ChatOverlayPageWidgetState();
}

class _ChatOverlayPageWidgetState extends State<ChatOverlayPageWidget> {
  AppStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final overlay = store.sessionOverlay ?? widget.overlay;
    return DecoratedBox(
      decoration: BoxDecoration(
          border: Border(
              left: BorderSide(color: colors.border.withValues(alpha: 0.5)))),
      child: Column(
        children: [
          SizedBox(
            height: AppBars.height,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  tooltip: context.l10n.back,
                  onPressed: () => store.popPage(),
                ),
                _OverlayTab(
                  label: _label(overlay),
                  selected: true,
                  onTap: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => store.popPage()),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  String _label(SessionOverlay ov) {
    return switch (ov) {
      SessionOverlay.mailbox => context.l10n.mailbox,
    };
  }

  Widget _buildBody() {
    final overlay = store.sessionOverlay ?? widget.overlay;
    return ChatOverlayViews(store: store, overlay: overlay);
  }
}

class _OverlayTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OverlayTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 1),
          decoration: BoxDecoration(
            color: selected ? colors.muted : Colors.transparent,
            borderRadius: AppRadius.rSm,
          ),
          child: Text(label,
              style: text.micro.copyWith(
                  color: selected ? colors.primary : colors.mutedForeground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }
}
