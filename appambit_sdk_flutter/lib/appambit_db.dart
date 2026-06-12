import 'appambit_sdk_flutter_method_channel.dart' as impl;
import 'appambit_sdk_flutter_platform_interface.dart';

class DbStatement {
  final String sql;
  final List<Object?>? params;

  const DbStatement._(this.sql, this.params);

  static DbStatement of(String sql, [List<Object?>? params]) =>
      DbStatement._(sql, params?.isNotEmpty == true ? params : null);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'sql': sql,
        if (params != null) 'params': params,
      };
}

class DbResult {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final int rowsRead;
  final int rowsWritten;
  final String? error;

  bool get hasError => error != null;
  bool get succeeded => error == null;

  const DbResult({
    required this.columns,
    required this.rows,
    required this.rowsRead,
    required this.rowsWritten,
    this.error,
  });

  factory DbResult.fromMap(Map<dynamic, dynamic> map) {
    return DbResult(
      columns: (map['columns'] as List?)?.cast<String>() ?? const [],
      rows: (map['rows'] as List?)
              ?.map((r) => (r as List).cast<dynamic>())
              .toList() ??
          const [],
      rowsRead: (map['rowsRead'] as int?) ?? 0,
      rowsWritten: (map['rowsWritten'] as int?) ?? 0,
      error: map['error'] as String?,
    );
  }

  List<Map<String, dynamic>> toMaps() {
    return rows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < columns.length && i < row.length; i++) {
        map[columns[i]] = row[i];
      }
      return map;
    }).toList();
  }
}

class DbQueryBuilder<T> {
  static const _allowedOps = <String>{
    '=', '!=', '<>', '>', '>=', '<', '<=', 'LIKE', 'NOT LIKE', 'IS', 'IS NOT'
  };

  final String _table;
  final T Function(Map<String, dynamic>)? _fromRow;
  final List<String> _selected = [];
  final List<String> _whereClauses = [];
  final List<Object?> _whereParams = [];
  String? _orderByCol;
  bool _orderByDesc = false;
  int _limitVal = -1;
  int _offsetVal = -1;
  bool _consumed = false;

  DbQueryBuilder._(this._table, {T Function(Map<String, dynamic>)? fromRow})
      : _fromRow = fromRow;

  DbQueryBuilder<T> select(List<String> columns) {
    for (final c in columns) {
      if (!_selected.contains(c)) _selected.add(c);
    }
    return this;
  }

  DbQueryBuilder<T> where(String column, Object? value) {
    if (value == null) {
      _whereClauses.add('${_quoteId(column)} IS NULL');
    } else {
      _whereClauses.add('${_quoteId(column)} = ?');
      _whereParams.add(value);
    }
    return this;
  }

  DbQueryBuilder<T> whereOp(String column, String op, Object? value) {
    final upper = op.toUpperCase();
    if (!_allowedOps.contains(upper)) {
      throw ArgumentError('Operator not allowed: $op');
    }
    if (value == null) {
      final rewritten = upper == '=' ? 'IS NULL' : upper == '!=' || upper == '<>' ? 'IS NOT NULL' : throw ArgumentError("Operator '$op' cannot be used with null");
      _whereClauses.add('${_quoteId(column)} $rewritten');
    } else {
      _whereClauses.add('${_quoteId(column)} $upper ?');
      _whereParams.add(value);
    }
    return this;
  }

  DbQueryBuilder<T> whereIn(String column, List<Object?> values) {
    if (values.isEmpty) {
      _whereClauses.add('1 = 0');
      return this;
    }
    final placeholders = values.map((_) => '?').join(', ');
    _whereClauses.add('${_quoteId(column)} IN ($placeholders)');
    _whereParams.addAll(values);
    return this;
  }

  DbQueryBuilder<T> orderBy(String column) {
    _orderByCol = column;
    _orderByDesc = false;
    return this;
  }

  DbQueryBuilder<T> orderByDesc(String column) {
    _orderByCol = column;
    _orderByDesc = true;
    return this;
  }

  DbQueryBuilder<T> limit(int n) {
    _limitVal = n;
    return this;
  }

  DbQueryBuilder<T> offset(int n) {
    _offsetVal = n;
    return this;
  }

  Future<List<T>> get() async {
    _ensureNotConsumed();
    final sql = _buildSelectSql();
    final raw = await AppAmbitSdkFlutterPlatform.instance
        .dbExecute(sql, _whereParams.isEmpty ? null : List.of(_whereParams));
    final result = DbResult.fromMap(raw);
    if (result.hasError) return const [];
    final maps = result.toMaps();
    if (_fromRow != null) return maps.map(_fromRow).toList();
    return maps as List<T>;
  }

  Future<T?> first() async {
    _ensureNotConsumed();
    final sql = _buildSelectSql(overrideLimit: 1);
    final raw = await AppAmbitSdkFlutterPlatform.instance
        .dbExecute(sql, _whereParams.isEmpty ? null : List.of(_whereParams));
    final result = DbResult.fromMap(raw);
    if (result.hasError) return null;
    final maps = result.toMaps();
    if (maps.isEmpty) return null;
    if (_fromRow != null) return _fromRow(maps.first);
    return maps.first as T?;
  }

  Future<int> count() async {
    _ensureNotConsumed();
    final sb = StringBuffer('SELECT COUNT(*) FROM ${_quoteId(_table)}');
    if (_whereClauses.isNotEmpty) sb.write(' WHERE ${_joinConditions()}');
    final raw = await AppAmbitSdkFlutterPlatform.instance
        .dbExecute(sb.toString(), _whereParams.isEmpty ? null : List.of(_whereParams));
    final result = DbResult.fromMap(raw);
    if (result.hasError || result.rows.isEmpty) return 0;
    final val = result.rows.first.firstOrNull;
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  Future<DbResult> insert(Map<String, Object?> data) async {
    _ensureNotConsumed();
    if (data.isEmpty) throw ArgumentError('data cannot be empty');
    final cols = data.keys.toList();
    final colList = cols.map(_quoteId).join(', ');
    final placeholders = cols.map((_) => '?').join(', ');
    final sql = 'INSERT INTO ${_quoteId(_table)} ($colList) VALUES ($placeholders)';
    final raw = await AppAmbitSdkFlutterPlatform.instance
        .dbExecute(sql, cols.map((c) => data[c]).toList());
    return DbResult.fromMap(raw);
  }

  Future<DbResult> update(Map<String, Object?> data) async {
    _ensureNotConsumed();
    if (_whereClauses.isEmpty) {
      throw StateError('update() without where() would affect all rows. Use AppAmbitDb.execute() for intentional full-table updates.');
    }
    final cols = data.keys.toList();
    final setClauses = cols.map((c) => '${_quoteId(c)} = ?').join(', ');
    final sql = 'UPDATE ${_quoteId(_table)} SET $setClauses WHERE ${_joinConditions()}';
    final params = [...cols.map((c) => data[c]), ..._whereParams];
    final raw = await AppAmbitSdkFlutterPlatform.instance.dbExecute(sql, params);
    return DbResult.fromMap(raw);
  }

  Future<DbResult> delete() async {
    _ensureNotConsumed();
    if (_whereClauses.isEmpty) {
      throw StateError('delete() without where() would delete all rows. Use AppAmbitDb.execute() for intentional full-table deletes.');
    }
    final sql = 'DELETE FROM ${_quoteId(_table)} WHERE ${_joinConditions()}';
    final raw = await AppAmbitSdkFlutterPlatform.instance
        .dbExecute(sql, _whereParams.isEmpty ? null : List.of(_whereParams));
    return DbResult.fromMap(raw);
  }

  String _buildSelectSql({int overrideLimit = -1}) {
    final cols = _selected.isEmpty ? '*' : _selected.map(_quoteId).join(', ');
    final sb = StringBuffer('SELECT $cols FROM ${_quoteId(_table)}');
    if (_whereClauses.isNotEmpty) sb.write(' WHERE ${_joinConditions()}');
    if (_orderByCol != null) {
      sb.write(' ORDER BY ${_quoteId(_orderByCol!)}');
      if (_orderByDesc) sb.write(' DESC');
    }
    final effLimit = overrideLimit > 0 ? overrideLimit : _limitVal;
    if (effLimit >= 0) sb.write(' LIMIT $effLimit');
    if (_offsetVal >= 0) sb.write(' OFFSET $_offsetVal');
    return sb.toString();
  }

  String _joinConditions() => _whereClauses.join(' AND ');

  void _ensureNotConsumed() {
    if (_consumed) {
      throw StateError('DbQueryBuilder already executed. Create a new builder via AppAmbitDb.from().');
    }
    _consumed = true;
  }

  static String _quoteId(String name) {
    if (name.isEmpty) throw ArgumentError('Identifier cannot be empty');
    return '"${name.replaceAll('"', '""')}"';
  }
}

class AppAmbitDb {
  AppAmbitDb._();

  static void _ensureRegistered() {
    impl.registerMethodChannelImplementation();
  }

  static Future<DbResult> execute(String sql, [List<Object?>? params]) async {
    _ensureRegistered();
    final raw =
        await AppAmbitSdkFlutterPlatform.instance.dbExecute(sql, params);
    return DbResult.fromMap(raw);
  }

  static Future<List<DbResult>> batch(List<DbStatement> statements) async {
    _ensureRegistered();
    final maps = await AppAmbitSdkFlutterPlatform.instance.dbBatch(
      statements.map((s) => s.toMap()).toList(),
      inTransaction: false,
    );
    return maps.map(DbResult.fromMap).toList();
  }

  static Future<List<DbResult>> batchInTransaction(
      List<DbStatement> statements) async {
    _ensureRegistered();
    final maps = await AppAmbitSdkFlutterPlatform.instance.dbBatch(
      statements.map((s) => s.toMap()).toList(),
      inTransaction: true,
    );
    return maps.map(DbResult.fromMap).toList();
  }

  static DbQueryBuilder<Map<String, dynamic>> from(String table) {
    _ensureRegistered();
    return DbQueryBuilder<Map<String, dynamic>>._(table);
  }

  static DbQueryBuilder<T> fromMapped<T>(
    String table, {
    required T Function(Map<String, dynamic>) fromRow,
  }) {
    _ensureRegistered();
    return DbQueryBuilder<T>._(table, fromRow: fromRow);
  }
}
