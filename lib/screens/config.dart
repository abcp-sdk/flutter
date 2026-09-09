import 'package:flutter/material.dart';

import '../api.dart';
import '../i18n.dart';
import '../models.dart';
import '../navigation.dart';
import '../prefs.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../services/models_dev.dart';
import '../widgets/dialogs.dart';

/// Recreates ConfigPage.svelte (simplified, without the external
/// models.dev template fetch and PWA install section).
///
/// A single widget serves both the config tab's stack root (the settings list)
/// and a drill-in sub page ([initialId] non-null) so the per-tab nav stack can
/// render the list and a drill-in side by side on tablets. Navigation is done
/// via [AppStore.pushPage]/[popPage] on the config stack.
class ConfigScreen extends StatefulWidget {
  final AppStore store;
  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final VoidCallback? onSwitchBackend;
  /// Switch to another saved backend (rebuilds the whole store). Used by the
  /// "backend" drill-in on tablets.
  final void Function(BackendCfg backend)? onBackendSwitched;
  /// When null this is the settings list (stack root); otherwise it renders the
  /// given drill-in page (providers / presets / tools / appearance).
  final String? initialId;
  const ConfigScreen({
    super.key,
    required this.store,
    this.darkMode = true,
    required this.onDarkMode,
    this.onSwitchBackend,
    this.onBackendSwitched,
    this.initialId,
  });

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  AppStore get store => widget.store;
  Map<String, ProviderInfo> _providers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await store.api.providers();
      if (mounted) _providers = p;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// Push a drill-in sub page onto the config tab's stack. Config drill-ins are
  /// SIBLING views (providers/presets/tools/appearance) — tapping one replaces
  /// the current one so the tablet split always shows the list alongside the
  /// tapped page (1 | 2 → 1 | 3), never a stack of two parallels.
  void _push(String id) => store.pushSibling(ConfigSubPage(id));

  @override
  Widget build(BuildContext context) {
    final id = widget.initialId;
    final isDetail = id != null;
    return Scaffold(
      appBar: AppBar(
        leading: isDetail
            ? IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: () => store.popPage())
            : null,
        title: Text(isDetail ? _titleOf(id) : context.l10n.tabConfig),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isDetail
              ? _detail(id, context)
              : _listView(context),
    );
  }

  String _titleOf(String id) {
    switch (id) {
      case 'providers':
        return context.l10n.llmProviders;
      case 'presets':
        return context.l10n.presets;
      case 'appearance':
        return context.l10n.appearance;
      case 'tools':
        return context.l10n.tools;
      case 'backends':
        return context.l10n.backendsTitle;
      default:
        return id;
    }
  }

  Widget _listView(BuildContext context) {
    return ListView(
      children: [
        _SectionHeader(context.l10n.appearance),
        _listTile(context, Icons.palette_outlined, 'appearance',
            () => _push('appearance')),
        _SectionHeader(context.l10n.backendSection),
        // Highlighted as a dangerous action: switching disconnects the
        // active workspace mid-flight.
        ListTile(
          leading: Icon(Icons.swap_horiz_rounded,
              size: 20, color: colorsOf(context).destructive),
          title: Text(context.l10n.switchBackend,
              style: textOf(context).meta.copyWith(
                  color: colorsOf(context).destructive,
                  fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.chevron_right,
              size: 18, color: colorsOf(context).destructive),
          onTap: () => _push('backends'),
        ),
        _SectionHeader(context.l10n.llm),
        _listTile(context, Icons.dns_outlined, 'providers',
            () => _push('providers')),
        _listTile(
            context, Icons.auto_awesome_outlined, 'presets', () => _push('presets')),
        _SectionHeader(context.l10n.workspace),
        _listTile(
            context, Icons.handyman_outlined, 'tools', () => _push('tools')),
        _SectionHeader(context.l10n.language),
        _listTile(context, Icons.language_rounded, 'language', _pickLanguage),
        _listTile(
            context,
            Icons.translate_rounded,
            'agentLocale',
            _pickAgentLocale),
      ],
    );
  }

  Future<void> _pickAgentLocale() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.agentLocale),
        children: [
          for (final (code, label) in [
            ('follow', ctx.l10n.agentLocaleFollow),
            ('zh', '中文'),
            ('en', 'English'),
          ])
            ListTile(
              leading: Icon(
                  agentLocaleValue == code
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: colorsOf(ctx).primary),
              title: Text(label),
              onTap: () => Navigator.pop(ctx, code),
            ),
        ],
      ),
    );
    if (picked == null || picked == agentLocaleValue) return;
    await Prefs.saveAgentLocale(picked);
    final messenger = ScaffoldMessenger.of(context);
    // Push to the agent so the prompt/tool descriptions use the locale
    // immediately (agent dynamic-locale reads the config KV each turn).
    final value = Prefs.effectiveAgentLocale(uiZh: I18n.isZh);
    try {
      await store.api.setConfigKey('locale', value);
      messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.agentLocaleApplied('$value'))));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e', style: TextStyle(color: colorsOf(context).destructive))));
    }
    setState(() {});
  }

  Future<void> _pickLanguage() async {
    final cur = I18n.locale.languageCode;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.language),
        children: [
          for (final (code, label) in [
            ('zh', '中文'),
            ('en', 'English'),
          ])
            ListTile(
              leading: Icon(
                  I18n.locale.languageCode == code
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: colorsOf(ctx).primary),
              title: Text(label),
              onTap: () => Navigator.pop(ctx, code),
            ),
        ],
      ),
    );
    if (picked != null && picked != cur) {
      await I18n.save(Locale(picked));
    }
  }

  Widget _listTile(
      BuildContext context, IconData icon, String labelKey, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(l10nString(labelKey)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _detail(String id, BuildContext context) {
    switch (id) {
      case 'appearance':
        return _appearance(context);
      case 'providers':
        return _providersDetail();
      case 'presets':
        return _presetsDetail();
      case 'tools':
        return _toolsDetail();
      case 'backends':
        return _BackendsDetail(
          onSwitched: widget.onBackendSwitched,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _appearance(BuildContext context) {
    final dark = widget.darkMode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: Text(context.l10n.darkMode),
          subtitle: Text(context.l10n.darkModeSub),
          value: dark,
          onChanged: (v) => widget.onDarkMode(v),
        ),
      ],
    );
  }

  Widget _providersDetail() {
    return _ProvidersDetail(
      providers: _providers,
      onChanged: _load,
      api: store.api,
    );
  }

  Widget _presetsDetail() {
    return _PresetsDetail(api: store.api);
  }

  Widget _toolsDetail() {
    return _ToolsDetail(api: store.api);
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
      child: Text(text.toUpperCase(),
          style: textOf(context).micro.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colorsOf(context).mutedForeground)),
    );
  }
}

/// Map a raw API type string to its localized display label.
String _apiTypeLabel(BuildContext context, String apiType) {
  switch (apiType) {
    case 'openai-compatible':
      return context.l10n.apiTypeOpenaiCompat;
    case 'openai':
      return context.l10n.apiTypeOpenai;
    case 'anthropic':
      return context.l10n.apiTypeAnthropic;
    case 'gemini':
      return context.l10n.apiTypeGemini;
    default:
      return apiType;
  }
}

/// Providers detail (recreates ProviderSection without models.dev template).
class _ProvidersDetail extends StatefulWidget {
  final Map<String, ProviderInfo> providers;
  final VoidCallback onChanged;
  final AgentBindApi api;
  const _ProvidersDetail(
      {required this.providers, required this.onChanged, required this.api});

  @override
  State<_ProvidersDetail> createState() => _ProvidersDetailState();
}

class _ProvidersDetailState extends State<_ProvidersDetail> {
  bool _showAdd = false;
  // Provider id being edited inline (mirrors the "add" inline panel). Keeping
  // edit and add the same presentation keeps the UI consistent.
  String? _editingKey;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final entries = widget.providers.entries.toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final e in entries) ...[
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              title: Text(context.l10n.providerTitle(
                  e.key, _apiTypeLabel(context, e.value.apiType))),
              subtitle: Text(e.value.baseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.micro.copyWith(color: colors.mutedForeground)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.modelsCount('${e.value.models.length}'),
                      style: text.micro.copyWith(color: colors.mutedForeground)),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: colors.mutedForeground),
                    onPressed: () => setState(() => _editingKey = e.key),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: colors.mutedForeground),
                    onPressed: () async {
                      final ok = await confirmDialog(context,
                          title: context.l10n.deleteProvider,
                          description:
                              context.l10n.deleteProviderBody(e.key));
                      if (ok) {
                        await widget.api.deleteProvider(e.key);
                        widget.onChanged();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_editingKey == e.key)
            _AddProviderForm(
              api: widget.api,
              initial: e.value,
              onRegistered: () {
                setState(() => _editingKey = null);
                widget.onChanged();
              },
              onCancel: () => setState(() => _editingKey = null),
            ),
        ],
        if (widget.providers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(context.l10n.noProviders,
                style: TextStyle(color: colors.mutedForeground)),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (_showAdd)
          _AddProviderForm(
            api: widget.api,
            onRegistered: () {
              setState(() => _showAdd = false);
              widget.onChanged();
            },
            onCancel: () => setState(() => _showAdd = false),
          )
        else
          OutlinedButton.icon(
            onPressed: () => setState(() => _showAdd = true),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(context.l10n.addProvider),
          ),
      ],
    );
  }
}

/// A manual model entry (tag + optional context length).
class _ModelEntry {
  final String id;
  final String name;
  final int? context;
  _ModelEntry({required this.id, required this.name, this.context});
}

class _AddProviderForm extends StatefulWidget {
  final AgentBindApi api;
  final VoidCallback onRegistered;
  final VoidCallback onCancel;
  final ProviderInfo? initial;
  const _AddProviderForm(
      {required this.api,
      required this.onRegistered,
      required this.onCancel,
      this.initial});

  @override
  State<_AddProviderForm> createState() => _AddProviderFormState();
}

class _AddProviderFormState extends State<_AddProviderForm> {
  final _id = TextEditingController();
  final _url = TextEditingController();
  final _key = TextEditingController();
  String _apiType = 'openai-compatible';
  String _testMsg = '';
  bool _testing = false;
  bool _registering = false;
  bool _editing = false;

  // models.dev template prefill (lazy-loaded on first picker open).
  MdProvider? _template;
  final Set<String> _selectedModels = {};
  String _modelQuery = '';

  // Manual model tags (the "tag + label" entry, no comma-separated CSV).
  final List<_ModelEntry> _modelEntries = [];
  final _modelIdCtrl = TextEditingController();
  final _modelCtxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _editing = true;
      _id.text = init.providerId;
      _url.text = init.baseUrl;
      _key.text = init.apiKey;
      _apiType = init.apiType;
      for (final m in init.models) {
        _modelEntries.add(
            _ModelEntry(id: m.id, name: m.name, context: m.contextLimit));
      }
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _url.dispose();
    _key.dispose();
    _modelIdCtrl.dispose();
    _modelCtxCtrl.dispose();
    super.dispose();
  }

  void _addModelTag() {
    final mid = _modelIdCtrl.text.trim();
    if (mid.isEmpty) return;
    _modelEntries.add(_ModelEntry(
      id: mid,
      name: mid,
      context: int.tryParse(_modelCtxCtrl.text.trim()),
    ));
    _modelIdCtrl.clear();
    _modelCtxCtrl.clear();
    setState(() {});
  }

  /// Selected models → [ProviderModel], auto-filling context length from the
  /// models.dev template when it came from a preset provider.
  List<ProviderModel> _buildModels() {
    if (_template != null) {
      final byId = {for (final m in _template!.models) m.id: m};
      return _selectedModels
          .map((id) {
            final m = byId[id];
            return ProviderModel(
              id: id,
              name: m?.name.isNotEmpty == true ? m!.name : id,
              contextLimit: m?.contextLimit,
            );
          })
          .toList();
    }
    return _modelEntries
        .map((e) =>
            ProviderModel(id: e.id, name: e.name, contextLimit: e.context))
        .toList();
  }

  /// Manual model entry: tag-style chips (one per model id) + a context
  /// length field. Context auto-fills when the model came from a template.
  Widget _manualModelEditor(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.modelsLabel,
            style: text.meta.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: AppSpacing.xs),
        if (_modelEntries.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final e in _modelEntries)
                Chip(
                  label: Text(
                    e.context != null ? '${e.id} · ${e.context}' : e.id,
                    style: text.micro.copyWith(fontSize: 10),
                  ),
                  onDeleted: () => setState(() {
                    _modelEntries.remove(e);
                  }),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _modelIdCtrl,
                decoration: InputDecoration(
                  hintText: context.l10n.modelIdLabel,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _modelCtxCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: context.l10n.contextLengthLabel,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.filledTonal(
              tooltip: context.l10n.add,
              onPressed: _addModelTag,
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.enterToAddHint,
            style: text.micro.copyWith(color: colors.mutedForeground)),
      ],
    );
  }

  Future<void> _test() async {
    final models = _buildModels();
    if (models.isEmpty) return;
    setState(() {
      _testing = true;
      _testMsg = '';
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      // If exactly one model is chosen, test that model with a real 1-turn
      // generation (proves it is usable); otherwise probe the provider.
      final model = models.length == 1 ? models.first.id : null;
      final r = await widget.api.testProvider(
          apiType: _apiType,
          baseUrl: _url.text,
          apiKey: _key.text,
          model: model);
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testMsg = r['ok'] == true
            ? (model != null
                ? context.l10n.testModelOk('${r['text'] ?? ''}')
                : (r['detail'] ?? 'OK'))
            : (r['error'] ?? 'Failed');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testMsg = '$e';
      });
    } finally {
      messenger.hideCurrentSnackBar();
    }
  }

  Future<void> _register() async {
    setState(() => _registering = true);
    final modelList = _buildModels();
    final updated = ProviderInfo(
      providerId: _id.text.trim(),
      apiType: _apiType,
      baseUrl: _url.text.trim(),
      apiKey: _key.text,
      models: modelList,
    );
    try {
      await widget.api.registerProvider(updated);
      widget.onRegistered();
      if (!_editing) return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    setState(() => _registering = false);
  }

  /// Template picker: a bottom sheet over the models.dev catalogue (lazy
  /// load + 1h cache inside [ModelsDev]). Kept as a sheet so it stays anchored
  /// to the provider form (a modal picker, not a tab-level page).
  Future<void> _pickTemplate() async {
    final picked = await showModalBottomSheet<MdProvider>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TemplatePickerSheet(),
    );
    if (picked == null) return;
    setState(() {
      _template = picked;
      _selectedModels.clear();
      _modelQuery = '';
      _id.text = picked.id;
      if (picked.api.isNotEmpty) _url.text = picked.api;
      _apiType = ModelsDev.npmToType(picked.npm);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final templateModels = _template?.models ?? <MdModel>[];
    final filteredModels = _modelQuery.isEmpty
        ? templateModels
        : templateModels
            .where((m) =>
                m.id.toLowerCase().contains(_modelQuery.toLowerCase()) ||
                m.name.toLowerCase().contains(_modelQuery.toLowerCase()))
            .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // models.dev template prefill: fills id / base URL / api type
            // and swaps the models CSV for a searchable multi-select. Hidden
            // while editing an existing provider (its fields are already set).
            if (!_editing)
              InkWell(
                borderRadius: AppRadius.rSm,
                onTap: _pickTemplate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.l10n.providerTemplate,
                    prefixIcon: const Icon(Icons.auto_awesome_outlined,
                        size: 18),
                    suffixIcon: _template == null
                        ? const Icon(Icons.chevron_right_rounded, size: 18)
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: context.l10n.none,
                            onPressed: () => setState(() {
                              _template = null;
                              _selectedModels.clear();
                            }),
                          ),
                  ),
                  child: Text(
                    _template == null
                        ? context.l10n.providerTemplateHint
                        : _template!.name,
                    style: text.meta.copyWith(
                        color: _template == null
                            ? colors.mutedForeground
                            : null),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _id,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: context.l10n.providerIdReq)),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _apiType,
              items: [
                DropdownMenuItem(
                    value: 'openai-compatible',
                    child: Text(context.l10n.apiTypeOpenaiCompat)),
                DropdownMenuItem(
                    value: 'openai',
                    child: Text(context.l10n.apiTypeOpenai)),
                DropdownMenuItem(
                    value: 'anthropic',
                    child: Text(context.l10n.apiTypeAnthropic)),
                DropdownMenuItem(
                    value: 'gemini',
                    child: Text(context.l10n.apiTypeGemini)),
              ],
              onChanged: (v) => setState(() => _apiType = v!),
              decoration:
                  InputDecoration(labelText: context.l10n.apiType),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _url,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: context.l10n.baseUrlReq)),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _key,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: context.l10n.apiKeyReq)),
            const SizedBox(height: AppSpacing.md),
            if (_template == null)
              _manualModelEditor(context)
            else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: context.l10n.searchModels,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _modelQuery = v),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  context.l10n.modelsSelected('${_selectedModels.length}',
                    '${templateModels.length}'),
                  style: text.micro
                      .copyWith(color: colors.mutedForeground)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final m in filteredModels)
                        FilterChip(
                          label: Text(m.name.isNotEmpty ? m.name : m.id,
                              style: text.micro),
                          selected: _selectedModels.contains(m.id),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _selectedModels.add(m.id);
                            } else {
                              _selectedModels.remove(m.id);
                            }
                          }),
                        ),
                      if (filteredModels.isEmpty)
                        Text(context.l10n.noPackagesYet,
                            style: text.micro
                                .copyWith(color: colors.mutedForeground)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: (_testing || _buildModels().isEmpty)
                      ? null
                      : _test,
                  icon: const Icon(Icons.science_outlined, size: 14),
                  label: Text(_testing ? context.l10n.testing : context.l10n.test),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(_testMsg,
                      overflow: TextOverflow.ellipsis,
                      style: text.micro.copyWith(color: colors.mutedForeground)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: widget.onCancel,
                    child: Text(context.l10n.cancel)),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: (_id.text.isEmpty || _url.text.isEmpty || _registering)
                      ? null
                      : _register,
                  child: Text(
                      _registering ? context.l10n.registering : context.l10n.register),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetsDetail extends StatefulWidget {
  final AgentBindApi api;
  const _PresetsDetail({required this.api});

  @override
  State<_PresetsDetail> createState() => _PresetsDetailState();
}

class _PresetsDetailState extends State<_PresetsDetail> {
  List<Preset> _presets = [];
  List<ToolInfo> _tools = [];
  bool _loading = true;
  String? _editingId;
  late Preset _edit;
  bool _showNew = false;
  final _newId = TextEditingController();

  // Persistent editors for the expanded preset so keystrokes never rebuild
  // the TextFields (which would reset the cursor / leak controllers).
  final _sysPromptCtrl = TextEditingController();
  final _maxTurnsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newId.dispose();
    _sysPromptCtrl.dispose();
    _maxTurnsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _presets = await widget.api.presets(
          locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh));
    } catch (_) {}
    try {
      _tools = await widget.api.tools(
          locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    final id = _newId.text.trim();
    if (id.isEmpty) return;
    await widget.api.savePreset(
        Preset(id: id, systemPrompt: '', tools: [], maxTurns: 30));
    setState(() {
      _showNew = false;
      _editingId = null;
    });
    _newId.clear();
    await _load();
  }

  Future<void> _delete(Preset p) async {
    final ok = await confirmDialog(context,
        title: context.l10n.deletePreset,
        description: context.l10n.deletePresetBody(p.id));
    if (ok) {
      await widget.api.deletePreset(p.id);
      setState(() => _editingId = null);
      await _load();
    }
  }

  void _open(Preset p) {
    _sysPromptCtrl.text = p.systemPrompt;
    _maxTurnsCtrl.text = '${p.maxTurns}';
    setState(() {
      _editingId = p.id;
      _edit = Preset(
          id: p.id,
          systemPrompt: p.systemPrompt,
          tools: [...p.tools],
          maxTurns: p.maxTurns);
    });
  }

  Future<void> _save() async {
    await widget.api.savePreset(_edit);
    await _load();
    setState(() => _editingId = null);
  }

  /// Read-only view for an immutable system preset. Shows the localized
  /// system prompt, the enabled tools, and the turn ceiling — no edit/save.
  Widget _systemPresetView(Preset p) {
    final colors = colorsOf(context);
    final text = textOf(context);
    // Display the preset's system prompt in the current agent locale (falling
    // back to the default prompt when the locale has no translation).
    final agentLocale = Prefs.effectiveAgentLocale(uiZh: I18n.isZh);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.readOnlyPreset,
              style: text.micro.copyWith(color: colors.warning)),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.systemPrompt,
              style: text.meta.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.4),
              borderRadius: AppRadius.rSm,
            ),
            child: SelectableText(p.localizedPrompt(agentLocale),
                style: text.mono.copyWith(fontSize: 11)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${context.l10n.tools} · ${p.tools.length}',
              style: text.meta.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in p.tools)
                Chip(
                  label: Text(t, style: text.micro.copyWith(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.presetSummary('${p.maxTurns}', '${p.tools.length}'),
              style: text.micro.copyWith(color: colors.mutedForeground)),
        ],
      ),
    );
  }

  /// Editable view for a user-created preset (non-system).
  Widget _presetEditView(Preset p) {
    final text = textOf(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            controller: _sysPromptCtrl,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.l10n.systemPrompt),
            onChanged: (v) => _edit = Preset(
                id: _edit.id,
                systemPrompt: v,
                tools: _edit.tools,
                maxTurns: _edit.maxTurns),
          ),
          TextField(
            controller: _maxTurnsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.maxTurns),
            onChanged: (v) => _edit = Preset(
                id: _edit.id,
                systemPrompt: _edit.systemPrompt,
                tools: _edit.tools,
                maxTurns: int.tryParse(v) ?? 30),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in _tools.map((t) => t.name).toList())
                FilterChip(
                  label: Text(t, style: text.micro),
                  selected: _edit.tools.contains(t),
                  onSelected: (sel) {
                    final tools = [..._edit.tools];
                    if (sel) {
                      tools.add(t);
                    } else {
                      tools.remove(t);
                    }
                    setState(() => _edit = Preset(
                        id: _edit.id,
                        systemPrompt: _edit.systemPrompt,
                        tools: tools,
                        maxTurns: _edit.maxTurns));
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                  onPressed: _save, child: Text(context.l10n.save)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final colors = colorsOf(context);
    final text = textOf(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (_showNew) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newId,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: context.l10n.presetId),
                  onSubmitted: (_) => _create(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                  onPressed: _newId.text.trim().isEmpty ? null : _create,
                  child: Text(context.l10n.create)),
              IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _showNew = false)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showNew = true),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(context.l10n.newPreset),
            ),
          ),
        for (final p in _presets)
          Card(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              children: [
                ListTile(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.id),
                      if (p.isSystem) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(context.l10n.systemPresetBadge,
                              style: text.micro.copyWith(
                                  color: colors.warning, fontSize: 9)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(context.l10n.presetSummary('${p.maxTurns}',
                        '${p.tools.length}')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // System presets are immutable — no delete/edit.
                      if (!p.isSystem)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 18, color: colors.mutedForeground),
                          onPressed: () => _delete(p),
                        ),
                      Icon(Icons.expand_more_rounded,
                          size: 18, color: colors.mutedForeground),
                    ],
                  ),
                  onTap: () => _editingId == p.id
                      ? setState(() => _editingId = null)
                      : _open(p),
                ),
                if (_editingId == p.id)
                  p.isSystem
                      ? _systemPresetView(p)
                      : _presetEditView(p),
              ],
            ),
          ),
        if (_presets.isEmpty)
          Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(context.l10n.noPresets,
                  style: TextStyle(color: colors.mutedForeground))),
      ],
    );
  }
}

class _ToolsDetail extends StatefulWidget {
  final AgentBindApi api;
  const _ToolsDetail({required this.api});

  @override
  State<_ToolsDetail> createState() => _ToolsDetailState();
}

class _ToolsDetailState extends State<_ToolsDetail> {
  List<ToolInfo> _tools = [];
  Map<String, dynamic> _config = {};
  String? _expanded;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _tools = await widget.api.tools(
          locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh));
    } catch (_) {}
    try {
      _config = await widget.api.toolConfig();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_tools.isEmpty) {
      return Center(child: Text(context.l10n.noTools));
    }
    final cats = <String, List<ToolInfo>>{};
    for (final t in _tools) {
      (cats[t.category.isNotEmpty ? t.category : 'other'] ??= []).add(t);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final entry in cats.entries) ...[
          Text(entry.key.toUpperCase(),
              style: textOf(context).micro.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: colorsOf(context).mutedForeground)),
          for (final t in entry.value) _toolCard(t),
        ],
      ],
    );
  }

  Widget _toolCard(ToolInfo tool) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final hasConfig = (_config[tool.name] ?? {}).isNotEmpty;
    // A tool whose owning extension declares config knobs shows a plain text
    // field per knob that the user fills in (model refs like vlm_model /
    // image_model are free-form "provider_id/model_id" strings).
    final extConfigs = tool.config ?? [];
    // `required_config` carries the "must be set" semantics: a tool that
    // lists a config here shows the required badge while that value is unset.
    final requiredMissing = tool.requiredConfig.any((name) {
      final v = (_config[tool.name] ?? {})[name];
      return v == null || '$v'.isEmpty;
    });
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          ListTile(
            title: Text(tool.name, style: text.mono.copyWith(fontSize: 12)),
            trailing: extConfigs.isEmpty
                ? Text(context.l10n.noConfig,
                    style: text.micro.copyWith(color: colors.mutedForeground))
                : Text(
                    requiredMissing
                        ? context.l10n.requiredConfig
                        : hasConfig
                            ? context.l10n.configured
                            : context.l10n.needsConfig,
                    style: text.micro.copyWith(
                        color: requiredMissing
                            ? colors.destructive
                            : hasConfig
                                ? colors.success
                                : colors.warning)),
            onTap: () => setState(
                () => _expanded = _expanded == tool.name ? null : tool.name),
          ),
          if (_expanded == tool.name)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tool.description.isNotEmpty)
                    Text(tool.description,
                        style: text.micro
                            .copyWith(color: colors.mutedForeground)),
                  // Data-driven config editors from the extension config.
                  // Every knob renders a plain text field the user fills in
                  // (model refs like vlm_model / image_model are free-form
                  // "provider_id/model_id" strings, typed by the user).
                  for (final c in extConfigs) _extConfigEditor(tool, c),
                  if (tool.params.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.l10n.toolParams,
                        style: text.meta.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: AppSpacing.xs),
                    _paramList(tool.params, 0),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Render a parameter list. Depth 0 rows are expanded; deeper levels wrap
  /// in a tappable fold (showMore) that expands on tap and collapses.
  Widget _paramList(List<ToolParam> params, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in params) _paramRow(p, depth),
      ],
    );
  }

  Widget _paramRow(ToolParam p, int depth) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.required ? '${p.name} *' : p.name,
                style: text.mono.copyWith(
                    fontSize: 12,
                    color: p.required ? colors.primary : null,
                    fontWeight: p.required ? FontWeight.w600 : null),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (p.enumValues != null)
                Text(
                  '${p.type} (${p.enumValues!.join('/')})',
                  style: text.micro.copyWith(color: colors.mutedForeground),
                )
              else
                Text(p.type,
                    style: text.micro.copyWith(color: colors.mutedForeground)),
            ],
          ),
        ),
        if (p.description.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0, top: 1),
            child: Text(p.description,
                style: text.micro.copyWith(color: colors.mutedForeground)),
          ),
        if (p.children.isNotEmpty)
          _FoldGroup(children: p.children, depth: depth + 1),
      ],
    );
  }

  /// Render an extension config knob — a plain text field + an explicit
  /// "Save" button (no enter-to-save surprise). Value is saved to the extId
  /// (tool.category) config.
  Widget _extConfigEditor(ToolInfo tool, ToolConfig c) {
    final extId = tool.category; // the owning extension id
    return _ConfigTextField(
      label: c.name,
      description: c.description,
      onSave: (v) => _saveExtConfig(extId, c.name, v),
    );
  }

  Future<void> _saveExtConfig(String extId, String name, Object? value) async {
    if (value == null || '$value'.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.api.setToolConfigValue(extId, name, '$value');
      setState(() {
        // Reflect the saved knob locally so badges/required flags update
        // immediately without a full reload.
        for (final t in _tools) {
          if (t.category != extId) continue;
          final cfgMap = (_config[t.name] ?? const <String, dynamic>{});
          final next = <String, dynamic>{...cfgMap, name: value};
          _config = {..._config, t.name: next};
        }
      });
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('$e',
              style: TextStyle(color: colorsOf(context).destructive))));
    }
  }

}

/// A labelled config text field with an explicit Save button.
class _ConfigTextField extends StatefulWidget {
  final String label;
  final String description;
  final ValueChanged<String> onSave;
  const _ConfigTextField({
    required this.label,
    required this.description,
    required this.onSave,
  });

  @override
  State<_ConfigTextField> createState() => _ConfigTextFieldState();
}

class _ConfigTextFieldState extends State<_ConfigTextField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.description.isNotEmpty)
            Text(widget.description,
                style: text.micro.copyWith(color: colors.mutedForeground)),
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: widget.label),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => widget.onSave(_controller.text),
              child: Text(context.l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deep-parameter group: collapsed inline summary, tap to expand, tap again
/// to collapse.
class _FoldGroup extends StatefulWidget {
  final List<ToolParam> children;
  final int depth;
  const _FoldGroup({required this.children, required this.depth});

  @override
  State<_FoldGroup> createState() => _FoldGroupState();
}

class _FoldGroupState extends State<_FoldGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    // Render the expanded children underneath. Kept here instead of only a
    // summary row so tapping the fold truly reveals the nested params.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: (widget.depth - 1) * 16.0, top: 2),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: AppRadius.rSm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    _open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 14,
                    color: colors.mutedForeground),
                const SizedBox(width: AppSpacing.xs),
                Text(
                    _open
                        ? '${context.l10n.showLess} (${widget.children.length})'
                        : '${context.l10n.showMore} (${widget.children.length})',
                    style: textOf(context)
                        .micro
                        .copyWith(color: colors.mutedForeground)),
              ],
            ),
          ),
        ),
        if (_open) _childParams(),
      ],
    );
  }

  /// Render the fold's nested params with the deeper indent, reusing the
  /// enclosing _ToolsDetailState's renderer by proxy: build simple rows here.
  Widget _childParams() {
    return Padding(
      padding: EdgeInsets.only(left: (widget.depth) * 16.0, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in widget.children) _childRow(p),
        ],
      ),
    );
  }

  Widget _childRow(ToolParam p) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.required ? '${p.name} *' : p.name,
                style: text.mono.copyWith(
                    fontSize: 12,
                    color: p.required ? colors.primary : null,
                    fontWeight: p.required ? FontWeight.w600 : null),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(p.type,
                  style:
                      text.micro.copyWith(color: colors.mutedForeground)),
            ],
          ),
          if (p.description.isNotEmpty)
            Text(p.description,
                style: text.micro.copyWith(color: colors.mutedForeground)),
          if (p.children.isNotEmpty)
            _FoldGroup(children: p.children, depth: widget.depth + 1),
        ],
      ),
    );
  }
}
/// Searchable models.dev template picker — a bottom sheet returning the
/// picked [MdProvider]. Anchored to the provider form (modal picker).
class _TemplatePickerSheet extends StatefulWidget {
  const _TemplatePickerSheet();

  @override
  State<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<_TemplatePickerSheet> {
  final _q = TextEditingController();
  List<MdProvider> _all = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _all = await ModelsDev.load();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final q = _q.text.trim().toLowerCase();
    // Fuzzy match: a provider matches when its name/id OR any of its models'
    // names/ids contain the query (case-insensitive), so searching a model
    // name finds the provider that provides it.
    final list = q.isEmpty
        ? _all
        : _all.where((p) {
            if (p.name.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q)) {
              return true;
            }
            return p.models.any((m) =>
                m.name.toLowerCase().contains(q) ||
                m.id.toLowerCase().contains(q));
          }).toList();
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: TextField(
                controller: _q,
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.l10n.providerTemplateHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const UnderlineInputBorder(),
                ),
              ),
            ),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error,
                                  style:
                                      TextStyle(color: colors.destructive)),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _loading = true;
                                      _error = '';
                                    });
                                    _load();
                                  },
                                  child: Text(context.l10n.back)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final p = list[i];
                            return ListTile(
                              title: Text(p.name,
                                  style: text.meta.copyWith(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${p.id} · ${context.l10n.modelsCount('${p.models.length}')}',
                                  style: text.micro.copyWith(
                                      color: colors.mutedForeground)),
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backend manager rendered as a config drill-in (right panel on tablets).
/// Owns its backend list state; switch/delete operate on [Prefs].
class _BackendsDetail extends StatefulWidget {
  final void Function(BackendCfg)? onSwitched;
  const _BackendsDetail({this.onSwitched});

  @override
  State<_BackendsDetail> createState() => _BackendsDetailState();
}

class _BackendsDetailState extends State<_BackendsDetail> {
  List<BackendCfg> _backends = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await Prefs.backends();
    if (mounted) setState(() => _backends = b);
  }

  Future<void> _delete(BackendCfg b) async {
    await Prefs.removeBackend(b.baseUrl);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.saved)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (_backends.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(context.l10n.noSavedBackends,
                style: TextStyle(color: colors.mutedForeground)),
          ),
        for (final b in _backends)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(Icons.dns_outlined,
                  color: Colors.greenAccent),
              title: Text(b.name.isNotEmpty ? b.name : b.baseUrl),
              subtitle: Text(b.baseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.micro.copyWith(color: colors.mutedForeground)),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: colors.mutedForeground),
                tooltip: context.l10n.deleteBackend,
                onPressed: () => _delete(b),
              ),
              onTap: () => widget.onSwitched?.call(b),
            ),
          ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.add_rounded),
          title: Text(context.l10n.addBackend),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.addBackend)));
          },
        ),
      ],
    );
  }
}
