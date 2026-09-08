import 'agent_api.dart';

/// Strong-typed agent stream events. The raw `StreamEvent` (event + dynamic
/// params) is coerced to exactly one of these at the store boundary; the rest
/// of the UI/store only ever sees these typed variants — zero casts.
sealed class AgentEvent {
  const AgentEvent();
}

class TextDelta extends AgentEvent {
  const TextDelta(this.id, this.text);
  final String id;
  final String text;
}

class ReasoningDelta extends AgentEvent {
  const ReasoningDelta(this.id, this.text);
  final String id;
  final String text;
}

class ToolCall extends AgentEvent {
  const ToolCall(this.id, this.name);
  final String id;
  final String name;
}

class ToolResult extends AgentEvent {
  const ToolResult(this.id, this.output);
  final String id;
  final String output;
}

class ToolError extends AgentEvent {
  const ToolError(this.id, this.output);
  final String id;
  final String output;
}

class TurnComplete extends AgentEvent {
  const TurnComplete();
}

class StatusEvent extends AgentEvent {
  const StatusEvent(this.type);
  final String type; // busy | running | idle | ...
}

class AgentError extends AgentEvent {
  const AgentError(this.message);
  final String message;
}

/// Coerces a raw [StreamEvent] into a typed [AgentEvent].
AgentEvent toAgentEvent(StreamEvent ev) {
  final p = ev.params;
  String s(dynamic v) => v == null ? '' : v.toString();
  switch (ev.event) {
    case 'text-delta':
      return TextDelta(s(p['id']), s(p['text']));
    case 'reasoning-delta':
      return ReasoningDelta(s(p['id']), s(p['text']));
    case 'tool-call':
      return ToolCall(s(p['toolCallId'] ?? p['id']), s(p['toolName'] ?? p['name'] ?? 'tool'));
    case 'tool-result':
      return ToolResult(
          s(p['toolCallId'] ?? p['id']), s(p['formatted'] ?? p['output'] ?? p['result']));
    case 'tool-error':
      return ToolError(
          s(p['toolCallId'] ?? p['id']), s(p['formatted'] ?? p['output'] ?? p['error']));
    case 'turn-complete':
      return const TurnComplete();
    case 'status':
      return StatusEvent(s(p['type']));
    case 'error':
    case 'provider-error':
      return AgentError(s(p['message'] ?? p['error']));
    default:
      return StatusEvent(s(p['type']) == 'busy' ? 'busy' : '');
  }
}
