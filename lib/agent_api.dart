import 'dart:convert';

import 'package:agent_client_sdk/agent_client_sdk.dart' as sdk;
import 'package:flutter/services.dart' show rootBundle;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart' as wkt;

/// Loads the bundled self-signed CA (assets/certs/ca.crt) so the app can talk
/// to a standalone agent over HTTP/2-TLS. Cached across calls.
class AgentCa {
  static String? _pem;
  static Future<String?> load() async {
    if (_pem != null) return _pem;
    try {
      final data = await rootBundle.load('assets/certs/ca.crt');
      _pem = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      _pem = null;
    }
    return _pem;
  }
  static Future<sdk.AgentTls?> tls() async {
    final pem = await load();
    return pem == null ? null : sdk.AgentTls(caPem: pem);
  }
}

/// A parsed watch/prompt stream event.
class StreamEvent {
  final String event;
  final Map<String, dynamic> params;
  StreamEvent(this.event, this.params);
  dynamic get(String key) => params[key];
  String str(String key) => params[key] as String? ?? '';
}

/// Session list model bound to a [sdk.Session].
class SessionView {
  final sdk.Session pb;
  SessionView(this.pb);
  String get id => pb.name;
  String get name => pb.name;
  String get model => pb.model;
  String get preset => pb.preset;
  String get title => pb.name;
  String get preview => pb.lastMessagePreview;
  String? get lastAt => pb.lastMessageAt.isEmpty ? null : pb.lastMessageAt;
}

/// UI chat message built from a [sdk.Message] + live stream deltas.
class ChatMessage {
  final String id;
  final String role; // user | assistant | system
  final String status; // done | streaming | pending | error
  final List<PartView> parts;
  final int seq;
  ChatMessage({
    required this.id,
    required this.role,
    required this.status,
    required this.parts,
    required this.seq,
  });

  String get text {
    final buf = StringBuffer();
    for (final p in parts) {
      if (p.type == 'text') buf.write(p.data);
    }
    return buf.toString();
  }

  List<Map<String, dynamic>> get toolCalls =>
      parts.where((p) => p.type == 'tool').map((p) {
        final d = jsonDecode(p.data);
        return d is Map<String, dynamic> ? d : {'input': d};
      }).toList();
}

class PartView {
  final String id;
  final String type;
  final String data;
  PartView({required this.id, required this.type, required this.data});
}

/// Parses proto [wkt.Struct] into a plain map (like easylab's StructUtils).
Map<String, dynamic> structToJson(wkt.Struct? st) {
  if (st == null) return {};
  return st.fields.map((k, v) => MapEntry(k, valueToJson(v)));
}

dynamic valueToJson(wkt.Value v) {
  switch (v.whichKind()) {
    case wkt.Value_Kind.stringValue:
      return v.stringValue;
    case wkt.Value_Kind.numberValue:
      return v.numberValue;
    case wkt.Value_Kind.boolValue:
      return v.boolValue;
    case wkt.Value_Kind.structValue:
      return structToJson(v.structValue);
    case wkt.Value_Kind.listValue:
      return v.listValue.values.map(valueToJson).toList();
    case wkt.Value_Kind.nullValue:
    case wkt.Value_Kind.notSet:
      return null;
  }
}

/// Parses a [sdk.Message] into UI chat messages.
List<ChatMessage> mapMessages(List<sdk.Message> msgs) {
  final out = <ChatMessage>[];
  for (var i = 0; i < msgs.length; i++) {
    final m = msgs[i];
    final parts = <PartView>[];
    for (final p in m.parts) {
      parts.add(PartView(id: p.id, type: p.type, data: p.data));
    }
    out.add(ChatMessage(
      id: m.id,
      role: m.role,
      status: 'done',
      parts: parts,
      seq: i,
    ));
  }
  return out;
}

/// Thin typed client over agent.v1.AgentService.
class AgentApi {
  final String baseUrl;
  final String token;
  final sdk.AgentClient _client;

  AgentApi({required this.baseUrl, required this.token, sdk.AgentTls? tls})
      : _client = sdk.AgentClient(baseUrl: baseUrl, token: token, tls: tls);

  /// Builds an AgentApi trusting the bundled CA (for a self-signed agent).
  static Future<AgentApi> create(
      {required String baseUrl, required String token}) async {
    final tls = await AgentCa.tls();
    return AgentApi(baseUrl: baseUrl, token: token, tls: tls);
  }

  sdk.AgentServiceClient get agent => _client.agent;

  Future<List<SessionView>> listSessions() async {
    final r = await agent.listSessions(sdk.ListSessionsRequest());
    return r.sessions.map((s) => SessionView(s)).toList();
  }

  Future<SessionView> createSession({String? name}) async {
    final s = await _client.createSession(name: name);
    return SessionView(s);
  }

  Future<void> deleteSession(String id) async {
    await agent.deleteSession(sdk.DeleteSessionRequest(id: id));
  }

  Future<String> renameSession(String id, String name) async {
    final r = await agent.rename(sdk.RenameRequest(id: id, name: name));
    return r.session.name;
  }

  Future<String> forkSession(String id, String name) async {
    final r = await agent.fork(sdk.ForkRequest(id: id, name: name));
    return r.session.name;
  }

  Future<List<ChatMessage>> messages(String id,
      {String? before, int limit = 50}) async {
    final r = await agent.listMessages(
        sdk.ListMessagesRequest(id: id, limit: limit, before: before ?? ''));
    return mapMessages(r.messages);
  }

  Future<String> prompt(String id, String prompt) async {
    await for (final e in agent.prompt(sdk.PromptRequest(id: id, prompt: prompt))) {
      if (e.event == 'accepted') return e.params['message_id'] ?? '';
    }
    return '';
  }

  Stream<StreamEvent> streamEvents(String sessionId) async* {
    yield* agent.watchSession(sdk.WatchSessionRequest(id: sessionId)).map(
      (e) => StreamEvent(e.event, structToJson(e.params)),
    );
  }

  Future<String> switchModel(String id, String model) async {
    await agent.setModel(sdk.SetModelRequest(id: id, model: model));
    return model;
  }

  Future<void> updateSettings(String id,
      {String? model, String? preset, int? maxTurns, String? systemPrompt}) async {
    await agent.updateSettings(sdk.UpdateSettingsRequest(
      id: id,
      model: model,
      preset: preset,
      maxTurns: maxTurns,
      systemPrompt: systemPrompt,
    ));
  }

  Future<bool> interrupt(String id) async {
    final r = await agent.interrupt(sdk.InterruptRequest(id: id));
    return r.interrupted;
  }

  Future<void> compact(String id) async {
    await agent.compact(sdk.CompactRequest(id: id));
  }

  Future<List<sdk.ModelInfo>> listModels() async {
    final r = await agent.listModels(sdk.ListModelsRequest());
    return r.models;
  }

  Future<List<sdk.Preset>> listPresets() async {
    final r = await agent.listPresets(sdk.ListPresetsRequest());
    return r.presets;
  }

  Future<sdk.HealthResponse> health() async => agent.health(sdk.HealthRequest());
}
