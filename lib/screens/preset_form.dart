import 'package:flutter/material.dart';

import '../api.dart';
import '../i18n.dart';
import '../models.dart';
import '../prefs.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';

/// A full-page editor for a NEW user preset: name it and fill in the system
/// prompt / max turns / tool whitelist up front — one screen, no "create a
/// stub, then expand and edit it" two-step. System presets are immutable and
/// are never created here.
class PresetFormScreen extends StatefulWidget {
  final AppStore store;
  final AgentBindApi api;
  final bool showBack;
  const PresetFormScreen({
    super.key,
    required this.store,
    required this.api,
    this.showBack = true,
  });

  @override
  State<PresetFormScreen> createState() => _PresetFormScreenState();
}

class _PresetFormScreenState extends State<PresetFormScreen> {
  final _id = TextEditingController();
  final _sysPrompt = TextEditingController();
  final _maxTurns = TextEditingController(text: '25');
  final Set<String> _selectedTools = {};
  List<ToolInfo> _tools = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    try {
      final t = await widget.api.tools(
        locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh),
      );
      if (mounted) setState(() => _tools = t);
    } catch (_) {}
  }

  @override
  void dispose() {
    _id.dispose();
    _sysPrompt.dispose();
    _maxTurns.dispose();
    super.dispose();
  }

  bool get _canSave => _id.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    final id = _id.text.trim();
    if (id.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.savePreset(Preset(
        id: id,
        systemPrompt: _sysPrompt.text,
        tools: _selectedTools.toList(),
        maxTurns: int.tryParse(_maxTurns.text.trim()) ?? 25,
      ));
      if (mounted) {
        showToast(context, context.l10n.saved);
        widget.store.popPage();
      }
    } catch (e) {
      if (mounted) showErrorToast(context, '$e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = textOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.store.popPage(),
              )
            : null,
        title: Text(context.l10n.newPreset),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(context.l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _id,
            autofocus: true,
            decoration: InputDecoration(labelText: context.l10n.presetId),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _sysPrompt,
            maxLines: 4,
            decoration: InputDecoration(labelText: context.l10n.systemPrompt),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _maxTurns,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.maxTurns),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${context.l10n.tools} · ${_selectedTools.length}',
            style: text.meta.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in _tools)
                FilterChip(
                  label: Text(t.name, style: text.micro),
                  selected: _selectedTools.contains(t.name),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _selectedTools.add(t.name);
                    } else {
                      _selectedTools.remove(t.name);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(context.l10n.create),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
