import 'package:flutter/material.dart';

import '../api.dart';
import '../i18n.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';

/// Tenant-level DEFAULTS applied to every newly created session: the default
/// text model (`provider_id/model_id`) and the default preset. Stored in the
/// agent's per-tenant config KV under `default_model` / `default_preset`; the
/// agent reads them whenever a create omits/blanks those fields.
class DefaultsDetail extends StatefulWidget {
  final AgentBindApi api;
  const DefaultsDetail({super.key, required this.api});

  @override
  State<DefaultsDetail> createState() => _DefaultsDetailState();
}

class _DefaultsDetailState extends State<DefaultsDetail> {
  bool _loading = true;
  String _model = '';
  String _preset = '';
  List<ModelInfo> _allModels = [];
  List<Preset> _presets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Current defaults.
    try {
      _model = await widget.api.config('default_model');
    } catch (_) {}
    try {
      _preset = await widget.api.config('default_preset');
    } catch (_) {}
    // Presets (for the dropdown).
    try {
      _presets = await widget.api.presets();
    } catch (_) {}
    // Text models across all providers.
    final out = <ModelInfo>[];
    try {
      final providers = await widget.api.providers();
      for (final pid in providers.keys) {
        try {
          out.addAll(await widget.api.models(providerId: pid));
        } catch (_) {}
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _allModels = out;
      _loading = false;
    });
  }

  Future<void> _save() async {
    try {
      await widget.api.setConfigKey('default_model', _model);
      await widget.api.setConfigKey('default_preset', _preset);
      if (mounted) showToast(context, context.l10n.saved);
    } catch (e) {
      if (mounted) showErrorToast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    // Dedup refs (a model id can recur across providers with distinct refs;
    // refs are the canonical key, so this is the full set).
    final refs = <String>{
      for (final m in _allModels)
        if (m.providerId.isNotEmpty) '${m.providerId}/${m.id}',
    }.toList()
      ..sort();
    if (_model.isNotEmpty && !refs.contains(_model)) refs.insert(0, _model);
    final presetIds = <String>{
      for (final p in _presets) p.id,
      if (_preset.isNotEmpty) _preset,
    }.toList()
      ..sort();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(context.l10n.defaultsHint,
              style: textOf(context)
                  .micro
                  .copyWith(color: colors.mutedForeground)),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _model.isEmpty ? '' : _model,
            isExpanded: true,
            decoration:
                InputDecoration(labelText: context.l10n.defaultModel),
            items: [
              DropdownMenuItem(value: '', child: Text(context.l10n.none)),
              for (final ref in refs)
                DropdownMenuItem(value: ref, child: Text(ref)),
            ],
            onChanged: (v) => setState(() => _model = v ?? ''),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _preset.isEmpty ? '' : _preset,
            isExpanded: true,
            decoration:
                InputDecoration(labelText: context.l10n.defaultPreset),
            items: [
              DropdownMenuItem(value: '', child: Text(context.l10n.none)),
              for (final id in presetIds)
                DropdownMenuItem(value: id, child: Text(id)),
            ],
            onChanged: (v) => setState(() => _preset = v ?? ''),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: _save,
                child: Text(context.l10n.apply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
