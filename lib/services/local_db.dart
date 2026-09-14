import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_db.g.dart';

/// Sessions table: local mirror of the server's session rows plus the sync
/// bookkeeping the client owns (`server_tip_id` = the last chain tip we synced
/// to; `last_synced_at` = when). `message_seq` mirrors the server fact used for
/// unread math (the read watermark itself lives in [ReadSeqs]).
class LocalSessions extends Table {
  TextColumn get id => text()();
  TextColumn get model => text().withDefault(const Constant(''))();
  TextColumn get variant => text().withDefault(const Constant(''))();
  TextColumn get preset => text().withDefault(const Constant(''))();
  TextColumn get systemPrompt => text().withDefault(const Constant(''))();
  IntColumn get maxTurns => integer().withDefault(const Constant(0))();
  TextColumn get locale => text().withDefault(const Constant(''))();
  TextColumn get org => text().withDefault(const Constant(''))();
  TextColumn get repo => text().withDefault(const Constant(''))();
  TextColumn get branch => text().withDefault(const Constant(''))();
  TextColumn get serverTipId => text().withDefault(const Constant(''))();
  IntColumn get messageSeq => integer().withDefault(const Constant(0))();
  TextColumn get lastMessageAt => text().withDefault(const Constant(''))();
  TextColumn get lastMessagePreview => text().withDefault(const Constant(''))();
  TextColumn get group => text().withDefault(const Constant(''))();
  TextColumn get updatedAt => text().withDefault(const Constant(''))();
  IntColumn get lastSyncedAt =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Messages of a session. `prevId` is the server pin used for incremental sync;
/// `orderKey` is a local monotonic counter so the UI can sort without a server
/// seq (a fork shares rows, so a per-message ordinal is meaningless globally).
///
/// The primary key is COMPOSITE `{sessionId, id}`: a forked session SHARES the
/// same underlying message ids as its parent, so keying on `id` alone would let
/// one fork's row overwrite the other's `sessionId` and strand the shared
/// prefix (a fork would render only its post-fork tail). Keying per session
/// keeps each chain's copy independent.
class LocalMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(LocalSessions, #id)();
  TextColumn get role => text()();
  TextColumn get prevId => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text().withDefault(const Constant(''))();
  IntColumn get orderKey => integer()();
  TextColumn get status => text().withDefault(const Constant('complete'))();
  TextColumn get partsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {sessionId, id};
}

/// Per-session computed sync state kept alongside (kept separate so a partial
/// resync can drop messages without touching the session row).
class LocalSyncState extends Table {
  TextColumn get sessionId => text()();
  /// The oldest message id we currently hold (the backward-paging cursor).
  TextColumn get oldestId => text().withDefault(const Constant(''))();
  /// Whether the server may still have older history for this session.
  BoolColumn get hasMore => boolean().withDefault(const Constant(true))();
  /// Last known tip at sync time (mirrors LocalSessions.serverTipId; denormalized
  /// so a message-only transaction stays self-contained).
  TextColumn get tipId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

/// Unsent composer drafts, persisted per session.
class LocalDrafts extends Table {
  TextColumn get sessionId => text()();
  TextColumn get draftText => text().withDefault(const Constant(''))();
  /// JSON array of pending attachments (name/mime/size/code/localPath).
  TextColumn get attachmentsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

/// Client-local read watermark (session → last read message_seq).
class ReadSeqs extends Table {
  TextColumn get sessionId => text()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

@DriftDatabase(
  tables: [LocalSessions, LocalMessages, LocalSyncState, LocalDrafts, ReadSeqs],
)
class LocalDb extends _$LocalDb {
  LocalDb()
      : super(driftDatabase(
          name: 'agent_app',
          // Web uses a WASM sqlite + a drift worker (served from the app's
          // document root). Ignored on native.
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));

  /// Test/desktop-friendly constructor over an explicit executor.
  LocalDb.forExecutor(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // These are pure caches; the correct/cheapest migration is to drop
          // the cached messages AND their sync anchors so the next session open
          // re-fetches a full baseline. Drafts and read watermarks are kept.
          //
          //  v1 → v2: LocalMessages PK moved to the composite {sessionId, id}
          //           (forked chains share message ids).
          //  v2 → v3: also clear local_sync_state — a stale anchor with an
          //           empty message cache made the incremental read return an
          //           empty delta and strand the whole chain.
          //  v3 → v4: LocalSessions gains the generic `group` column
          //           (subsession parent link). Additive: keep the cache.
          if (from < 2) {
            await m.deleteTable(localMessages.actualTableName);
            await m.createTable(localMessages);
          }
          if (from < 3) {
            await m.deleteTable(localSyncState.actualTableName);
            await m.createTable(localSyncState);
          }
          if (from < 4) {
            await m.addColumn(localSessions, localSessions.group);
          }
        },
      );

  // ---- sessions ----

  Future<void> upsertSession(LocalSessionsCompanion s) =>
      into(localSessions).insertOnConflictUpdate(s);

  Future<List<LocalSession>> allSessions() => select(localSessions).get();

  Future<LocalSession?> session(String id) =>
      (select(localSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteSessionLocal(String id) async {
    await (delete(localMessages)..where((t) => t.sessionId.equals(id))).go();
    await (delete(localSyncState)..where((t) => t.sessionId.equals(id))).go();
    await (delete(localSessions)..where((t) => t.id.equals(id))).go();
  }

  // ---- messages ----

  Future<void> upsertMessages(List<LocalMessagesCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(localMessages, rows));
  }

  Future<List<LocalMessage>> messages(String sessionId) =>
      (select(localMessages)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.orderKey)]))
          .get();

  Future<int> messageCount(String sessionId) async {
    final c = countAll();
    final q = selectOnly(localMessages)
      ..addColumns([c])
      ..where(localMessages.sessionId.equals(sessionId));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<int> nextOrderKey(String sessionId) async {
    final maxKey = localMessages.orderKey.max();
    final q = selectOnly(localMessages)
      ..addColumns([maxKey])
      ..where(localMessages.sessionId.equals(sessionId));
    final row = await q.getSingleOrNull();
    return (row?.read(maxKey) ?? 0) + 1;
  }

  /// The id of the OLDEST cached message for a session (smallest orderKey), or
  /// '' when the session has no cached rows. Used as the cache-integrity anchor.
  Future<String> oldestMessageId(String sessionId) async {
    final rows = await (select(localMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderKey)])
          ..limit(1))
        .get();
    return rows.isEmpty ? '' : rows.first.id;
  }

  Future<void> replaceMessages(
    String sessionId,
    List<LocalMessagesCompanion> rows,
  ) async {
    await (delete(localMessages)..where((t) => t.sessionId.equals(sessionId)))
        .go();
    await upsertMessages(rows);
  }

  // ---- sync state ----

  Future<void> upsertSyncState(LocalSyncStateCompanion s) =>
      into(localSyncState).insertOnConflictUpdate(s);

  Future<LocalSyncStateData?> syncState(String sessionId) =>
      (select(localSyncState)..where((t) => t.sessionId.equals(sessionId)))
          .getSingleOrNull();

  // ---- drafts ----

  Future<void> upsertDraft(LocalDraftsCompanion d) =>
      into(localDrafts).insertOnConflictUpdate(d);

  Future<LocalDraft?> draft(String sessionId) =>
      (select(localDrafts)..where((t) => t.sessionId.equals(sessionId)))
          .getSingleOrNull();

  Future<void> deleteDraft(String sessionId) =>
      (delete(localDrafts)..where((t) => t.sessionId.equals(sessionId))).go();

  // ---- read watermarks ----

  Future<Map<String, int>> allReadSeqs() async {
    final rows = await select(readSeqs).get();
    return {for (final r in rows) r.sessionId: r.seq};
  }

  Future<void> setReadSeq(String sessionId, int seq) =>
      into(readSeqs).insertOnConflictUpdate(
        ReadSeqsCompanion.insert(sessionId: sessionId, seq: Value(seq)),
      );
}
