// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Agent';

  @override
  String get sessions => 'Sessions';

  @override
  String get newSession => 'New session';

  @override
  String get noSessions => 'No sessions';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get model => 'Model';

  @override
  String get preset => 'Preset';

  @override
  String get stop => 'Stop';

  @override
  String get compact => 'Compact';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get send => 'Send';

  @override
  String get messagePlaceholder => 'Type a message…';

  @override
  String get loading => 'Loading…';

  @override
  String get noMessages => 'No messages yet. Send one to start.';

  @override
  String get selectOrCreate => 'Select a session or create a new one';

  @override
  String get thinking => 'Thinking…';

  @override
  String get interrupt => 'Interrupt';

  @override
  String get error => 'Error';
}
