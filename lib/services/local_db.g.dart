// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalSessionsTable extends LocalSessions
    with TableInfo<$LocalSessionsTable, LocalSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _variantMeta = const VerificationMeta(
    'variant',
  );
  @override
  late final GeneratedColumn<String> variant = GeneratedColumn<String>(
    'variant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _presetMeta = const VerificationMeta('preset');
  @override
  late final GeneratedColumn<String> preset = GeneratedColumn<String>(
    'preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _systemPromptMeta = const VerificationMeta(
    'systemPrompt',
  );
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
    'system_prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _maxTurnsMeta = const VerificationMeta(
    'maxTurns',
  );
  @override
  late final GeneratedColumn<int> maxTurns = GeneratedColumn<int>(
    'max_turns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _orgMeta = const VerificationMeta('org');
  @override
  late final GeneratedColumn<String> org = GeneratedColumn<String>(
    'org',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _repoMeta = const VerificationMeta('repo');
  @override
  late final GeneratedColumn<String> repo = GeneratedColumn<String>(
    'repo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _serverTipIdMeta = const VerificationMeta(
    'serverTipId',
  );
  @override
  late final GeneratedColumn<String> serverTipId = GeneratedColumn<String>(
    'server_tip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _messageSeqMeta = const VerificationMeta(
    'messageSeq',
  );
  @override
  late final GeneratedColumn<int> messageSeq = GeneratedColumn<int>(
    'message_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<String> lastMessageAt = GeneratedColumn<String>(
    'last_message_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
    'group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    model,
    variant,
    preset,
    systemPrompt,
    maxTurns,
    locale,
    org,
    repo,
    branch,
    serverTipId,
    messageSeq,
    lastMessageAt,
    lastMessagePreview,
    group,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('variant')) {
      context.handle(
        _variantMeta,
        variant.isAcceptableOrUnknown(data['variant']!, _variantMeta),
      );
    }
    if (data.containsKey('preset')) {
      context.handle(
        _presetMeta,
        preset.isAcceptableOrUnknown(data['preset']!, _presetMeta),
      );
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
        _systemPromptMeta,
        systemPrompt.isAcceptableOrUnknown(
          data['system_prompt']!,
          _systemPromptMeta,
        ),
      );
    }
    if (data.containsKey('max_turns')) {
      context.handle(
        _maxTurnsMeta,
        maxTurns.isAcceptableOrUnknown(data['max_turns']!, _maxTurnsMeta),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('org')) {
      context.handle(
        _orgMeta,
        org.isAcceptableOrUnknown(data['org']!, _orgMeta),
      );
    }
    if (data.containsKey('repo')) {
      context.handle(
        _repoMeta,
        repo.isAcceptableOrUnknown(data['repo']!, _repoMeta),
      );
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    }
    if (data.containsKey('server_tip_id')) {
      context.handle(
        _serverTipIdMeta,
        serverTipId.isAcceptableOrUnknown(
          data['server_tip_id']!,
          _serverTipIdMeta,
        ),
      );
    }
    if (data.containsKey('message_seq')) {
      context.handle(
        _messageSeqMeta,
        messageSeq.isAcceptableOrUnknown(data['message_seq']!, _messageSeqMeta),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('group')) {
      context.handle(
        _groupMeta,
        group.isAcceptableOrUnknown(data['group']!, _groupMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      variant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant'],
      )!,
      preset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset'],
      )!,
      systemPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_prompt'],
      )!,
      maxTurns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_turns'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      org: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}org'],
      )!,
      repo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo'],
      )!,
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      )!,
      serverTipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_tip_id'],
      )!,
      messageSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_seq'],
      )!,
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_at'],
      )!,
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      )!,
      group: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $LocalSessionsTable createAlias(String alias) {
    return $LocalSessionsTable(attachedDatabase, alias);
  }
}

class LocalSession extends DataClass implements Insertable<LocalSession> {
  final String id;
  final String model;
  final String variant;
  final String preset;
  final String systemPrompt;
  final int maxTurns;
  final String locale;
  final String org;
  final String repo;
  final String branch;
  final String serverTipId;
  final int messageSeq;
  final String lastMessageAt;
  final String lastMessagePreview;
  final String group;
  final String updatedAt;
  final int lastSyncedAt;
  const LocalSession({
    required this.id,
    required this.model,
    required this.variant,
    required this.preset,
    required this.systemPrompt,
    required this.maxTurns,
    required this.locale,
    required this.org,
    required this.repo,
    required this.branch,
    required this.serverTipId,
    required this.messageSeq,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.group,
    required this.updatedAt,
    required this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['model'] = Variable<String>(model);
    map['variant'] = Variable<String>(variant);
    map['preset'] = Variable<String>(preset);
    map['system_prompt'] = Variable<String>(systemPrompt);
    map['max_turns'] = Variable<int>(maxTurns);
    map['locale'] = Variable<String>(locale);
    map['org'] = Variable<String>(org);
    map['repo'] = Variable<String>(repo);
    map['branch'] = Variable<String>(branch);
    map['server_tip_id'] = Variable<String>(serverTipId);
    map['message_seq'] = Variable<int>(messageSeq);
    map['last_message_at'] = Variable<String>(lastMessageAt);
    map['last_message_preview'] = Variable<String>(lastMessagePreview);
    map['group'] = Variable<String>(group);
    map['updated_at'] = Variable<String>(updatedAt);
    map['last_synced_at'] = Variable<int>(lastSyncedAt);
    return map;
  }

  LocalSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSessionsCompanion(
      id: Value(id),
      model: Value(model),
      variant: Value(variant),
      preset: Value(preset),
      systemPrompt: Value(systemPrompt),
      maxTurns: Value(maxTurns),
      locale: Value(locale),
      org: Value(org),
      repo: Value(repo),
      branch: Value(branch),
      serverTipId: Value(serverTipId),
      messageSeq: Value(messageSeq),
      lastMessageAt: Value(lastMessageAt),
      lastMessagePreview: Value(lastMessagePreview),
      group: Value(group),
      updatedAt: Value(updatedAt),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory LocalSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSession(
      id: serializer.fromJson<String>(json['id']),
      model: serializer.fromJson<String>(json['model']),
      variant: serializer.fromJson<String>(json['variant']),
      preset: serializer.fromJson<String>(json['preset']),
      systemPrompt: serializer.fromJson<String>(json['systemPrompt']),
      maxTurns: serializer.fromJson<int>(json['maxTurns']),
      locale: serializer.fromJson<String>(json['locale']),
      org: serializer.fromJson<String>(json['org']),
      repo: serializer.fromJson<String>(json['repo']),
      branch: serializer.fromJson<String>(json['branch']),
      serverTipId: serializer.fromJson<String>(json['serverTipId']),
      messageSeq: serializer.fromJson<int>(json['messageSeq']),
      lastMessageAt: serializer.fromJson<String>(json['lastMessageAt']),
      lastMessagePreview: serializer.fromJson<String>(
        json['lastMessagePreview'],
      ),
      group: serializer.fromJson<String>(json['group']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<int>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'model': serializer.toJson<String>(model),
      'variant': serializer.toJson<String>(variant),
      'preset': serializer.toJson<String>(preset),
      'systemPrompt': serializer.toJson<String>(systemPrompt),
      'maxTurns': serializer.toJson<int>(maxTurns),
      'locale': serializer.toJson<String>(locale),
      'org': serializer.toJson<String>(org),
      'repo': serializer.toJson<String>(repo),
      'branch': serializer.toJson<String>(branch),
      'serverTipId': serializer.toJson<String>(serverTipId),
      'messageSeq': serializer.toJson<int>(messageSeq),
      'lastMessageAt': serializer.toJson<String>(lastMessageAt),
      'lastMessagePreview': serializer.toJson<String>(lastMessagePreview),
      'group': serializer.toJson<String>(group),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'lastSyncedAt': serializer.toJson<int>(lastSyncedAt),
    };
  }

  LocalSession copyWith({
    String? id,
    String? model,
    String? variant,
    String? preset,
    String? systemPrompt,
    int? maxTurns,
    String? locale,
    String? org,
    String? repo,
    String? branch,
    String? serverTipId,
    int? messageSeq,
    String? lastMessageAt,
    String? lastMessagePreview,
    String? group,
    String? updatedAt,
    int? lastSyncedAt,
  }) => LocalSession(
    id: id ?? this.id,
    model: model ?? this.model,
    variant: variant ?? this.variant,
    preset: preset ?? this.preset,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    maxTurns: maxTurns ?? this.maxTurns,
    locale: locale ?? this.locale,
    org: org ?? this.org,
    repo: repo ?? this.repo,
    branch: branch ?? this.branch,
    serverTipId: serverTipId ?? this.serverTipId,
    messageSeq: messageSeq ?? this.messageSeq,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    group: group ?? this.group,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
  LocalSession copyWithCompanion(LocalSessionsCompanion data) {
    return LocalSession(
      id: data.id.present ? data.id.value : this.id,
      model: data.model.present ? data.model.value : this.model,
      variant: data.variant.present ? data.variant.value : this.variant,
      preset: data.preset.present ? data.preset.value : this.preset,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      maxTurns: data.maxTurns.present ? data.maxTurns.value : this.maxTurns,
      locale: data.locale.present ? data.locale.value : this.locale,
      org: data.org.present ? data.org.value : this.org,
      repo: data.repo.present ? data.repo.value : this.repo,
      branch: data.branch.present ? data.branch.value : this.branch,
      serverTipId: data.serverTipId.present
          ? data.serverTipId.value
          : this.serverTipId,
      messageSeq: data.messageSeq.present
          ? data.messageSeq.value
          : this.messageSeq,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      group: data.group.present ? data.group.value : this.group,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSession(')
          ..write('id: $id, ')
          ..write('model: $model, ')
          ..write('variant: $variant, ')
          ..write('preset: $preset, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('maxTurns: $maxTurns, ')
          ..write('locale: $locale, ')
          ..write('org: $org, ')
          ..write('repo: $repo, ')
          ..write('branch: $branch, ')
          ..write('serverTipId: $serverTipId, ')
          ..write('messageSeq: $messageSeq, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('group: $group, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    model,
    variant,
    preset,
    systemPrompt,
    maxTurns,
    locale,
    org,
    repo,
    branch,
    serverTipId,
    messageSeq,
    lastMessageAt,
    lastMessagePreview,
    group,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSession &&
          other.id == this.id &&
          other.model == this.model &&
          other.variant == this.variant &&
          other.preset == this.preset &&
          other.systemPrompt == this.systemPrompt &&
          other.maxTurns == this.maxTurns &&
          other.locale == this.locale &&
          other.org == this.org &&
          other.repo == this.repo &&
          other.branch == this.branch &&
          other.serverTipId == this.serverTipId &&
          other.messageSeq == this.messageSeq &&
          other.lastMessageAt == this.lastMessageAt &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.group == this.group &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LocalSessionsCompanion extends UpdateCompanion<LocalSession> {
  final Value<String> id;
  final Value<String> model;
  final Value<String> variant;
  final Value<String> preset;
  final Value<String> systemPrompt;
  final Value<int> maxTurns;
  final Value<String> locale;
  final Value<String> org;
  final Value<String> repo;
  final Value<String> branch;
  final Value<String> serverTipId;
  final Value<int> messageSeq;
  final Value<String> lastMessageAt;
  final Value<String> lastMessagePreview;
  final Value<String> group;
  final Value<String> updatedAt;
  final Value<int> lastSyncedAt;
  final Value<int> rowid;
  const LocalSessionsCompanion({
    this.id = const Value.absent(),
    this.model = const Value.absent(),
    this.variant = const Value.absent(),
    this.preset = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.maxTurns = const Value.absent(),
    this.locale = const Value.absent(),
    this.org = const Value.absent(),
    this.repo = const Value.absent(),
    this.branch = const Value.absent(),
    this.serverTipId = const Value.absent(),
    this.messageSeq = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.group = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSessionsCompanion.insert({
    required String id,
    this.model = const Value.absent(),
    this.variant = const Value.absent(),
    this.preset = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.maxTurns = const Value.absent(),
    this.locale = const Value.absent(),
    this.org = const Value.absent(),
    this.repo = const Value.absent(),
    this.branch = const Value.absent(),
    this.serverTipId = const Value.absent(),
    this.messageSeq = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.group = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LocalSession> custom({
    Expression<String>? id,
    Expression<String>? model,
    Expression<String>? variant,
    Expression<String>? preset,
    Expression<String>? systemPrompt,
    Expression<int>? maxTurns,
    Expression<String>? locale,
    Expression<String>? org,
    Expression<String>? repo,
    Expression<String>? branch,
    Expression<String>? serverTipId,
    Expression<int>? messageSeq,
    Expression<String>? lastMessageAt,
    Expression<String>? lastMessagePreview,
    Expression<String>? group,
    Expression<String>? updatedAt,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (variant != null) 'variant': variant,
      if (preset != null) 'preset': preset,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (maxTurns != null) 'max_turns': maxTurns,
      if (locale != null) 'locale': locale,
      if (org != null) 'org': org,
      if (repo != null) 'repo': repo,
      if (branch != null) 'branch': branch,
      if (serverTipId != null) 'server_tip_id': serverTipId,
      if (messageSeq != null) 'message_seq': messageSeq,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (group != null) 'group': group,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? model,
    Value<String>? variant,
    Value<String>? preset,
    Value<String>? systemPrompt,
    Value<int>? maxTurns,
    Value<String>? locale,
    Value<String>? org,
    Value<String>? repo,
    Value<String>? branch,
    Value<String>? serverTipId,
    Value<int>? messageSeq,
    Value<String>? lastMessageAt,
    Value<String>? lastMessagePreview,
    Value<String>? group,
    Value<String>? updatedAt,
    Value<int>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return LocalSessionsCompanion(
      id: id ?? this.id,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      preset: preset ?? this.preset,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      maxTurns: maxTurns ?? this.maxTurns,
      locale: locale ?? this.locale,
      org: org ?? this.org,
      repo: repo ?? this.repo,
      branch: branch ?? this.branch,
      serverTipId: serverTipId ?? this.serverTipId,
      messageSeq: messageSeq ?? this.messageSeq,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      group: group ?? this.group,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (variant.present) {
      map['variant'] = Variable<String>(variant.value);
    }
    if (preset.present) {
      map['preset'] = Variable<String>(preset.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (maxTurns.present) {
      map['max_turns'] = Variable<int>(maxTurns.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (org.present) {
      map['org'] = Variable<String>(org.value);
    }
    if (repo.present) {
      map['repo'] = Variable<String>(repo.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (serverTipId.present) {
      map['server_tip_id'] = Variable<String>(serverTipId.value);
    }
    if (messageSeq.present) {
      map['message_seq'] = Variable<int>(messageSeq.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<String>(lastMessageAt.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSessionsCompanion(')
          ..write('id: $id, ')
          ..write('model: $model, ')
          ..write('variant: $variant, ')
          ..write('preset: $preset, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('maxTurns: $maxTurns, ')
          ..write('locale: $locale, ')
          ..write('org: $org, ')
          ..write('repo: $repo, ')
          ..write('branch: $branch, ')
          ..write('serverTipId: $serverTipId, ')
          ..write('messageSeq: $messageSeq, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('group: $group, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_sessions (id)',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevIdMeta = const VerificationMeta('prevId');
  @override
  late final GeneratedColumn<String> prevId = GeneratedColumn<String>(
    'prev_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<int> orderKey = GeneratedColumn<int>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('complete'),
  );
  static const VerificationMeta _partsJsonMeta = const VerificationMeta(
    'partsJson',
  );
  @override
  late final GeneratedColumn<String> partsJson = GeneratedColumn<String>(
    'parts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    role,
    prevId,
    createdAt,
    orderKey,
    status,
    partsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('prev_id')) {
      context.handle(
        _prevIdMeta,
        prevId.isAcceptableOrUnknown(data['prev_id']!, _prevIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('parts_json')) {
      context.handle(
        _partsJsonMeta,
        partsJson.isAcceptableOrUnknown(data['parts_json']!, _partsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      prevId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_key'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      partsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parts_json'],
      )!,
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final String id;
  final String sessionId;
  final String role;
  final String prevId;
  final String createdAt;
  final int orderKey;
  final String status;
  final String partsJson;
  const LocalMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.prevId,
    required this.createdAt,
    required this.orderKey,
    required this.status,
    required this.partsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['role'] = Variable<String>(role);
    map['prev_id'] = Variable<String>(prevId);
    map['created_at'] = Variable<String>(createdAt);
    map['order_key'] = Variable<int>(orderKey);
    map['status'] = Variable<String>(status);
    map['parts_json'] = Variable<String>(partsJson);
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      prevId: Value(prevId),
      createdAt: Value(createdAt),
      orderKey: Value(orderKey),
      status: Value(status),
      partsJson: Value(partsJson),
    );
  }

  factory LocalMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      role: serializer.fromJson<String>(json['role']),
      prevId: serializer.fromJson<String>(json['prevId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      orderKey: serializer.fromJson<int>(json['orderKey']),
      status: serializer.fromJson<String>(json['status']),
      partsJson: serializer.fromJson<String>(json['partsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'role': serializer.toJson<String>(role),
      'prevId': serializer.toJson<String>(prevId),
      'createdAt': serializer.toJson<String>(createdAt),
      'orderKey': serializer.toJson<int>(orderKey),
      'status': serializer.toJson<String>(status),
      'partsJson': serializer.toJson<String>(partsJson),
    };
  }

  LocalMessage copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? prevId,
    String? createdAt,
    int? orderKey,
    String? status,
    String? partsJson,
  }) => LocalMessage(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    role: role ?? this.role,
    prevId: prevId ?? this.prevId,
    createdAt: createdAt ?? this.createdAt,
    orderKey: orderKey ?? this.orderKey,
    status: status ?? this.status,
    partsJson: partsJson ?? this.partsJson,
  );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      prevId: data.prevId.present ? data.prevId.value : this.prevId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      status: data.status.present ? data.status.value : this.status,
      partsJson: data.partsJson.present ? data.partsJson.value : this.partsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('prevId: $prevId, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderKey: $orderKey, ')
          ..write('status: $status, ')
          ..write('partsJson: $partsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    role,
    prevId,
    createdAt,
    orderKey,
    status,
    partsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.prevId == this.prevId &&
          other.createdAt == this.createdAt &&
          other.orderKey == this.orderKey &&
          other.status == this.status &&
          other.partsJson == this.partsJson);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> role;
  final Value<String> prevId;
  final Value<String> createdAt;
  final Value<int> orderKey;
  final Value<String> status;
  final Value<String> partsJson;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.prevId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.status = const Value.absent(),
    this.partsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required String role,
    this.prevId = const Value.absent(),
    this.createdAt = const Value.absent(),
    required int orderKey,
    this.status = const Value.absent(),
    this.partsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       role = Value(role),
       orderKey = Value(orderKey);
  static Insertable<LocalMessage> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? role,
    Expression<String>? prevId,
    Expression<String>? createdAt,
    Expression<int>? orderKey,
    Expression<String>? status,
    Expression<String>? partsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (prevId != null) 'prev_id': prevId,
      if (createdAt != null) 'created_at': createdAt,
      if (orderKey != null) 'order_key': orderKey,
      if (status != null) 'status': status,
      if (partsJson != null) 'parts_json': partsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? role,
    Value<String>? prevId,
    Value<String>? createdAt,
    Value<int>? orderKey,
    Value<String>? status,
    Value<String>? partsJson,
    Value<int>? rowid,
  }) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      prevId: prevId ?? this.prevId,
      createdAt: createdAt ?? this.createdAt,
      orderKey: orderKey ?? this.orderKey,
      status: status ?? this.status,
      partsJson: partsJson ?? this.partsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (prevId.present) {
      map['prev_id'] = Variable<String>(prevId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<int>(orderKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (partsJson.present) {
      map['parts_json'] = Variable<String>(partsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('prevId: $prevId, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderKey: $orderKey, ')
          ..write('status: $status, ')
          ..write('partsJson: $partsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncStateTable extends LocalSyncState
    with TableInfo<$LocalSyncStateTable, LocalSyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldestIdMeta = const VerificationMeta(
    'oldestId',
  );
  @override
  late final GeneratedColumn<String> oldestId = GeneratedColumn<String>(
    'oldest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hasMoreMeta = const VerificationMeta(
    'hasMore',
  );
  @override
  late final GeneratedColumn<bool> hasMore = GeneratedColumn<bool>(
    'has_more',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_more" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _tipIdMeta = const VerificationMeta('tipId');
  @override
  late final GeneratedColumn<String> tipId = GeneratedColumn<String>(
    'tip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, oldestId, hasMore, tipId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('oldest_id')) {
      context.handle(
        _oldestIdMeta,
        oldestId.isAcceptableOrUnknown(data['oldest_id']!, _oldestIdMeta),
      );
    }
    if (data.containsKey('has_more')) {
      context.handle(
        _hasMoreMeta,
        hasMore.isAcceptableOrUnknown(data['has_more']!, _hasMoreMeta),
      );
    }
    if (data.containsKey('tip_id')) {
      context.handle(
        _tipIdMeta,
        tipId.isAcceptableOrUnknown(data['tip_id']!, _tipIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  LocalSyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncStateData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      oldestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oldest_id'],
      )!,
      hasMore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_more'],
      )!,
      tipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tip_id'],
      )!,
    );
  }

  @override
  $LocalSyncStateTable createAlias(String alias) {
    return $LocalSyncStateTable(attachedDatabase, alias);
  }
}

class LocalSyncStateData extends DataClass
    implements Insertable<LocalSyncStateData> {
  final String sessionId;

  /// The oldest message id we currently hold (the backward-paging cursor).
  final String oldestId;

  /// Whether the server may still have older history for this session.
  final bool hasMore;

  /// Last known tip at sync time (mirrors LocalSessions.serverTipId; denormalized
  /// so a message-only transaction stays self-contained).
  final String tipId;
  const LocalSyncStateData({
    required this.sessionId,
    required this.oldestId,
    required this.hasMore,
    required this.tipId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['oldest_id'] = Variable<String>(oldestId);
    map['has_more'] = Variable<bool>(hasMore);
    map['tip_id'] = Variable<String>(tipId);
    return map;
  }

  LocalSyncStateCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncStateCompanion(
      sessionId: Value(sessionId),
      oldestId: Value(oldestId),
      hasMore: Value(hasMore),
      tipId: Value(tipId),
    );
  }

  factory LocalSyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncStateData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      oldestId: serializer.fromJson<String>(json['oldestId']),
      hasMore: serializer.fromJson<bool>(json['hasMore']),
      tipId: serializer.fromJson<String>(json['tipId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'oldestId': serializer.toJson<String>(oldestId),
      'hasMore': serializer.toJson<bool>(hasMore),
      'tipId': serializer.toJson<String>(tipId),
    };
  }

  LocalSyncStateData copyWith({
    String? sessionId,
    String? oldestId,
    bool? hasMore,
    String? tipId,
  }) => LocalSyncStateData(
    sessionId: sessionId ?? this.sessionId,
    oldestId: oldestId ?? this.oldestId,
    hasMore: hasMore ?? this.hasMore,
    tipId: tipId ?? this.tipId,
  );
  LocalSyncStateData copyWithCompanion(LocalSyncStateCompanion data) {
    return LocalSyncStateData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      oldestId: data.oldestId.present ? data.oldestId.value : this.oldestId,
      hasMore: data.hasMore.present ? data.hasMore.value : this.hasMore,
      tipId: data.tipId.present ? data.tipId.value : this.tipId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncStateData(')
          ..write('sessionId: $sessionId, ')
          ..write('oldestId: $oldestId, ')
          ..write('hasMore: $hasMore, ')
          ..write('tipId: $tipId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, oldestId, hasMore, tipId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncStateData &&
          other.sessionId == this.sessionId &&
          other.oldestId == this.oldestId &&
          other.hasMore == this.hasMore &&
          other.tipId == this.tipId);
}

class LocalSyncStateCompanion extends UpdateCompanion<LocalSyncStateData> {
  final Value<String> sessionId;
  final Value<String> oldestId;
  final Value<bool> hasMore;
  final Value<String> tipId;
  final Value<int> rowid;
  const LocalSyncStateCompanion({
    this.sessionId = const Value.absent(),
    this.oldestId = const Value.absent(),
    this.hasMore = const Value.absent(),
    this.tipId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncStateCompanion.insert({
    required String sessionId,
    this.oldestId = const Value.absent(),
    this.hasMore = const Value.absent(),
    this.tipId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<LocalSyncStateData> custom({
    Expression<String>? sessionId,
    Expression<String>? oldestId,
    Expression<bool>? hasMore,
    Expression<String>? tipId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (oldestId != null) 'oldest_id': oldestId,
      if (hasMore != null) 'has_more': hasMore,
      if (tipId != null) 'tip_id': tipId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncStateCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? oldestId,
    Value<bool>? hasMore,
    Value<String>? tipId,
    Value<int>? rowid,
  }) {
    return LocalSyncStateCompanion(
      sessionId: sessionId ?? this.sessionId,
      oldestId: oldestId ?? this.oldestId,
      hasMore: hasMore ?? this.hasMore,
      tipId: tipId ?? this.tipId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (oldestId.present) {
      map['oldest_id'] = Variable<String>(oldestId.value);
    }
    if (hasMore.present) {
      map['has_more'] = Variable<bool>(hasMore.value);
    }
    if (tipId.present) {
      map['tip_id'] = Variable<String>(tipId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncStateCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('oldestId: $oldestId, ')
          ..write('hasMore: $hasMore, ')
          ..write('tipId: $tipId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDraftsTable extends LocalDrafts
    with TableInfo<$LocalDraftsTable, LocalDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _draftTextMeta = const VerificationMeta(
    'draftText',
  );
  @override
  late final GeneratedColumn<String> draftText = GeneratedColumn<String>(
    'draft_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, draftText, attachmentsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('draft_text')) {
      context.handle(
        _draftTextMeta,
        draftText.isAcceptableOrUnknown(data['draft_text']!, _draftTextMeta),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  LocalDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDraft(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      draftText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_text'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      )!,
    );
  }

  @override
  $LocalDraftsTable createAlias(String alias) {
    return $LocalDraftsTable(attachedDatabase, alias);
  }
}

class LocalDraft extends DataClass implements Insertable<LocalDraft> {
  final String sessionId;
  final String draftText;

  /// JSON array of pending attachments (name/mime/size/code/localPath).
  final String attachmentsJson;
  const LocalDraft({
    required this.sessionId,
    required this.draftText,
    required this.attachmentsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['draft_text'] = Variable<String>(draftText);
    map['attachments_json'] = Variable<String>(attachmentsJson);
    return map;
  }

  LocalDraftsCompanion toCompanion(bool nullToAbsent) {
    return LocalDraftsCompanion(
      sessionId: Value(sessionId),
      draftText: Value(draftText),
      attachmentsJson: Value(attachmentsJson),
    );
  }

  factory LocalDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDraft(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      draftText: serializer.fromJson<String>(json['draftText']),
      attachmentsJson: serializer.fromJson<String>(json['attachmentsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'draftText': serializer.toJson<String>(draftText),
      'attachmentsJson': serializer.toJson<String>(attachmentsJson),
    };
  }

  LocalDraft copyWith({
    String? sessionId,
    String? draftText,
    String? attachmentsJson,
  }) => LocalDraft(
    sessionId: sessionId ?? this.sessionId,
    draftText: draftText ?? this.draftText,
    attachmentsJson: attachmentsJson ?? this.attachmentsJson,
  );
  LocalDraft copyWithCompanion(LocalDraftsCompanion data) {
    return LocalDraft(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      draftText: data.draftText.present ? data.draftText.value : this.draftText,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraft(')
          ..write('sessionId: $sessionId, ')
          ..write('draftText: $draftText, ')
          ..write('attachmentsJson: $attachmentsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, draftText, attachmentsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDraft &&
          other.sessionId == this.sessionId &&
          other.draftText == this.draftText &&
          other.attachmentsJson == this.attachmentsJson);
}

class LocalDraftsCompanion extends UpdateCompanion<LocalDraft> {
  final Value<String> sessionId;
  final Value<String> draftText;
  final Value<String> attachmentsJson;
  final Value<int> rowid;
  const LocalDraftsCompanion({
    this.sessionId = const Value.absent(),
    this.draftText = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDraftsCompanion.insert({
    required String sessionId,
    this.draftText = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<LocalDraft> custom({
    Expression<String>? sessionId,
    Expression<String>? draftText,
    Expression<String>? attachmentsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (draftText != null) 'draft_text': draftText,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDraftsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? draftText,
    Value<String>? attachmentsJson,
    Value<int>? rowid,
  }) {
    return LocalDraftsCompanion(
      sessionId: sessionId ?? this.sessionId,
      draftText: draftText ?? this.draftText,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (draftText.present) {
      map['draft_text'] = Variable<String>(draftText.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraftsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('draftText: $draftText, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadSeqsTable extends ReadSeqs with TableInfo<$ReadSeqsTable, ReadSeq> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadSeqsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_seqs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadSeq> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  ReadSeq map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadSeq(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $ReadSeqsTable createAlias(String alias) {
    return $ReadSeqsTable(attachedDatabase, alias);
  }
}

class ReadSeq extends DataClass implements Insertable<ReadSeq> {
  final String sessionId;
  final int seq;
  const ReadSeq({required this.sessionId, required this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  ReadSeqsCompanion toCompanion(bool nullToAbsent) {
    return ReadSeqsCompanion(sessionId: Value(sessionId), seq: Value(seq));
  }

  factory ReadSeq.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadSeq(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
    };
  }

  ReadSeq copyWith({String? sessionId, int? seq}) =>
      ReadSeq(sessionId: sessionId ?? this.sessionId, seq: seq ?? this.seq);
  ReadSeq copyWithCompanion(ReadSeqsCompanion data) {
    return ReadSeq(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadSeq(')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadSeq &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq);
}

class ReadSeqsCompanion extends UpdateCompanion<ReadSeq> {
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<int> rowid;
  const ReadSeqsCompanion({
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadSeqsCompanion.insert({
    required String sessionId,
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<ReadSeq> custom({
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadSeqsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return ReadSeqsCompanion(
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadSeqsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDb extends GeneratedDatabase {
  _$LocalDb(QueryExecutor e) : super(e);
  $LocalDbManager get managers => $LocalDbManager(this);
  late final $LocalSessionsTable localSessions = $LocalSessionsTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalSyncStateTable localSyncState = $LocalSyncStateTable(this);
  late final $LocalDraftsTable localDrafts = $LocalDraftsTable(this);
  late final $ReadSeqsTable readSeqs = $ReadSeqsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSessions,
    localMessages,
    localSyncState,
    localDrafts,
    readSeqs,
  ];
}

typedef $$LocalSessionsTableCreateCompanionBuilder =
    LocalSessionsCompanion Function({
      required String id,
      Value<String> model,
      Value<String> variant,
      Value<String> preset,
      Value<String> systemPrompt,
      Value<int> maxTurns,
      Value<String> locale,
      Value<String> org,
      Value<String> repo,
      Value<String> branch,
      Value<String> serverTipId,
      Value<int> messageSeq,
      Value<String> lastMessageAt,
      Value<String> lastMessagePreview,
      Value<String> group,
      Value<String> updatedAt,
      Value<int> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$LocalSessionsTableUpdateCompanionBuilder =
    LocalSessionsCompanion Function({
      Value<String> id,
      Value<String> model,
      Value<String> variant,
      Value<String> preset,
      Value<String> systemPrompt,
      Value<int> maxTurns,
      Value<String> locale,
      Value<String> org,
      Value<String> repo,
      Value<String> branch,
      Value<String> serverTipId,
      Value<int> messageSeq,
      Value<String> lastMessageAt,
      Value<String> lastMessagePreview,
      Value<String> group,
      Value<String> updatedAt,
      Value<int> lastSyncedAt,
      Value<int> rowid,
    });

final class $$LocalSessionsTableReferences
    extends BaseReferences<_$LocalDb, $LocalSessionsTable, LocalSession> {
  $$LocalSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalMessagesTable, List<LocalMessage>>
  _localMessagesRefsTable(_$LocalDb db) => MultiTypedResultKey.fromTable(
    db.localMessages,
    aliasName: 'local_sessions__id__local_messages__session_id',
  );

  $$LocalMessagesTableProcessedTableManager get localMessagesRefs {
    final manager = $$LocalMessagesTableTableManager(
      $_db,
      $_db.localMessages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalSessionsTableFilterComposer
    extends Composer<_$LocalDb, $LocalSessionsTable> {
  $$LocalSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxTurns => $composableBuilder(
    column: $table.maxTurns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get org => $composableBuilder(
    column: $table.org,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repo => $composableBuilder(
    column: $table.repo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverTipId => $composableBuilder(
    column: $table.serverTipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageSeq => $composableBuilder(
    column: $table.messageSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localMessagesRefs(
    Expression<bool> Function($$LocalMessagesTableFilterComposer f) f,
  ) {
    final $$LocalMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMessagesTableFilterComposer(
            $db: $db,
            $table: $db.localMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalSessionsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalSessionsTable> {
  $$LocalSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxTurns => $composableBuilder(
    column: $table.maxTurns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get org => $composableBuilder(
    column: $table.org,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repo => $composableBuilder(
    column: $table.repo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverTipId => $composableBuilder(
    column: $table.serverTipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageSeq => $composableBuilder(
    column: $table.messageSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSessionsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalSessionsTable> {
  $$LocalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get variant =>
      $composableBuilder(column: $table.variant, builder: (column) => column);

  GeneratedColumn<String> get preset =>
      $composableBuilder(column: $table.preset, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
    column: $table.systemPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxTurns =>
      $composableBuilder(column: $table.maxTurns, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get org =>
      $composableBuilder(column: $table.org, builder: (column) => column);

  GeneratedColumn<String> get repo =>
      $composableBuilder(column: $table.repo, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<String> get serverTipId => $composableBuilder(
    column: $table.serverTipId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageSeq => $composableBuilder(
    column: $table.messageSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  Expression<T> localMessagesRefs<T extends Object>(
    Expression<T> Function($$LocalMessagesTableAnnotationComposer a) f,
  ) {
    final $$LocalMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.localMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalSessionsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $LocalSessionsTable,
          LocalSession,
          $$LocalSessionsTableFilterComposer,
          $$LocalSessionsTableOrderingComposer,
          $$LocalSessionsTableAnnotationComposer,
          $$LocalSessionsTableCreateCompanionBuilder,
          $$LocalSessionsTableUpdateCompanionBuilder,
          (LocalSession, $$LocalSessionsTableReferences),
          LocalSession,
          PrefetchHooks Function({bool localMessagesRefs})
        > {
  $$LocalSessionsTableTableManager(_$LocalDb db, $LocalSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> variant = const Value.absent(),
                Value<String> preset = const Value.absent(),
                Value<String> systemPrompt = const Value.absent(),
                Value<int> maxTurns = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> org = const Value.absent(),
                Value<String> repo = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<String> serverTipId = const Value.absent(),
                Value<int> messageSeq = const Value.absent(),
                Value<String> lastMessageAt = const Value.absent(),
                Value<String> lastMessagePreview = const Value.absent(),
                Value<String> group = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSessionsCompanion(
                id: id,
                model: model,
                variant: variant,
                preset: preset,
                systemPrompt: systemPrompt,
                maxTurns: maxTurns,
                locale: locale,
                org: org,
                repo: repo,
                branch: branch,
                serverTipId: serverTipId,
                messageSeq: messageSeq,
                lastMessageAt: lastMessageAt,
                lastMessagePreview: lastMessagePreview,
                group: group,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> model = const Value.absent(),
                Value<String> variant = const Value.absent(),
                Value<String> preset = const Value.absent(),
                Value<String> systemPrompt = const Value.absent(),
                Value<int> maxTurns = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> org = const Value.absent(),
                Value<String> repo = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<String> serverTipId = const Value.absent(),
                Value<int> messageSeq = const Value.absent(),
                Value<String> lastMessageAt = const Value.absent(),
                Value<String> lastMessagePreview = const Value.absent(),
                Value<String> group = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSessionsCompanion.insert(
                id: id,
                model: model,
                variant: variant,
                preset: preset,
                systemPrompt: systemPrompt,
                maxTurns: maxTurns,
                locale: locale,
                org: org,
                repo: repo,
                branch: branch,
                serverTipId: serverTipId,
                messageSeq: messageSeq,
                lastMessageAt: lastMessageAt,
                lastMessagePreview: lastMessagePreview,
                group: group,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSessionsTable, LocalSession>(table),
                  $$LocalSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localMessagesRefs) db.localMessages,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localMessagesRefs)
                    await $_getPrefetchedData<
                      LocalSession,
                      $LocalSessionsTable,
                      LocalMessage
                    >(
                      currentTable: table,
                      referencedTable: $$LocalSessionsTableReferences
                          ._localMessagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).localMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $LocalSessionsTable,
      LocalSession,
      $$LocalSessionsTableFilterComposer,
      $$LocalSessionsTableOrderingComposer,
      $$LocalSessionsTableAnnotationComposer,
      $$LocalSessionsTableCreateCompanionBuilder,
      $$LocalSessionsTableUpdateCompanionBuilder,
      (LocalSession, $$LocalSessionsTableReferences),
      LocalSession,
      PrefetchHooks Function({bool localMessagesRefs})
    >;
typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      required String id,
      required String sessionId,
      required String role,
      Value<String> prevId,
      Value<String> createdAt,
      required int orderKey,
      Value<String> status,
      Value<String> partsJson,
      Value<int> rowid,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> role,
      Value<String> prevId,
      Value<String> createdAt,
      Value<int> orderKey,
      Value<String> status,
      Value<String> partsJson,
      Value<int> rowid,
    });

final class $$LocalMessagesTableReferences
    extends BaseReferences<_$LocalDb, $LocalMessagesTable, LocalMessage> {
  $$LocalMessagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalSessionsTable _sessionIdTable(_$LocalDb db) => db.localSessions
      .createAlias('local_messages__session_id__local_sessions__id');

  $$LocalSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$LocalSessionsTableTableManager(
      $_db,
      $_db.localSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalMessagesTableFilterComposer
    extends Composer<_$LocalDb, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prevId => $composableBuilder(
    column: $table.prevId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalSessionsTableFilterComposer get sessionId {
    final $$LocalSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.localSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSessionsTableFilterComposer(
            $db: $db,
            $table: $db.localSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$LocalDb, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prevId => $composableBuilder(
    column: $table.prevId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalSessionsTableOrderingComposer get sessionId {
    final $$LocalSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.localSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.localSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get prevId =>
      $composableBuilder(column: $table.prevId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get partsJson =>
      $composableBuilder(column: $table.partsJson, builder: (column) => column);

  $$LocalSessionsTableAnnotationComposer get sessionId {
    final $$LocalSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.localSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.localSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $LocalMessagesTable,
          LocalMessage,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (LocalMessage, $$LocalMessagesTableReferences),
          LocalMessage,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LocalMessagesTableTableManager(_$LocalDb db, $LocalMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> prevId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> orderKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> partsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion(
                id: id,
                sessionId: sessionId,
                role: role,
                prevId: prevId,
                createdAt: createdAt,
                orderKey: orderKey,
                status: status,
                partsJson: partsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String role,
                Value<String> prevId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                required int orderKey,
                Value<String> status = const Value.absent(),
                Value<String> partsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                role: role,
                prevId: prevId,
                createdAt: createdAt,
                orderKey: orderKey,
                status: status,
                partsJson: partsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMessagesTable, LocalMessage>(table),
                  $$LocalMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$LocalMessagesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$LocalMessagesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $LocalMessagesTable,
      LocalMessage,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (LocalMessage, $$LocalMessagesTableReferences),
      LocalMessage,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$LocalSyncStateTableCreateCompanionBuilder =
    LocalSyncStateCompanion Function({
      required String sessionId,
      Value<String> oldestId,
      Value<bool> hasMore,
      Value<String> tipId,
      Value<int> rowid,
    });
typedef $$LocalSyncStateTableUpdateCompanionBuilder =
    LocalSyncStateCompanion Function({
      Value<String> sessionId,
      Value<String> oldestId,
      Value<bool> hasMore,
      Value<String> tipId,
      Value<int> rowid,
    });

class $$LocalSyncStateTableFilterComposer
    extends Composer<_$LocalDb, $LocalSyncStateTable> {
  $$LocalSyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldestId => $composableBuilder(
    column: $table.oldestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMore => $composableBuilder(
    column: $table.hasMore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipId => $composableBuilder(
    column: $table.tipId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncStateTableOrderingComposer
    extends Composer<_$LocalDb, $LocalSyncStateTable> {
  $$LocalSyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldestId => $composableBuilder(
    column: $table.oldestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMore => $composableBuilder(
    column: $table.hasMore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipId => $composableBuilder(
    column: $table.tipId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncStateTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalSyncStateTable> {
  $$LocalSyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get oldestId =>
      $composableBuilder(column: $table.oldestId, builder: (column) => column);

  GeneratedColumn<bool> get hasMore =>
      $composableBuilder(column: $table.hasMore, builder: (column) => column);

  GeneratedColumn<String> get tipId =>
      $composableBuilder(column: $table.tipId, builder: (column) => column);
}

class $$LocalSyncStateTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $LocalSyncStateTable,
          LocalSyncStateData,
          $$LocalSyncStateTableFilterComposer,
          $$LocalSyncStateTableOrderingComposer,
          $$LocalSyncStateTableAnnotationComposer,
          $$LocalSyncStateTableCreateCompanionBuilder,
          $$LocalSyncStateTableUpdateCompanionBuilder,
          (
            LocalSyncStateData,
            BaseReferences<_$LocalDb, $LocalSyncStateTable, LocalSyncStateData>,
          ),
          LocalSyncStateData,
          PrefetchHooks Function()
        > {
  $$LocalSyncStateTableTableManager(_$LocalDb db, $LocalSyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> oldestId = const Value.absent(),
                Value<bool> hasMore = const Value.absent(),
                Value<String> tipId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncStateCompanion(
                sessionId: sessionId,
                oldestId: oldestId,
                hasMore: hasMore,
                tipId: tipId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<String> oldestId = const Value.absent(),
                Value<bool> hasMore = const Value.absent(),
                Value<String> tipId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncStateCompanion.insert(
                sessionId: sessionId,
                oldestId: oldestId,
                hasMore: hasMore,
                tipId: tipId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncStateTable, LocalSyncStateData>(table),
                  BaseReferences<
                    _$LocalDb,
                    $LocalSyncStateTable,
                    LocalSyncStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $LocalSyncStateTable,
      LocalSyncStateData,
      $$LocalSyncStateTableFilterComposer,
      $$LocalSyncStateTableOrderingComposer,
      $$LocalSyncStateTableAnnotationComposer,
      $$LocalSyncStateTableCreateCompanionBuilder,
      $$LocalSyncStateTableUpdateCompanionBuilder,
      (
        LocalSyncStateData,
        BaseReferences<_$LocalDb, $LocalSyncStateTable, LocalSyncStateData>,
      ),
      LocalSyncStateData,
      PrefetchHooks Function()
    >;
typedef $$LocalDraftsTableCreateCompanionBuilder =
    LocalDraftsCompanion Function({
      required String sessionId,
      Value<String> draftText,
      Value<String> attachmentsJson,
      Value<int> rowid,
    });
typedef $$LocalDraftsTableUpdateCompanionBuilder =
    LocalDraftsCompanion Function({
      Value<String> sessionId,
      Value<String> draftText,
      Value<String> attachmentsJson,
      Value<int> rowid,
    });

class $$LocalDraftsTableFilterComposer
    extends Composer<_$LocalDb, $LocalDraftsTable> {
  $$LocalDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftText => $composableBuilder(
    column: $table.draftText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDraftsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalDraftsTable> {
  $$LocalDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftText => $composableBuilder(
    column: $table.draftText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDraftsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalDraftsTable> {
  $$LocalDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get draftText =>
      $composableBuilder(column: $table.draftText, builder: (column) => column);

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );
}

class $$LocalDraftsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $LocalDraftsTable,
          LocalDraft,
          $$LocalDraftsTableFilterComposer,
          $$LocalDraftsTableOrderingComposer,
          $$LocalDraftsTableAnnotationComposer,
          $$LocalDraftsTableCreateCompanionBuilder,
          $$LocalDraftsTableUpdateCompanionBuilder,
          (
            LocalDraft,
            BaseReferences<_$LocalDb, $LocalDraftsTable, LocalDraft>,
          ),
          LocalDraft,
          PrefetchHooks Function()
        > {
  $$LocalDraftsTableTableManager(_$LocalDb db, $LocalDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> draftText = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDraftsCompanion(
                sessionId: sessionId,
                draftText: draftText,
                attachmentsJson: attachmentsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<String> draftText = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDraftsCompanion.insert(
                sessionId: sessionId,
                draftText: draftText,
                attachmentsJson: attachmentsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDraftsTable, LocalDraft>(table),
                  BaseReferences<_$LocalDb, $LocalDraftsTable, LocalDraft>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $LocalDraftsTable,
      LocalDraft,
      $$LocalDraftsTableFilterComposer,
      $$LocalDraftsTableOrderingComposer,
      $$LocalDraftsTableAnnotationComposer,
      $$LocalDraftsTableCreateCompanionBuilder,
      $$LocalDraftsTableUpdateCompanionBuilder,
      (LocalDraft, BaseReferences<_$LocalDb, $LocalDraftsTable, LocalDraft>),
      LocalDraft,
      PrefetchHooks Function()
    >;
typedef $$ReadSeqsTableCreateCompanionBuilder = ReadSeqsCompanion Function({
  required String sessionId,
  Value<int> seq,
  Value<int> rowid,
});
typedef $$ReadSeqsTableUpdateCompanionBuilder = ReadSeqsCompanion Function({
  Value<String> sessionId,
  Value<int> seq,
  Value<int> rowid,
});

class $$ReadSeqsTableFilterComposer
    extends Composer<_$LocalDb, $ReadSeqsTable> {
  $$ReadSeqsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadSeqsTableOrderingComposer
    extends Composer<_$LocalDb, $ReadSeqsTable> {
  $$ReadSeqsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadSeqsTableAnnotationComposer
    extends Composer<_$LocalDb, $ReadSeqsTable> {
  $$ReadSeqsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$ReadSeqsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $ReadSeqsTable,
          ReadSeq,
          $$ReadSeqsTableFilterComposer,
          $$ReadSeqsTableOrderingComposer,
          $$ReadSeqsTableAnnotationComposer,
          $$ReadSeqsTableCreateCompanionBuilder,
          $$ReadSeqsTableUpdateCompanionBuilder,
          (ReadSeq, BaseReferences<_$LocalDb, $ReadSeqsTable, ReadSeq>),
          ReadSeq,
          PrefetchHooks Function()
        > {
  $$ReadSeqsTableTableManager(_$LocalDb db, $ReadSeqsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadSeqsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadSeqsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadSeqsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ReadSeqsCompanion(sessionId: sessionId, seq: seq, rowid: rowid),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadSeqsCompanion.insert(
                sessionId: sessionId,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadSeqsTable, ReadSeq>(table),
                  BaseReferences<_$LocalDb, $ReadSeqsTable, ReadSeq>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadSeqsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $ReadSeqsTable,
      ReadSeq,
      $$ReadSeqsTableFilterComposer,
      $$ReadSeqsTableOrderingComposer,
      $$ReadSeqsTableAnnotationComposer,
      $$ReadSeqsTableCreateCompanionBuilder,
      $$ReadSeqsTableUpdateCompanionBuilder,
      (ReadSeq, BaseReferences<_$LocalDb, $ReadSeqsTable, ReadSeq>),
      ReadSeq,
      PrefetchHooks Function()
    >;

class $LocalDbManager {
  final _$LocalDb _db;
  $LocalDbManager(this._db);
  $$LocalSessionsTableTableManager get localSessions =>
      $$LocalSessionsTableTableManager(_db, _db.localSessions);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalSyncStateTableTableManager get localSyncState =>
      $$LocalSyncStateTableTableManager(_db, _db.localSyncState);
  $$LocalDraftsTableTableManager get localDrafts =>
      $$LocalDraftsTableTableManager(_db, _db.localDrafts);
  $$ReadSeqsTableTableManager get readSeqs =>
      $$ReadSeqsTableTableManager(_db, _db.readSeqs);
}
