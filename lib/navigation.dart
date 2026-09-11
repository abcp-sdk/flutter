/// Navigation types: per-tab page stacks and the page descriptors.
///
/// This file defines only the data model (enums + [AppPage]) and the stack root
/// factory. The widget-to-page dispatch lives in `page_builder.dart` so there is
/// no import cycle with `store.dart` (which consumes these types) or the page
/// widget files.
library;

import 'enums.dart';

export 'enums.dart' show SessionOverlay, SiderTab;

/// One view in a tab's navigation stack. An [AppPage] describes *which* view
/// to show; the widget itself reads live state (active session) from [AppStore].
sealed class AppPage {
  final String? key;
  const AppPage([this.key]);
}

/// Chat tab — bottom of the stack (sessions list).
class ChatListPage extends AppPage {
  const ChatListPage() : super('chat_list');
}

/// Chat tab — a conversation is open.
class ChatSessionPage extends AppPage {
  const ChatSessionPage() : super('chat_session');
}

/// Chat tab — a session sub-page (mailbox). [overlay] selects which.
class ChatOverlayPage extends AppPage {
  final SessionOverlay overlay;
  const ChatOverlayPage(this.overlay) : super('chat_overlay');
}

/// Config tab — bottom of the stack (settings list).
class ConfigRootPage extends AppPage {
  const ConfigRootPage() : super('config_root');
}

/// Config tab — a drill-in sub page (providers / presets / tools / …).
class ConfigSubPage extends AppPage {
  final String id;
  const ConfigSubPage(this.id) : super('config_sub_$id');
}

/// Config tab — the provider list (its own page with an add action in the bar).
class ProvidersListPage extends AppPage {
  const ProvidersListPage() : super('providers_list');
}

/// Config tab — add/edit a single provider's connection fields; its bottom
/// section lists the provider's models and offers "+" → [ProviderModelsPage].
class ProviderFormPage extends AppPage {
  const ProviderFormPage() : super('provider_form');
}

/// Config tab — a single model entry form. [modelId] selects the model being
/// edited, or null for a brand-new model. Used both for adding a model to the
/// provider draft and for tapping an existing model row to edit it.
class ProviderModelsPage extends AppPage {
  final String? modelId;
  ProviderModelsPage({this.modelId})
    : super('provider_model_${modelId ?? 'new'}');
}

/// The stack-bottom page for a given tab.
AppPage rootPageFor(SiderTab tab) => switch (tab) {
  SiderTab.chat => const ChatListPage(),
  SiderTab.config => const ConfigRootPage(),
};
