import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models.dart';
import '../navigation.dart';
import '../services/models_dev.dart';
import '../store.dart';
import '../theme/app_theme.dart';

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
Widget capabilityIcon(
  BuildContext context,
  String capability, {
  double size = 14,
}) {
  final colors = colorsOf(context);
  switch (capability) {
    case 'image':
      return Icon(Icons.image_outlined, size: size, color: colors.warning);
    case 'video':
      return Icon(
        Icons.videocam_outlined,
        size: size,
        color: colors.destructive,
      );
    case 'speech':
      return Icon(Icons.graphic_eq_rounded, size: size, color: colors.primary);
    default:
      return Icon(
        Icons.chat_bubble_outline_rounded,
        size: size,
        color: colors.success,
      );
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

/// The full model capability set offered when adding a model.
const List<String> kModelCapabilities = ['text', 'image', 'video', 'speech'];

// ---------------------------------------------------------------------------
// Providers list page — a plain LIST of providers; "+" in the app bar starts
/// the add flow (provider form). Tapping a row edits that provider.
// ---------------------------------------------------------------------------
class ProvidersListScreen extends StatefulWidget {
  final AppStore store;
  const ProvidersListScreen({super.key, required this.store});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  AppStore get store => widget.store;
  Map<String, ProviderInfo> _providers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _load();
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (!mounted) return;
    // The store is notified when a provider draft is completed/cancelled, so a
    // return from the form page refreshes this list. Guard against overlapping
    // reloads (store notifications are cheap but can arrive in bursts).
    setState(() {});
    if (_providersLoading) return;
    _reload();
  }

  bool _providersLoading = false;

  Future<void> _reload() async {
    _providersLoading = true;
    try {
      final p = await store.api.providers();
      if (mounted) setState(() => _providers = p);
    } catch (_) {}
    _providersLoading = false;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _reload();
    if (mounted) setState(() => _loading = false);
  }

  void _add() {
    store.beginProviderDraft(null);
    store.pushPage(const ProviderFormPage());
  }

  void _edit(ProviderInfo p) {
    store.beginProviderDraft(p);
    store.pushPage(const ProviderFormPage());
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final entries = _providers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => store.popPage(),
        ),
        title: Text(context.l10n.llmProviders),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: colors.primary),
            tooltip: context.l10n.addProvider,
            onPressed: _add,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      context.l10n.noProviders,
                      style: text.meta.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                for (final e in entries)
                  ListTile(
                    leading: Icon(
                      Icons.dns_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    title: Text(
                      e.key,
                      style: text.meta.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${apiTypeLabel(context, e.value.apiType)} · '
                      '${context.l10n.modelsCount('${e.value.models.length}')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.micro.copyWith(color: colors.mutedForeground),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () => _edit(e.value),
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider form page — the provider's connection fields plus a bottom model
// section. "+" in the model section opens the model form page.
// ---------------------------------------------------------------------------
class ProviderFormScreen extends StatefulWidget {
  final AppStore store;
  const ProviderFormScreen({super.key, required this.store});

  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  AppStore get store => widget.store;
  ProviderDraft? get draft => store.providerDraft;

  TextEditingController? _id;
  TextEditingController? _url;
  TextEditingController? _key;
  String _apiType = 'openai-compatible';
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    final d = draft;
    if (d != null) {
      _id = TextEditingController(text: d.id);
      _url = TextEditingController(text: d.baseUrl);
      _key = TextEditingController(text: d.apiKey);
      _apiType = d.apiType;
    }
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _id?.dispose();
    _url?.dispose();
    _key?.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> _pickTemplate() async {
    final d = draft;
    if (d == null) return;
    final picked = await showModalBottomSheet<MdProvider>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TemplatePickerSheet(),
    );
    if (picked == null) return;
    setState(() {
      _id?.text = picked.id;
      _url?.text = picked.api.isNotEmpty ? picked.api : (_url?.text ?? '');
      _apiType = ModelsDev.npmToType(picked.npm);
      d.id = picked.id;
      d.baseUrl = _url?.text ?? '';
      d.apiType = _apiType;
      // Prefill every catalog model (capability-derived); the user prunes.
      d.models
        ..clear()
        ..addAll(
          picked.models
              .map(
                (m) => ProviderModel(
                  id: m.id,
                  name: m.name,
                  contextLimit: m.contextLimit,
                  capability: m.capability,
                ),
              )
              .toList(),
        );
    });
  }

  Future<void> _save() async {
    final d = draft;
    if (d == null) return;
    d.id = _id?.text.trim() ?? d.id;
    d.apiType = _apiType;
    d.baseUrl = _url?.text.trim() ?? d.baseUrl;
    d.apiKey = _key?.text ?? d.apiKey;
    if (d.id.isEmpty || d.baseUrl.isEmpty) return;
    // Text models must carry a context length; generation models are fine at 0.
    if (d.models.any(
      (m) =>
          (m.capability.isEmpty || m.capability == 'text') &&
          (m.contextLimit ?? 0) <= 0,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contextLengthRequired)),
      );
      return;
    }
    setState(() => _registering = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.api.registerProvider(
        ProviderInfo(
          providerId: d.id,
          apiType: d.apiType,
          baseUrl: d.baseUrl,
          apiKey: d.apiKey,
          models: d.models,
        ),
      );
      store.endProviderDraft();
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.saved)));
      // Back to the providers list.
      store.popPage();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _registering = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final d = draft;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final canSave =
        (_id?.text.trim().isNotEmpty ?? false) &&
        (_url?.text.trim().isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            store.endProviderDraft();
            store.popPage();
          },
        ),
        title: Text(
          d.isEdit ? context.l10n.settingsTitle : context.l10n.addProvider,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // models.dev template prefill.
          InkWell(
            borderRadius: AppRadius.rSm,
            onTap: _pickTemplate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: context.l10n.providerTemplate,
                prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 18),
              ),
              child: Text(
                context.l10n.providerTemplateHint,
                style: text.meta.copyWith(color: colors.mutedForeground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _id,
            enabled: !d.isEdit,
            onChanged: (v) {
              d.id = v;
              setState(() {});
            },
            decoration: InputDecoration(labelText: context.l10n.providerIdReq),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _apiType,
            items: [
              DropdownMenuItem(
                value: 'openai-compatible',
                child: Text(context.l10n.apiTypeOpenaiCompat),
              ),
              DropdownMenuItem(
                value: 'openai',
                child: Text(context.l10n.apiTypeOpenai),
              ),
              DropdownMenuItem(
                value: 'anthropic',
                child: Text(context.l10n.apiTypeAnthropic),
              ),
              DropdownMenuItem(
                value: 'gemini',
                child: Text(context.l10n.apiTypeGemini),
              ),
            ],
            onChanged: (v) => setState(() {
              _apiType = v!;
              d.apiType = v;
            }),
            decoration: InputDecoration(labelText: context.l10n.apiType),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _url,
            onChanged: (v) {
              d.baseUrl = v;
              setState(() {});
            },
            decoration: InputDecoration(labelText: context.l10n.baseUrlReq),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _key,
            obscureText: true,
            onChanged: (v) => d.apiKey = v,
            decoration: InputDecoration(labelText: context.l10n.apiKeyReq),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- model section ----
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.modelsLabel,
                  style: text.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.addModel,
                icon: Icon(Icons.add_rounded, size: 20, color: colors.primary),
                onPressed: () {
                  store.pushPage(ProviderModelsPage());
                },
              ),
            ],
          ),
          if (d.models.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                context.l10n.providerTemplateHint,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
            ),
          for (final m in d.models)
            _ModelRow(
              model: m,
              onTap: () => store.pushPage(ProviderModelsPage(modelId: m.id)),
              onRemove: () => setState(() => d.models.remove(m)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: canSave && !_registering ? _save : null,
            child: Text(
              _registering
                  ? context.l10n.registering
                  : (d.isEdit ? context.l10n.save : context.l10n.register),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact, tappable model row in the provider form. Tapping opens the
/// model's own form page; the × removes it from the draft.
class _ModelRow extends StatelessWidget {
  final ProviderModel model;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _ModelRow({
    required this.model,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final isText = model.capability.isEmpty || model.capability == 'text';
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.4),
        borderRadius: AppRadius.rSm,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              capabilityIcon(context, model.capability),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  model.id,
                  overflow: TextOverflow.ellipsis,
                  style: text.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                isText
                    ? '${capabilityLabel(context, model.capability)} · ${model.contextLimit ?? 0}'
                    : capabilityLabel(context, model.capability),
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: context.l10n.delete,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model form page — a SINGLE model's form (its own capability, id, context and
// test). Opened with `modelId == null` to add a new model, or with an existing
// id to edit that model in place. Writes straight onto the provider draft.
// ---------------------------------------------------------------------------
class ProviderModelScreen extends StatefulWidget {
  final AppStore store;

  /// Null = adding a new model; otherwise the id of the model being edited.
  final String? modelId;
  const ProviderModelScreen({super.key, required this.store, this.modelId});

  @override
  State<ProviderModelScreen> createState() => _ProviderModelScreenState();
}

class _ProviderModelScreenState extends State<ProviderModelScreen> {
  AppStore get store => widget.store;

  late final TextEditingController _modelIdCtrl;
  late final TextEditingController _modelCtxCtrl;
  late String _capability;
  late String _name;

  // Catalog picker (fills the id/name/context fields).
  MdProvider? _template;
  String _modelQuery = '';
  String _catalogCapability = 'text';

  // Per-model test state.
  bool _testing = false;
  bool? _testOk;
  String? _testMsg;

  bool get _isEdit => widget.modelId != null;

  ProviderModel? _existing() {
    final d = store.providerDraft;
    if (d == null || widget.modelId == null) return null;
    for (final m in d.models) {
      if (m.id == widget.modelId) return m;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final m = _existing();
    _modelIdCtrl = TextEditingController(text: m?.id ?? '');
    _modelCtxCtrl = TextEditingController(
      text: (m?.contextLimit ?? 0) > 0 ? '${m!.contextLimit}' : '',
    );
    _capability = (m?.capability.isNotEmpty ?? false) ? m!.capability : 'text';
    _name = m?.name ?? '';
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _modelIdCtrl.dispose();
    _modelCtxCtrl.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _save() {
    final d = store.providerDraft;
    if (d == null) return;
    final mid = _modelIdCtrl.text.trim();
    if (mid.isEmpty) return;
    final isText = _capability == 'text';
    final ctx = int.tryParse(_modelCtxCtrl.text.trim());
    if (isText && (ctx == null || ctx <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contextLengthRequired)),
      );
      return;
    }
    // Editing: drop the old entry if the id changed (so a rename replaces).
    if (_isEdit) {
      d.models.removeWhere((m) => m.id == widget.modelId);
    }
    d.models.removeWhere((m) => m.id == mid);
    d.models.add(
      ProviderModel(
        id: mid,
        name: _name.isNotEmpty ? _name : mid,
        contextLimit: isText ? ctx : null,
        capability: _capability,
      ),
    );
    store.popPage();
  }

  Future<void> _test() async {
    final d = store.providerDraft;
    if (d == null) return;
    final mid = _modelIdCtrl.text.trim();
    if (mid.isEmpty) return;
    setState(() {
      _testing = true;
      _testOk = null;
      _testMsg = null;
    });
    final r = await store.api.testProvider(
      apiType: d.apiType,
      baseUrl: d.baseUrl,
      apiKey: d.apiKey,
      model: '${d.id}/$mid',
      capability: _capability,
    );
    if (!mounted) return;
    final ok = r['ok'] == true;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testMsg = ok
          ? context.l10n.testModelOk('${r['result'] ?? ''}')
          : '${r['result'] ?? 'Failed'}';
    });
  }

  void _remove() {
    final d = store.providerDraft;
    if (d == null) return;
    d.models.removeWhere((m) => m.id == widget.modelId);
    store.popPage();
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
      _catalogCapability = 'text';
    });
  }

  void _applyCatalog(MdModel m) {
    setState(() {
      _modelIdCtrl.text = m.id;
      _name = m.name.isNotEmpty ? m.name : m.id;
      _capability = m.capability;
      if ((m.contextLimit ?? 0) > 0) {
        _modelCtxCtrl.text = '${m.contextLimit}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final d = store.providerDraft;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isText = _capability == 'text';
    final templateModels = _template?.models ?? <MdModel>[];
    final filtered = templateModels
        .where(
          (m) =>
              _catalogCapability == 'all' || m.capability == _catalogCapability,
        )
        .where(
          (m) =>
              _modelQuery.isEmpty ||
              m.id.toLowerCase().contains(_modelQuery.toLowerCase()) ||
              m.name.toLowerCase().contains(_modelQuery.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => store.popPage(),
        ),
        title: Text(_isEdit ? context.l10n.modelLabel : context.l10n.addModel),
        actions: [
          if (_isEdit)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.destructive,
              ),
              tooltip: context.l10n.delete,
              onPressed: _remove,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Capability selector (decides the model's generation modality).
          Text(
            context.l10n.modelLabel,
            style: text.meta.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<String>(
            segments: [
              for (final c in kModelCapabilities)
                ButtonSegment(
                  value: c,
                  label: Text(capabilityLabel(context, c)),
                ),
            ],
            selected: {_capability},
            onSelectionChanged: (s) => setState(() => _capability = s.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _modelIdCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: context.l10n.modelIdLabel),
          ),
          if (isText) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _modelCtxCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.contextLengthLabel,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Test (text models only — generation models have no test path).
          if (isText)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing || _modelIdCtrl.text.trim().isEmpty
                      ? null
                      : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _testOk == true
                              ? Icons.check_circle_rounded
                              : Icons.science_outlined,
                          size: 16,
                          color: _testOk == true ? colors.success : null,
                        ),
                  label: Text(
                    _testing
                        ? context.l10n.testing
                        : (_testOk == true
                              ? context.l10n.taskDone
                              : context.l10n.test),
                  ),
                ),
              ],
            ),
          if (_testMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _testMsg!,
                style: text.micro.copyWith(
                  color: _testOk == true ? colors.success : colors.destructive,
                ),
              ),
            ),

          const Divider(height: AppSpacing.xl),
          // Catalog browser (optional): pick a models.dev provider, filter by
          // capability, tap a chip to fill the form.
          OutlinedButton.icon(
            onPressed: _pickTemplate,
            icon: const Icon(Icons.auto_awesome_outlined, size: 16),
            label: Text(
              _template == null
                  ? context.l10n.providerTemplateHint
                  : _template!.name,
            ),
          ),
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
              selected: {_catalogCapability},
              onSelectionChanged: (s) =>
                  setState(() => _catalogCapability = s.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
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
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in filtered)
                  ActionChip(
                    label: Text(
                      m.name.isNotEmpty ? m.name : m.id,
                      style: text.micro,
                    ),
                    avatar: capabilityIcon(context, m.capability, size: 13),
                    onPressed: () => _applyCatalog(m),
                  ),
                if (filtered.isEmpty)
                  Text(
                    context.l10n.noPackagesYet,
                    style: text.micro.copyWith(color: colors.mutedForeground),
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _modelIdCtrl.text.trim().isEmpty ? null : _save,
            child: Text(context.l10n.save),
          ),
        ),
      ),
    );
  }
}

/// models.dev catalog picker (bottom sheet): search + list of providers.
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
              .where(
                (p) =>
                    p.id.toLowerCase().contains(_q.toLowerCase()) ||
                    p.name.toLowerCase().contains(_q.toLowerCase()),
              )
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
                          title: Text(
                            p.name,
                            style: text.meta.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            p.id,
                            style: text.micro.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
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
