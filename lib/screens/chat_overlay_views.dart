import 'package:flutter/material.dart';

import '../navigation.dart';
import '../store.dart';
import 'overlays.dart';

/// The body of a session sub-page, switching on the overlay type. Lives
/// separately so `chat_overlay_page.dart` (a nav page) can build it without an
/// import cycle.
class ChatOverlayViews extends StatelessWidget {
  final AppStore store;
  final SessionOverlay overlay;
  const ChatOverlayViews({super.key, required this.store, required this.overlay});

  @override
  Widget build(BuildContext context) {
    switch (overlay) {
      case SessionOverlay.mailbox:
        return MailboxOverlay(store: store);
    }
  }
}
