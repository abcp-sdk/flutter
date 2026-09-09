// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Agent';

  @override
  String get sessions => '会话';

  @override
  String get newSession => '新会话';

  @override
  String get noSessions => '暂无会话';

  @override
  String get rename => '重命名';

  @override
  String get fork => '派生';

  @override
  String get delete => '删除';

  @override
  String get model => '模型';

  @override
  String get preset => '预设';

  @override
  String get stop => '停止';

  @override
  String get compact => '压缩';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get send => '发送';

  @override
  String get messagePlaceholder => '输入消息…';

  @override
  String get loading => '加载中…';

  @override
  String get noMessages => '暂无消息，发送一条开始对话。';

  @override
  String get selectOrCreate => '选择一个会话或创建一个新的';

  @override
  String get thinking => '思考中…';

  @override
  String get interrupt => '中断';

  @override
  String get error => '出错了';
}
