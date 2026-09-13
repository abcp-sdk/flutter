import 'package:flutter/material.dart';

import '../api.dart';
import '../auth_gate.dart';
import '../i18n.dart';
import '../models.dart';
import '../navigation.dart';
import '../prefs.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import 'defaults.dart';
import 'providers.dart';

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
  bool _loading = true;
  /// Lets the AppBar's "+" drive the presets detail's inline new-preset row,
  /// mirroring the providers page (top-right action instead of a button).
  final GlobalKey<_PresetsDetailState> _presetsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // The config root only needs to exist; individual detail pages load their
    // own data. Keep a brief loading state for the first frame.
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
                icon: const Icon(Icons.arrow_back),
                onPressed: () => store.popPage(),
              )
            : null,
        title: Text(isDetail ? _titleOf(id) : context.l10n.tabConfig),
        actions: [
          if (isDetail && id == 'presets')
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: context.l10n.newPreset,
              onPressed: () => _presetsKey.currentState?.startNew(),
            ),
        ],
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
      case 'defaults':
        return context.l10n.defaults;
      default:
        return id;
    }
  }

  Widget _listView(BuildContext context) {
    return ListView(
      children: [
        _SectionHeader(context.l10n.appearance),
        _listTile(
          context,
          Icons.palette_outlined,
          'appearance',
          () => _push('appearance'),
        ),
        _SectionHeader(context.l10n.backendSection),
        // Highlighted as a dangerous action: switching disconnects the
        // active workspace mid-flight.
        ListTile(
          leading: Icon(
            Icons.swap_horiz_rounded,
            size: 20,
            color: colorsOf(context).destructive,
          ),
          title: Text(
            context.l10n.switchBackend,
            style: textOf(context).meta.copyWith(
              color: colorsOf(context).destructive,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 18,
            color: colorsOf(context).destructive,
          ),
          onTap: () => _push('backends'),
        ),
        _SectionHeader(context.l10n.llm),
        // SIBLING like the other drill-ins: entering providers from the list
        // replaces any open drill-in instead of stacking, so the tablet split
        // shows `1 | 2` (list alongside providers), never `2 | 3`.
        _listTile(
          context,
          Icons.dns_outlined,
          'providers',
          () => store.pushSibling(const ProvidersListPage()),
        ),
        _listTile(
          context,
          Icons.auto_awesome_outlined,
          'presets',
          () => _push('presets'),
        ),
        _listTile(
          context,
          Icons.star_outline_rounded,
          'defaults',
          () => _push('defaults'),
        ),
        _SectionHeader(context.l10n.workspace),
        _listTile(
          context,
          Icons.handyman_outlined,
          'tools',
          () => _push('tools'),
        ),
        _SectionHeader(context.l10n.language),
        _listTile(context, Icons.language_rounded, 'language', _pickLanguage),
        _listTile(
          context,
          Icons.translate_rounded,
          'agentLocale',
          _pickAgentLocale,
        ),
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
                color: colorsOf(ctx).primary,
              ),
              title: Text(label),
              onTap: () => Navigator.pop(ctx, code),
            ),
        ],
      ),
    );
    if (picked == null || picked == agentLocaleValue) return;
    await Prefs.saveAgentLocale(picked);
    // Push to the agent so the prompt/tool descriptions use the locale
    // immediately (agent dynamic-locale reads the config KV each turn).
    final value = Prefs.effectiveAgentLocale(uiZh: I18n.isZh);
    try {
      await store.api.setConfigKey('locale', value);
      showToast(context, context.l10n.agentLocaleApplied('$value'));
    } catch (e) {
      showErrorToast(context, '$e');
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
          for (final (code, label) in [('zh', '中文'), ('en', 'English')])
            ListTile(
              leading: Icon(
                I18n.locale.languageCode == code
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: colorsOf(ctx).primary,
              ),
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
    BuildContext context,
    IconData icon,
    String labelKey,
    VoidCallback onTap,
  ) {
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
      case 'defaults':
        return DefaultsDetail(api: store.api);
      case 'tools':
        return _toolsDetail();
      case 'backends':
        return _BackendsDetail(onSwitched: widget.onBackendSwitched);
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
    return ProvidersListScreen(store: store);
  }

  Widget _presetsDetail() {
    return _PresetsDetail(key: _presetsKey, api: store.api);
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: textOf(context).micro.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: colorsOf(context).mutedForeground,
        ),
      ),
    );
  }
}

class _PresetsDetail extends StatefulWidget {
  final AgentBindApi api;
  const _PresetsDetail({super.key, required this.api});

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
        locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh),
      );
    } catch (e) {
      if (isAuthError(e)) showAuthExpiredDialog();
    }
    try {
      _tools = await widget.api.tools(
        locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh),
      );
    } catch (e) {
      if (isAuthError(e)) showAuthExpiredDialog();
    }
    setState(() => _loading = false);
  }

  /// Reveal the inline new-preset row (driven by the AppBar "+").
  void startNew() {
    if (!mounted) return;
    setState(() => _showNew = true);
  }

  Future<void> _create() async {
    final id = _newId.text.trim();
    if (id.isEmpty) return;
    await widget.api.savePreset(
      Preset(id: id, systemPrompt: '', tools: [], maxTurns: 30),
    );
    setState(() {
      _showNew = false;
      _editingId = null;
    });
    _newId.clear();
    await _load();
  }

  Future<void> _delete(Preset p) async {
    final ok = await confirmDialog(
      context,
      title: context.l10n.deletePreset,
      description: context.l10n.deletePresetBody(p.id),
    );
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
        maxTurns: p.maxTurns,
      );
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
          Text(
            context.l10n.readOnlyPreset,
            style: text.micro.copyWith(color: colors.warning),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.systemPrompt,
            style: text.meta.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.4),
              borderRadius: AppRadius.rSm,
            ),
            child: SelectableText(
              p.localizedPrompt(agentLocale),
              style: text.mono.copyWith(fontSize: 11),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${context.l10n.tools} · ${p.tools.length}',
            style: text.meta.copyWith(fontWeight: FontWeight.w600),
          ),
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
          Text(
            context.l10n.presetSummary('${p.maxTurns}', '${p.tools.length}'),
            style: text.micro.copyWith(color: colors.mutedForeground),
          ),
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
              maxTurns: _edit.maxTurns,
            ),
          ),
          TextField(
            controller: _maxTurnsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.maxTurns),
            onChanged: (v) => _edit = Preset(
              id: _edit.id,
              systemPrompt: _edit.systemPrompt,
              tools: _edit.tools,
              maxTurns: int.tryParse(v) ?? 30,
            ),
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
                    setState(
                      () => _edit = Preset(
                        id: _edit.id,
                        systemPrompt: _edit.systemPrompt,
                        tools: tools,
                        maxTurns: _edit.maxTurns,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(onPressed: _save, child: Text(context.l10n.save)),
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
                  decoration: InputDecoration(labelText: context.l10n.presetId),
                  onSubmitted: (_) => _create(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _newId.text.trim().isEmpty ? null : _create,
                child: Text(context.l10n.create),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _showNew = false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
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
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            context.l10n.systemPresetBadge,
                            style: text.micro.copyWith(
                              color: colors.warning,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    context.l10n.presetSummary(
                      '${p.maxTurns}',
                      '${p.tools.length}',
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // System presets are immutable — no delete/edit.
                      if (!p.isSystem)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: colors.mutedForeground,
                          ),
                          onPressed: () => _delete(p),
                        ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: colors.mutedForeground,
                      ),
                    ],
                  ),
                  onTap: () => _editingId == p.id
                      ? setState(() => _editingId = null)
                      : _open(p),
                ),
                if (_editingId == p.id)
                  p.isSystem ? _systemPresetView(p) : _presetEditView(p),
              ],
            ),
          ),
        if (_presets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              context.l10n.noPresets,
              style: TextStyle(color: colors.mutedForeground),
            ),
          ),
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
  Map<String, ProviderInfo> _providers = {};
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
        locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh),
      );
    } catch (_) {}
    try {
      _config = await widget.api.toolConfig();
    } catch (_) {}
    try {
      _providers = await widget.api.providers();
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
          Text(
            entry.key.toUpperCase(),
            style: textOf(context).micro.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colorsOf(context).mutedForeground,
            ),
          ),
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
                ? Text(
                    context.l10n.noConfig,
                    style: text.micro.copyWith(color: colors.mutedForeground),
                  )
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
                          : colors.warning,
                    ),
                  ),
            onTap: () => setState(
              () => _expanded = _expanded == tool.name ? null : tool.name,
            ),
          ),
          if (_expanded == tool.name)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tool.description.isNotEmpty)
                    Text(
                      tool.description,
                      style: text.micro.copyWith(color: colors.mutedForeground),
                    ),
                  // Data-driven config editors from the extension config.
                  // Every knob renders a plain text field the user fills in
                  // (model refs like vlm_model / image_model are free-form
                  // "provider_id/model_id" strings, typed by the user).
                  for (final c in extConfigs) _extConfigEditor(tool, c),
                  if (tool.params.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.toolParams,
                      style: text.meta.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
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
      children: [for (final p in params) _paramRow(p, depth)],
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
                  fontWeight: p.required ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (p.enumValues != null)
                Text(
                  '${p.type} (${p.enumValues!.join('/')})',
                  style: text.micro.copyWith(color: colors.mutedForeground),
                )
              else
                Text(
                  p.type,
                  style: text.micro.copyWith(color: colors.mutedForeground),
                ),
            ],
          ),
        ),
        if (p.description.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0, top: 1),
            child: Text(
              p.description,
              style: text.micro.copyWith(color: colors.mutedForeground),
            ),
          ),
        if (p.children.isNotEmpty)
          _FoldGroup(children: p.children, depth: depth + 1),
      ],
    );
  }

  /// Render an extension config knob — a plain text field + an explicit
  /// "Save" button (no enter-to-save surprise). Value is saved to the extId
  /// (tool.category) config. When a value is already set it is pre-filled so
  /// the user can see/edit what is configured (like a settings form).
  Widget _extConfigEditor(ToolInfo tool, ToolConfig c) {
    final extId = tool.category; // the owning extension id
    final current = _config[tool.name]?[c.name];
    // Model-ref knobs (image_model / image_edit_model / video_model /
    // tts_model / asr_model) list the GATEWAY provider's models — multimodal
    // models live only on the single Vercel-compatible gateway. `vlm_model` is
    // special: a vision model is a gateway TEXT model (context_limit > 0).
    if (_isModelRefKnob(c.name)) {
      return _GenerativeModelPicker(
        label: c.name,
        description: c.description,
        textOnly: c.name.toLowerCase() == 'vlm_model',
        providers: _providers,
        initialValue: current == null ? '' : '$current',
        onSave: (v) => _saveExtConfig(extId, c.name, v),
      );
    }
    return _ConfigTextField(
      label: c.name,
      description: c.description,
      initialValue: current == null ? '' : '$current',
      onSave: (v) => _saveExtConfig(extId, c.name, v),
    );
  }

  /// True when a config knob is a model reference (vision or a gateway
  /// multimodal model).
  static bool _isModelRefKnob(String knob) {
    const names = {
      'vlm_model',
      'image_model',
      'image_edit_model',
      'video_model',
      'tts_model',
      'asr_model',
    };
    return names.contains(knob.toLowerCase());
  }

  Future<void> _saveExtConfig(String extId, String name, Object? value) async {
    if (value == null || '$value'.isEmpty) return;
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
      showToast(context, context.l10n.saved);
    } catch (e) {
      showErrorToast(context, '$e');
    }
  }
}

/// Provider/model dropdown for a model-reference config knob. The saved value
/// is a canonical `provider_id/model_id` reference, echoed back when set.
///
/// Multimodal models (image / image-edit / video / tts / asr) exist only on
/// the single Vercel-compatible gateway, so [textOnly] picks text models
/// (`context_limit > 0`) and everything else picks the gateway's multimodal
/// models (`context_limit == 0`).
class _GenerativeModelPicker extends StatefulWidget {
  final String label;
  final String description;
  final bool textOnly;
  final Map<String, ProviderInfo> providers;
  final String initialValue;
  final ValueChanged<String> onSave;
  const _GenerativeModelPicker({
    required this.label,
    required this.description,
    required this.providers,
    required this.onSave,
    this.textOnly = false,
    this.initialValue = '',
  });

  @override
  State<_GenerativeModelPicker> createState() => _GenerativeModelPickerState();
}

class _GenerativeModelPickerState extends State<_GenerativeModelPicker> {
  late String _selected = widget.initialValue;

  @override
  void didUpdateWidget(covariant _GenerativeModelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _selected = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = textOf(context);
    final colors = colorsOf(context);
    // Flatten registered models into `provider_id/model_id` refs.
    //
    // `vlm_model` (textOnly) wants a vision-capable TEXT model, so list text
    // providers' models with a context window. All other knobs are multimodal
    // and resolve to the single gateway provider's models.
    const gatewayId = 'gateway';
    final refs = <(String, String)>[]; // (ref, modelName)
    for (final p in widget.providers.values) {
      final isGateway = p.providerId == gatewayId;
      if (widget.textOnly) {
        if (isGateway) continue;
        for (final m in p.models) {
          if ((m.contextLimit ?? 0) <= 0) continue;
          refs.add(('${p.providerId}/${m.id}', m.name));
        }
      } else {
        if (!isGateway) continue;
        for (final m in p.models) {
          refs.add(('${p.providerId}/${m.id}', m.name));
        }
      }
    }
    final valid = refs.any((r) => r.$1 == _selected) || _selected.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.description.isNotEmpty)
            Text(
              widget.description,
              style: text.micro.copyWith(color: colors.mutedForeground),
            ),
          DropdownButtonFormField<String>(
            // An unknown stored ref (provider deleted) still shows, so the
            // user sees the stale value instead of a silent reset.
            initialValue: valid
                ? (_selected.isEmpty ? null : _selected)
                : _selected,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: _selected.isEmpty
                  ? null
                  : Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: colors.success,
                    ),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(context.l10n.none)),
              for (final (ref, name) in refs)
                DropdownMenuItem(
                  value: ref,
                  child: Text(name == ref ? ref : '$name —— $ref'),
                ),
            ],
            onChanged: (v) => setState(() => _selected = v ?? ''),
          ),
          if (refs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                context.l10n.selectProviderFirst,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _selected.isEmpty
                  ? null
                  : () => widget.onSave(_selected),
              child: Text(context.l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled config text field with an explicit Save button. [initialValue]
/// pre-fills the field with the currently configured value (empty when unset).
class _ConfigTextField extends StatefulWidget {
  final String label;
  final String description;
  final String initialValue;
  final ValueChanged<String> onSave;
  const _ConfigTextField({
    required this.label,
    required this.description,
    required this.onSave,
    this.initialValue = '',
  });

  @override
  State<_ConfigTextField> createState() => _ConfigTextFieldState();
}

class _ConfigTextFieldState extends State<_ConfigTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void didUpdateWidget(covariant _ConfigTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect an externally-loaded/refreshed value (e.g. the async config load
    // completing after first build) without stomping on what the user typed.
    if (widget.initialValue != oldWidget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final hasValue = _controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.description.isNotEmpty)
            Text(
              widget.description,
              style: text.micro.copyWith(color: colors.mutedForeground),
            ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.label,
              // A configured knob is visually flagged so the user can tell
              // "set" from "empty" at a glance.
              prefixIcon: hasValue
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: colors.success,
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
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
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _open
                      ? '${context.l10n.showLess} (${widget.children.length})'
                      : '${context.l10n.showMore} (${widget.children.length})',
                  style: textOf(context).micro
                      .copyWith(color: colors.mutedForeground),
                ),
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
        children: [for (final p in widget.children) _childRow(p)],
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
                  fontWeight: p.required ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                p.type,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
          if (p.description.isNotEmpty)
            Text(
              p.description,
              style: text.micro.copyWith(color: colors.mutedForeground),
            ),
          if (p.children.isNotEmpty)
            _FoldGroup(children: p.children, depth: widget.depth + 1),
        ],
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
    showToast(context, context.l10n.saved);
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
            child: Text(
              context.l10n.noSavedBackends,
              style: TextStyle(color: colors.mutedForeground),
            ),
          ),
        for (final b in _backends)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(
                Icons.dns_outlined,
                color: Colors.greenAccent,
              ),
              title: Text(b.name.isNotEmpty ? b.name : b.baseUrl),
              subtitle: Text(
                b.baseUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: colors.mutedForeground,
                ),
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
          onTap: () => onAddUser?.call(),
        ),
      ],
    );
  }
}
