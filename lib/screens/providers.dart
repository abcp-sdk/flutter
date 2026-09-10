import 'package:flutter/material.dart';

import '../api.dart';
import '../i18n.dart';
import '../models.dart';
import '../services/models_dev.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';

/// Map a raw API type string to its localized display label.
String apiTypeLabel(BuildContext context, String apiType) {
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

/// Icon + color for a model capability (text/image/video/speech).
Widget capabilityIcon(BuildContext context, String capability,
    {double size = 14}) {
  final colors = colorsOf(context);
  switch (capability) {
    case 'image':
      return Icon(Icons.image_outlined, size: size, color: colors.warning);
    case 'video':
      return Icon(Icons.videocam_outlined, size: size, color: colors.destructive);
    case 'speech':
      return Icon(Icons.graphic_eq_rounded, size: size, color: colors.primary);
    default:
      return Icon(Icons.chat_bubble_outline_rounded,
          size: size, color: colors.success);
  }
}

/// Localized capability label.
String capabilityLabel(BuildContext context, String capability) {
  switch (capability) {
    case 'image':
      return context.l10n.capImage;
    case 'video':
      return context.l10n.capVideo;
    case 'speech':
      return context.l10n.capSpeech;
    default:
      return context.l10n.capText;
  }
}

/// Providers detail: one card per provider; inside each, ONE CARD PER MODEL
/// with its own test button (text models only) and remove action. Editing
/// happens on a DRAFT: model add/remove/test are local until "save" registers
/// the whole provider (register is an upsert keyed by provider id).
class ProvidersDetail extends StatefulWidget {
  final Map<String, ProviderInfo> providers;
  final VoidCallback onChanged;
  final AgentBindApi api;
  const ProvidersDetail(
      {super.key,
      required this.providers,
      required this.onChanged,
      required this.api});

  @override
  State<ProvidersDetail> createState() => _ProvidersDetailState();
}

class _ProvidersDetailState extends State<ProvidersDetail> {
  /// Provider id whose model cards are expanded, or '__add__' for the add form.
  String? _expanded;
  // Draft edit of an existing provider (null = view mode for that provider).
  _ProviderDraft? _draft;

  @override
  Widget build(BuildContext context) {
    final text = textOf(context);
    final entries = widget.providers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (final e in entries) ...[
          _providerCard(e.key, e.value),
          if (_expanded == e.key && _draft != null && _draft!.id == e.key)
            _ProviderEditor(
              api: widget.api,
              draft: _draft!,
              onSaved: () {
                setState(() {
                  _expanded = null;
                  _draft = null;
                });
                widget.onChanged();
              },
              onCancel: () => setState(() {
                _expanded = null;
                _draft = null;
              }),
            ),
        ],
        if (widget.providers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(context.l10n.noProviders,
                style: TextStyle(color: colorsOf(context).mutedForeground)),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (_expanded == '__add__' && _draft != null)
          _ProviderEditor(
            api: widget.api,
            draft: _draft!,
            onSaved: () {
              setState(() {
                _expanded = null;
                _draft = null;
              });
              widget.onChanged();
            },
            onCancel: () => setState(() {
              _expanded = null;
              _draft = null;
            }),
          )
        else
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _expanded = '__add__';
              _draft = _ProviderDraft(apiType: 'openai-compatible');
            }),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(context.l10n.addProvider),
          ),
        if (entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(text.micro.color == null ? '' : '',
                style: const TextStyle(fontSize: 0)),
          ),
      ],
    );
  }

  Widget _providerCard(String id, ProviderInfo p) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final expanded = _expanded == id;
    final byCap = <String, int>{};
    for (final m in p.models) {
      byCap[m.capability] = (byCap[m.capability] ?? 0) + 1;
    }
    final capSummary = byCap.entries
        .map((e) => e.key == 'text'
            ? '${e.value}'
            : '${e.value} ${capabilityLabel(context, e.key)}')
        .join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: () => setState(() {
          if (expanded) {
            _expanded = null;
            _draft = null;
          } else {
            _expanded = id;
            _draft = _ProviderDraft.fromProvider(p);
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.folder_open_rounded
                    : Icons.folder_outlined,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$id · ${apiTypeLabel(context, p.apiType)}',
                      overflow: TextOverflow.ellipsis,
                      style: text.meta
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.modelsCount('${p.models.length}') + (capSummary.isEmpty ? '' : ' · $capSummary'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.micro.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: colors.mutedForeground),
                tooltip: context.l10n.deleteProvider,
                onPressed: () async {
                  final ok = await confirmDialog(context,
                      title: context.l10n.deleteProvider,
                      description: context.l10n.deleteProviderBody(id));
                  if (ok) {
                    await widget.api.deleteProvider(id);
                    widget.onChanged();
                  }
                },
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draft state while editing/adding a provider. Model mutations stay local
/// until the editor's save button re-registers the provider.
class _ProviderDraft {
  String? originalId; // null = brand-new provider
  String id;
  String apiType;
  String baseUrl;
  String apiKey;
  List<ProviderModel> models;

  _ProviderDraft({
    this.originalId,
    this.id = '',
    this.apiType = 'openai-compatible',
    this.baseUrl = '',
    this.apiKey = '',
    List<ProviderModel>? models,
  }) : models = models ?? [];

  factory _ProviderDraft.fromProvider(ProviderInfo p) => _ProviderDraft(
        originalId: p.providerId,
        id: p.providerId,
        apiType: p.apiType,
        baseUrl: p.baseUrl,
        apiKey: p.apiKey,
        models: [...p.models],
      );

}

/// The provider editor: provider fields + one card per model + save.
class _ProviderEditor extends StatefulWidget {
  final AgentBindApi api;
  final _ProviderDraft draft;
  final VoidCallback onSaved;
  final VoidCallback onCancel;
  const _ProviderEditor({
    required this.api,
    required this.draft,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_ProviderEditor> createState() => _ProviderEditorState();
}

class _ProviderEditorState extends State<_ProviderEditor> {
  late final TextEditingController _id =
      TextEditingController(text: widget.draft.id);
  late final TextEditingController _url =
      TextEditingController(text: widget.draft.baseUrl);
  late final TextEditingController _key =
      TextEditingController(text: widget.draft.apiKey);
  late String _apiType = widget.draft.apiType;

  // Per-model test state, keyed by model id. [_testOk] holds the verdict,
  // [_testMsg] the message.
  final Map<String, bool> _testOk = {};
  final Map<String, String> _testMsg = {};
  final Set<String> _testing = {};

  // models.dev template prefill (fills fields + adds cards, no auto-select).
  MdProvider? _template;
  String _modelQuery = '';
  /// Capability filter for the catalog list: text (default) | image | video |
  /// speech | all.
  String _capabilityFilter = 'text';

  // Manual model entry.
  final _modelIdCtrl = TextEditingController();
  final _modelCtxCtrl = TextEditingController();
  String _manualCapability = 'text';

  bool _registering = false;

  bool get _isEdit => widget.draft.originalId != null;

  @override
  void dispose() {
    _id.dispose();
    _url.dispose();
    _key.dispose();
    _modelIdCtrl.dispose();
    _modelCtxCtrl.dispose();
    super.dispose();
  }

  ProviderInfo _build() => ProviderInfo(
        providerId: _id.text.trim(),
        apiType: _apiType,
        baseUrl: _url.text.trim(),
        apiKey: _key.text,
        models: widget.draft.models,
      );

  Future<void> _save() async {
    final p = _build();
    if (p.providerId.isEmpty || p.baseUrl.isEmpty) return;
    // Text models must carry a context length; generation models are fine at 0.
    if (p.models.any((m) =>
        (m.capability.isEmpty || m.capability == 'text') &&
        (m.contextLimit ?? 0) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contextLengthRequired)));
      return;
    }
    setState(() => _registering = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.api.registerProvider(p);
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.saved)));
      widget.onSaved();
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _registering = false);
  }

  Future<void> _testModel(ProviderModel m) async {
    final key = m.id;
    setState(() {
      _testing.add(key);
      _testOk.remove(key);
      _testMsg.remove(key);
    });
    final r = await widget.api.testProvider(
      apiType: _apiType,
      baseUrl: _url.text.trim(),
      apiKey: _key.text,
      model: '${_id.text.trim()}/${m.id}',
      capability: m.capability,
    );
    if (!mounted) return;
    final ok = r['ok'] == true;
    setState(() {
      _testing.remove(key);
      _testOk[key] = ok;
      _testMsg[key] = ok
          ? context.l10n.testModelOk('${r['result'] ?? ''}')
          : '${r['result'] ?? 'Failed'}';
    });
  }

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
      _id.text = picked.id;
      if (picked.api.isNotEmpty) _url.text = picked.api;
      _apiType = ModelsDev.npmToType(picked.npm);
      // Selecting a template pre-adds EVERY catalog model as a card
      // (capability derived from each model's output modality) — the user
      // then prunes with the per-card remove button.
      widget.draft.models
        ..clear()
        ..addAll(picked.models
            .map((m) => ProviderModel(
                  id: m.id,
                  name: m.name,
                  contextLimit: m.contextLimit,
                  capability: m.capability,
                ))
            .toList());
    });
  }

  void _addManualModel() {
    final mid = _modelIdCtrl.text.trim();
    if (mid.isEmpty) return;
    if (widget.draft.models.any((m) => m.id == mid)) return;
    final isText = _manualCapability == 'text';
    final ctx = int.tryParse(_modelCtxCtrl.text.trim());
    if (isText && (ctx == null || ctx <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contextLengthRequired)));
      return;
    }
    setState(() {
      widget.draft.models.add(ProviderModel(
        id: mid,
        name: mid,
        contextLimit: isText ? ctx : null,
        capability: _manualCapability,
      ));
    });
    _modelIdCtrl.clear();
    _modelCtxCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final templateModels = _template?.models ?? <MdModel>[];
    final filteredModels = templateModels
        .where((m) =>
            _capabilityFilter == 'all' || m.capability == _capabilityFilter)
        .where((m) =>
            _modelQuery.isEmpty ||
            m.id.toLowerCase().contains(_modelQuery.toLowerCase()) ||
            m.name.toLowerCase().contains(_modelQuery.toLowerCase()))
        .toList();
    final canSave = _id.text.trim().isNotEmpty && _url.text.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // models.dev template prefill: fills id / base URL / api type and
            // pre-adds every catalog model as a card.
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
                            if (!_isEdit) widget.draft.models.clear();
                          }),
                        ),
                ),
                child: Text(
                  _template == null
                      ? context.l10n.providerTemplateHint
                      : _template!.name,
                  style: text.meta.copyWith(
                      color:
                          _template == null ? colors.mutedForeground : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _id,
                enabled: !_isEdit,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: context.l10n.providerIdReq,
                    helperText: _isEdit ? null : null)),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _apiType,
              items: [
                DropdownMenuItem(
                    value: 'openai-compatible',
                    child: Text(context.l10n.apiTypeOpenaiCompat)),
                DropdownMenuItem(
                    value: 'openai', child: Text(context.l10n.apiTypeOpenai)),
                DropdownMenuItem(
                    value: 'anthropic',
                    child: Text(context.l10n.apiTypeAnthropic)),
                DropdownMenuItem(
                    value: 'gemini', child: Text(context.l10n.apiTypeGemini)),
              ],
              onChanged: (v) => setState(() => _apiType = v!),
              decoration: InputDecoration(labelText: context.l10n.apiType),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _url,
                onChanged: (_) => setState(() {}),
                decoration:
                    InputDecoration(labelText: context.l10n.baseUrlReq)),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _key,
                obscureText: true,
                decoration: InputDecoration(labelText: context.l10n.apiKeyReq)),
            const SizedBox(height: AppSpacing.md),

            // ---- model cards ----
            Text(context.l10n.modelsLabel,
                style: text.meta
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: AppSpacing.xs),
            if (widget.draft.models.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(context.l10n.providerTemplateHint,
                    style:
                        text.micro.copyWith(color: colors.mutedForeground)),
              ),
            for (final m in widget.draft.models)
              _ModelCard(
                model: m,
                testState: _testing.contains(m.id)
                    ? _ModelTestState.running
                    : (_testOk.containsKey(m.id)
                        ? (_testOk[m.id]! ? _ModelTestState.ok : _ModelTestState.fail)
                        : _ModelTestState.idle),
                testMessage: _testMsg[m.id],
                onTest: () => _testModel(m),
                onRemove: () => setState(() {
                  widget.draft.models.remove(m);
                  _testOk.remove(m.id);
                  _testMsg.remove(m.id);
                }),
              ),

            // ---- add a model ----
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.addModel,
                style: text.meta
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'text', label: Text(context.l10n.capText)),
                ButtonSegment(
                    value: 'image', label: Text(context.l10n.capImage)),
                ButtonSegment(
                    value: 'video', label: Text(context.l10n.capVideo)),
                ButtonSegment(
                    value: 'speech', label: Text(context.l10n.capSpeech)),
              ],
              selected: {_manualCapability},
              onSelectionChanged: (s) =>
                  setState(() => _manualCapability = s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
                if (_manualCapability == 'text')
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
                  onPressed: _addManualModel,
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ),

            // ---- catalog browser (template picked) ----
            if (_template != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'text', label: Text('text')),
                  ButtonSegment(value: 'image', label: Text('image')),
                  ButtonSegment(value: 'video', label: Text('video')),
                  ButtonSegment(value: 'speech', label: Text('speech')),
                  ButtonSegment(value: 'all', label: Text('all')),
                ],
                selected: {_capabilityFilter},
                onSelectionChanged: (s) =>
                    setState(() => _capabilityFilter = s.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                decoration: InputDecoration(
                  hintText: context.l10n.searchModels,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _modelQuery = v),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final m in filteredModels)
                        if (!widget.draft.models.any((x) => x.id == m.id))
                          ActionChip(
                            label: Text(
                                m.name.isNotEmpty ? m.name : m.id,
                                style: text.micro),
                            avatar: capabilityIcon(context, m.capability,
                                size: 13),
                            onPressed: () => setState(() {
                              widget.draft.models.add(ProviderModel(
                                id: m.id,
                                name: m.name,
                                contextLimit: m.contextLimit,
                                capability: m.capability,
                              ));
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: widget.onCancel,
                    child: Text(context.l10n.cancel)),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: canSave && !_registering ? _save : null,
                  child: Text(_registering
                      ? context.l10n.registering
                      : (_isEdit ? context.l10n.save : context.l10n.register)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ModelTestState { idle, running, ok, fail }

/// One card per model: capability icon, id (+context), per-model test button
/// and remove.
class _ModelCard extends StatelessWidget {
  final ProviderModel model;
  final _ModelTestState testState;
  final String? testMessage;
  final VoidCallback onTest;
  final VoidCallback onRemove;
  const _ModelCard({
    required this.model,
    required this.testState,
    required this.testMessage,
    required this.onTest,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final isText = model.capability.isEmpty || model.capability == 'text';
    final testable = isText; // generation models: no test yet
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: colors.muted.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                capabilityIcon(context, model.capability),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(model.id,
                      overflow: TextOverflow.ellipsis,
                      style: text.mono.copyWith(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: context.l10n.delete,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  isText
                      ? '${capabilityLabel(context, model.capability)} · ${context.l10n.contextLengthLabel} ${model.contextLimit ?? 0}'
                      : capabilityLabel(context, model.capability),
                  style:
                      text.micro.copyWith(color: colors.mutedForeground),
                ),
                const Spacer(),
                if (testable)
                  testState == _ModelTestState.running
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                          ),
                          onPressed: onTest,
                          icon: Icon(
                            testState == _ModelTestState.ok
                                ? Icons.check_circle_rounded
                                : Icons.science_outlined,
                            size: 14,
                            color: testState == _ModelTestState.ok
                                ? colors.success
                                : null,
                          ),
                          label: Text(
                            testState == _ModelTestState.ok
                                ? context.l10n.taskDone
                                : context.l10n.test,
                            style: text.micro,
                          ),
                        )
                else
                  Text(context.l10n.noTest,
                      style: text.micro
                          .copyWith(color: colors.mutedForeground)),
              ],
            ),
            if (testState == _ModelTestState.fail && testMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(testMessage!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.micro
                        .copyWith(color: colors.destructive)),
              ),
          ],
        ),
      ),
    );
  }
}

/// models.dev catalog picker (bottom sheet): search + capability filter.
class _TemplatePickerSheet extends StatefulWidget {
  const _TemplatePickerSheet();
  @override
  State<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<_TemplatePickerSheet> {
  List<MdProvider> _all = [];
  String _q = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ModelsDev.load();
      if (!mounted) return;
      setState(() {
        _all = p;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final filtered = _q.isEmpty
        ? _all
        : _all
            .where((p) =>
                p.id.toLowerCase().contains(_q.toLowerCase()) ||
                p.name.toLowerCase().contains(_q.toLowerCase()))
            .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.searchModels,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return ListTile(
                          leading: const Icon(Icons.dns_outlined, size: 18),
                          title: Text(p.name,
                              style: text.meta
                                  .copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(p.id,
                              style: text.micro
                                  .copyWith(color: colors.mutedForeground)),
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
