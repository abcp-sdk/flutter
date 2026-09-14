import 'dart:convert';

import 'package:drift/drift.dart';

import '../models.dart';
import 'local_db.dart';

/// Local, persistent mirror of the agent state used for instant startup and
/// incremental sync. Thin, typed wrapper over [LocalDb]: every method either
/// converts a domain object to a drift row or back, nothing else.
///
/// The sync contract with the server is PIN-based (message `prev_id`):
///   * [serverTipId] — the chain tip we last synced to. Sent back as the
///     `after` anchor on the next incremental read.
///   * a delta read returns the messages appended since that anchor; when the
///     server reports `resync` (anchor withdrawn / chain re-pointed) the caller
///     drops this session's cached messages and re-fetches.
class LocalStore {
  LocalStore._(this._db);
  static LocalStore? _instance;

  /// Open (once) the on-disk / IndexedDB database.
  static Future<LocalStore> open() async {
    return _instance ??= LocalStore._(LocalDb());
  }

  /// Test hook: wrap an explicit database.
  static LocalStore forDb(LocalDb db) => LocalStore._(db);

  final LocalDb _db;
  LocalDb get db => _db;

  // ---- sessions ----

  Future<void> upsertSessions(List<Session> sessions) async {
    if (sessions.isEmpty) return;
    await _db.batch((b) {
      for (final s in sessions) {
        b.insert(
          _db.localSessions,
          LocalSessionsCompanion.insert(
            id: s.id,
            model: Value(s.model),
            variant: Value(s.variant),
            preset: Value(s.preset),
            systemPrompt: Value(s.systemPrompt ?? ''),
            maxTurns: Value(s.maxTurns ?? 0),
            locale: Value(s.locale ?? ''),
            org: Value(s.org),
            repo: Value(s.repo),
            branch: Value(s.branch),
            serverTipId: Value(s.tipId ?? ''),
            group: Value(s.group),
            messageSeq: Value(s.messageSeq),
            lastMessageAt: Value(s.lastMessageAt),
            lastMessagePreview: Value(s.lastMessagePreview),
            updatedAt: Value(s.updatedAt),
            lastSyncedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          onConflict: DoUpdate((_) => LocalSessionsCompanion(
                serverTipId: Value(s.tipId ?? ''),
                group: Value(s.group),
                messageSeq: Value(s.messageSeq),
                lastMessageAt: Value(s.lastMessageAt),
                lastMessagePreview: Value(s.lastMessagePreview),
                updatedAt: Value(s.updatedAt),
              )),
        );
      }
    });
  }

  /// Replace the whole session list with [sessions] (drops rows not present).
  Future<void> replaceSessions(List<Session> sessions) async {
    final keep = sessions.map((s) => s.id).toSet();
    final existing = await _db.allSessions();
    for (final row in existing) {
      if (!keep.contains(row.id)) await _db.deleteSessionLocal(row.id);
    }
    await upsertSessions(sessions);
  }

  Future<void> removeSession(String id) => _db.deleteSessionLocal(id);

  Future<List<Session>> loadSessions() async {
    final rows = await _db.allSessions();
    return rows.map(_sessionFromRow).toList();
  }

  // ---- messages ----

  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    final rows = await _db.messages(sessionId);
    return rows.map(_chatFromRow).toList();
  }

  Future<String> serverTipId(String sessionId) async {
    final s = await _db.syncState(sessionId);
    return s?.tipId ?? '';
  }

  /// The id of the oldest cached message (cache-integrity anchor), or '' when
  /// nothing is cached.
  Future<String> oldestCachedId(String sessionId) =>
      _db.oldestMessageId(sessionId);

  /// Upsert server messages (from a baseline fetch or a delta), assigning a
  /// stable local order. When [replace] is set the session's cached messages
  /// are dropped first (resync).
  Future<void> applyServerMessages(
    String sessionId,
    List<Message> msgs, {
    required bool replace,
    required String tipId,
  }) async {
    if (replace) {
      await (_db.delete(_db.localMessages)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
    }
    var order = await _db.nextOrderKey(sessionId);
    final rows = <LocalMessagesCompanion>[];
    for (final m in msgs) {
      rows.add(LocalMessagesCompanion.insert(
        id: m.id,
        sessionId: sessionId,
        role: m.role,
        prevId: Value(m.prevId),
        createdAt: Value(m.createdAt ?? ''),
        orderKey: order++,
        status: const Value('complete'),
        partsJson: Value(jsonEncode([
          for (final p in m.parts) _partToJson(p),
        ])),
      ));
    }
    await _db.upsertMessages(rows);
    await _db.upsertSyncState(LocalSyncStateCompanion.insert(
      sessionId: sessionId,
      tipId: Value(tipId),
      oldestId: Value(await _db.oldestMessageId(sessionId)),
    ));
  }

  /// Persist an in-memory list as the authoritative cache (used after live
  /// streaming finishes so a restart shows exactly what was on screen).
  Future<void> persistMessages(
    String sessionId,
    List<ChatMessage> msgs, {
    required String tipId,
  }) async {
    final rows = <LocalMessagesCompanion>[];
    var order = 0;
    for (final m in msgs) {
      if (m.isLocal) {
        // Locally-owned optimistic/streaming rows are not server history.
        continue;
      }
      rows.add(LocalMessagesCompanion.insert(
        id: m.id,
        sessionId: sessionId,
        role: m.role,
        prevId: Value(m.prevId),
        createdAt: Value(m.createdAt),
        orderKey: order++,
        status: Value(m.status),
        partsJson: Value(jsonEncode([
          for (final p in m.parts) partToJson(p),
        ])),
      ));
    }
    await _db.replaceMessages(sessionId, rows);
    await _db.upsertSyncState(LocalSyncStateCompanion.insert(
      sessionId: sessionId,
      tipId: Value(tipId),
      oldestId: Value(await _db.oldestMessageId(sessionId)),
    ));
  }

  Future<void> clearMessages(String sessionId) async {
    await (_db.delete(_db.localMessages)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
    await (_db.delete(_db.localSyncState)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  // ---- drafts ----

  Future<void> saveDraft(String sessionId, String text,
      List<UploadedFile> attachments) async {
    if (text.trim().isEmpty && attachments.isEmpty) {
      await _db.deleteDraft(sessionId);
      return;
    }
    await _db.upsertDraft(LocalDraftsCompanion.insert(
      sessionId: sessionId,
      draftText: Value(text),
      attachmentsJson: Value(jsonEncode([
        for (final a in attachments) _fileToJson(a),
      ])),
    ));
  }

  Future<Map<String, ChatDraft>> loadDrafts() async {
    final rows = await _db.select(_db.localDrafts).get();
    final out = <String, ChatDraft>{};
    for (final r in rows) {
      out[r.sessionId] = ChatDraft(
        text: r.draftText,
        attachments: [
          for (final e in (jsonDecode(r.attachmentsJson) as List))
            _fileFromJson((e as Map).cast<String, dynamic>()),
        ],
      );
    }
    return out;
  }

  // ---- read watermarks ----

  Future<Map<String, int>> loadReadSeqs() => _db.allReadSeqs();

  Future<void> setReadSeq(String sessionId, int seq) =>
      _db.setReadSeq(sessionId, seq);

  // ---- conversions ----

  Session _sessionFromRow(LocalSession r) => Session(
        id: r.id,
        model: r.model,
        variant: r.variant,
        preset: r.preset,
        systemPrompt: r.systemPrompt.isEmpty ? null : r.systemPrompt,
        maxTurns: r.maxTurns == 0 ? null : r.maxTurns,
        locale: r.locale.isEmpty ? null : r.locale,
        org: r.org,
        repo: r.repo,
        branch: r.branch,
        tipId: r.serverTipId.isEmpty ? null : r.serverTipId,
        messageSeq: r.messageSeq,
        group: r.group,
        lastMessageAt: r.lastMessageAt,
        lastMessagePreview: r.lastMessagePreview,
        updatedAt: r.updatedAt,
      );

  ChatMessage _chatFromRow(LocalMessage r) => ChatMessage(
        id: r.id,
        role: r.role,
        status: r.status,
        createdAt: r.createdAt,
        prevId: r.prevId,
        seq: r.orderKey,
        parts: [
          for (final e in (jsonDecode(r.partsJson) as List))
            chatPartFromJson((e as Map).cast<String, dynamic>()),
        ],
      );

  static Map<String, dynamic> _partToJson(MessagePart p) => {
        'id': p.id,
        'type': p.type,
        if (p.text != null) 'text': p.text,
        if (p.tool != null) 'tool': p.tool,
        if (p.toolCallId != null) 'tool_call_id': p.toolCallId,
        if (p.state != null) 'state': p.state!.toJson(),
        if (p.code != null) 'code': p.code,
        if (p.name != null) 'name': p.name,
        if (p.mime != null) 'mime': p.mime,
        if (p.size != null) 'size': p.size,
      };

  // ChatPart <-> same JSON shape (streaming controller).
  static Map<String, dynamic> partToJson(ChatPart p) => {
        'id': p.id,
        'type': p.type,
        if (p.text.isNotEmpty) 'text': p.text,
        if (p.tool.isNotEmpty) 'tool': p.tool,
        if (p.state != null) 'state': p.state!.toJson(),
        if (p.code != null) 'code': p.code,
        if (p.name != null) 'name': p.name,
        if (p.mime != null) 'mime': p.mime,
        if (p.size != null) 'size': p.size,
      };

  static ChatPart chatPartFromJson(Map<String, dynamic> j) => ChatPart(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? '',
        text: j['text'] as String? ?? '',
        tool: j['tool'] as String? ?? '',
        state: j['state'] == null
            ? null
            : ToolState.fromJson((j['state'] as Map).cast<String, dynamic>()),
        code: j['code'] as String?,
        name: j['name'] as String?,
        mime: j['mime'] as String?,
        size: (j['size'] as num?)?.toInt(),
      );

  static Map<String, dynamic> _fileToJson(UploadedFile a) => {
        'code': a.code,
        'name': a.name,
        'mime': a.mime,
        'size': a.size,
        'localPath': a.localPath,
        'state': a.uploadState,
      };

  static UploadedFile _fileFromJson(Map<String, dynamic> j) => UploadedFile(
        code: j['code'] as String? ?? '',
        name: j['name'] as String?,
        mime: j['mime'] as String?,
        size: (j['size'] as num?)?.toInt(),
        localPath: j['localPath'] as String? ?? '',
        uploadState: j['state'] as String? ?? 'done',
      );
}
