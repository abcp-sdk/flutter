import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models.dart';
import '../navigation.dart';
import '../services/models_dev.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';

/// The one special provider id + api type for the Vercel-AI-SDK-compatible
/// gateway. The gateway is a SUPERSET: it carries text models
/// (context_limit > 0) AND multimodal models (context_limit == 0) used by the
/// tools. It is registered at most once.
const String kGatewayApiType = 'vercel-compatible-gateway';
const String kGatewayProviderId = 'gateway';

bool isGatewayProvider(ProviderInfo p) => p.apiType == kGatewayApiType;

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
    case kGatewayApiType:
      return context.l10n.apiTypeGateway;
    default:
      return apiType;
  }
}

/// Text-provider api types (a text provider carries ONLY text models).
const List<String> kTextApiTypes = [
  'openai-compatible',
  'openai',
  'anthropic',
  'gemini',
];

/// Multimodal capabilities, used by the gateway model TEST (a gateway model
/// does not store its capability — it is implied by the tool config knob).
const List<String> kMultimodalCapabilities = [
  'text',
  'image',
  'video',
  'speech',
  'transcription',
];

/// Icon + color for a capability (test selector / gateway rows).
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
    case 'transcription':
      return Icon(
        Icons.record_voice_over_outlined,
        size: size,
        color: colors.accent,
      );
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
    case 'transcription':
      return context.l10n.capTranscription;
    default:
      return context.l10n.capText;
  }
}

// ---------------------------------------------------------------------------
// Providers list page — TWO sections:
//   * Providers : text providers (multi-provider; text models only)
//   * Gateway   : the single Vercel-compatible gateway (superset)
// ---------------------------------------------------------------------------
class ProvidersListScreen extends StatefulWidget {
  final AppStore store;
  /// Whether this page is the top of the tablet split (show a back arrow).
  final bool showBack;
  const ProvidersListScreen({super.key, required this.store, this.showBack = true});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  AppStore get store => widget.store;
  Map<String, ProviderInfo> _providers = {};
  bool _loading = true;
  bool _providersLoading = false;
  String _defaultModel = '';

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

  int _seenProvidersRevision = 0;

  void _onStore() {
    if (!mounted) return;
    setState(() {});
    // Only refetch when a provider actually changed — not on every store
    // notification (message deltas, drafts, navigation all notify).
    if (store.providersRevision == _seenProvidersRevision) return;
    _seenProvidersRevision = store.providersRevision;
    if (_providersLoading) return;
    _reload();
  }

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
    try {
      _defaultModel = await store.api.config('default_model');
    } catch (_) {}
    await _reload();
    if (mounted) setState(() => _loading = false);
  }

  void _addText() {
    store.beginProviderDraft(null);
    store.pushPage(const ProviderFormPage());
  }

  void _edit(ProviderInfo p) {
    store.beginProviderDraft(p);
    store.pushPage(const ProviderFormPage());
  }

  void _editGateway(ProviderInfo? g) {
    store.beginProviderDraft(
      g ??
          ProviderInfo(
            providerId: kGatewayProviderId,
            apiType: kGatewayApiType,
            baseUrl: '',
            apiKey: '',
            models: const [],
          ),
    );
    store.pushPage(const GatewayFormPage());
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final all = _providers.values.toList();
    final textProviders = all.where((p) => !isGatewayProvider(p)).toList()
      ..sort((a, b) => a.providerId.compareTo(b.providerId));
    final gateway = all.firstWhere(
      isGatewayProvider,
      orElse: () => ProviderInfo(
        providerId: kGatewayProviderId,
        apiType: kGatewayApiType,
        baseUrl: '',
        apiKey: '',
        models: const [],
      ),
    );
    final hasGateway = all.any(isGatewayProvider);
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => store.popPage(),
              )
            : null,
        title: Text(context.l10n.llmProviders),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: colors.primary),
            tooltip: context.l10n.addProvider,
            onPressed: _addText,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader(context, context.l10n.providersSection),
                _defaultProviderTile(context, textProviders, colors),
                if (textProviders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      context.l10n.noProviders,
                      style: text.meta.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                for (final p in textProviders) _providerTile(context, p),
                const Divider(height: AppSpacing.xl),
                _sectionHeader(context, context.l10n.gatewaySection),
                ListTile(
                  leading: Icon(
                    Icons.hub_outlined,
                    size: 20,
                    color: hasGateway ? colors.success : colors.mutedForeground,
                  ),
                  title: Text(
                    kGatewayProviderId,
                    style: text.meta.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    hasGateway
                        ? '${context.l10n.modelsCount('${gateway.models.length}')} · ${gateway.baseUrl}'
                        : context.l10n.gatewayHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.micro.copyWith(color: colors.mutedForeground),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () => _editGateway(hasGateway ? gateway : null),
                ),
                if (hasGateway)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                    child: Text(
                      context.l10n.gatewayHint,
                      style: text.micro.copyWith(color: colors.mutedForeground),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    final text = textOf(context);
    final colors = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        label,
        style: text.micro.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: colors.mutedForeground,
        ),
      ),
    );
  }

  Widget _providerTile(BuildContext context, ProviderInfo p) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return ListTile(
      leading: Icon(Icons.dns_outlined, size: 20, color: colors.primary),
      title: Text(
        p.providerId,
        style: text.meta.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${apiTypeLabel(context, p.apiType)} · '
        '${context.l10n.modelsCount('${p.models.length}')}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.micro.copyWith(color: colors.mutedForeground),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () => _edit(p),
    );
  }

  /// The tenant DEFAULT text model, chosen inline here (not in a separate
  /// settings box). Selecting a provider's text model sets `default_model`,
  /// which the agent applies to every session created without an explicit
  /// model. Value is the canonical `provider_id/model_id` ref.
  Widget _defaultProviderTile(
    BuildContext context,
    List<ProviderInfo> providers,
    AppColors colors,
  ) {
    final text = textOf(context);
    final refs = <String>[
      for (final p in providers)
        for (final m in p.models)
          if ((m.contextLimit ?? 0) > 0) '${p.providerId}/${m.id}',
    ]..sort();
    if (_defaultModel.isNotEmpty && !refs.contains(_defaultModel)) {
      refs.insert(0, _defaultModel);
    }
    return ListTile(
      leading: Icon(Icons.star_outline_rounded, size: 20, color: colors.primary),
      title: Text(
        context.l10n.defaultModel,
        style: text.meta.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _defaultModel.isEmpty ? context.l10n.none : _defaultModel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.micro.copyWith(color: colors.mutedForeground),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () => _pickDefaultModel(context, refs),
    );
  }

  Future<void> _pickDefaultModel(
    BuildContext context,
    List<String> refs,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.defaultModel),
        children: [
          for (final ref in ['', ...refs])
            RadioListTile<String>(
              value: ref,
              groupValue: _defaultModel,
              title: Text(ref.isEmpty ? ctx.l10n.none : ref,
                  style: textOf(ctx).meta),
              onChanged: (v) => Navigator.pop(ctx, v ?? ''),
            ),
        ],
      ),
    );
    if (picked == null || picked == _defaultModel) return;
    try {
      await store.api.setConfigKey('default_model', picked);
      if (mounted) setState(() => _defaultModel = picked);
    } catch (e) {
      if (mounted) showErrorToast(context, '$e');
    }
  }
}

// ---------------------------------------------------------------------------
// Text provider form — id / api type / base URL / key + text models (each
// requires a context_limit). "+" opens the text-model form.
// ---------------------------------------------------------------------------
class ProviderFormScreen extends StatefulWidget {
  final AppStore store;
  final bool showBack;
  const ProviderFormScreen({super.key, required this.store, this.showBack = true});

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
      _apiType = d.apiType == kGatewayApiType
          ? 'openai-compatible'
          : d.apiType;
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
      d.models
        ..clear()
        ..addAll(
          picked.models
              .map(
                (m) => ProviderModel(
                  id: m.id,
                  name: m.name,
                  contextLimit: m.contextLimit,
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
    if (d.models.any((m) => (m.contextLimit ?? 0) <= 0)) {
      showToast(context, context.l10n.contextLengthRequired);
      return;
    }
    setState(() => _registering = true);
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
      store.bumpProvidersRevision();
      store.endProviderDraft();
      showToast(context, context.l10n.saved);
      store.popPage();
    } catch (e) {
      showErrorToast(context, '$e');
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
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  store.endProviderDraft();
                  store.popPage();
                },
              )
            : null,
        title: Text(
          d.isEdit ? context.l10n.settingsTitle : context.l10n.addProvider,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
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
              for (final t in kTextApiTypes)
                DropdownMenuItem(value: t, child: Text(apiTypeLabel(context, t))),
            ],
            onChanged: (v) => setState(() {
              _apiType = v ?? 'openai-compatible';
              d.apiType = _apiType;
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
                onPressed: () => store.pushPage(ProviderModelsPage()),
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

// ---------------------------------------------------------------------------
// Gateway form — the single Vercel-compatible gateway. base URL + key +
// model list. A model's context_limit > 0 marks it as a text model; == 0 marks
// it as a multimodal model (used by the tools).
// ---------------------------------------------------------------------------
class GatewayFormScreen extends StatefulWidget {
  final AppStore store;
  final bool showBack;
  const GatewayFormScreen({super.key, required this.store, this.showBack = true});

  @override
  State<GatewayFormScreen> createState() => _GatewayFormScreenState();
}

class _GatewayFormScreenState extends State<GatewayFormScreen> {
  AppStore get store => widget.store;
  ProviderDraft? get draft => store.providerDraft;

  TextEditingController? _url;
  TextEditingController? _key;
  bool _registering = false;
  bool _discovering = false;

  @override
  void initState() {
    super.initState();
    final d = draft;
    _url = TextEditingController(text: d?.baseUrl ?? '');
    _key = TextEditingController(text: d?.apiKey ?? '');
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _url?.dispose();
    _key?.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  /// Ask the gateway's `/config` for its models and classify each by the
  /// advertised kind (language → real context; everything else → multimodal).
  /// This is how the user avoids typing model ids and guessing capabilities.
  Future<void> _discover() async {
    final d = draft;
    if (d == null) return;
    final url = _url?.text.trim() ?? '';
    if (url.isEmpty) return;
    setState(() => _discovering = true);
    try {
      final r = await store.api.discoverGatewayModels(
        providerId: kGatewayProviderId,
        apiType: kGatewayApiType,
        baseUrl: url,
        apiKey: _key?.text ?? '',
      );
      if (!mounted) return;
      if (!r.error.isEmpty && r.models.isEmpty) {
        showErrorToast(context, r.error);
      } else {
        setState(() {
          d.models
            ..clear()
            ..addAll(r.models);
        });
        showToast(
          context,
          context.l10n.discoveredModels('${r.models.length}'),
        );
      }
    } catch (e) {
      showErrorToast(context, '$e');
    }
    if (mounted) setState(() => _discovering = false);
  }

  Future<void> _save() async {
    final d = draft;
    if (d == null) return;
    d.id = kGatewayProviderId;
    d.apiType = kGatewayApiType;
    d.baseUrl = _url?.text.trim() ?? '';
    d.apiKey = _key?.text ?? '';
    if (d.baseUrl.isEmpty) return;
    setState(() => _registering = true);
    try {
      await store.api.registerProvider(
        ProviderInfo(
          providerId: kGatewayProviderId,
          apiType: kGatewayApiType,
          baseUrl: d.baseUrl,
          apiKey: d.apiKey,
          models: d.models,
        ),
      );
      store.bumpProvidersRevision();
      store.endProviderDraft();
      showToast(context, context.l10n.saved);
      store.popPage();
    } catch (e) {
      showErrorToast(context, '$e');
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
    final canSave = (_url?.text.trim().isNotEmpty ?? false);
    final textModels = d.models.where((m) => (m.contextLimit ?? 0) > 0).toList();
    final multiModels =
        d.models.where((m) => (m.contextLimit ?? 0) <= 0).toList();
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  store.endProviderDraft();
                  store.popPage();
                },
              )
            : null,
        title: Text(context.l10n.gatewayTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            context.l10n.gatewayHint,
            style: text.micro.copyWith(color: colors.mutedForeground),
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
          const SizedBox(height: AppSpacing.md),
          // Auto-detect the models + their kinds straight from the gateway, so
          // the user doesn't hand-type ids or classify each one.
          OutlinedButton.icon(
            onPressed: (_url?.text.trim().isEmpty ?? true) || _discovering
                ? null
                : _discover,
            icon: _discovering
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined, size: 16),
            label: Text(
              _discovering
                  ? context.l10n.discoveringModels
                  : context.l10n.discoverModels,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Text / vision models (context_limit > 0).
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.gatewayTextModels,
                  style: text.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.addModel,
                icon: Icon(Icons.add_rounded, size: 20, color: colors.primary),
                onPressed: () => store.pushPage(GatewayModelPage()),
              ),
            ],
          ),
          if (textModels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                context.l10n.gatewayTextModelsHint,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
            ),
          for (final m in textModels)
            _ModelRow(
              model: m,
              onTap: () => store.pushPage(GatewayModelPage(modelId: m.id)),
              onRemove: () => setState(() => d.models.remove(m)),
            ),
          const SizedBox(height: AppSpacing.lg),
          // Multimodal models (image/video/speech/transcription).
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.gatewayMultimodalModels,
                  style: text.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.addModel,
                icon: Icon(Icons.add_rounded, size: 20, color: colors.accent),
                onPressed: () => store.pushPage(GatewayModelPage()),
              ),
            ],
          ),
          if (multiModels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                context.l10n.gatewayModelsHint,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
            ),
          for (final m in multiModels)
            _ModelRow(
              model: m,
              onTap: () => store.pushPage(GatewayModelPage(modelId: m.id)),
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
              _registering ? context.l10n.registering : context.l10n.save,
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact, tappable model row. A gateway multimodal model shows its kind
/// (image / video / speech / transcription / …) from `model.modelType`; a text
/// model shows its context window. Tapping edits; the × removes it.
class _ModelRow extends StatelessWidget {
  final ProviderModel model;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _ModelRow({
    required this.model,
    required this.onTap,
    required this.onRemove,
  });

  /// Localized label for a model kind tag.
  String _typeLabel(BuildContext context, String type) {
    switch (type) {
      case 'text':
      case '':
        return context.l10n.capText;
      case 'image':
        return context.l10n.capImage;
      case 'video':
        return context.l10n.capVideo;
      case 'speech':
        return context.l10n.capSpeech;
      case 'transcription':
        return context.l10n.capTranscription;
      case 'embedding':
        return context.l10n.capEmbedding;
      case 'reranking':
        return context.l10n.capReranking;
      case 'realtime':
        return context.l10n.capRealtime;
      default:
        return type;
    }
  }

  IconData _typeIcon(String type) => switch (type) {
        'image' => Icons.image_outlined,
        'video' => Icons.videocam_outlined,
        'speech' => Icons.graphic_eq_rounded,
        'transcription' => Icons.record_voice_over_outlined,
        'embedding' => Icons.scatter_plot_outlined,
        'reranking' => Icons.reorder_rounded,
        'realtime' => Icons.bolt_rounded,
        _ => Icons.chat_bubble_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final isText = (model.contextLimit ?? 0) > 0;
    final type = isText ? 'text' : model.modelType;
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
              Icon(
                _typeIcon(type),
                size: 14,
                color: colors.mutedForeground,
              ),
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
                    ? '${context.l10n.capText} · ${model.contextLimit ?? 0}'
                    : _typeLabel(context, type),
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
// TEXT-provider model form — a SINGLE text model (id, name, context). The
// context is REQUIRED (it drives compaction). A vision model is still a text
// model; the models.dev catalog can fill the fields. The gateway uses a
// DIFFERENT form ([GatewayModelScreen]) because its models are classified by
// context (text vs multimodal) rather than capability.
// ---------------------------------------------------------------------------
class ProviderModelScreen extends StatefulWidget {
  final AppStore store;
  final String? modelId;
  final bool showBack;
  const ProviderModelScreen({super.key, required this.store, this.modelId, this.showBack = true});

  @override
  State<ProviderModelScreen> createState() => _ProviderModelScreenState();
}

class _ProviderModelScreenState extends State<ProviderModelScreen> {
  AppStore get store => widget.store;

  late final TextEditingController _modelIdCtrl;
  late final TextEditingController _modelNameCtrl;
  late final TextEditingController _modelCtxCtrl;

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
    _modelNameCtrl = TextEditingController(text: m?.name ?? '');
    _modelCtxCtrl = TextEditingController(
      text: (m?.contextLimit ?? 0) > 0 ? '${m!.contextLimit}' : '',
    );
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _modelIdCtrl.dispose();
    _modelNameCtrl.dispose();
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
    final ctx = int.tryParse(_modelCtxCtrl.text.trim());
    if (ctx == null || ctx <= 0) {
      showToast(context, context.l10n.contextLengthRequired);
      return;
    }
    final name = _modelNameCtrl.text.trim();
    if (_isEdit) d.models.removeWhere((m) => m.id == widget.modelId);
    d.models.removeWhere((m) => m.id == mid);
    d.models.add(
      ProviderModel(
        id: mid,
        name: name.isNotEmpty ? name : mid,
        contextLimit: ctx,
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
      providerId: d.id,
      model: '${d.id}/$mid',
      capability: 'text',
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

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final d = store.providerDraft;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => store.popPage(),
              )
            : null,
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
          TextField(
            controller: _modelIdCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: context.l10n.modelIdLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _modelNameCtrl,
            decoration: InputDecoration(labelText: context.l10n.modelNameLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _modelCtxCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.contextLengthLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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

// ---------------------------------------------------------------------------
// GATEWAY model form — the gateway is a SUPERSET: it serves text/vision models
// (context_limit > 0) AND multimodal models (context_limit == 0 → image/video/
// speech/transcription, used by the tools). The form mirrors that split: the
// context field is optional and its emptiness decides the model kind. A "test
// as" selector picks which probe to run. There is no models.dev catalog here.
// ---------------------------------------------------------------------------
class GatewayModelScreen extends StatefulWidget {
  final AppStore store;
  final String? modelId;
  final bool showBack;
  const GatewayModelScreen({super.key, required this.store, this.modelId, this.showBack = true});

  @override
  State<GatewayModelScreen> createState() => _GatewayModelScreenState();
}

class _GatewayModelScreenState extends State<GatewayModelScreen> {
  AppStore get store => widget.store;

  late final TextEditingController _modelIdCtrl;
  late final TextEditingController _modelNameCtrl;
  late final TextEditingController _modelCtxCtrl;
  String _testCapability = 'text';

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
    _modelNameCtrl = TextEditingController(text: m?.name ?? '');
    _modelCtxCtrl = TextEditingController(
      text: (m?.contextLimit ?? 0) > 0 ? '${m!.contextLimit}' : '',
    );
    // Pre-select the probe kind from the stored kind (discovered modelType),
    // else from the context: a positive context is a text model, empty is
    // multimodal (image/video/speech/transcription).
    if (m != null) {
      if ((m.contextLimit ?? 0) > 0) {
        _testCapability = 'text';
      } else if (kMultimodalCapabilities.contains(m.modelType)) {
        _testCapability = m.modelType;
      } else {
        _testCapability = 'image';
      }
    }
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _modelIdCtrl.dispose();
    _modelNameCtrl.dispose();
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
    final ctx = int.tryParse(_modelCtxCtrl.text.trim());
    final name = _modelNameCtrl.text.trim();
    // The model kind is NOT invented here: it comes from discovery /config.
    // Preserve the existing tag when editing; default new manual entries to
    // '' (unknown) — a text model is implied by a positive context.
    final prev = _existing();
    final modelType = (prev?.modelType ?? '');
    if (_isEdit) d.models.removeWhere((m) => m.id == widget.modelId);
    d.models.removeWhere((m) => m.id == mid);
    d.models.add(
      ProviderModel(
        id: mid,
        name: name.isNotEmpty ? name : mid,
        contextLimit: (ctx != null && ctx > 0) ? ctx : 0,
        modelType: (ctx != null && ctx > 0) ? 'text' : modelType,
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
      providerId: d.id,
      model: '${d.id}/$mid',
      capability: _testCapability,
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

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final d = store.providerDraft;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ctx = int.tryParse(_modelCtxCtrl.text.trim());
    final isMultimodal = ctx == null || ctx <= 0;
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => store.popPage(),
              )
            : null,
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
          TextField(
            controller: _modelIdCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: context.l10n.modelIdLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _modelNameCtrl,
            decoration: InputDecoration(labelText: context.l10n.modelNameLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _modelCtxCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: context.l10n.contextLengthLabel,
              helperText: context.l10n.contextOptional,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // A one-line readout of the inferred kind so the user sees the
          // consequence of leaving the context empty.
          Row(
            children: [
              Icon(
                isMultimodal
                    ? Icons.auto_awesome_outlined
                    : Icons.chat_bubble_outline_rounded,
                size: 14,
                color: isMultimodal ? colors.accent : colors.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isMultimodal
                    ? context.l10n.multimodal
                    : context.l10n.capText,
                style: text.micro.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Test — the probe kind is chosen HERE only (never stored): the
          // stored context (not this selector) decides text vs multimodal.
          Text(
            context.l10n.testAs,
            style: text.meta.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in kMultimodalCapabilities)
                ChoiceChip(
                  label: Text(capabilityLabel(context, c)),
                  selected: _testCapability == c,
                  onSelected: (_) => setState(() => _testCapability = c),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
