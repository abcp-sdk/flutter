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
              IconButton.filledTonal(
                tooltip: context.l10n.addModel,
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: () {
                  store.pushPage(const ProviderModelsPage());
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

/// A compact, read-only model row in the provider form (removable).
class _ModelRow extends StatelessWidget {
  final ProviderModel model;
  final VoidCallback onRemove;
  const _ModelRow({required this.model, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final isText = model.capability.isEmpty || model.capability == 'text';
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.4),
        borderRadius: AppRadius.rSm,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Model form page — pick a capability + a model id (manual), or browse the
// models.dev catalog. Added models land on the provider draft's model list.
// ---------------------------------------------------------------------------
class ProviderModelsScreen extends StatefulWidget {
  final AppStore store;
  const ProviderModelsScreen({super.key, required this.store});

  @override
  State<ProviderModelsScreen> createState() => _ProviderModelsScreenState();
}

class _ProviderModelsScreenState extends State<ProviderModelsScreen> {
  AppStore get store => widget.store;

  final _modelIdCtrl = TextEditingController();
  final _modelCtxCtrl = TextEditingController();
  String _capability = 'text';

  MdProvider? _template;
  String _modelQuery = '';
  String _catalogCapability = 'text';

  @override
  void initState() {
    super.initState();
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

  void _addManual() {
    final d = store.providerDraft;
    if (d == null) return;
    final mid = _modelIdCtrl.text.trim();
    if (mid.isEmpty) return;
    if (d.models.any((m) => m.id == mid)) {
      store.popPage();
      return;
    }
    final isText = _capability == 'text';
    final ctx = int.tryParse(_modelCtxCtrl.text.trim());
    if (isText && (ctx == null || ctx <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contextLengthRequired)),
      );
      return;
    }
    d.models.add(
      ProviderModel(
        id: mid,
        name: mid,
        contextLimit: isText ? ctx : null,
        capability: _capability,
      ),
    );
    store.popPage();
  }

  void _addCatalog(MdModel m) {
    final d = store.providerDraft;
    if (d == null) return;
    if (d.models.any((x) => x.id == m.id)) return;
    setState(() {
      d.models.add(
        ProviderModel(
          id: m.id,
          name: m.name,
          contextLimit: m.contextLimit,
          capability: m.capability,
        ),
      );
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
    setState(() => _template = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final d = store.providerDraft;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
        title: Text(context.l10n.addModel),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Capability selector (decides the model's generation modality).
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
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _modelIdCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.modelIdLabel,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (_capability == 'text')
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _modelCtxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.contextLengthLabel,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: _addManual,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.add),
          ),
          const Divider(height: AppSpacing.xl),
          // Catalog browser (optional): pick a models.dev provider, filter by
          // capability, tap a chip to add it.
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
                    onPressed: d.models.any((x) => x.id == m.id)
                        ? null
                        : () => _addCatalog(m),
                  ),
                if (filtered.isEmpty)
                  Text(
                    context.l10n.noPackagesYet,
                    style: text.micro.copyWith(color: colors.mutedForeground),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // The draft's current models, so the user sees what they added.
          if (d.models.isNotEmpty) ...[
            Text(
              context.l10n.modelsLabel,
              style: text.meta.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            for (final m in d.models)
              _ModelRow(
                model: m,
                onRemove: () => setState(() => d.models.remove(m)),
              ),
          ],
        ],
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
