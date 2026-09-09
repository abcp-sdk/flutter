// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ZergX';

  @override
  String get gatewayUrl => '网关地址';

  @override
  String get tokenLabel => '令牌';

  @override
  String get connect => '连接';

  @override
  String get connecting => '连接中…';

  @override
  String get search => '搜索';

  @override
  String get searchHint => '搜索会话名称';

  @override
  String get createNewOrg => '新建组织';

  @override
  String get createNewRepo => '新建仓库…';

  @override
  String get createCloneRepo => '克隆仓库…';

  @override
  String get chooseOrg => '选择组织';

  @override
  String get createOrgFirst => '请先创建组织';

  @override
  String get recent => '最近';

  @override
  String get allRepos => '所有仓库';

  @override
  String get noRepos => '暂无仓库，先创建一个会话吧。';

  @override
  String get me => '我';

  @override
  String get tabChat => '会话';

  @override
  String get tabCode => '代码';

  @override
  String get tabContainers => '容器';

  @override
  String get tabPackages => '包';

  @override
  String get tabConfig => '设置';

  @override
  String get contextTokens => '上下文';

  @override
  String loadError(String arg1) {
    return '加载失败：$arg1';
  }

  @override
  String get markRead => '标记已读';

  @override
  String get typeMessage => '输入消息…';

  @override
  String get chatTitle => '会话';

  @override
  String get thinkLabel => '思考';

  @override
  String get compactedLabel => '历史已压缩 · 查看摘要';

  @override
  String get copied => '已复制';

  @override
  String get copy => '复制';

  @override
  String get error => '错误';

  @override
  String get undo => '撤销';

  @override
  String get undoTitle => '撤销此消息？';

  @override
  String get undoBody => '将删除该消息，并撤销之后的所有消息。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get apply => '应用';

  @override
  String get delete => '删除';

  @override
  String get loading => '加载中…';

  @override
  String get loadEarlier => '加载更早的消息';

  @override
  String get noChanges => '无变更';

  @override
  String get thinking => '思考中…';

  @override
  String get running => '运行中…';

  @override
  String sendFailed(String arg1) {
    return '发送失败: $arg1';
  }

  @override
  String get attach => '添加附件';

  @override
  String get image => '图片';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseImage => '从相册选图';

  @override
  String get chooseFile => '选择文件';

  @override
  String get waitUpload => '附件仍在上传中，请稍候';

  @override
  String get downloaded => '已下载到';

  @override
  String get sessionSettings => '会话设置';

  @override
  String get compactHistory => '压缩历史';

  @override
  String get timeline => '时间线';

  @override
  String get files => '文件';

  @override
  String get mailbox => '收件箱';

  @override
  String get container => '容器';

  @override
  String get todos => '待办';

  @override
  String get deleteSession => '删除会话';

  @override
  String get historyCompacted => '历史已压缩';

  @override
  String get nothingToCompact => '历史太短，无需压缩';

  @override
  String get back => '返回';

  @override
  String get refresh => '刷新';

  @override
  String get viewOutput => '查看实时输出';

  @override
  String get taskProgress => '任务进度';

  @override
  String get taskDone => '已完成';

  @override
  String get taskFailed => '已失败';

  @override
  String get viewChange => '查看变更';

  @override
  String get changeDiff => '变更对比';

  @override
  String get you => '我';

  @override
  String get settingsTitle => '会话设置';

  @override
  String get modelLabel => '模型';

  @override
  String get presetLabel => '预设';

  @override
  String get maxTurnsLabel => '最大轮数';

  @override
  String get sysPromptLabel => '系统提示（留空继承）';

  @override
  String get deleteSessionTitle => '删除会话';

  @override
  String deleteSessionBody(String arg1) {
    return '删除会话\"$arg1\"？';
  }

  @override
  String get newOrg => '新建组织';

  @override
  String get orgNameLabel => '组织名称';

  @override
  String newRepoIn(String arg1) {
    return '在 $arg1 新建仓库';
  }

  @override
  String get repoNameLabel => '仓库名称';

  @override
  String cloneInto(String arg1) {
    return '克隆到 $arg1';
  }

  @override
  String get gitUrlLabel => 'Git 地址';

  @override
  String get repoName2 => '仓库名称';

  @override
  String get accessTokenOpt => '访问令牌（可选）';

  @override
  String get revOpt => '分支 / 标签 / 提交（可选）';

  @override
  String get clone => '克隆';

  @override
  String get deleteOrgTitle => '删除组织';

  @override
  String get deleteRepoTitle => '删除仓库';

  @override
  String deleteOrgBody(String arg1) {
    return '删除组织 $arg1？将移除其所有仓库和会话。';
  }

  @override
  String deleteRepoBody(String arg1, String arg2) {
    return '删除仓库 $arg1/$arg2？将移除其所有会话。';
  }

  @override
  String get fork => '分叉';

  @override
  String get forkBranchLabel => '分支名称';

  @override
  String get branchExists => '分支已存在';

  @override
  String adoptFailed(String arg1) {
    return '接管失败: $arg1';
  }

  @override
  String cloneFailed(String arg1) {
    return '克隆失败: $arg1';
  }

  @override
  String failed(String arg1) {
    return '失败: $arg1';
  }

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSub => '切换深/浅色外观';

  @override
  String get llm => '语言模型';

  @override
  String get llmProviders => '供应商';

  @override
  String get providers => '供应商';

  @override
  String get presets => '预设';

  @override
  String get workspace => '工作区';

  @override
  String get tools => '工具';

  @override
  String get language => '语言';

  @override
  String get logout => '退出登录';

  @override
  String get logoutBody => '将清除已保存的网关地址与令牌，并返回登录页。';

  @override
  String get switchBackend => '切换后端';

  @override
  String get backendsTitle => '后端';

  @override
  String get noSavedBackends => '暂无已保存的后端。';

  @override
  String get addBackend => '添加新后端';

  @override
  String get deleteBackend => '移除后端';

  @override
  String get backendSection => '后端';

  @override
  String get providerTemplate => '模板（models.dev）';

  @override
  String get providerTemplateHint => '选择服务商自动填充';

  @override
  String get searchModels => '搜索模型…';

  @override
  String modelsSelected(String arg1, String arg2) {
    return '已选 $arg1 / $arg2';
  }

  @override
  String get noProviders => '暂无供应商，添加一个开始使用。';

  @override
  String get addProvider => '添加供应商';

  @override
  String get deleteProvider => '删除供应商';

  @override
  String deleteProviderBody(String arg1) {
    return '删除供应商 $arg1？';
  }

  @override
  String modelsCount(String arg1) {
    return '$arg1 个模型';
  }

  @override
  String get providerId => '供应商 ID';

  @override
  String providerTitle(String arg1, String arg2) {
    return '供应商：$arg1（$arg2）';
  }

  @override
  String get providerIdReq => '供应商 ID（必填）';

  @override
  String get providerIdLabel => '供应商 ID';

  @override
  String get apiType => 'API 类型';

  @override
  String get apiTypeOpenai => 'OpenAI';

  @override
  String get apiTypeAnthropic => 'Anthropic';

  @override
  String get apiTypeGemini => 'Gemini';

  @override
  String get baseUrl => '基础地址';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get test => '测试';

  @override
  String get testing => '测试中…';

  @override
  String get register => '注册';

  @override
  String get registering => '注册中…';

  @override
  String get saved => '已保存';

  @override
  String get noConfig => '无配置';

  @override
  String get configured => '已配置';

  @override
  String get needsConfig => '需配置';

  @override
  String get newPreset => '新建预设';

  @override
  String get presetId => '预设 ID…';

  @override
  String get create => '创建';

  @override
  String get noPresets => '暂无预设。';

  @override
  String get deletePreset => '删除预设';

  @override
  String deletePresetBody(String arg1) {
    return '删除预设 $arg1？';
  }

  @override
  String presetSummary(String arg1, String arg2) {
    return '最大 $arg1 轮 · $arg2 个工具';
  }

  @override
  String get systemPrompt => '系统提示';

  @override
  String get maxTurns => '最大轮数';

  @override
  String get containersTitle => '容器';

  @override
  String get deployments => '部署';

  @override
  String get noDeployments => '暂无部署。';

  @override
  String get sandboxes => '沙箱';

  @override
  String get noContainers => '没有运行中的容器。';

  @override
  String get deployService => '部署服务';

  @override
  String get terminal => '终端';

  @override
  String ready(String arg1, String arg2) {
    return '$arg1/$arg2 就绪';
  }

  @override
  String get deleteDeploymentTitle => '删除部署';

  @override
  String deleteDeploymentBody(String arg1) {
    return '删除部署 $arg1？';
  }

  @override
  String get deleteSandboxTitle => '删除沙箱';

  @override
  String deleteSandboxBody(String arg1) {
    return '删除沙箱 $arg1？其中运行的任务将被终止。';
  }

  @override
  String get terminalTab => '终端';

  @override
  String get jobsTab => '任务';

  @override
  String get commandHint => '输入命令…';

  @override
  String get close => '关闭';

  @override
  String get noOutput => '无输出';

  @override
  String get noSession => '无会话';

  @override
  String get noJobs => '暂无任务';

  @override
  String get noWorker => '还没有 worker 容器 — agent 运行 bash 等工具时自动创建。';

  @override
  String get createContainerNow => '立即创建容器';

  @override
  String backgrounded(String arg1) {
    return '[$arg1] 已转入后台（见任务页）';
  }

  @override
  String get packagesTitle => '包';

  @override
  String get registries => '注册表';

  @override
  String get packagesTab => '包';

  @override
  String get filterEcosystems => '过滤生态…';

  @override
  String proxyRegistries(String arg1) {
    return '代理注册表（$arg1）';
  }

  @override
  String get endpointCopied => '端点已复制';

  @override
  String ociCatalog(String arg1) {
    return 'OCI 镜像目录（$arg1）';
  }

  @override
  String get noImages => '暂无镜像。';

  @override
  String get searchPackages => '搜索包…';

  @override
  String get typeLabel => '类型';

  @override
  String get prev => '上一页';

  @override
  String get next => '下一页';

  @override
  String get deletePackage => '删除包';

  @override
  String deletePackageBody(String arg1, String arg2) {
    return '删除包 $arg1（$arg2）？';
  }

  @override
  String get noVersions => '暂无版本。';

  @override
  String downloads(String arg1) {
    return '$arg1 次下载';
  }

  @override
  String get noPackagesYet => '暂无已发布的包。';

  @override
  String versionsCount(String arg1) {
    return '$arg1 个版本';
  }

  @override
  String cachedPackages(String arg1) {
    return '$arg1 个包';
  }

  @override
  String get noUpstreamLocal => '无上游（仅本地）';

  @override
  String get nameLabel => '名称';

  @override
  String get imageLabel => '镜像';

  @override
  String get replicasLabel => '副本数';

  @override
  String get portLabel => '端口';

  @override
  String get sessionOptLabel => '会话（可选）';

  @override
  String get repositories => '仓库';

  @override
  String get history => '历史';

  @override
  String get none => '无';

  @override
  String get download => '下载';

  @override
  String get selectFile => '选择一个文件查看';

  @override
  String get selectBookmark => '选择书签浏览文件';

  @override
  String get noCommits => '暂无提交';

  @override
  String get noHistory => '该文件暂无历史。';

  @override
  String get noChangesYet => '暂无变更';

  @override
  String get noMessages => '暂无消息';

  @override
  String get noTodosYet => '暂无待办 — agent 通过 todowrite 在此跟踪计划。';

  @override
  String get noDescription => '（无描述）';

  @override
  String get consumed => '已消费';

  @override
  String get pending => '待审批';

  @override
  String get browserTitle => '浏览';

  @override
  String get bookmarksSection => '书签';

  @override
  String reposCount(String arg1) {
    return '$arg1 个仓库';
  }

  @override
  String get overview => '概要';

  @override
  String get releasesTab => '发布';

  @override
  String get branchesTab => '分支';

  @override
  String get defaultBranch => '默认分支';

  @override
  String get recentCommits => '最近提交';

  @override
  String get noBranches => '暂无分支';

  @override
  String get noReleases => '暂无发布。';

  @override
  String assetsCount(String arg1) {
    return '$arg1 个附件';
  }

  @override
  String get draftBadge => '草稿';

  @override
  String get prereleaseBadge => '预发布';

  @override
  String get downloadSource => '下载源码 (tar.gz)';

  @override
  String get downloading => '下载中';

  @override
  String savedToDownloads(String arg1) {
    return '已保存到「下载」：$arg1';
  }

  @override
  String savedToAppDir(String arg1) {
    return '已保存：$arg1';
  }

  @override
  String downloadFailed(String arg1) {
    return '下载失败：$arg1';
  }

  @override
  String get newRepoInOrg => '在此组织新建仓库';

  @override
  String get pickRepo => '选择仓库';

  @override
  String get pickBranch => '选择分支';

  @override
  String get pickOrg => '选择组织';

  @override
  String get codeEmptyHint => '先选一个 org / repo / 书签开始浏览代码';

  @override
  String get backToList => '返回列表';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinAgo(String arg1) {
    return '$arg1 分钟前';
  }

  @override
  String timeHour(String arg1) {
    return '$arg1 小时前';
  }

  @override
  String timeDay(String arg1) {
    return '$arg1 天前';
  }

  @override
  String get baseUrlReq => '基础地址（必填）';

  @override
  String get apiKeyReq => 'API 密钥（必填）';

  @override
  String get save => '保存';

  @override
  String get noTools => '暂无工具';

  @override
  String packPageOf(String arg1, String arg2, String arg3) {
    return '$arg1–$arg2 / 共$arg3';
  }

  @override
  String get syncRepo => '同步';

  @override
  String get pullFromRemote => '从远程拉取';

  @override
  String get pushToRemote => '推送到远程';

  @override
  String get pullConfirm => '拉取';

  @override
  String get pushConfirm => '推送';

  @override
  String get secretLabel => '访问令牌（可选，用于鉴权）';

  @override
  String get pullDone => '已从远程拉取';

  @override
  String get pushDone => '已推送到远程';

  @override
  String syncFailed(String e) {
    return '同步失败：$e';
  }

  @override
  String get mirrorSettings => '镜像设置';

  @override
  String get pullUrlLabel => '拉取地址';

  @override
  String get pushUrlLabel => '推送地址';

  @override
  String get secretSetPlaceholder => '已设置（留空保持不变）';

  @override
  String get secretKeepToUpdate => '已保存过凭证，输入新值可更新';

  @override
  String get clearMirror => '清除';

  @override
  String get savedMirror => '镜像设置已保存';

  @override
  String get agentLocale => 'Agent 语言';

  @override
  String get agentLocaleSub => '控制 agent 拼提示词与工具描述的语言（跟随/中文/English），写入后端并即时生效';

  @override
  String get agentLocaleFollow => '跟随（UI 语言）';

  @override
  String agentLocaleApplied(String l) {
    return 'Agent 语言已切换为 $l';
  }

  @override
  String get toolParams => '参数';

  @override
  String get showMore => '展开';

  @override
  String get showLess => '收起';

  @override
  String get vlmModelLabel => '视觉模型';

  @override
  String get configValueHint => '输入值后回车保存';

  @override
  String get systemPresetBadge => '系统';

  @override
  String get readOnlyPreset => '系统预设：只读，不可编辑';

  @override
  String get sysPromptByPreset => '系统提示由所选预设决定，不可直接修改。';

  @override
  String get requiredConfig => '必需配置';

  @override
  String get selectProviderFirst => '请先选择服务商';

  @override
  String get noModelsForProvider => '该服务商已注册暂无模型';

  @override
  String get apiTypeOpenaiCompat => 'OpenAI 兼容';

  @override
  String get modelsLabel => '模型';

  @override
  String get modelIdLabel => '模型 ID…';

  @override
  String get contextLengthLabel => '上下文';

  @override
  String get add => '添加';

  @override
  String get enterToAddHint => '回车添加模型标签';

  @override
  String get turnsByPreset => '最大轮数由所选预设决定。';

  @override
  String testModelOk(Object arg1) {
    return '模型可用：$arg1';
  }

  @override
  String get connected => '已连接';

  @override
  String connectionError(Object arg1) {
    return '连接错误：$arg1';
  }

  @override
  String get toolInputParams => '输入参数';

  @override
  String get content => '内容';

  @override
  String get metadata => '元数据';

  @override
  String get newSession => '新会话';

  @override
  String get noSessions => '暂无会话';
}
