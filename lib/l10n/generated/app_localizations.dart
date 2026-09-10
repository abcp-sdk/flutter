import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'ZergX'**
  String get appTitle;

  /// No description provided for @gatewayUrl.
  ///
  /// In zh, this message translates to:
  /// **'网关地址'**
  String get gatewayUrl;

  /// No description provided for @tokenLabel.
  ///
  /// In zh, this message translates to:
  /// **'令牌'**
  String get tokenLabel;

  /// No description provided for @connect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In zh, this message translates to:
  /// **'连接中…'**
  String get connecting;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索会话名称'**
  String get searchHint;

  /// No description provided for @createNewOrg.
  ///
  /// In zh, this message translates to:
  /// **'新建组织'**
  String get createNewOrg;

  /// No description provided for @createNewRepo.
  ///
  /// In zh, this message translates to:
  /// **'新建仓库…'**
  String get createNewRepo;

  /// No description provided for @createCloneRepo.
  ///
  /// In zh, this message translates to:
  /// **'克隆仓库…'**
  String get createCloneRepo;

  /// No description provided for @chooseOrg.
  ///
  /// In zh, this message translates to:
  /// **'选择组织'**
  String get chooseOrg;

  /// No description provided for @createOrgFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先创建组织'**
  String get createOrgFirst;

  /// No description provided for @recent.
  ///
  /// In zh, this message translates to:
  /// **'最近'**
  String get recent;

  /// No description provided for @allRepos.
  ///
  /// In zh, this message translates to:
  /// **'所有仓库'**
  String get allRepos;

  /// No description provided for @noRepos.
  ///
  /// In zh, this message translates to:
  /// **'暂无仓库，先创建一个会话吧。'**
  String get noRepos;

  /// No description provided for @me.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get me;

  /// No description provided for @tabChat.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get tabChat;

  /// No description provided for @tabCode.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get tabCode;

  /// No description provided for @tabContainers.
  ///
  /// In zh, this message translates to:
  /// **'容器'**
  String get tabContainers;

  /// No description provided for @tabPackages.
  ///
  /// In zh, this message translates to:
  /// **'包'**
  String get tabPackages;

  /// No description provided for @tabConfig.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabConfig;

  /// No description provided for @contextTokens.
  ///
  /// In zh, this message translates to:
  /// **'上下文'**
  String get contextTokens;

  /// No description provided for @loadError.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{arg1}'**
  String loadError(String arg1);

  /// No description provided for @markRead.
  ///
  /// In zh, this message translates to:
  /// **'标记已读'**
  String get markRead;

  /// No description provided for @typeMessage.
  ///
  /// In zh, this message translates to:
  /// **'输入消息…'**
  String get typeMessage;

  /// No description provided for @chatTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get chatTitle;

  /// No description provided for @thinkLabel.
  ///
  /// In zh, this message translates to:
  /// **'思考'**
  String get thinkLabel;

  /// No description provided for @compactedLabel.
  ///
  /// In zh, this message translates to:
  /// **'历史已压缩 · 查看摘要'**
  String get compactedLabel;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @undo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get undo;

  /// No description provided for @undoTitle.
  ///
  /// In zh, this message translates to:
  /// **'撤销此消息？'**
  String get undoTitle;

  /// No description provided for @undoBody.
  ///
  /// In zh, this message translates to:
  /// **'将删除该消息，并撤销之后的所有消息。'**
  String get undoBody;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @apply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get apply;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get loading;

  /// No description provided for @loadEarlier.
  ///
  /// In zh, this message translates to:
  /// **'加载更早的消息'**
  String get loadEarlier;

  /// No description provided for @noChanges.
  ///
  /// In zh, this message translates to:
  /// **'无变更'**
  String get noChanges;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中…'**
  String get thinking;

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'运行中…'**
  String get running;

  /// No description provided for @sendFailed.
  ///
  /// In zh, this message translates to:
  /// **'发送失败: {arg1}'**
  String sendFailed(String arg1);

  /// No description provided for @attach.
  ///
  /// In zh, this message translates to:
  /// **'添加附件'**
  String get attach;

  /// No description provided for @image.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get image;

  /// No description provided for @takePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get takePhoto;

  /// No description provided for @chooseImage.
  ///
  /// In zh, this message translates to:
  /// **'从相册选图'**
  String get chooseImage;

  /// No description provided for @chooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get chooseFile;

  /// No description provided for @waitUpload.
  ///
  /// In zh, this message translates to:
  /// **'附件仍在上传中，请稍候'**
  String get waitUpload;

  /// No description provided for @downloaded.
  ///
  /// In zh, this message translates to:
  /// **'已下载到'**
  String get downloaded;

  /// No description provided for @sessionSettings.
  ///
  /// In zh, this message translates to:
  /// **'会话设置'**
  String get sessionSettings;

  /// No description provided for @compactHistory.
  ///
  /// In zh, this message translates to:
  /// **'压缩历史'**
  String get compactHistory;

  /// No description provided for @timeline.
  ///
  /// In zh, this message translates to:
  /// **'时间线'**
  String get timeline;

  /// No description provided for @files.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get files;

  /// No description provided for @mailbox.
  ///
  /// In zh, this message translates to:
  /// **'收件箱'**
  String get mailbox;

  /// No description provided for @container.
  ///
  /// In zh, this message translates to:
  /// **'容器'**
  String get container;

  /// No description provided for @todos.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get todos;

  /// No description provided for @deleteSession.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get deleteSession;

  /// No description provided for @historyCompacted.
  ///
  /// In zh, this message translates to:
  /// **'历史已压缩'**
  String get historyCompacted;

  /// No description provided for @nothingToCompact.
  ///
  /// In zh, this message translates to:
  /// **'历史太短，无需压缩'**
  String get nothingToCompact;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @viewOutput.
  ///
  /// In zh, this message translates to:
  /// **'查看实时输出'**
  String get viewOutput;

  /// No description provided for @taskProgress.
  ///
  /// In zh, this message translates to:
  /// **'任务进度'**
  String get taskProgress;

  /// No description provided for @taskDone.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get taskDone;

  /// No description provided for @taskFailed.
  ///
  /// In zh, this message translates to:
  /// **'已失败'**
  String get taskFailed;

  /// No description provided for @viewChange.
  ///
  /// In zh, this message translates to:
  /// **'查看变更'**
  String get viewChange;

  /// No description provided for @changeDiff.
  ///
  /// In zh, this message translates to:
  /// **'变更对比'**
  String get changeDiff;

  /// No description provided for @you.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get you;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话设置'**
  String get settingsTitle;

  /// No description provided for @modelLabel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get modelLabel;

  /// No description provided for @variantLabel.
  ///
  /// In zh, this message translates to:
  /// **'推理档位'**
  String get variantLabel;

  /// No description provided for @variantNone.
  ///
  /// In zh, this message translates to:
  /// **'默认（不指定档位）'**
  String get variantNone;

  /// No description provided for @presetLabel.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get presetLabel;

  /// No description provided for @maxTurnsLabel.
  ///
  /// In zh, this message translates to:
  /// **'最大轮数'**
  String get maxTurnsLabel;

  /// No description provided for @sysPromptLabel.
  ///
  /// In zh, this message translates to:
  /// **'系统提示（留空继承）'**
  String get sysPromptLabel;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In zh, this message translates to:
  /// **'删除会话\"{arg1}\"？'**
  String deleteSessionBody(String arg1);

  /// No description provided for @deleteSessionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get deleteSessionsTitle;

  /// No description provided for @deleteSessionsBody.
  ///
  /// In zh, this message translates to:
  /// **'删除选中的 {arg1} 个会话？此操作不可撤销。'**
  String deleteSessionsBody(String arg1);

  /// No description provided for @selectSessions.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get selectSessions;

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get selectNone;

  /// No description provided for @selectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {arg1} 项'**
  String selectedCount(String arg1);

  /// No description provided for @addModel.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get addModel;

  /// No description provided for @noTest.
  ///
  /// In zh, this message translates to:
  /// **'不可测试'**
  String get noTest;

  /// No description provided for @capText.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get capText;

  /// No description provided for @capImage.
  ///
  /// In zh, this message translates to:
  /// **'图像'**
  String get capImage;

  /// No description provided for @capVideo.
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get capVideo;

  /// No description provided for @capSpeech.
  ///
  /// In zh, this message translates to:
  /// **'语音'**
  String get capSpeech;

  /// No description provided for @newOrg.
  ///
  /// In zh, this message translates to:
  /// **'新建组织'**
  String get newOrg;

  /// No description provided for @orgNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'组织名称'**
  String get orgNameLabel;

  /// No description provided for @newRepoIn.
  ///
  /// In zh, this message translates to:
  /// **'在 {arg1} 新建仓库'**
  String newRepoIn(String arg1);

  /// No description provided for @repoNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'仓库名称'**
  String get repoNameLabel;

  /// No description provided for @cloneInto.
  ///
  /// In zh, this message translates to:
  /// **'克隆到 {arg1}'**
  String cloneInto(String arg1);

  /// No description provided for @gitUrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'Git 地址'**
  String get gitUrlLabel;

  /// No description provided for @repoName2.
  ///
  /// In zh, this message translates to:
  /// **'仓库名称'**
  String get repoName2;

  /// No description provided for @accessTokenOpt.
  ///
  /// In zh, this message translates to:
  /// **'访问令牌（可选）'**
  String get accessTokenOpt;

  /// No description provided for @revOpt.
  ///
  /// In zh, this message translates to:
  /// **'分支 / 标签 / 提交（可选）'**
  String get revOpt;

  /// No description provided for @clone.
  ///
  /// In zh, this message translates to:
  /// **'克隆'**
  String get clone;

  /// No description provided for @deleteOrgTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除组织'**
  String get deleteOrgTitle;

  /// No description provided for @deleteRepoTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除仓库'**
  String get deleteRepoTitle;

  /// No description provided for @deleteOrgBody.
  ///
  /// In zh, this message translates to:
  /// **'删除组织 {arg1}？将移除其所有仓库和会话。'**
  String deleteOrgBody(String arg1);

  /// No description provided for @deleteRepoBody.
  ///
  /// In zh, this message translates to:
  /// **'删除仓库 {arg1}/{arg2}？将移除其所有会话。'**
  String deleteRepoBody(String arg1, String arg2);

  /// No description provided for @fork.
  ///
  /// In zh, this message translates to:
  /// **'分叉'**
  String get fork;

  /// No description provided for @forkBranchLabel.
  ///
  /// In zh, this message translates to:
  /// **'分支名称'**
  String get forkBranchLabel;

  /// No description provided for @branchExists.
  ///
  /// In zh, this message translates to:
  /// **'分支已存在'**
  String get branchExists;

  /// No description provided for @adoptFailed.
  ///
  /// In zh, this message translates to:
  /// **'接管失败: {arg1}'**
  String adoptFailed(String arg1);

  /// No description provided for @cloneFailed.
  ///
  /// In zh, this message translates to:
  /// **'克隆失败: {arg1}'**
  String cloneFailed(String arg1);

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'失败: {arg1}'**
  String failed(String arg1);

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @darkModeSub.
  ///
  /// In zh, this message translates to:
  /// **'切换深/浅色外观'**
  String get darkModeSub;

  /// No description provided for @llm.
  ///
  /// In zh, this message translates to:
  /// **'语言模型'**
  String get llm;

  /// No description provided for @llmProviders.
  ///
  /// In zh, this message translates to:
  /// **'供应商'**
  String get llmProviders;

  /// No description provided for @providers.
  ///
  /// In zh, this message translates to:
  /// **'供应商'**
  String get providers;

  /// No description provided for @presets.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get presets;

  /// No description provided for @workspace.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get workspace;

  /// No description provided for @tools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get tools;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @logoutBody.
  ///
  /// In zh, this message translates to:
  /// **'将清除已保存的网关地址与令牌，并返回登录页。'**
  String get logoutBody;

  /// No description provided for @switchBackend.
  ///
  /// In zh, this message translates to:
  /// **'切换后端'**
  String get switchBackend;

  /// No description provided for @backendsTitle.
  ///
  /// In zh, this message translates to:
  /// **'后端'**
  String get backendsTitle;

  /// No description provided for @noSavedBackends.
  ///
  /// In zh, this message translates to:
  /// **'暂无已保存的后端。'**
  String get noSavedBackends;

  /// No description provided for @addBackend.
  ///
  /// In zh, this message translates to:
  /// **'添加新后端'**
  String get addBackend;

  /// No description provided for @deleteBackend.
  ///
  /// In zh, this message translates to:
  /// **'移除后端'**
  String get deleteBackend;

  /// No description provided for @backendSection.
  ///
  /// In zh, this message translates to:
  /// **'后端'**
  String get backendSection;

  /// No description provided for @providerTemplate.
  ///
  /// In zh, this message translates to:
  /// **'模板（models.dev）'**
  String get providerTemplate;

  /// No description provided for @providerTemplateHint.
  ///
  /// In zh, this message translates to:
  /// **'选择服务商自动填充'**
  String get providerTemplateHint;

  /// No description provided for @searchModels.
  ///
  /// In zh, this message translates to:
  /// **'搜索模型…'**
  String get searchModels;

  /// No description provided for @modelsSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选 {arg1} / {arg2}'**
  String modelsSelected(String arg1, String arg2);

  /// No description provided for @noProviders.
  ///
  /// In zh, this message translates to:
  /// **'暂无供应商，添加一个开始使用。'**
  String get noProviders;

  /// No description provided for @addProvider.
  ///
  /// In zh, this message translates to:
  /// **'添加供应商'**
  String get addProvider;

  /// No description provided for @deleteProvider.
  ///
  /// In zh, this message translates to:
  /// **'删除供应商'**
  String get deleteProvider;

  /// No description provided for @deleteProviderBody.
  ///
  /// In zh, this message translates to:
  /// **'删除供应商 {arg1}？'**
  String deleteProviderBody(String arg1);

  /// No description provided for @modelsCount.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 个模型'**
  String modelsCount(String arg1);

  /// No description provided for @providerId.
  ///
  /// In zh, this message translates to:
  /// **'供应商 ID'**
  String get providerId;

  /// No description provided for @providerTitle.
  ///
  /// In zh, this message translates to:
  /// **'供应商：{arg1}（{arg2}）'**
  String providerTitle(String arg1, String arg2);

  /// No description provided for @providerIdReq.
  ///
  /// In zh, this message translates to:
  /// **'供应商 ID（必填）'**
  String get providerIdReq;

  /// No description provided for @providerIdLabel.
  ///
  /// In zh, this message translates to:
  /// **'供应商 ID'**
  String get providerIdLabel;

  /// No description provided for @apiType.
  ///
  /// In zh, this message translates to:
  /// **'API 类型'**
  String get apiType;

  /// No description provided for @apiTypeOpenai.
  ///
  /// In zh, this message translates to:
  /// **'OpenAI'**
  String get apiTypeOpenai;

  /// No description provided for @apiTypeAnthropic.
  ///
  /// In zh, this message translates to:
  /// **'Anthropic'**
  String get apiTypeAnthropic;

  /// No description provided for @apiTypeGemini.
  ///
  /// In zh, this message translates to:
  /// **'Gemini'**
  String get apiTypeGemini;

  /// No description provided for @baseUrl.
  ///
  /// In zh, this message translates to:
  /// **'基础地址'**
  String get baseUrl;

  /// No description provided for @apiKey.
  ///
  /// In zh, this message translates to:
  /// **'API 密钥'**
  String get apiKey;

  /// No description provided for @test.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get test;

  /// No description provided for @testing.
  ///
  /// In zh, this message translates to:
  /// **'测试中…'**
  String get testing;

  /// No description provided for @register.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// No description provided for @registering.
  ///
  /// In zh, this message translates to:
  /// **'注册中…'**
  String get registering;

  /// No description provided for @saved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get saved;

  /// No description provided for @noConfig.
  ///
  /// In zh, this message translates to:
  /// **'无配置'**
  String get noConfig;

  /// No description provided for @configured.
  ///
  /// In zh, this message translates to:
  /// **'已配置'**
  String get configured;

  /// No description provided for @needsConfig.
  ///
  /// In zh, this message translates to:
  /// **'需配置'**
  String get needsConfig;

  /// No description provided for @newPreset.
  ///
  /// In zh, this message translates to:
  /// **'新建预设'**
  String get newPreset;

  /// No description provided for @presetId.
  ///
  /// In zh, this message translates to:
  /// **'预设 ID…'**
  String get presetId;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @noPresets.
  ///
  /// In zh, this message translates to:
  /// **'暂无预设。'**
  String get noPresets;

  /// No description provided for @deletePreset.
  ///
  /// In zh, this message translates to:
  /// **'删除预设'**
  String get deletePreset;

  /// No description provided for @deletePresetBody.
  ///
  /// In zh, this message translates to:
  /// **'删除预设 {arg1}？'**
  String deletePresetBody(String arg1);

  /// No description provided for @presetSummary.
  ///
  /// In zh, this message translates to:
  /// **'最大 {arg1} 轮 · {arg2} 个工具'**
  String presetSummary(String arg1, String arg2);

  /// No description provided for @systemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'系统提示'**
  String get systemPrompt;

  /// No description provided for @maxTurns.
  ///
  /// In zh, this message translates to:
  /// **'最大轮数'**
  String get maxTurns;

  /// No description provided for @containersTitle.
  ///
  /// In zh, this message translates to:
  /// **'容器'**
  String get containersTitle;

  /// No description provided for @deployments.
  ///
  /// In zh, this message translates to:
  /// **'部署'**
  String get deployments;

  /// No description provided for @noDeployments.
  ///
  /// In zh, this message translates to:
  /// **'暂无部署。'**
  String get noDeployments;

  /// No description provided for @sandboxes.
  ///
  /// In zh, this message translates to:
  /// **'沙箱'**
  String get sandboxes;

  /// No description provided for @noContainers.
  ///
  /// In zh, this message translates to:
  /// **'没有运行中的容器。'**
  String get noContainers;

  /// No description provided for @deployService.
  ///
  /// In zh, this message translates to:
  /// **'部署服务'**
  String get deployService;

  /// No description provided for @terminal.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get terminal;

  /// No description provided for @ready.
  ///
  /// In zh, this message translates to:
  /// **'{arg1}/{arg2} 就绪'**
  String ready(String arg1, String arg2);

  /// No description provided for @deleteDeploymentTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除部署'**
  String get deleteDeploymentTitle;

  /// No description provided for @deleteDeploymentBody.
  ///
  /// In zh, this message translates to:
  /// **'删除部署 {arg1}？'**
  String deleteDeploymentBody(String arg1);

  /// No description provided for @deleteSandboxTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除沙箱'**
  String get deleteSandboxTitle;

  /// No description provided for @deleteSandboxBody.
  ///
  /// In zh, this message translates to:
  /// **'删除沙箱 {arg1}？其中运行的任务将被终止。'**
  String deleteSandboxBody(String arg1);

  /// No description provided for @terminalTab.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get terminalTab;

  /// No description provided for @jobsTab.
  ///
  /// In zh, this message translates to:
  /// **'任务'**
  String get jobsTab;

  /// No description provided for @commandHint.
  ///
  /// In zh, this message translates to:
  /// **'输入命令…'**
  String get commandHint;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @noOutput.
  ///
  /// In zh, this message translates to:
  /// **'无输出'**
  String get noOutput;

  /// No description provided for @noSession.
  ///
  /// In zh, this message translates to:
  /// **'无会话'**
  String get noSession;

  /// No description provided for @noJobs.
  ///
  /// In zh, this message translates to:
  /// **'暂无任务'**
  String get noJobs;

  /// No description provided for @noWorker.
  ///
  /// In zh, this message translates to:
  /// **'还没有 worker 容器 — agent 运行 bash 等工具时自动创建。'**
  String get noWorker;

  /// No description provided for @createContainerNow.
  ///
  /// In zh, this message translates to:
  /// **'立即创建容器'**
  String get createContainerNow;

  /// No description provided for @backgrounded.
  ///
  /// In zh, this message translates to:
  /// **'[{arg1}] 已转入后台（见任务页）'**
  String backgrounded(String arg1);

  /// No description provided for @packagesTitle.
  ///
  /// In zh, this message translates to:
  /// **'包'**
  String get packagesTitle;

  /// No description provided for @registries.
  ///
  /// In zh, this message translates to:
  /// **'注册表'**
  String get registries;

  /// No description provided for @packagesTab.
  ///
  /// In zh, this message translates to:
  /// **'包'**
  String get packagesTab;

  /// No description provided for @filterEcosystems.
  ///
  /// In zh, this message translates to:
  /// **'过滤生态…'**
  String get filterEcosystems;

  /// No description provided for @proxyRegistries.
  ///
  /// In zh, this message translates to:
  /// **'代理注册表（{arg1}）'**
  String proxyRegistries(String arg1);

  /// No description provided for @endpointCopied.
  ///
  /// In zh, this message translates to:
  /// **'端点已复制'**
  String get endpointCopied;

  /// No description provided for @ociCatalog.
  ///
  /// In zh, this message translates to:
  /// **'OCI 镜像目录（{arg1}）'**
  String ociCatalog(String arg1);

  /// No description provided for @noImages.
  ///
  /// In zh, this message translates to:
  /// **'暂无镜像。'**
  String get noImages;

  /// No description provided for @searchPackages.
  ///
  /// In zh, this message translates to:
  /// **'搜索包…'**
  String get searchPackages;

  /// No description provided for @typeLabel.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get typeLabel;

  /// No description provided for @prev.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get prev;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get next;

  /// No description provided for @deletePackage.
  ///
  /// In zh, this message translates to:
  /// **'删除包'**
  String get deletePackage;

  /// No description provided for @deletePackageBody.
  ///
  /// In zh, this message translates to:
  /// **'删除包 {arg1}（{arg2}）？'**
  String deletePackageBody(String arg1, String arg2);

  /// No description provided for @noVersions.
  ///
  /// In zh, this message translates to:
  /// **'暂无版本。'**
  String get noVersions;

  /// No description provided for @downloads.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 次下载'**
  String downloads(String arg1);

  /// No description provided for @noPackagesYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无已发布的包。'**
  String get noPackagesYet;

  /// No description provided for @versionsCount.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 个版本'**
  String versionsCount(String arg1);

  /// No description provided for @cachedPackages.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 个包'**
  String cachedPackages(String arg1);

  /// No description provided for @noUpstreamLocal.
  ///
  /// In zh, this message translates to:
  /// **'无上游（仅本地）'**
  String get noUpstreamLocal;

  /// No description provided for @nameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get nameLabel;

  /// No description provided for @imageLabel.
  ///
  /// In zh, this message translates to:
  /// **'镜像'**
  String get imageLabel;

  /// No description provided for @replicasLabel.
  ///
  /// In zh, this message translates to:
  /// **'副本数'**
  String get replicasLabel;

  /// No description provided for @portLabel.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get portLabel;

  /// No description provided for @sessionOptLabel.
  ///
  /// In zh, this message translates to:
  /// **'会话（可选）'**
  String get sessionOptLabel;

  /// No description provided for @repositories.
  ///
  /// In zh, this message translates to:
  /// **'仓库'**
  String get repositories;

  /// No description provided for @history.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get history;

  /// No description provided for @none.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get none;

  /// No description provided for @download.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @selectFile.
  ///
  /// In zh, this message translates to:
  /// **'选择一个文件查看'**
  String get selectFile;

  /// No description provided for @selectBookmark.
  ///
  /// In zh, this message translates to:
  /// **'选择书签浏览文件'**
  String get selectBookmark;

  /// No description provided for @noCommits.
  ///
  /// In zh, this message translates to:
  /// **'暂无提交'**
  String get noCommits;

  /// No description provided for @noHistory.
  ///
  /// In zh, this message translates to:
  /// **'该文件暂无历史。'**
  String get noHistory;

  /// No description provided for @noChangesYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无变更'**
  String get noChangesYet;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get noMessages;

  /// No description provided for @noTodosYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无待办 — agent 通过 todowrite 在此跟踪计划。'**
  String get noTodosYet;

  /// No description provided for @noDescription.
  ///
  /// In zh, this message translates to:
  /// **'（无描述）'**
  String get noDescription;

  /// No description provided for @consumed.
  ///
  /// In zh, this message translates to:
  /// **'已消费'**
  String get consumed;

  /// No description provided for @pending.
  ///
  /// In zh, this message translates to:
  /// **'待审批'**
  String get pending;

  /// No description provided for @browserTitle.
  ///
  /// In zh, this message translates to:
  /// **'浏览'**
  String get browserTitle;

  /// No description provided for @bookmarksSection.
  ///
  /// In zh, this message translates to:
  /// **'书签'**
  String get bookmarksSection;

  /// No description provided for @reposCount.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 个仓库'**
  String reposCount(String arg1);

  /// No description provided for @overview.
  ///
  /// In zh, this message translates to:
  /// **'概要'**
  String get overview;

  /// No description provided for @releasesTab.
  ///
  /// In zh, this message translates to:
  /// **'发布'**
  String get releasesTab;

  /// No description provided for @branchesTab.
  ///
  /// In zh, this message translates to:
  /// **'分支'**
  String get branchesTab;

  /// No description provided for @defaultBranch.
  ///
  /// In zh, this message translates to:
  /// **'默认分支'**
  String get defaultBranch;

  /// No description provided for @recentCommits.
  ///
  /// In zh, this message translates to:
  /// **'最近提交'**
  String get recentCommits;

  /// No description provided for @noBranches.
  ///
  /// In zh, this message translates to:
  /// **'暂无分支'**
  String get noBranches;

  /// No description provided for @noReleases.
  ///
  /// In zh, this message translates to:
  /// **'暂无发布。'**
  String get noReleases;

  /// No description provided for @assetsCount.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 个附件'**
  String assetsCount(String arg1);

  /// No description provided for @draftBadge.
  ///
  /// In zh, this message translates to:
  /// **'草稿'**
  String get draftBadge;

  /// No description provided for @prereleaseBadge.
  ///
  /// In zh, this message translates to:
  /// **'预发布'**
  String get prereleaseBadge;

  /// No description provided for @downloadSource.
  ///
  /// In zh, this message translates to:
  /// **'下载源码 (tar.gz)'**
  String get downloadSource;

  /// No description provided for @downloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中'**
  String get downloading;

  /// No description provided for @savedToDownloads.
  ///
  /// In zh, this message translates to:
  /// **'已保存到「下载」：{arg1}'**
  String savedToDownloads(String arg1);

  /// No description provided for @savedToAppDir.
  ///
  /// In zh, this message translates to:
  /// **'已保存：{arg1}'**
  String savedToAppDir(String arg1);

  /// No description provided for @downloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败：{arg1}'**
  String downloadFailed(String arg1);

  /// No description provided for @newRepoInOrg.
  ///
  /// In zh, this message translates to:
  /// **'在此组织新建仓库'**
  String get newRepoInOrg;

  /// No description provided for @pickRepo.
  ///
  /// In zh, this message translates to:
  /// **'选择仓库'**
  String get pickRepo;

  /// No description provided for @pickBranch.
  ///
  /// In zh, this message translates to:
  /// **'选择分支'**
  String get pickBranch;

  /// No description provided for @pickOrg.
  ///
  /// In zh, this message translates to:
  /// **'选择组织'**
  String get pickOrg;

  /// No description provided for @codeEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'先选一个 org / repo / 书签开始浏览代码'**
  String get codeEmptyHint;

  /// No description provided for @backToList.
  ///
  /// In zh, this message translates to:
  /// **'返回列表'**
  String get backToList;

  /// No description provided for @timeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeMinAgo.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 分钟前'**
  String timeMinAgo(String arg1);

  /// No description provided for @timeHour.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 小时前'**
  String timeHour(String arg1);

  /// No description provided for @timeDay.
  ///
  /// In zh, this message translates to:
  /// **'{arg1} 天前'**
  String timeDay(String arg1);

  /// No description provided for @baseUrlReq.
  ///
  /// In zh, this message translates to:
  /// **'基础地址（必填）'**
  String get baseUrlReq;

  /// No description provided for @apiKeyReq.
  ///
  /// In zh, this message translates to:
  /// **'API 密钥（必填）'**
  String get apiKeyReq;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @noTools.
  ///
  /// In zh, this message translates to:
  /// **'暂无工具'**
  String get noTools;

  /// No description provided for @packPageOf.
  ///
  /// In zh, this message translates to:
  /// **'{arg1}–{arg2} / 共{arg3}'**
  String packPageOf(String arg1, String arg2, String arg3);

  /// No description provided for @syncRepo.
  ///
  /// In zh, this message translates to:
  /// **'同步'**
  String get syncRepo;

  /// No description provided for @pullFromRemote.
  ///
  /// In zh, this message translates to:
  /// **'从远程拉取'**
  String get pullFromRemote;

  /// No description provided for @pushToRemote.
  ///
  /// In zh, this message translates to:
  /// **'推送到远程'**
  String get pushToRemote;

  /// No description provided for @pullConfirm.
  ///
  /// In zh, this message translates to:
  /// **'拉取'**
  String get pullConfirm;

  /// No description provided for @pushConfirm.
  ///
  /// In zh, this message translates to:
  /// **'推送'**
  String get pushConfirm;

  /// No description provided for @secretLabel.
  ///
  /// In zh, this message translates to:
  /// **'访问令牌（可选，用于鉴权）'**
  String get secretLabel;

  /// No description provided for @pullDone.
  ///
  /// In zh, this message translates to:
  /// **'已从远程拉取'**
  String get pullDone;

  /// No description provided for @pushDone.
  ///
  /// In zh, this message translates to:
  /// **'已推送到远程'**
  String get pushDone;

  /// No description provided for @syncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败：{e}'**
  String syncFailed(String e);

  /// No description provided for @mirrorSettings.
  ///
  /// In zh, this message translates to:
  /// **'镜像设置'**
  String get mirrorSettings;

  /// No description provided for @pullUrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'拉取地址'**
  String get pullUrlLabel;

  /// No description provided for @pushUrlLabel.
  ///
  /// In zh, this message translates to:
  /// **'推送地址'**
  String get pushUrlLabel;

  /// No description provided for @secretSetPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'已设置（留空保持不变）'**
  String get secretSetPlaceholder;

  /// No description provided for @secretKeepToUpdate.
  ///
  /// In zh, this message translates to:
  /// **'已保存过凭证，输入新值可更新'**
  String get secretKeepToUpdate;

  /// No description provided for @clearMirror.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get clearMirror;

  /// No description provided for @savedMirror.
  ///
  /// In zh, this message translates to:
  /// **'镜像设置已保存'**
  String get savedMirror;

  /// No description provided for @agentLocale.
  ///
  /// In zh, this message translates to:
  /// **'Agent 语言'**
  String get agentLocale;

  /// No description provided for @agentLocaleSub.
  ///
  /// In zh, this message translates to:
  /// **'控制 agent 拼提示词与工具描述的语言（跟随/中文/English），写入后端并即时生效'**
  String get agentLocaleSub;

  /// No description provided for @agentLocaleFollow.
  ///
  /// In zh, this message translates to:
  /// **'跟随（UI 语言）'**
  String get agentLocaleFollow;

  /// No description provided for @agentLocaleApplied.
  ///
  /// In zh, this message translates to:
  /// **'Agent 语言已切换为 {l}'**
  String agentLocaleApplied(String l);

  /// No description provided for @toolParams.
  ///
  /// In zh, this message translates to:
  /// **'参数'**
  String get toolParams;

  /// No description provided for @showMore.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get showLess;

  /// No description provided for @vlmModelLabel.
  ///
  /// In zh, this message translates to:
  /// **'视觉模型'**
  String get vlmModelLabel;

  /// No description provided for @configValueHint.
  ///
  /// In zh, this message translates to:
  /// **'输入值后回车保存'**
  String get configValueHint;

  /// No description provided for @systemPresetBadge.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get systemPresetBadge;

  /// No description provided for @readOnlyPreset.
  ///
  /// In zh, this message translates to:
  /// **'系统预设：只读，不可编辑'**
  String get readOnlyPreset;

  /// No description provided for @sysPromptByPreset.
  ///
  /// In zh, this message translates to:
  /// **'系统提示由所选预设决定，不可直接修改。'**
  String get sysPromptByPreset;

  /// No description provided for @requiredConfig.
  ///
  /// In zh, this message translates to:
  /// **'必需配置'**
  String get requiredConfig;

  /// No description provided for @selectProviderFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择服务商'**
  String get selectProviderFirst;

  /// No description provided for @noModelsForProvider.
  ///
  /// In zh, this message translates to:
  /// **'该服务商已注册暂无模型'**
  String get noModelsForProvider;

  /// No description provided for @apiTypeOpenaiCompat.
  ///
  /// In zh, this message translates to:
  /// **'OpenAI 兼容'**
  String get apiTypeOpenaiCompat;

  /// No description provided for @modelsLabel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get modelsLabel;

  /// No description provided for @modelIdLabel.
  ///
  /// In zh, this message translates to:
  /// **'模型 ID…'**
  String get modelIdLabel;

  /// No description provided for @contextLengthLabel.
  ///
  /// In zh, this message translates to:
  /// **'上下文'**
  String get contextLengthLabel;

  /// No description provided for @contextLengthRequired.
  ///
  /// In zh, this message translates to:
  /// **'必须填写上下文长度（正整数）。'**
  String get contextLengthRequired;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @enterToAddHint.
  ///
  /// In zh, this message translates to:
  /// **'回车添加模型标签'**
  String get enterToAddHint;

  /// No description provided for @turnsByPreset.
  ///
  /// In zh, this message translates to:
  /// **'最大轮数由所选预设决定。'**
  String get turnsByPreset;

  /// No description provided for @testModelOk.
  ///
  /// In zh, this message translates to:
  /// **'模型可用：{arg1}'**
  String testModelOk(Object arg1);

  /// No description provided for @connected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connected;

  /// No description provided for @connectionError.
  ///
  /// In zh, this message translates to:
  /// **'连接错误：{arg1}'**
  String connectionError(Object arg1);

  /// No description provided for @toolInputParams.
  ///
  /// In zh, this message translates to:
  /// **'输入参数'**
  String get toolInputParams;

  /// No description provided for @content.
  ///
  /// In zh, this message translates to:
  /// **'内容'**
  String get content;

  /// No description provided for @metadata.
  ///
  /// In zh, this message translates to:
  /// **'元数据'**
  String get metadata;

  /// No description provided for @newSession.
  ///
  /// In zh, this message translates to:
  /// **'新会话'**
  String get newSession;

  /// No description provided for @noSessions.
  ///
  /// In zh, this message translates to:
  /// **'暂无会话'**
  String get noSessions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
