/// Shared enum types used by both the store and the navigation model, kept in
/// their own file so `store.dart` and `navigation.dart` can both reference them
/// without an import cycle.
library;

enum SiderTab { chat, config }

enum SessionOverlay { mailbox }
