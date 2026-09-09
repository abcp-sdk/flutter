import 'dart:convert';
import 'dart:io';

import 'package:agent_client_sdk/agent_client_sdk.dart' as sdk;
import 'package:protobuf/well_known_types/google/protobuf/struct.pb.dart';

// Mirrors the flutter app's AgentBindApi: the same SDK client, connectrpc,
// hitting the same agent.v1 methods the app uses.
Future<void> main() async {
  const base = 'http://127.0.0.1:8096';
  const tok = 'devtoken';

  final client = sdk.AgentClient(baseUrl: base, token: tok);
  final agent = client.agent;

  // 1. health
  final h = await agent.health(sdk.HealthRequest());
  print('health -> ok=${h.ok}');

  // 2. listSessions (empty)
  final ls = await agent.listSessions(sdk.ListSessionsRequest());
  print('listSessions -> count=${ls.sessions.length}');

  // 3. createSession (free-form name, as the app does)
  final cs = await agent.createSession(sdk.CreateSessionRequest(name: 'app-e2e'));
  final sid = cs.sessionName;
  print('createSession -> id=$sid');

  // 4. listSessions again
  final ls2 = await agent.listSessions(sdk.ListSessionsRequest());
  print('listSessions2 -> count=${ls2.sessions.length}');

  // 5. getSession
  final gs = await agent.getSession(sdk.GetSessionRequest(id: sid));
  print('getSession -> name=${gs.session.name}');

  // 6. listMessages (empty chain)
  final lm = await agent.listMessages(sdk.ListMessagesRequest(id: sid));
  print('listMessages -> count=${lm.messages.length}');

  // 7. state (Struct -> status in fields['status'])
  final st = await agent.state(sdk.StateRequest(id: sid));
  print('state -> fields=${st.state.fields.map((k, v) => MapEntry(k, v.toString()))}');

  // 8. listProviders / listModels / listPresets / listTools / getToolConfig
  final lp = await agent.listProviders(sdk.ListProvidersRequest());
  print('listProviders -> ${lp.providers.length}');
  final lmd = await agent.listModels(sdk.ListModelsRequest());
  print('listModels -> ${lmd.models.length}');
  final lpr = await agent.listPresets(sdk.ListPresetsRequest());
  print('listPresets -> ${lpr.presets.length}');
  final lt = await agent.listTools(sdk.ListToolsRequest());
  print('listTools -> ${lt.tools.map((t) => t.name).toList()}');
  final gtc = await agent.getToolConfig(sdk.GetToolConfigRequest());
  print('getToolConfig -> keys=${gtc.config.values.keys.toList()}');

  // 9. setExtensionConfig (bundled/vlm_model) — the config the app writes
  // (SetExtensionConfigRequest uses extId + name + Value)
  try {
    final val = Value(stringValue: 'a/b');
    await agent.setExtensionConfig(
        sdk.SetExtensionConfigRequest(extId: 'bundled', name: 'vlm_model', value: val));
    print('setExtensionConfig(bundled/vlm_model) ok');
  } catch (e) {
    print('setExtensionConfig err: $e');
  }

  // 10. updateSettings (locale) as app does in settings
  try {
    await agent.updateSettings(sdk.UpdateSettingsRequest(id: sid, locale: 'zh'));
    print('updateSettings(zh) ok');
  } catch (e) {
    print('updateSettings err: $e');
  }

  // 11. deleteSession
  await agent.deleteSession(sdk.DeleteSessionRequest(id: sid));
  print('deleteSession ok');

  final ls3 = await agent.listSessions(sdk.ListSessionsRequest());
  print('listSessions after delete -> count=${ls3.sessions.length}');

  print('ALL_OK');
}
