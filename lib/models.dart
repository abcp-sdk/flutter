/// Wire models mirroring the gateway aggregate API + zod schemas in
/// gateway-go/web/schema.
library;

import 'dart:convert';

// ---- enums / roles ----

const kSessionRoles = [
  'user',
  'assistant',
  'tool',
  'system',
  'error',
  'compaction',
  'event',
];

const kToolStatuses = ['pending', 'running', 'complete', 'error'];

// ---- session ----

class Session {
  final String id;
  final String org;
  final String repo;
  final String branch;
  /// Canonical model reference "provider_id/model_id".
  final String model;
  /// Selected reasoning variant id (empty = provider defaults).
  final String variant;
  final String preset;
  final String? tipId;
  final int? maxTurns;
  final String? systemPrompt;
  final String? locale;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final int? lastInputTokens;
  final int? lastOutputTokens;
  final String createdAt;
  final String updatedAt;
  final int? unreadCount;
  final String lastMessageAt;
  final String lastMessagePreview;

  /// Monotonic per-session message counter (server-owned). The client derives
  /// the unread count from `messageSeq - readSeq` (read state is local).
  final int messageSeq;

  Session({
    required this.id,
    this.org = '',
    this.repo = '',
    this.branch = '',
    this.model = '',
    this.variant = '',
    this.preset = '',
    this.tipId,
    this.maxTurns,
    this.systemPrompt,
    this.locale,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.lastInputTokens,
    this.lastOutputTokens,
    this.createdAt = '',
    this.updatedAt = '',
    this.unreadCount,
    this.lastMessageAt = '',
    this.lastMessagePreview = '',
    this.messageSeq = 0,
  });

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String? ?? '',
        org: j['org'] as String? ?? '',
        repo: j['repo'] as String? ?? '',
        branch: j['branch'] as String? ?? '',
        model: j['model'] as String? ?? '',
        variant: j['variant'] as String? ?? '',
        preset: j['preset'] as String? ?? '',
        locale: j['locale'] as String?,
        tipId: j['tip_id'] as String?,
        maxTurns: j['max_turns'] as int?,
        systemPrompt: j['system_prompt'] as String?,
        inputTokens: j['input_tokens'] as int?,
        outputTokens: j['output_tokens'] as int?,
        totalTokens: j['total_tokens'] as int?,
        lastInputTokens: j['last_input_tokens'] as int?,
        lastOutputTokens: j['last_output_tokens'] as int?,
        createdAt: j['created_at'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
        unreadCount: j['unread_count'] as int?,
        lastMessageAt: j['last_message_at'] as String? ?? '',
        lastMessagePreview: j['last_message_preview'] as String? ?? '',
        messageSeq: j['message_seq'] as int? ?? 0,
      );

  String get sessionName =>
      org.isNotEmpty ? '$org:$repo:$branch' : id;

  Session copyWith({
    String? model,
    String? variant,
    String? preset,
    int? maxTurns,
    String? systemPrompt,
    int? unreadCount,
    int? messageSeq,
    String? lastMessageAt,
    String? lastMessagePreview,
  }) =>
      Session(
        id: id,
        org: org,
        repo: repo,
        branch: branch,
        model: model ?? this.model,
        variant: variant ?? this.variant,
        preset: preset ?? this.preset,
        tipId: tipId,
        maxTurns: maxTurns ?? this.maxTurns,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
        lastInputTokens: lastInputTokens,
        lastOutputTokens: lastOutputTokens,
        createdAt: createdAt,
        updatedAt: updatedAt,
        unreadCount: unreadCount ?? this.unreadCount,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        messageSeq: messageSeq ?? this.messageSeq,
      );
}

class SessionInfo {
  final String sessionId;
  final String branch;
  final int messageCount;
  final int? unread;
  final String model;
  final String preset;
  final String? locale;

  SessionInfo({
    required this.sessionId,
    required this.branch,
    required this.messageCount,
    this.unread,
    this.model = '',
    this.preset = '',
    this.locale,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> j) => SessionInfo(
        sessionId: j['session_id'] as String? ?? '',
        branch: j['branch'] as String? ?? '',
        messageCount: j['message_count'] as int? ?? 0,
        unread: j['unread'] as int?,
        model: j['model'] as String? ?? '',
        preset: j['preset'] as String? ?? '',
        locale: j['locale'] as String?,
      );
}

// ---- repo tree ----

class BranchNode {
  final String branch;
  final SessionInfo? session;
  BranchNode({required this.branch, this.session});
  factory BranchNode.fromJson(Map<String, dynamic> j) => BranchNode(
        branch: j['branch'] as String? ?? '',
        session: j['session'] == null
            ? null
            : SessionInfo.fromJson(j['session'] as Map<String, dynamic>),
      );
}

class RepoNode {
  final String repo;
  final List<BranchNode> branches;
  RepoNode({required this.repo, required this.branches});
  factory RepoNode.fromJson(Map<String, dynamic> j) => RepoNode(
        repo: j['repo'] as String? ?? '',
        branches: (j['branches'] as List? ?? [])
            .map((e) => BranchNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class OrgNode {
  final String org;
  final List<RepoNode> repos;
  OrgNode({required this.org, required this.repos});
  factory OrgNode.fromJson(Map<String, dynamic> j) => OrgNode(
        org: j['org'] as String? ?? '',
        repos: (j['repos'] as List? ?? [])
            .map((e) => RepoNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ---- message ----

class ToolState {
  final String? status;
  final String? title;
  final String? error;
  final Map<String, dynamic>? input;
  final String? output;
  /// Structured result data (tool `data`), e.g. media tool fixed fields
  /// (`images`/`videos`/`audio` file refs). Opaque to the UI except for the
  /// known media keys rendered by [MediaCard].
  final Map<String, dynamic>? data;
  final String? changeId;
  final String? diff;
  final int? additions;
  final int? deletions;

  ToolState({
    this.status,
    this.title,
    this.error,
    this.input,
    this.output,
    this.data,
    this.changeId,
    this.diff,
    this.additions,
    this.deletions,
  });

  ToolState copyWith({
    String? status,
    String? title,
    String? error,
    Map<String, dynamic>? input,
    String? output,
    Map<String, dynamic>? data,
    String? changeId,
    String? diff,
    int? additions,
    int? deletions,
  }) =>
      ToolState(
        status: status ?? this.status,
        title: title ?? this.title,
        error: error ?? this.error,
        input: input ?? this.input,
        output: output ?? this.output,
        data: data ?? this.data,
        changeId: changeId ?? this.changeId,
        diff: diff ?? this.diff,
        additions: additions ?? this.additions,
        deletions: deletions ?? this.deletions,
      );

  factory ToolState.fromJson(Map<String, dynamic> j) => ToolState(
        status: j['status'] as String?,
        title: j['title'] as String?,
        error: j['error'] as String?,
        input: (j['input'] as Map?)?.cast<String, dynamic>(),
        output: j['output'] as String?,
        data: (j['data'] as Map?)?.cast<String, dynamic>(),
        changeId: j['change_id'] as String?,
        diff: j['diff'] as String?,
        additions: j['additions'] as int?,
        deletions: j['deletions'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status,
        if (title != null) 'title': title,
        if (error != null) 'error': error,
        if (input != null) 'input': input,
        if (output != null) 'output': output,
        if (data != null) 'data': data,
        if (changeId != null) 'change_id': changeId,
        if (diff != null) 'diff': diff,
        if (additions != null) 'additions': additions,
        if (deletions != null) 'deletions': deletions,
      };
}

class MessagePart {
  final String id;
  final String type; // text | reasoning | tool | compaction | file | ...
  final String? text;
  final String? tool;
  final String? toolCallId;
  final ToolState? state;
  final Map<String, dynamic>? metadata;
  // Attachment fields (type == 'file')
  final String? code;
  final String? name;
  final String? mime;
  final int? size;

  MessagePart({
    required this.id,
    required this.type,
    this.text,
    this.tool,
    this.toolCallId,
    this.state,
    this.metadata,
    this.code,
    this.name,
    this.mime,
    this.size,
  });

  factory MessagePart.fromJson(Map<String, dynamic> j) => MessagePart(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? '',
        text: j['text'] as String?,
        tool: j['tool'] as String?,
        toolCallId: j['tool_call_id'] as String?,
        state: j['state'] == null
            ? null
            : ToolState.fromJson(j['state'] as Map<String, dynamic>),
        metadata: (j['metadata'] as Map?)?.cast<String, dynamic>(),
        code: j['code'] as String?,
        name: j['name'] as String?,
        mime: j['mime'] as String?,
        size: j['size'] as int?,
      );

  MessagePart copyWith({
    String? text,
    ToolState? state,
    String? tool,
  }) =>
      MessagePart(
        id: id,
        type: type,
        text: text ?? this.text,
        tool: tool ?? this.tool,
        toolCallId: toolCallId,
        state: state ?? this.state,
        metadata: metadata,
        code: code,
        name: name,
        mime: mime,
        size: size,
      );
}

class Message {
  final String id;
  final String role;
  final List<MessagePart> parts;
  final String? createdAt;

  Message({
    required this.id,
    required this.role,
    required this.parts,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String? ?? '',
        role: j['role'] as String? ?? '',
        parts: (j['parts'] as List? ?? [])
            .map((e) => MessagePart.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: j['created_at'] as String?,
      );
}

// ---- attachment upload / download ----

/// A file the user picked to attach to a message, before upload.
class UploadedFileSource {
  final String path;
  final String name;
  final String mimeType;
  UploadedFileSource({
    required this.path,
    required this.name,
    required this.mimeType,
  });
}

/// The server-side record for an uploaded file. The [code] is the 8-char
/// content hash-based object key; the model refers to it as `file:<code>`.
/// Also mirrors a LOCAL pending attachment (uploading/error) before the code
/// exists — [localPath] lets an image show its thumbnail while uploading.
class UploadedFile {
  final String code;
  final String? name;
  final String? mime;
  final int? size;
  final String? sha256;
  final bool deduped;
  final String localPath;
  final String uploadState; // 'idle' | 'uploading' | 'done' | 'error'
  final String? error;
  UploadedFile({
    required this.code,
    this.name,
    this.mime,
    this.size,
    this.sha256,
    this.deduped = false,
    this.localPath = '',
    this.uploadState = 'done',
    this.error,
  });

  UploadedFile uploading(String srcPath) => UploadedFile(
      code: code,
      name: name,
      mime: mime,
      size: size,
      sha256: sha256,
      deduped: deduped,
      localPath: srcPath,
      uploadState: 'uploading');

  UploadedFile uploadError(String msg) => UploadedFile(
      code: code,
      name: name,
      mime: mime,
      size: size,
      sha256: sha256,
      deduped: deduped,
      localPath: localPath,
      uploadState: 'error',
      error: msg);

  bool get isUploading => uploadState == 'uploading';
  bool get hasError => uploadState == 'error';
  bool get isLocal => code.isEmpty;

  factory UploadedFile.fromJson(Map<String, dynamic> j) => UploadedFile(
        code: j['code'] as String? ?? '',
        name: j['name'] as String?,
        mime: j['mime'] as String?,
        size: (j['size'] as num?)?.toInt(),
        sha256: j['hash'] as String?,
        deduped: j['deduped'] as bool? ?? false,
      );

  /// The file code the client sends to the platform, which splices it into a
  /// `[附件 …file:<code>…]` reference. The client never renders the text.
}

// ---- chat domain (streaming state) ----

class ChatPart {
  final String id;
  final String type;
  final String text;
  final String tool;
  final ToolState? state;
  // Attachment fields (type == 'file')
  final String? code;
  final String? name;
  final String? mime;
  final int? size;

  ChatPart({
    required this.id,
    required this.type,
    this.text = '',
    this.tool = '',
    this.state,
    this.code,
    this.name,
    this.mime,
    this.size,
  });

  ChatPart copyWith({String? text, ToolState? state, String? type, String? tool}) =>
      ChatPart(
        id: id,
        type: type ?? this.type,
        text: text ?? this.text,
        tool: tool ?? this.tool,
        state: state ?? this.state,
        code: code,
        name: name,
        mime: mime,
        size: size,
      );
}

class ChatMessage {
  final String id;
  final String role;
  final String status; // pending | streaming | complete | error
  final List<ChatPart> parts;
  final String createdAt;
  final int? seq;

  ChatMessage({
    required this.id,
    required this.role,
    required this.status,
    required this.parts,
    this.createdAt = '',
    this.seq,
  });

  ChatMessage copyWith({String? id, String? status, List<ChatPart>? parts}) =>
      ChatMessage(
        id: id ?? this.id,
        role: role,
        status: status ?? this.status,
        parts: parts ?? this.parts,
        createdAt: createdAt,
        seq: seq,
      );
}

// ---- other ----

class MailboxEntry {
  final String id;
  final String msgType;
  final String payload;
  final String? effectiveAt;
  final String status;
  final String createdAt;
  final String? consumedAt;
  MailboxEntry({
    required this.id,
    required this.msgType,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.effectiveAt,
    this.consumedAt,
  });
  factory MailboxEntry.fromJson(Map<String, dynamic> j) => MailboxEntry(
        id: j['id'] as String? ?? '',
        msgType: j['msg_type'] as String? ?? '',
        payload: j['payload'] as String? ?? '',
        effectiveAt: j['effective_at'] as String?,
        status: j['status'] as String? ?? '',
        createdAt: j['created_at'] as String? ?? '',
        consumedAt: j['consumed_at'] as String?,
      );
}

class ChangeEntry {
  final String changeId;
  final String commitId;
  final String author;
  final String timestamp;
  final String message;
  ChangeEntry({
    required this.changeId,
    required this.commitId,
    required this.author,
    required this.timestamp,
    required this.message,
  });
  factory ChangeEntry.fromJson(Map<String, dynamic> j) => ChangeEntry(
        changeId: j['change_id'] as String? ?? '',
        commitId: j['commit_id'] as String? ?? '',
        author: j['author'] as String? ?? '',
        timestamp: j['timestamp'] as String? ?? '',
        message: j['message'] as String? ?? '',
      );
}

class FileEntry {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  FileEntry({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
  });
  factory FileEntry.fromJson(Map<String, dynamic> j) => FileEntry(
        name: j['name'] as String? ?? '',
        path: j['path'] as String? ?? '',
        isDir: j['is_dir'] as bool? ?? false,
        size: j['size'] as int? ?? 0,
      );
}

class DiffFile {
  final String path;
  final String? diffText;
  DiffFile({required this.path, this.diffText});
  factory DiffFile.fromJson(Map<String, dynamic> j) => DiffFile(
        path: j['path'] as String? ?? '',
        diffText: j['diff_text'] as String?,
      );
}

class FileCommit {
  final String changeId;
  final String commitId;
  final String author;
  final String timestamp;
  final String message;
  FileCommit({
    required this.changeId,
    required this.commitId,
    required this.author,
    required this.timestamp,
    required this.message,
  });
  factory FileCommit.fromJson(Map<String, dynamic> j) => FileCommit(
        changeId: j['change_id'] as String? ?? '',
        commitId: j['sha'] as String? ?? j['commit_id'] as String? ?? '',
        author: j['author'] as String? ?? '',
        timestamp: j['timestamp'] as String? ?? '',
        message: j['description'] as String? ?? j['message'] as String? ?? '',
      );
}

/// Parse a `{locale: text}` map (from JSON) into a String->String map.
Map<String, String> _mapStringString(dynamic v) {
  if (v is Map) {
    return v.map((k, val) => MapEntry('$k', '$val'));
  }
  // system_prompt_i18n may arrive as a JSON string.
  if (v is String && v.isNotEmpty && v != '{}') {
    try {
      final m = jsonDecode(v);
      if (m is Map) {
        return m.map((k, val) => MapEntry('$k', '$val'));
      }
    } catch (_) {}
  }
  return const {};
}

class Preset {
  final String id;
  final String systemPrompt;
  final Map<String, String> systemPromptI18n;
  final List<String> tools;
  final int maxTurns;
  final bool isSystem;
  Preset({
    required this.id,
    required this.systemPrompt,
    this.systemPromptI18n = const {},
    required this.tools,
    required this.maxTurns,
    this.isSystem = false,
  });
  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
        id: j['id'] as String? ?? '',
        systemPrompt: j['system_prompt'] as String? ?? '',
        systemPromptI18n: _mapStringString(j['system_prompt_i18n']),
        tools: (j['tools'] as List? ?? []).map((e) => e.toString()).toList(),
        maxTurns: j['max_turns'] as int? ?? 30,
        isSystem: j['is_system'] as bool? ?? false,
      );
  /// The system prompt localized for [locale] ('zh'/'en'), falling back to the
  /// default prompt when the locale has no translation.
  String localizedPrompt(String locale) {
    if (systemPromptI18n.containsKey(locale)) return systemPromptI18n[locale]!;
    return systemPrompt;
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'system_prompt': systemPrompt,
        'tools': tools,
        'max_turns': maxTurns,
      };
}

class ToolConfigField {
  final String key;
  final String label;
  final String type; // select-provider | select-model | text | number
  final String placeholder;
  final String? dependsOnProvider;
  ToolConfigField({
    required this.key,
    required this.label,
    required this.type,
    this.placeholder = '',
    this.dependsOnProvider,
  });
  factory ToolConfigField.fromJson(Map<String, dynamic> j) => ToolConfigField(
        key: j['key'] as String? ?? '',
        label: j['label'] as String? ?? '',
        type: j['type'] as String? ?? '',
        placeholder: j['placeholder'] as String? ?? '',
        dependsOnProvider: j['dependsOnProvider'] as String?,
      );
}

class ToolInfo {
  final String name;
  final String description;
  final String category;
  final Map<String, dynamic>? parameters;
  final List<ToolConfigField>? configFields;
  final List<ToolConfig>? config;
  final List<String> requiredConfig;
  ToolInfo({
    required this.name,
    required this.description,
    required this.category,
    this.parameters,
    this.configFields,
    this.config,
    this.requiredConfig = const [],
  });
  factory ToolInfo.fromJson(Map<String, dynamic> j) => ToolInfo(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        category: j['category'] as String? ?? '',
        parameters: (j['parameters'] as Map?)?.cast<String, dynamic>(),
        configFields: (j['configFields'] as List? ?? [])
            .map((e) => ToolConfigField.fromJson(e as Map<String, dynamic>))
            .toList(),
        config: (j['config'] as List? ?? [])
            .map((e) => ToolConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
        requiredConfig: (j['required_config'] as List? ?? [])
            .map((e) => '$e')
            .toList(),
      );

  /// Parsed parameter tree (properties + nested array/object items),
  /// honoring the required list. Empty when parameters is missing/empty.
  List<ToolParam> get params => ToolParam.parseSchema(parameters);
}

/// A declared extension config knob (from the tool's owning extension config).
class ToolConfig {
  final String name;
  final String type; // string | number | boolean | enum | json
  final List<String> enumValues;
  final dynamic defaultValue;
  final String description;
  final String scope; // global | session
  ToolConfig({
    required this.name,
    required this.type,
    this.enumValues = const [],
    this.defaultValue,
    this.description = '',
    this.scope = 'global',
  });
  factory ToolConfig.fromJson(Map<String, dynamic> j) => ToolConfig(
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? 'string',
        enumValues: (j['enum_values'] as List? ?? []).map((e) => '$e').toList(),
        defaultValue: j['default'],
        description: j['description'] as String? ?? '',
        scope: j['scope'] as String? ?? 'global',
      );
}

/// A single tool input parameter (recursively nests array/object items).
class ToolParam {
  final String name;
  final String type;
  final String description;
  final bool required;
  final List<String>? enumValues;
  final List<ToolParam> children;
  final String? defaultValue;
  ToolParam({
    required this.name,
    required this.type,
    this.description = '',
    this.required = false,
    this.enumValues,
    this.children = const [],
    this.defaultValue,
  });

  /// Parse `parameters` JSON-Schema into a flat/recursive param list.
  static List<ToolParam> parseSchema(Map<String, dynamic>? schema) {
    if (schema == null) return const [];
    final out = <ToolParam>[];
    final properties = schema['properties'];
    if (properties is! Map) return out;
    final requiredList = (schema['required'] as List?)?.map((e) => '$e').toSet() ??
        const <String>{};
    properties.forEach((key, value) {
      if (value is! Map) return;
      final v = value.cast<String, dynamic>();
      final type = (v['type'] as String?) ?? 'object';
      final children = <ToolParam>[];
      // array items object/array
      final items = v['items'];
      if (items is Map) {
        final im = items.cast<String, dynamic>();
        if ((im['type'] as String?) == 'array' ||
            (im['properties'] as Map?)?.isNotEmpty == true) {
          children.addAll(parseSchema({
            'type': 'object',
            'properties': im['properties'],
            'required': im['required'],
          }));
        }
      } else if (type == 'object' && v['properties'] is Map) {
        children.addAll(parseSchema(v));
      }
      out.add(ToolParam(
        name: '$key',
        type: type,
        description: (v['description'] as String?) ?? '',
        required: requiredList.contains('$key'),
        enumValues: v['enum'] is List ? (v['enum'] as List).map((e) => '$e').toList() : null,
        defaultValue: v['default'] == null ? null : '${v['default']}',
        children: children,
      ));
    });
    return out;
  }
}

class ProviderModel {
  final String id;
  final String name;
  /// Model context window (tokens). REQUIRED for text models (drives
  /// compaction budgets); generation models (image/video/speech) omit it.
  final int? contextLimit;
  /// What the model generates: text (default) | image | video | speech.
  final String capability;
  ProviderModel({
    required this.id,
    required this.name,
    this.contextLimit,
    this.capability = 'text',
  });
  factory ProviderModel.fromJson(Map<String, dynamic> j) => ProviderModel(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        contextLimit: j['context_limit'] as int?,
        capability: j['capability'] as String? ?? 'text',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (contextLimit != null) 'context_limit': contextLimit,
        if (capability != 'text') 'capability': capability,
      };
}

class ProviderInfo {
  final String providerId;
  final String apiType;
  final String baseUrl;
  final String apiKey;
  final Map<String, String>? headers;
  final List<ProviderModel> models;
  ProviderInfo({
    required this.providerId,
    required this.apiType,
    required this.baseUrl,
    required this.apiKey,
    this.headers,
    required this.models,
  });
  factory ProviderInfo.fromJson(Map<String, dynamic> j) => ProviderInfo(
        providerId: j['provider_id'] as String? ?? '',
        apiType: j['api_type'] as String? ?? '',
        baseUrl: j['base_url'] as String? ?? '',
        apiKey: j['api_key'] as String? ?? '',
        headers: (j['headers'] as Map?)?.cast<String, String>(),
        models: (j['models'] as List? ?? [])
            .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'provider_id': providerId,
        'api_type': apiType,
        'base_url': baseUrl,
        'api_key': apiKey,
        if (headers != null) 'headers': headers,
        'models': models.map((m) => m.toJson()).toList(),
      };
}

class ModelVariantInfo {
  final String id;
  final String name;
  final String description;
  ModelVariantInfo({
    required this.id,
    this.name = '',
    this.description = '',
  });
  factory ModelVariantInfo.fromJson(Map<String, dynamic> j) => ModelVariantInfo(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );
}

class ModelInfo {
  final String id;
  final String name;
  final String providerId;
  final int? contextLimit;
  final bool reasoning;
  final bool toolCall;
  /// Selectable reasoning variants (models.dev catalog).
  final List<ModelVariantInfo> variants;
  ModelInfo({
    required this.id,
    required this.name,
    this.providerId = '',
    this.contextLimit,
    this.reasoning = false,
    this.toolCall = false,
    this.variants = const [],
  });
  factory ModelInfo.fromJson(Map<String, dynamic> j) => ModelInfo(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        providerId: j['provider_id'] as String? ?? '',
        contextLimit: j['context_limit'] as int?,
        reasoning: j['reasoning'] as bool? ?? false,
        toolCall: j['tool_call'] as bool? ?? false,
        variants: (j['variants'] as List? ?? [])
            .map((e) =>
                ModelVariantInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ---- container / ops ----

class Sandbox {
  final String containerId;
  final String session;
  final String podName;
  final String status;
  final String workerUrl;
  final String podIp;
  final String syncedRev;
  Sandbox({
    required this.containerId,
    required this.session,
    required this.podName,
    required this.status,
    required this.workerUrl,
    required this.podIp,
    required this.syncedRev,
  });
  factory Sandbox.fromJson(Map<String, dynamic> j) => Sandbox(
        containerId: j['container_id'] as String? ?? '',
        session: j['session'] as String? ?? '',
        podName: j['pod_name'] as String? ?? '',
        status: j['status'] as String? ?? '',
        workerUrl: j['worker_url'] as String? ?? '',
        podIp: j['pod_ip'] as String? ?? '',
        syncedRev: j['synced_rev'] as String? ?? '',
      );
}

class Deployment {
  final String name;
  final String image;
  final int replicas;
  final int ready;
  final String namespace;
  final String age;
  final List<int> ports;
  final String? session;
  Deployment({
    required this.name,
    required this.image,
    required this.replicas,
    required this.ready,
    required this.namespace,
    required this.age,
    required this.ports,
    this.session,
  });
  factory Deployment.fromJson(Map<String, dynamic> j) => Deployment(
        name: j['name'] as String? ?? '',
        image: j['image'] as String? ?? '',
        replicas: j['replicas'] as int? ?? 0,
        ready: j['ready'] as int? ?? 0,
        namespace: j['namespace'] as String? ?? '',
        age: j['age'] as String? ?? '',
        ports: (j['ports'] as List? ?? []).map((e) => e as int).toList(),
        session: j['session'] as String?,
      );
}

class DeploymentPod {
  final String name;
  final String ip;
  final String phase;
  final bool ready;
  final String image;
  final String age;
  final int restarts;
  DeploymentPod({
    required this.name,
    required this.ip,
    required this.phase,
    required this.ready,
    required this.image,
    required this.age,
    required this.restarts,
  });
  factory DeploymentPod.fromJson(Map<String, dynamic> j) => DeploymentPod(
        name: j['name'] as String? ?? '',
        ip: j['ip'] as String? ?? '',
        phase: j['phase'] as String? ?? '',
        ready: j['ready'] as bool? ?? false,
        image: j['image'] as String? ?? '',
        age: j['age'] as String? ?? '',
        restarts: j['restarts'] as int? ?? 0,
      );
}

class DeploymentEvent {
  final String type;
  final String reason;
  final String message;
  final String age;
  DeploymentEvent({
    this.type = '',
    this.reason = '',
    this.message = '',
    this.age = '',
  });
  factory DeploymentEvent.fromJson(Map<String, dynamic> j) => DeploymentEvent(
        type: j['type'] as String? ?? '',
        reason: j['reason'] as String? ?? '',
        message: j['message'] as String? ?? '',
        age: j['age'] as String? ?? '',
      );
}

class ContainerfileTemplate {
  final String name;
  final String content;
  ContainerfileTemplate({required this.name, required this.content});
  factory ContainerfileTemplate.fromJson(Map<String, dynamic> j) =>
      ContainerfileTemplate(
        name: j['name'] as String? ?? '',
        content: j['content'] as String? ?? '',
      );
}

class JobInfo {
  final String id;
  final String command;
  final String state;
  final int exitCode;
  final int? startedAt;
  final int? finishedAt;
  final String? stdout;
  JobInfo({
    required this.id,
    required this.command,
    required this.state,
    required this.exitCode,
    this.startedAt,
    this.finishedAt,
    this.stdout,
  });
  factory JobInfo.fromJson(Map<String, dynamic> j) => JobInfo(
        id: j['id'] as String? ?? '',
        command: j['command'] as String? ?? '',
        state: j['state'] as String? ?? '',
        exitCode: j['exit_code'] as int? ?? 0,
        startedAt: j['started_at'] as int?,
        finishedAt: j['finished_at'] as int?,
        stdout: j['stdout'] as String?,
      );
}

class ExecResult {
  final int? exitCode;
  final String? output;
  final String? jobId;
  final bool backgrounded;
  final String? note;
  final String? error;
  ExecResult({
    this.exitCode,
    this.output,
    this.jobId,
    this.backgrounded = false,
    this.note,
    this.error,
  });
  factory ExecResult.fromJson(Map<String, dynamic> j) => ExecResult(
        exitCode: j['exit_code'] as int?,
        output: j['output'] as String?,
        jobId: j['job_id'] as String?,
        backgrounded: j['backgrounded'] as bool? ?? false,
        note: j['note'] as String?,
        error: j['error'] as String?,
      );
}

class PublishSpec {
  final String protocol;
  final List<String> args;
  final List<String> required;
  PublishSpec({
    required this.protocol,
    required this.args,
    required this.required,
  });
  factory PublishSpec.fromJson(Map<String, dynamic> j) => PublishSpec(
        protocol: j['protocol'] as String? ?? '',
        args: (j['args'] as List? ?? []).map((e) => e.toString()).toList(),
        required:
            (j['required'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class OpsStatus {
  final bool ok;
  final String version;
  final int sandboxes;
  OpsStatus({required this.ok, required this.version, required this.sandboxes});
  factory OpsStatus.fromJson(Map<String, dynamic> j) => OpsStatus(
        ok: j['ok'] as bool? ?? false,
        version: j['version'] as String? ?? '',
        sandboxes: j['sandboxes'] as int? ?? 0,
      );
}

// ---- packages ----

class PackageTypeEntry {
  final String type;
  final String upstream;
  final int packages;
  PackageTypeEntry(
      {required this.type, required this.upstream, this.packages = 0});
  factory PackageTypeEntry.fromJson(Map<String, dynamic> j) =>
      PackageTypeEntry(
        type: j['type'] as String? ?? '',
        upstream: j['upstream'] as String? ?? '',
        packages: j['packages'] as int? ?? 0,
      );
}

class UnifiedPackageEntry {
  final String name;
  final String type;
  final String? latestVersion;
  final int versions;
  UnifiedPackageEntry({
    required this.name,
    required this.type,
    this.latestVersion,
    required this.versions,
  });
  factory UnifiedPackageEntry.fromJson(Map<String, dynamic> j) =>
      UnifiedPackageEntry(
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? '',
        latestVersion: j['latest_version'] as String?,
        versions: j['versions'] as int? ?? 0,
      );
}

class PackageVersionFile {
  final String name;
  final int size;
  final String sha256;
  PackageVersionFile({
    required this.name,
    required this.size,
    required this.sha256,
  });
  factory PackageVersionFile.fromJson(Map<String, dynamic> j) =>
      PackageVersionFile(
        name: j['name'] as String? ?? '',
        size: j['size'] as int? ?? 0,
        sha256: j['sha256'] as String? ?? '',
      );
}

class PackageVersion {
  final String version;
  final int downloadCount;
  final int createdUnix;
  final List<PackageVersionFile> files;
  PackageVersion({
    required this.version,
    required this.downloadCount,
    required this.createdUnix,
    required this.files,
  });
  factory PackageVersion.fromJson(Map<String, dynamic> j) => PackageVersion(
        version: j['version'] as String? ?? '',
        downloadCount: j['download_count'] as int? ?? 0,
        createdUnix: j['created_unix'] as int? ?? 0,
        files: (j['files'] as List? ?? [])
            .map((e) => PackageVersionFile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GitCommit {
  final String changeId;
  final String commitId;
  final String author;
  final String timestamp;
  final String message;
  GitCommit({
    required this.changeId,
    required this.commitId,
    required this.author,
    required this.timestamp,
    required this.message,
  });
  factory GitCommit.fromJson(Map<String, dynamic> j) => GitCommit(
        changeId: j['change_id'] as String? ?? '',
        commitId: j['commit_id'] as String? ?? '',
        author: j['author'] as String? ?? '',
        timestamp: j['timestamp'] as String? ?? '',
        message: j['message'] as String? ?? '',
      );
}

class GitTag {
  final String name;
  final String target;
  GitTag({required this.name, required this.target});
  factory GitTag.fromJson(Map<String, dynamic> j) => GitTag(
        name: j['name'] as String? ?? '',
        target: j['target'] as String? ?? '',
      );
}

class RepoMirror {
  final String org;
  final String repo;
  final String mirrorUrl;
  final bool hasSecret;
  RepoMirror({
    required this.org,
    required this.repo,
    required this.mirrorUrl,
    required this.hasSecret,
  });
  factory RepoMirror.fromJson(Map<String, dynamic> j) => RepoMirror(
        org: j['org'] as String? ?? '',
        repo: j['repo'] as String? ?? '',
        mirrorUrl: j['mirror_url'] as String? ?? '',
        hasSecret: j['has_secret'] as bool? ?? false,
      );
}

/// Stored per-repo mirror config (urls + whether a push secret is set; the
/// secret itself never leaves the platform).
class MirrorCfg {
  final String pullUrl;
  final String pushUrl;
  final bool pushSecretSet;
  MirrorCfg({
    this.pullUrl = '',
    this.pushUrl = '',
    this.pushSecretSet = false,
  });
}
/// jj-lab branch (GET /repos/{org}/{repo}/branches).
class BranchInfo {
  final String name;
  final String sha;
  BranchInfo({required this.name, required this.sha});
  factory BranchInfo.fromJson(Map<String, dynamic> j) => BranchInfo(
        name: j['name'] as String? ?? '',
        sha: j['sha'] as String? ?? '',
      );
}

/// A release asset (jj-lab releases.rs): name/size/digest/content_type.
class ReleaseAsset {
  final String name;
  final int size;
  final String digest;
  final String contentType;
  ReleaseAsset({
    required this.name,
    required this.size,
    required this.digest,
    required this.contentType,
  });
  factory ReleaseAsset.fromJson(Map<String, dynamic> j) => ReleaseAsset(
        name: j['name'] as String? ?? '',
        size: (j['size'] as num?)?.toInt() ?? 0,
        digest: j['digest'] as String? ?? '',
        contentType: j['content_type'] as String? ?? '',
      );
}

/// jj-lab release (GET /repos/{org}/{repo}/releases).
class Release {
  final String tagName;
  final String name;
  final String body;
  final bool draft;
  final bool prerelease;
  final List<ReleaseAsset> assets;
  Release({
    required this.tagName,
    required this.name,
    required this.body,
    required this.draft,
    required this.prerelease,
    required this.assets,
  });
  factory Release.fromJson(Map<String, dynamic> j) => Release(
        tagName: j['tag_name'] as String? ?? '',
        name: j['name'] as String? ?? '',
        body: j['body'] as String? ?? '',
        draft: j['draft'] as bool? ?? false,
        prerelease: j['prerelease'] as bool? ?? false,
        assets: ((j['assets'] as List?) ?? [])
            .map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
