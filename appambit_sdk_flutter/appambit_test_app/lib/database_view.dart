import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_flutter_example/models/task_model.dart';
import 'package:flutter/material.dart';

typedef _Demo = ({String label, Future<void> Function() action});

class DatabaseView extends StatefulWidget {
  const DatabaseView({super.key});

  @override
  State<DatabaseView> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  final TextEditingController _sqlCtrl = TextEditingController(
    text: 'SELECT * FROM tasks LIMIT 10',
  );

  late final List<_Demo> _demos;
  int _selectedIndex = 0;
  bool _loading = false;
  String? _statusMsg;
  bool _statusIsError = false;
  List<String> _columns = [];
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _demos = _buildDemos();
  }

  @override
  void dispose() {
    _sqlCtrl.dispose();
    super.dispose();
  }

  List<_Demo> _buildDemos() => [
        (label: 'Raw SQL → execute(sql)', action: _runExecute),
        (label: 'Raw SQL → execute(sql, params)', action: _runExecuteParams),
        (label: 'Schema → DROP TABLE tasks', action: _runDropTable),
        (label: 'Batch → batch()', action: _runBatch),
        (label: 'Batch → batchInTransaction()', action: _runBatchInTransaction),
        (
          label: 'Fluent SELECT → select+where+orderByDesc+limit',
          action: _runFluentSelect
        ),
        (label: 'Fluent SELECT → where(col, val)', action: _runWhereEquality),
        (label: 'Fluent SELECT → whereIn()', action: _runWhereIn),
        (label: 'Fluent SELECT → limit+offset', action: _runOffset),
        (label: 'Fluent SELECT → first()', action: _runFirst),
        (label: 'Fluent SELECT → count()', action: _runCount),
        (label: 'Fluent WRITE → insert()', action: _runInsert),
        (label: 'Fluent WRITE → insert() high priority', action: _runInsertHigh),
        (label: 'Fluent WRITE → insert() raw SQL', action: _runInsertRawSQL),
        (label: 'Fluent WRITE → insert many (batch)', action: _runInsertMany),
        (label: 'Fluent WRITE → update()', action: _runUpdate),
        (label: 'Fluent WRITE → delete()', action: _runDelete),
        (
          label: 'Typed Model → fromMapped(tasks, TaskModel)',
          action: _runTypedModel
        ),
        (label: 'Preset → List tables', action: _runPresetTables),
        (
          label: "Preset → SELECT * WHERE priority='high'",
          action: _runPresetHighPriority
        ),
      ];

  Future<void> _onRun() async {
    final demo = _demos[_selectedIndex];
    setState(() {
      _loading = true;
      _statusMsg = 'Running: ${demo.label}';
      _statusIsError = false;
    });
    try {
      await demo.action();
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showStatus(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusMsg = msg;
      _statusIsError = isError;
    });
  }

  void _showRows(List<String> cols, List<Map<String, dynamic>> rows) {
    if (!mounted) return;
    setState(() {
      _columns = cols;
      _rows = rows;
    });
  }




  Future<void> _runDropTable() async {
    const sql = 'DROP TABLE IF EXISTS tasks';
    _sqlCtrl.text = sql;
    final result = await AppAmbitDb.execute(sql);
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('DROP TABLE tasks — OK');
    _showRows([], []);
  }

  // ── Raw Execute ─────────────────────────────────────────────────────────────

  Future<void> _runExecute() async {
    var sql = _sqlCtrl.text.trim();
    if (sql.isEmpty) {
      sql = 'SELECT * FROM tasks LIMIT 10';
      _sqlCtrl.text = sql;
    }
    final result = await AppAmbitDb.execute(sql);
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus(
        'execute(sql) — rows_read=${result.rowsRead}  rows_written=${result.rowsWritten}');
    _showRows(result.columns, result.toMaps());
  }

  Future<void> _runExecuteParams() async {
    final result = await AppAmbitDb.execute(
      'SELECT * FROM tasks WHERE is_completed = ? LIMIT ?',
      [0, 10],
    );
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('execute(sql, 0, 10) — rows_read=${result.rowsRead}');
    _showRows(result.columns, result.toMaps());
  }

  // ── Batch ───────────────────────────────────────────────────────────────────

  Future<void> _runBatch() async {
    final results = await AppAmbitDb.batch([
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Buy coffee', 0, 'low', '2026-06-10']),
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Review PR', 0, 'high', '2026-06-05']),
      DbStatement.of('SELECT COUNT(*) AS total FROM tasks'),
    ]);
    final firstError = results.where((r) => r.hasError).firstOrNull;
    if (firstError != null) {
      _showStatus('Error: ${firstError.error}', isError: true);
      return;
    }
    final written = results.fold(0, (s, r) => s + r.rowsWritten);
    _showStatus(
        'batch() — $written row(s) written, ${results.length} statements, no transaction');
    _showRows(
      ['statement', 'rows_written', 'rows_read'],
      results.indexed
          .map((e) => {
                'statement': e.$1 + 1,
                'rows_written': e.$2.rowsWritten,
                'rows_read': e.$2.rowsRead,
              })
          .toList(),
    );
  }

  Future<void> _runBatchInTransaction() async {
    final results = await AppAmbitDb.batchInTransaction([
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Team meeting', 0, 'high', '2026-06-06']),
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Prepare agenda', 0, 'medium', '2026-06-06']),
    ]);
    final firstError = results.where((r) => r.hasError).firstOrNull;
    if (firstError != null) {
      _showStatus('Error: ${firstError.error}', isError: true);
      return;
    }
    final written = results.fold(0, (s, r) => s + r.rowsWritten);
    _showStatus(
        'batchInTransaction() — $written row(s) written, rolled back on any failure');
    _showRows(
      ['statement', 'rows_written'],
      results.indexed
          .map((e) => {'statement': e.$1 + 1, 'rows_written': e.$2.rowsWritten})
          .toList(),
    );
  }

  // ── Fluent SELECT ────────────────────────────────────────────────────────────

  Future<void> _runFluentSelect() async {
    final maps = await AppAmbitDb.from('tasks')
        .select(['id', 'title', 'priority', 'due_date'])
        .whereOp('is_completed', '=', 0)
        .orderByDesc('due_date')
        .limit(5)
        .get();
    _showStatus(maps.isEmpty
        ? 'No pending tasks'
        : 'from().select().where().orderByDesc().limit(5) — ${maps.length} row(s)');
    if (maps.isNotEmpty) _showRows(maps.first.keys.toList(), maps);
  }

  Future<void> _runWhereEquality() async {
    final maps = await AppAmbitDb.from('tasks').where('is_completed', 0).get();
    _showStatus(maps.isEmpty
        ? 'No pending tasks'
        : 'where(is_completed, 0) — ${maps.length} row(s)');
    _showRows(maps.isNotEmpty ? maps.first.keys.toList() : [], maps);
  }

  Future<void> _runWhereIn() async {
    final maps = await AppAmbitDb.from('tasks')
        .whereIn('priority', ['high', 'medium'])
        .orderBy('due_date')
        .get();
    _showStatus(maps.isEmpty
        ? 'No high/medium tasks'
        : 'whereIn(priority, [high,medium]) — ${maps.length} row(s)');
    _showRows(maps.isNotEmpty ? maps.first.keys.toList() : [], maps);
  }

  Future<void> _runOffset() async {
    final maps = await AppAmbitDb.from('tasks')
        .orderBy('due_date')
        .limit(5)
        .offset(0)
        .get();
    _showStatus(maps.isEmpty
        ? 'No tasks'
        : 'limit(5).offset(0) — page 1, ${maps.length} row(s)');
    _showRows(maps.isNotEmpty ? maps.first.keys.toList() : [], maps);
  }

  Future<void> _runFirst() async {
    final item = await AppAmbitDb.from('tasks')
        .whereOp('is_completed', '=', 0)
        .orderBy('due_date')
        .first();
    if (item == null) {
      _showStatus('first() — no pending tasks');
      _showRows([], []);
      return;
    }
    _showStatus('first() — next task to expire');
    _showRows(item.keys.toList(), [item]);
  }

  Future<void> _runCount() async {
    final count =
        await AppAmbitDb.from('tasks').where('is_completed', 0).count();
    _showStatus('count() — $count pending task(s)');
    _showRows(['pending_tasks'], [
      {'pending_tasks': count}
    ]);
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  Future<void> _runInsert() async {
    final result = await AppAmbitDb.from('tasks').insert({
      'title': 'New task',
      'is_completed': 0,
      'priority': 'medium',
      'due_date': DateTime.now().toUtc().add(const Duration(days: 7)).toString().substring(0, 10),
    });
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('insert() — rows_written=${result.rowsWritten}');
    _showRows(['rows_written'], [
      {'rows_written': result.rowsWritten}
    ]);
  }

  Future<void> _runInsertHigh() async {
    final result = await AppAmbitDb.from('tasks').insert({
      'title': 'Fix critical bug',
      'is_completed': 0,
      'priority': 'high',
      'due_date': DateTime.now().toUtc().add(const Duration(days: 1)).toString().substring(0, 10),
    });
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('insert() high priority — rows_written=${result.rowsWritten}');
    _showRows(['rows_written'], [{'rows_written': result.rowsWritten}]);
  }

  Future<void> _runInsertRawSQL() async {
    const sql =
        'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)';
    final params = [
      'Raw SQL task',
      0,
      'low',
      DateTime.now().toUtc().add(const Duration(days: 3)).toString().substring(0, 10),
    ];
    _sqlCtrl.text = sql;
    final result = await AppAmbitDb.execute(sql, params);
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('insert() raw SQL — rows_written=${result.rowsWritten}');
    _showRows(['rows_written'], [{'rows_written': result.rowsWritten}]);
  }

  Future<void> _runInsertMany() async {
    final today = DateTime.now().toUtc().toString().substring(0, 10);
    final results = await AppAmbitDb.batchInTransaction([
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Task Alpha', 0, 'high', today]),
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Task Beta', 0, 'medium', today]),
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Task Gamma', 0, 'low', today]),
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Task Delta', 0, 'high', today]),
      DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) VALUES (?, ?, ?, ?)',
          ['Task Epsilon', 0, 'medium', today]),
    ]);
    final firstError = results.where((r) => r.hasError).firstOrNull;
    if (firstError != null) {
      _showStatus('Error: ${firstError.error}', isError: true);
      return;
    }
    final written = results.fold(0, (s, r) => s + r.rowsWritten);
    _showStatus('insert many (batch) — $written row(s) written in transaction');
    _showRows(
      ['statement', 'rows_written'],
      results.indexed
          .map((e) => {'statement': e.$1 + 1, 'rows_written': e.$2.rowsWritten})
          .toList(),
    );
  }

  Future<void> _runUpdate() async {
    final result = await AppAmbitDb.from('tasks')
        .where('title', 'New task')
        .update({'is_completed': 1});
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('update() — rows_written=${result.rowsWritten}  (run insert first)');
    _showRows(['rows_written'], [
      {'rows_written': result.rowsWritten}
    ]);
  }

  Future<void> _runDelete() async {
    final result =
        await AppAmbitDb.from('tasks').where('is_completed', 1).delete();
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('delete() — rows_written=${result.rowsWritten}  (run update first)');
    _showRows(['rows_written'], [
      {'rows_written': result.rowsWritten}
    ]);
  }

  // ── Typed model ──────────────────────────────────────────────────────────────

  Future<void> _runTypedModel() async {
    final tasks = await AppAmbitDb.fromMapped<TaskModel>(
      'tasks',
      fromRow: TaskModel.fromMap,
    )
        .select(['id', 'title', 'is_completed', 'priority', 'due_date'])
        .limit(5)
        .get();
    _showStatus('fromMapped<TaskModel>() — ${tasks.length} typed row(s)');
    _showRows(
      ['id', 'title', 'isCompleted', 'priority', 'dueDate'],
      tasks
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'isCompleted': t.isCompleted,
                'priority': t.priority,
                'dueDate': t.dueDate,
              })
          .toList(),
    );
  }

  // ── Presets ──────────────────────────────────────────────────────────────────

  Future<void> _runPresetTables() async {
    const q = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name";
    _sqlCtrl.text = q;
    final result = await AppAmbitDb.execute(q);
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus('List tables — ${result.rowsRead} table(s) found');
    _showRows(result.columns, result.toMaps());
  }

  Future<void> _runPresetHighPriority() async {
    const q = "SELECT * FROM tasks WHERE priority = 'high'";
    _sqlCtrl.text = q;
    final result = await AppAmbitDb.execute(q);
    if (result.hasError) {
      _showStatus('Error: ${result.error}', isError: true);
      return;
    }
    _showStatus("tasks WHERE priority='high' — ${result.rowsRead} row(s)");
    _showRows(result.columns, result.toMaps());
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _sqlCtrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'SELECT * FROM tasks LIMIT 10',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedIndex,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _demos.indexed
                            .map((e) => DropdownMenuItem<int>(
                                  value: e.$1,
                                  child: Text(e.$2.label,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedIndex = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _onRun,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('▶ Run'),
                  ),
                ],
              ),
              if (_statusMsg != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _statusIsError
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusMsg!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _statusIsError
                          ? const Color(0xFFC62828)
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
        const Divider(height: 12, thickness: 1),
        Expanded(
          child: _rows.isEmpty
              ? const Center(
                  child: Text('(no rows)',
                      style: TextStyle(color: Colors.grey, fontFamily: 'monospace')))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final row = _rows[i];
                    final line = _columns
                        .map((c) =>
                            '$c: ${row[c]?.toString() ?? 'null'}')
                        .join('   |   ');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          line,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF212121)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
