# Agent chat app (Flutter)

A minimal two-pane agent chat app talking **directly to the abc agent backend**
over `agent.v1.AgentService` via Connect (HTTP/2 over TLS). It has only two
areas: a **session list** and a **chat view with a settings bar** (model/preset
switch + interrupt/compact). No easylab gateway, no REST.

Powered by `agent_client_sdk` (agent-sdk-dart), generated from
`agent/v1/agent.proto`.

## Run

```bash
flutter pub get
flutter run
```

On launch, enter the agent base URL (`https://...`) + bearer token in Settings.

## Layout

```
lib/
├── main.dart          # entry + app root (config gate)
├── app.dart           # two-pane shell: SessionList | ChatPane
├── settings_page.dart # baseUrl + token (SharedPreferences)
├── session_list.dart  # session list (new/delete/rename)
├── chat_pane.dart     # chat + settings bar (model/preset/interrupt/compact)
├── agent_api.dart     # AgentApi + ChatController + models + stream parsing
└── prefs.dart         # persisted config
```
