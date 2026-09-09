import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Recreates ToolIcon.svelte: picks an icon + color by tool name.
class ToolIcon extends StatelessWidget {
  final String name;
  const ToolIcon(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final n = name.toLowerCase();
    IconData icon;
    Color color;
    if (n.contains('sandbox-run') || n.contains('shell') || n.contains('exec')) {
      icon = Icons.terminal;
      color = colors.warning;
    } else if (n.contains('read') || n.contains('write') || n.contains('edit')) {
      icon = n.contains('write')
          ? Icons.edit_outlined
          : Icons.description_outlined;
      color = colors.primary;
    } else if (n.contains('grep') || n.contains('search')) {
      icon = Icons.manage_search;
      color = colors.primary;
    } else if (n.contains('glob') || n.contains('ls') || n.contains('explore')) {
      icon = Icons.folder_open;
      color = colors.primary;
    } else if (n.contains('delete')) {
      icon = Icons.delete_outline;
      color = colors.destructive;
    } else if (n.contains('git') || n.contains('change') || n.contains('diff')) {
      icon = Icons.code;
      color = colors.mutedForeground;
    } else if (n.contains('rebuild') || n.contains('rebase')) {
      icon = Icons.call_merge;
      color = colors.mutedForeground;
    } else if (n.contains('build') || n.contains('image') || n.contains('docker')) {
      icon = Icons.inventory_2_outlined;
      color = colors.accent;
    } else if (n.contains('deploy') || n.contains('release') || n.contains('helm')) {
      icon = Icons.rocket_launch_outlined;
      color = colors.success;
    } else if (n.contains('package') || n.contains('publish') || n.contains('registry')) {
      icon = Icons.all_inbox_outlined;
      color = colors.success;
    } else if (n.contains('pull') || n.contains('download') || n.contains('fetch')) {
      icon = Icons.download_rounded;
      color = colors.accent;
    } else if (n.contains('web') || n.contains('browser') || n.contains('navigate') ||
        n.contains('click') || n.contains('type') || n.contains('snapshot')) {
      icon = Icons.public;
      color = colors.accent;
    } else if (n.contains('todo') || n.contains('job') || n.contains('task')) {
      icon = Icons.checklist;
      color = colors.accent;
    } else if (n.contains('history') || n.contains('memory') || n.contains('file_info')) {
      icon = Icons.history;
      color = colors.accent;
    } else if (n.contains('image_read') || n.contains('image')) {
      icon = Icons.image_outlined;
      color = colors.accent;
    } else {
      icon = Icons.build_outlined;
      color = colors.mutedForeground;
    }
    return Icon(icon, size: 14, color: color);
  }
}

String toolDisplayName(String t) {
  const map = {'todowrite': 'todo'};
  return map[t] ?? t;
}

String fmtOutput(Object? raw) {
  if (raw == null) return '';
  return raw is String ? raw : _pretty(raw);
}

String _pretty(Object o) {
  if (o is Map || o is List) {
    const enc = JsonEncoder.withIndent('  ');
    return enc.convert(o);
  }
  return o.toString();
}
