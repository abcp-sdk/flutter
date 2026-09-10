// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZergX';

  @override
  String get gatewayUrl => 'Gateway URL';

  @override
  String get tokenLabel => 'Token';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting...';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search session name';

  @override
  String get createNewOrg => 'New organization';

  @override
  String get createNewRepo => 'New repo…';

  @override
  String get createCloneRepo => 'Clone repo…';

  @override
  String get chooseOrg => 'Choose organization';

  @override
  String get createOrgFirst => 'Create an organization first';

  @override
  String get recent => 'Recent';

  @override
  String get allRepos => 'All repositories';

  @override
  String get noRepos => 'No repositories. Create a session first.';

  @override
  String get me => 'me';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabCode => 'Code';

  @override
  String get tabContainers => 'Containers';

  @override
  String get tabPackages => 'Packages';

  @override
  String get tabConfig => 'Config';

  @override
  String get contextTokens => 'Context';

  @override
  String loadError(String arg1) {
    return 'Load failed: $arg1';
  }

  @override
  String get markRead => 'Mark as read';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get chatTitle => 'Chat';

  @override
  String get thinkLabel => 'Thinking';

  @override
  String get compactedLabel => 'History compacted · view summary';

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get error => 'Error';

  @override
  String get undo => 'Undo';

  @override
  String get undoTitle => 'Undo this message?';

  @override
  String get undoBody => 'This deletes the message and everything after it.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get apply => 'Apply';

  @override
  String get delete => 'Delete';

  @override
  String get loading => 'Loading...';

  @override
  String get loadEarlier => 'Load earlier';

  @override
  String get noChanges => 'No changes';

  @override
  String get thinking => 'thinking...';

  @override
  String get running => 'running...';

  @override
  String sendFailed(String arg1) {
    return 'Send failed: $arg1';
  }

  @override
  String get attach => 'Attach file';

  @override
  String get image => 'image';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseImage => 'Choose from gallery';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get waitUpload => 'Attachment is still uploading';

  @override
  String get downloaded => 'Downloaded to';

  @override
  String get sessionSettings => 'Session settings';

  @override
  String get compactHistory => 'Compact history';

  @override
  String get timeline => 'Timeline';

  @override
  String get files => 'Files';

  @override
  String get mailbox => 'Mailbox';

  @override
  String get container => 'Container';

  @override
  String get todos => 'Todos';

  @override
  String get deleteSession => 'Delete session';

  @override
  String get historyCompacted => 'History compacted';

  @override
  String get nothingToCompact => 'Nothing to compact — history is short';

  @override
  String get back => 'Back';

  @override
  String get refresh => 'Refresh';

  @override
  String get viewOutput => 'View live output';

  @override
  String get taskProgress => 'Task progress';

  @override
  String get taskDone => 'Done';

  @override
  String get taskFailed => 'Failed';

  @override
  String get viewChange => 'View change';

  @override
  String get changeDiff => 'Change diff';

  @override
  String get you => 'me';

  @override
  String get settingsTitle => 'Session Settings';

  @override
  String get modelLabel => 'Model';

  @override
  String get variantLabel => 'Reasoning variant';

  @override
  String get variantNone => 'Default (no variant)';

  @override
  String get presetLabel => 'Preset';

  @override
  String get maxTurnsLabel => 'Max Turns';

  @override
  String get sysPromptLabel => 'System Prompt (blank = inherit)';

  @override
  String get deleteSessionTitle => 'Delete session';

  @override
  String deleteSessionBody(String arg1) {
    return 'Delete session \"$arg1\"?';
  }

  @override
  String get deleteSessionsTitle => 'Delete sessions';

  @override
  String deleteSessionsBody(String arg1) {
    return 'Delete $arg1 selected sessions? This cannot be undone.';
  }

  @override
  String get selectSessions => 'Select';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'Deselect all';

  @override
  String selectedCount(String arg1) {
    return '$arg1 selected';
  }

  @override
  String get newOrg => 'New organization';

  @override
  String get orgNameLabel => 'Organization name';

  @override
  String newRepoIn(String arg1) {
    return 'New repo in $arg1';
  }

  @override
  String get repoNameLabel => 'Repo name';

  @override
  String cloneInto(String arg1) {
    return 'Clone into $arg1';
  }

  @override
  String get gitUrlLabel => 'Git URL';

  @override
  String get repoName2 => 'Repo name';

  @override
  String get accessTokenOpt => 'Access token (optional)';

  @override
  String get revOpt => 'Branch / tag / commit (optional)';

  @override
  String get clone => 'Clone';

  @override
  String get deleteOrgTitle => 'Delete organization';

  @override
  String get deleteRepoTitle => 'Delete repo';

  @override
  String deleteOrgBody(String arg1) {
    return 'Delete organization $arg1? This removes all its repos and sessions.';
  }

  @override
  String deleteRepoBody(String arg1, String arg2) {
    return 'Delete repo $arg1/$arg2? This removes all its sessions.';
  }

  @override
  String get fork => 'Fork';

  @override
  String get forkBranchLabel => 'Branch name';

  @override
  String get branchExists => 'Branch already exists';

  @override
  String adoptFailed(String arg1) {
    return 'Adopt failed: $arg1';
  }

  @override
  String cloneFailed(String arg1) {
    return 'Clone failed: $arg1';
  }

  @override
  String failed(String arg1) {
    return 'Failed: $arg1';
  }

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeSub => 'Toggle light/dark appearance';

  @override
  String get llm => 'LLM';

  @override
  String get llmProviders => 'Providers';

  @override
  String get providers => 'Providers';

  @override
  String get presets => 'Presets';

  @override
  String get workspace => 'Workspace';

  @override
  String get tools => 'Tools';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Log out';

  @override
  String get logoutBody =>
      'This clears the saved gateway URL and token and returns to the login screen.';

  @override
  String get switchBackend => 'Switch backend';

  @override
  String get backendsTitle => 'Backends';

  @override
  String get noSavedBackends => 'No saved backends yet.';

  @override
  String get addBackend => 'Add new backend';

  @override
  String get deleteBackend => 'Remove backend';

  @override
  String get backendSection => 'Backend';

  @override
  String get providerTemplate => 'Template (models.dev)';

  @override
  String get providerTemplateHint => 'Pick a provider to prefill';

  @override
  String get searchModels => 'Search models...';

  @override
  String modelsSelected(String arg1, String arg2) {
    return '$arg1 of $arg2 selected';
  }

  @override
  String get noProviders => 'No providers. Add one to get started.';

  @override
  String get addProvider => 'Add Provider';

  @override
  String get deleteProvider => 'Delete Provider';

  @override
  String deleteProviderBody(String arg1) {
    return 'Delete Provider $arg1?';
  }

  @override
  String modelsCount(String arg1) {
    return '$arg1 models';
  }

  @override
  String get providerId => 'Provider ID';

  @override
  String providerTitle(String arg1, String arg2) {
    return 'Provider: $arg1 ($arg2)';
  }

  @override
  String get providerIdReq => 'Provider ID (required)';

  @override
  String get providerIdLabel => 'Provider ID';

  @override
  String get apiType => 'API Type';

  @override
  String get apiTypeOpenai => 'OpenAI';

  @override
  String get apiTypeAnthropic => 'Anthropic';

  @override
  String get apiTypeGemini => 'Gemini';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get test => 'Test';

  @override
  String get testing => 'Testing...';

  @override
  String get register => 'Register';

  @override
  String get registering => 'Registering...';

  @override
  String get saved => 'Saved';

  @override
  String get noConfig => 'no config';

  @override
  String get configured => 'configured';

  @override
  String get needsConfig => 'needs config';

  @override
  String get newPreset => 'New preset';

  @override
  String get presetId => 'Preset id...';

  @override
  String get create => 'Create';

  @override
  String get noPresets => 'No presets.';

  @override
  String get deletePreset => 'Delete preset';

  @override
  String deletePresetBody(String arg1) {
    return 'Delete preset $arg1?';
  }

  @override
  String presetSummary(String arg1, String arg2) {
    return '$arg1 turns · $arg2 tools';
  }

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get maxTurns => 'Max turns';

  @override
  String get containersTitle => 'Containers';

  @override
  String get deployments => 'Deployments';

  @override
  String get noDeployments => 'No deployments yet.';

  @override
  String get sandboxes => 'Sandboxes';

  @override
  String get noContainers => 'No containers running.';

  @override
  String get deployService => 'Deploy service';

  @override
  String get terminal => 'Terminal';

  @override
  String ready(String arg1, String arg2) {
    return '$arg1/$arg2 ready';
  }

  @override
  String get deleteDeploymentTitle => 'Delete deployment';

  @override
  String deleteDeploymentBody(String arg1) {
    return 'Delete deployment $arg1?';
  }

  @override
  String get deleteSandboxTitle => 'Delete sandbox';

  @override
  String deleteSandboxBody(String arg1) {
    return 'Delete sandbox $arg1? Its running jobs will be killed.';
  }

  @override
  String get terminalTab => 'Terminal';

  @override
  String get jobsTab => 'Jobs';

  @override
  String get commandHint => 'command...';

  @override
  String get close => 'Close';

  @override
  String get noOutput => 'No output';

  @override
  String get noSession => 'No session';

  @override
  String get noJobs => 'No jobs';

  @override
  String get noWorker =>
      'No worker container yet — it starts automatically when the agent runs bash.';

  @override
  String get createContainerNow => 'Create container now';

  @override
  String backgrounded(String arg1) {
    return '[$arg1] backgrounded (see Jobs)';
  }

  @override
  String get packagesTitle => 'Packages';

  @override
  String get registries => 'Registries';

  @override
  String get packagesTab => 'Packages';

  @override
  String get filterEcosystems => 'Filter ecosystems...';

  @override
  String proxyRegistries(String arg1) {
    return 'Proxy Registries ($arg1)';
  }

  @override
  String get endpointCopied => 'Endpoint copied';

  @override
  String ociCatalog(String arg1) {
    return 'OCI Image Catalog ($arg1)';
  }

  @override
  String get noImages => 'No images stored.';

  @override
  String get searchPackages => 'Search packages...';

  @override
  String get typeLabel => 'Type';

  @override
  String get prev => 'Prev';

  @override
  String get next => 'Next';

  @override
  String get deletePackage => 'Delete package';

  @override
  String deletePackageBody(String arg1, String arg2) {
    return 'Delete package $arg1 ($arg2)?';
  }

  @override
  String get noVersions => 'No versions found.';

  @override
  String downloads(String arg1) {
    return '$arg1 downloads';
  }

  @override
  String get noPackagesYet => 'No packages registered yet.';

  @override
  String versionsCount(String arg1) {
    return '$arg1 versions';
  }

  @override
  String cachedPackages(String arg1) {
    return '$arg1 packages';
  }

  @override
  String get noUpstreamLocal => 'no upstream (local only)';

  @override
  String get nameLabel => 'Name';

  @override
  String get imageLabel => 'Image';

  @override
  String get replicasLabel => 'Replicas';

  @override
  String get portLabel => 'Port';

  @override
  String get sessionOptLabel => 'Session (optional)';

  @override
  String get repositories => 'Repositories';

  @override
  String get history => 'History';

  @override
  String get none => 'None';

  @override
  String get download => 'Download';

  @override
  String get selectFile => 'Select a file to view';

  @override
  String get selectBookmark => 'Select a bookmark to browse files';

  @override
  String get noCommits => 'No commits';

  @override
  String get noHistory => 'No history for this file.';

  @override
  String get noChangesYet => 'No changes yet';

  @override
  String get noMessages => 'No messages';

  @override
  String get noTodosYet =>
      'No todos yet — the agent tracks its plan here via todowrite.';

  @override
  String get noDescription => '(no description)';

  @override
  String get consumed => 'consumed';

  @override
  String get pending => 'Pending';

  @override
  String get browserTitle => 'Browse';

  @override
  String get bookmarksSection => 'Bookmarks';

  @override
  String reposCount(String arg1) {
    return '$arg1 repos';
  }

  @override
  String get overview => 'Overview';

  @override
  String get releasesTab => 'Releases';

  @override
  String get branchesTab => 'Branches';

  @override
  String get defaultBranch => 'Default branch';

  @override
  String get recentCommits => 'Recent commits';

  @override
  String get noBranches => 'No branches';

  @override
  String get noReleases => 'No releases yet.';

  @override
  String assetsCount(String arg1) {
    return '$arg1 assets';
  }

  @override
  String get draftBadge => 'draft';

  @override
  String get prereleaseBadge => 'pre-release';

  @override
  String get downloadSource => 'Download source (tar.gz)';

  @override
  String get downloading => 'Downloading';

  @override
  String savedToDownloads(String arg1) {
    return 'Saved to Downloads: $arg1';
  }

  @override
  String savedToAppDir(String arg1) {
    return 'Saved: $arg1';
  }

  @override
  String downloadFailed(String arg1) {
    return 'Download failed: $arg1';
  }

  @override
  String get newRepoInOrg => 'New repo in this org';

  @override
  String get pickRepo => 'Pick a repository';

  @override
  String get pickBranch => 'Pick a branch';

  @override
  String get pickOrg => 'Pick an organization';

  @override
  String get codeEmptyHint => 'Pick an org / repo / bookmark to browse code';

  @override
  String get backToList => 'Back to list';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinAgo(String arg1) {
    return '$arg1 min ago';
  }

  @override
  String timeHour(String arg1) {
    return '$arg1 h ago';
  }

  @override
  String timeDay(String arg1) {
    return '$arg1 d ago';
  }

  @override
  String get baseUrlReq => 'Base URL (required)';

  @override
  String get apiKeyReq => 'API Key (required)';

  @override
  String get save => 'Save';

  @override
  String get noTools => 'No tools';

  @override
  String packPageOf(String arg1, String arg2, String arg3) {
    return '$arg1–$arg2 of $arg3';
  }

  @override
  String get syncRepo => 'Sync';

  @override
  String get pullFromRemote => 'Pull from remote';

  @override
  String get pushToRemote => 'Push to remote';

  @override
  String get pullConfirm => 'Pull';

  @override
  String get pushConfirm => 'Push';

  @override
  String get secretLabel => 'Access token (optional)';

  @override
  String get pullDone => 'Pulled from remote';

  @override
  String get pushDone => 'Pushed to remote';

  @override
  String syncFailed(String e) {
    return 'Sync failed: $e';
  }

  @override
  String get mirrorSettings => 'Mirror settings';

  @override
  String get pullUrlLabel => 'Pull URL';

  @override
  String get pushUrlLabel => 'Push URL';

  @override
  String get secretSetPlaceholder => 'Secret set (leave blank to keep)';

  @override
  String get secretKeepToUpdate =>
      'A secret is stored; enter a new value to update it';

  @override
  String get clearMirror => 'Clear';

  @override
  String get savedMirror => 'Mirror settings saved';

  @override
  String get agentLocale => 'Agent language';

  @override
  String get agentLocaleSub =>
      'Agent prompt/tool language: follow UI, zh or en; written to backend immediately';

  @override
  String get agentLocaleFollow => 'Follow (UI language)';

  @override
  String agentLocaleApplied(String l) {
    return 'Agent language set to $l';
  }

  @override
  String get toolParams => 'Parameters';

  @override
  String get showMore => 'Show';

  @override
  String get showLess => 'Collapse';

  @override
  String get vlmModelLabel => 'Vision model';

  @override
  String get configValueHint => 'Enter to save';

  @override
  String get systemPresetBadge => 'System';

  @override
  String get readOnlyPreset => 'System preset: read-only';

  @override
  String get sysPromptByPreset =>
      'System prompt is determined by the selected preset.';

  @override
  String get requiredConfig => 'required config';

  @override
  String get selectProviderFirst => 'Select a provider first';

  @override
  String get noModelsForProvider => 'No models registered for this provider';

  @override
  String get apiTypeOpenaiCompat => 'OpenAI Compatible';

  @override
  String get modelsLabel => 'Models';

  @override
  String get modelIdLabel => 'model id…';

  @override
  String get contextLengthLabel => 'context';

  @override
  String get contextLengthRequired =>
      'Context length is required (positive number).';

  @override
  String get add => 'Add';

  @override
  String get enterToAddHint => 'Enter to add a model tag';

  @override
  String get turnsByPreset => 'Max turns is set by the selected preset.';

  @override
  String testModelOk(Object arg1) {
    return 'Model OK: $arg1';
  }

  @override
  String get connected => 'Connected';

  @override
  String connectionError(Object arg1) {
    return 'Connection error: $arg1';
  }

  @override
  String get toolInputParams => 'Input';

  @override
  String get content => 'Content';

  @override
  String get metadata => 'Metadata';

  @override
  String get newSession => 'New session';

  @override
  String get noSessions => 'No sessions';
}
