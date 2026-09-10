import 'dart:async';
import 'dart:io' as io;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:agent_client_sdk/agent_client_sdk.dart' as sdk;
import 'package:connectrpc/protobuf.dart';
import 'package:connectrpc/protocol/connect.dart' as protocol;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart' as wkt;

import 'models.dart';
import 'transport.dart';

/// Parsed watch/prompt stream event.
class StreamEvent {
  final String event;
  final Map<String, dynamic> params;
  StreamEvent(this.event, Map<String, dynamic>? params)
      : params = params ?? const {};
  dynamic get(String key) => params[key];
  String str(String key) => params[key] as String? ?? '';
}

/// CA certificate (PEM) used on native HTTP/2-TLS. Ignored on web.
class AgentTls {
  const AgentTls({this.caPem});
  final String? caPem;
}

/// Thin client over a standalone abc agent: the typed agent.v1 client over
/// HTTP/2-TLS (self-signed CA). Talks directly to agent.v1.AgentService — no
/// gateway, no lab/ops/registry.
class AgentBindApi {
  final String baseUrl;
  final String token;

  // Strong-typed Connect client (h2 over TLS), direct to the agent. The
  // transport is built here (caller owns it); the SDK ships only the generated
  // client + messages, no transport primitive.
  late final sdk.AgentServiceClient _agent;

  AgentBindApi({required this.baseUrl, required this.token})
      : _agent = _buildAgent(baseUrl, token);

  static AgentTls? _tls;
  static Future<void> _loadCa() async {
    if (_tls != null) return;
    try {
      final data = await rootBundle.load('assets/certs/ca.crt');
      _tls = AgentTls(
          caPem: utf8.decode(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
    } catch (_) {
      _tls = null;
    }
  }

  /// Build the connect Transport for a base URL + bearer token + CA.
  static sdk.AgentServiceClient _buildAgent(String baseUrl, String token) {
    final trimmed =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final transport = protocol.Transport(
      baseUrl: trimmed,
      codec: const ProtoCodec(),
      httpClient: buildAgentHttpClient(caPem: _tls?.caPem),
      interceptors: [
        if (token.isNotEmpty) agentBearerInterceptor(token),
      ],
    );
    return sdk.AgentServiceClient(transport);
  }

  static Future<AgentBindApi> create(
      {required String baseUrl, required String token}) async {
    await _loadCa();
    return AgentBindApi(baseUrl: baseUrl, token: token);
  }

  // ---- sessions ----

  Future<List<Session>> listSessions() async {
    final r = await _agent.listSessions(sdk.ListSessionsRequest());
    return r.sessions.map(sessionFromPb).toList();
  }

  Future<Session> createSession(Map<String, dynamic> params) async {
    final r = await _agent.createSession(sdk.CreateSessionRequest(
      name: (params['name'] as String?) ?? '',
      model: (params['model'] as String?) ?? '',
      variant: (params['variant'] as String?) ?? '',
      preset: (params['preset'] as String?) ?? '',
      org: (params['org'] as String?) ?? '',
      repo: (params['repo'] as String?) ?? '',
      branch: (params['branch'] as String?) ?? '',
    ));
    return Session(
      id: r.sessionName,
      model: (params['model'] as String?) ?? '',
      variant: (params['variant'] as String?) ?? '',
      org: (params['org'] as String?) ?? '',
      repo: (params['repo'] as String?) ?? '',
      branch: (params['branch'] as String?) ?? '',
    );
  }

  Future<Session> getSession(String id) async {
    final r = await _agent.getSession(sdk.GetSessionRequest(id: id));
    return _sessionFromSessionResults(r.session);
  }

  Future<void> deleteSession(String id) =>
      _agent.deleteSession(sdk.DeleteSessionRequest(id: id));

  Future<String> prompt(String id, String prompt,
      {List<String>? attachments}) async {
    await for (final e
        in _agent.prompt(sdk.PromptRequest(id: id, prompt: prompt))) {
      if (e.event == 'accepted') return e.params['message_id'] ?? '';
    }
    return '';
  }

  // ---- attachment upload/download (agent.v1 file) ----

  Future<UploadedFile> uploadFile(UploadedFileSource src) async {
    final bytes = await io.File(src.path).readAsBytes();
    final r = await _agent.ingestFile(sdk.IngestFileRequest(
      data: bytes,
      name: src.name,
      mime: src.mimeType,
    ));
    return UploadedFile(
      code: r.code,
      name: src.name,
      mime: src.mimeType,
      size: bytes.length,
      deduped: false,
    );
  }

  Future<List<int>> fetchFileBytes(String code) async {
    final r = await _agent.getFile(sdk.GetFileRequest(code: code));
    return r.data;
  }

  Future<({String? contentType, int length})> fileHead(String code) async {
    final r = await _agent.getFileMeta(sdk.GetFileMetaRequest(code: code));
    return (contentType: r.mime, length: r.size);
  }

  Future<(List<Message>, bool)> messages(String id,
      {String? before, int limit = 30}) async {
    final r = await _agent.listMessages(sdk.ListMessagesRequest(
        id: id, limit: limit, before: before ?? ''));
    final msgs = r.messages.map(messageFromPb).toList();
    return (msgs, msgs.length >= limit);
  }

  Future<String> switchModel(String id, String model,
      {String variant = ''}) async {
    await _agent.setModel(
        sdk.SetModelRequest(id: id, model: model, variant: variant));
    return model;
  }

  Future<Session> settings(String id, Map<String, dynamic> settings) async {
    final r = await _agent.updateSettings(sdk.UpdateSettingsRequest(
      id: id,
      model: (settings['model'] as String?) ?? '',
      preset: (settings['preset'] as String?) ?? '',
      maxTurns: (settings['max_turns'] as int?) ?? 0,
      systemPrompt: (settings['system_prompt'] as String?) ?? '',
      locale: (settings['locale'] as String?) ?? '',
      variant: (settings['variant'] as String?) ?? '',
    ));
    return _sessionFromSessionResults(r.session);
  }

  Future<Session> fork(String id, String branch) async {
    final r = await _agent.fork(sdk.ForkRequest(id: id, name: branch));
    return _sessionFromSessionResults(r.session);
  }

  Future<void> revert(String id, String? messageId) async {
    await _agent.undo(sdk.UndoRequest(id: id, messageId: messageId ?? ''));
  }

  Future<bool> interrupt(String id) async {
    final r = await _agent.interrupt(sdk.InterruptRequest(id: id));
    return r.ok;
  }

  Future<bool> compact(String id) async {
    final r = await _agent.compact(sdk.CompactRequest(id: id));
    return r.ok;
  }

  Future<void> markRead(String id) async {
    await _agent.undo(sdk.UndoRequest(id: id));
  }

  Future<(String, List<dynamic>)> state(String id) async {
    final r = await _agent.state(sdk.StateRequest(id: id));
    final st = StructUtils.toJson(r.state);
    return ((st['status'] as String?) ?? 'idle', (st['parts'] as List?) ?? []);
  }

  Future<List<MailboxEntry>> mailbox(String id) async {
    final r = await _agent.mailbox(sdk.MailboxRequest(id: id));
    return r.mailbox.map((m) => MailboxEntry(
          id: m.id,
          msgType: m.msgType,
          payload: m.payload,
          effectiveAt: m.effectiveAt.isEmpty ? null : m.effectiveAt,
          status: m.status,
          createdAt: m.createdAt,
          consumedAt: m.consumedAt.isEmpty ? null : m.consumedAt,
        )).toList();
  }

  // ---- stream ----

  Stream<StreamEvent> streamEvents(String sessionId) {
    final sdkStream =
        _agent.watchSession(sdk.WatchSessionRequest(id: sessionId));
    return sdkStream.map((e) => StreamEvent(
        e.event,
        StructUtils.toJson(e.params)));
  }

  // ---- config / providers / models / presets / tools ----

  Future<void> setToolConfigValue(
          String extId, String name, Object? value) async {
    await _agent.setExtensionConfig(sdk.SetExtensionConfigRequest(
      extId: extId,
      name: name,
      value: wkt.Value(stringValue: '$value'),
    ));
  }

  Future<Map<String, ProviderInfo>> providers() async {
    final r = await _agent.listProviders(sdk.ListProvidersRequest());
    final out = <String, ProviderInfo>{};
    for (final p in r.providers) {
      out[p.providerId] = ProviderInfo(
        providerId: p.providerId,
        apiType: p.apiType,
        baseUrl: p.baseUrl,
        apiKey: p.apiKey,
        headers: p.headers.map((k, v) => MapEntry(k, v)),
        models: p.models.map((id) => ProviderModel(id: id, name: id)).toList(),
      );
    }
    return out;
  }

  Future<void> registerProvider(ProviderInfo p) async {
    await _agent.registerProvider(sdk.RegisterProviderRequest(
      provider: sdk.Provider(
        providerId: p.providerId,
        apiType: p.apiType,
        baseUrl: p.baseUrl,
        apiKey: p.apiKey,
        headers: p.headers?.entries,
        models: p.models.map((m) => m.id),
      ),
    ));
  }

  Future<void> deleteProvider(String pid) =>
      _agent.deleteProvider(sdk.DeleteProviderRequest(providerId: pid));

  Future<Map<String, dynamic>> testProvider(
          {required String apiType,
          required String baseUrl,
          required String apiKey,
          String? model}) async {
    final r = await _agent.testProvider(sdk.TestProviderRequest(
      providerId: '',
      apiType: apiType,
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model ?? '',
    ));
    return {'ok': r.ok, 'result': r.result};
  }

  /// List the models of ONE provider. [providerId] is required (the agent
  /// rejects a global list, which would duplicate ids across providers).
  Future<List<ModelInfo>> models({required String providerId}) async {
    if (providerId.isEmpty) return const [];
    final r = await _agent
        .listModels(sdk.ListModelsRequest(providerId: providerId));
    return r.models
        .map((m) => ModelInfo(
              id: m.id,
              name: m.name,
              providerId: providerId,
              variants: m.variants
                  .map((v) => ModelVariantInfo(
                      id: v.id, name: v.name, description: v.description))
                  .toList(),
            ))
        .toList();
  }

  Future<List<Preset>> presets({String? locale}) async {
    final r = await _agent
        .listPresets(sdk.ListPresetsRequest(locale: locale ?? ''));
    return r.presets.map((p) => Preset(
          id: p.id,
          systemPrompt: p.systemPrompt,
          tools: p.tools,
          maxTurns: p.maxTurns,
          isSystem: p.isSystem,
        )).toList();
  }

  Future<void> savePreset(Preset p) =>
      _agent.upsertPreset(sdk.UpsertPresetRequest(
          preset: sdk.Preset(
        id: p.id,
        systemPrompt: p.systemPrompt,
        tools: p.tools,
        maxTurns: p.maxTurns,
      )));

  Future<void> deletePreset(String id) =>
      _agent.deletePreset(sdk.DeletePresetRequest(id: id));

  Future<List<ToolInfo>> tools({String? locale}) async {
    final r = await _agent.listTools(
        sdk.ListToolsRequest(locale: locale ?? ''));
    return r.tools.map((t) => ToolInfo(
          name: t.name,
          description: t.description,
          category: t.category,
          parameters: StructUtils.toJson(t.parameters),
          configFields: t.configFields.map((c) => ToolConfigField(
                key: c.name,
                label: c.description.isEmpty ? c.name : c.description,
                type: c.type,
                placeholder: '',
              )).toList(),
          config: t.configFields.map((c) => ToolConfig(
                name: c.name,
                type: c.type,
                enumValues: c.enumValues.toList(),
                defaultValue: c.hasDefault_6()
                    ? StructUtils.valueToJson(c.default_6)
                    : null,
                description: c.description,
                scope: c.scope,
              )).toList(),
          requiredConfig: t.requiredConfig.toList(),
        )).toList();
  }

  Future<void> setConfigKey(String key, String value) =>
      _agent.setConfig(sdk.SetConfigRequest(key: key, value: value));

  Future<Session> sessionLocale(String id, String locale) =>
      settings(id, {'locale': locale});

  Future<Map<String, dynamic>> toolConfig() async {
    final r = await _agent.getToolConfig(sdk.GetToolConfigRequest());
    return r.config.values
        .map((k, v) => MapEntry(k, StructUtils.valueToJson(v)));
  }
}

// ---- pb -> model mappers (agent native) ----

Session sessionFromPb(sdk.Session s) => Session(
      id: s.name,
      org: s.org,
      repo: s.repo,
      branch: s.branch,
      model: s.model,
      variant: s.variant,
      preset: s.preset,
      tipId: s.tipId.isEmpty ? null : s.tipId,
      maxTurns: s.maxTurns == 0 ? null : s.maxTurns,
      systemPrompt: s.systemPrompt.isEmpty ? null : s.systemPrompt,
      locale: s.locale.isEmpty ? null : s.locale,
      inputTokens: s.inputTokens,
      outputTokens: s.outputTokens,
      totalTokens: s.totalTokens,
      lastInputTokens: s.lastInputTokens,
      lastOutputTokens: s.lastOutputTokens,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      unreadCount: s.unreadCount,
      lastMessageAt: s.lastMessageAt,
      lastMessagePreview: s.lastMessagePreview,
    );

Session _sessionFromSessionResults(sdk.Session? s) =>
    s == null ? Session(id: '') : sessionFromPb(s);

Message messageFromPb(sdk.Message m) {
  // Pair each tool call with its result (tool_use_id) so history renders one
  // tool card (with output) per call, matching the live stream shape.
  final decoded = m.parts.map((p) => (p, _decodeJson(p.data))).toList();
  final results = <String, Map<String, dynamic>>{};
  for (final (p, d) in decoded) {
    if (p.type == 'tool_result') {
      final id = (d['tool_use_id'] as String?) ?? '';
      if (id.isNotEmpty) results[id] = d;
    }
  }
  final parts = <MessagePart>[];
  for (final (p, d) in decoded) {
    switch (p.type) {
      case 'text':
        parts.add(MessagePart(
          id: p.id,
          type: 'text',
          text: (d['text'] as String?) ?? '',
        ));
      case 'summary':
      case 'compaction':
        parts.add(MessagePart(
          id: p.id,
          type: 'compaction',
          text: (d['summary'] as String?) ?? '',
        ));
      case 'file':
        parts.add(MessagePart(
          id: p.id,
          type: 'file',
          code: (d['code'] as String?) ?? '',
          name: (d['name'] as String?) ?? '',
          mime: d['mime'] as String?,
          size: (d['size'] as num?)?.toInt(),
        ));
      case 'tool':
        final callId = (d['id'] as String?) ?? p.messageId;
        final res = results[callId];
        final content = res?['content'];
        parts.add(MessagePart(
          id: p.id,
          type: 'tool',
          tool: (d['name'] as String?) ?? '',
          toolCallId: callId,
          state: ToolState(
            status: res != null ? 'complete' : 'running',
            title: (d['name'] as String?) ?? '',
            input: (d['input'] as Map?)?.cast<String, dynamic>(),
            output: content is String ? content : null,
          ),
        ));
      case 'tool_result':
        // Merged into its tool part above; render standalone only when the
        // call part is missing (defensive).
        final id = (d['tool_use_id'] as String?) ?? p.messageId;
        if (results[id] != null && m.parts.any((q) => q.type == 'tool')) {
          break;
        }
        final content = d['content'];
        parts.add(MessagePart(
          id: p.id,
          type: 'tool',
          tool: '',
          toolCallId: id,
          state: ToolState(
            status: 'complete',
            output: content is String ? content : null,
          ),
        ));
    }
  }
  return Message(
    id: m.id,
    role: m.role,
    createdAt: m.createdAt.isEmpty ? null : m.createdAt,
    parts: parts,
  );
}

Map<String, dynamic> _decodeJson(String data) {
  if (data.isEmpty) return const {};
  try {
    final v = jsonDecode(data);
    return v is Map<String, dynamic> ? v : const {};
  } catch (_) {
    return const {};
  }
}

class StructUtils {
  static Map<String, dynamic> toJson(wkt.Struct? st) {
    if (st == null) return {};
    return st.fields.map((k, v) => MapEntry(k, valueToJson(v)));
  }

  static dynamic valueToJson(wkt.Value v) {
    switch (v.whichKind()) {
      case wkt.Value_Kind.stringValue:
        return v.stringValue;
      case wkt.Value_Kind.numberValue:
        return v.numberValue;
      case wkt.Value_Kind.boolValue:
        return v.boolValue;
      case wkt.Value_Kind.structValue:
        return toJson(v.structValue);
      case wkt.Value_Kind.listValue:
        return v.listValue.values.map(valueToJson).toList();
      case wkt.Value_Kind.nullValue:
      case wkt.Value_Kind.notSet:
        return null;
    }
  }
}
