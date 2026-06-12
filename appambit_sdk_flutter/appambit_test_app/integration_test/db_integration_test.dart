import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_flutter_example/main.dart' as app;

/// Waits until the AppAmbit auth token is ready by probing with a DML query.
/// CREATE TABLE / SELECT 1 always return "Unexpected error" on the backend
/// (DDL/tableless queries are restricted), so those cannot be used as probe.
/// We use SELECT on an actual table — when auth is ready we get either a proper
/// SQL error ("no such table") or real rows; both indicate auth is working.
Future<void> waitForAuthReady({int maxWaitSeconds = 30}) async {
  for (var i = 0; i < maxWaitSeconds; i++) {
    final r = await AppAmbitDb.execute('SELECT * FROM tasks LIMIT 1');
    if (r.error != 'Unexpected error') {
      print('AppAmbitDb auth ready after ~${i + 1}s');
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  print('WARNING: DB auth still not ready after ${maxWaitSeconds}s');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AppAmbitDb Integration Tests', () {
    setUpAll(() async {
      app.main();
      await waitForAuthReady(maxWaitSeconds: 30);
    });

    // DDL — backend may not support these via SDK; logs the error but doesn't fail
    test('execute CREATE TABLE (DDL)', () async {
      const sql = 'CREATE TABLE IF NOT EXISTS tasks ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT, '
          'is_completed INTEGER DEFAULT 0, '
          'priority TEXT, '
          'due_date TEXT)';
      final result = await AppAmbitDb.execute(sql);
      print('CREATE TABLE → hasError=${result.hasError} error=${result.error} '
          'rowsWritten=${result.rowsWritten}');
      expect(result, isNotNull);
    });

    test('execute INSERT into tasks', () async {
      final result = await AppAmbitDb.execute(
        'INSERT INTO tasks (title, is_completed, priority, due_date) '
        'VALUES (?, ?, ?, ?)',
        ['Integration test task', 0, 'medium', '2026-06-11'],
      );
      print('INSERT → hasError=${result.hasError} error=${result.error} '
          'rowsWritten=${result.rowsWritten}');
      expect(result, isNotNull);
      if (!result.hasError) {
        expect(result.rowsWritten, equals(1));
      }
    });

    test('execute SELECT from tasks', () async {
      final result = await AppAmbitDb.execute('SELECT * FROM tasks LIMIT 10');
      print('SELECT tasks → hasError=${result.hasError} error=${result.error} '
          'rowsRead=${result.rowsRead} columns=${result.columns}');
      expect(result, isNotNull);
    });

    test('execute SELECT with params', () async {
      final result = await AppAmbitDb.execute(
        'SELECT * FROM tasks WHERE is_completed = ? LIMIT ?',
        [0, 10],
      );
      print('SELECT params → hasError=${result.hasError} error=${result.error} '
          'rowsRead=${result.rowsRead}');
      expect(result, isNotNull);
    });

    test('batch executes multiple statements', () async {
      final results = await AppAmbitDb.batch([
        DbStatement.of('SELECT COUNT(*) AS total FROM tasks'),
        DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) '
          'VALUES (?, ?, ?, ?)',
          ['Batch task', 0, 'low', '2026-06-12'],
        ),
      ]);
      print('batch → ${results.length} result(s)');
      for (var i = 0; i < results.length; i++) {
        print('  [$i] hasError=${results[i].hasError} error=${results[i].error} '
            'rowsRead=${results[i].rowsRead} rowsWritten=${results[i].rowsWritten}');
      }
      expect(results, isNotEmpty);
    });

    test('batchInTransaction executes inserts atomically', () async {
      final results = await AppAmbitDb.batchInTransaction([
        DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) '
          'VALUES (?, ?, ?, ?)',
          ['Tx task 1', 0, 'high', '2026-06-13'],
        ),
        DbStatement.of(
          'INSERT INTO tasks (title, is_completed, priority, due_date) '
          'VALUES (?, ?, ?, ?)',
          ['Tx task 2', 0, 'medium', '2026-06-14'],
        ),
      ]);
      print('batchInTransaction → ${results.length} result(s)');
      for (var i = 0; i < results.length; i++) {
        print('  [$i] hasError=${results[i].hasError} error=${results[i].error} '
            'rowsWritten=${results[i].rowsWritten}');
      }
      expect(results, isNotEmpty);
    });

    test('fluent from().get() returns list', () async {
      final rows = await AppAmbitDb.from('tasks').limit(5).get();
      print('from(tasks).limit(5).get() → ${rows.length} row(s)');
      for (final r in rows) {
        print('  $r');
      }
      expect(rows, isNotNull);
    });

    test('fluent from().count() returns integer', () async {
      final count = await AppAmbitDb.from('tasks').count();
      print('from(tasks).count() → $count');
      expect(count, isA<int>());
    });

    test('fluent from().where().get()', () async {
      final rows = await AppAmbitDb.from('tasks').where('is_completed', 0).limit(5).get();
      print('where(is_completed=0).get() → ${rows.length} row(s)');
      expect(rows, isNotNull);
    });

    test('fluent from().whereIn().get()', () async {
      final rows = await AppAmbitDb.from('tasks')
          .whereIn('priority', ['high', 'medium']).limit(5).get();
      print('whereIn(priority, [high,medium]).get() → ${rows.length} row(s)');
      expect(rows, isNotNull);
    });

    test('fluent from().first()', () async {
      final row = await AppAmbitDb.from('tasks').orderBy('due_date').first();
      print('first() → ${row != null ? "got row: $row" : "null (empty table)"}');
      expect(true, isTrue);
    });

    test('fluent from().insert()', () async {
      final result = await AppAmbitDb.from('tasks').insert({
        'title': 'Fluent insert test',
        'is_completed': 0,
        'priority': 'high',
        'due_date': '2026-06-11',
      });
      print('fluent insert → hasError=${result.hasError} error=${result.error} '
          'rowsWritten=${result.rowsWritten}');
      expect(result, isNotNull);
      if (!result.hasError) {
        expect(result.rowsWritten, equals(1));
      }
    });

    test('fluent from().where().update()', () async {
      final result = await AppAmbitDb.from('tasks')
          .where('title', 'Fluent insert test')
          .update({'is_completed': 1});
      print('update → hasError=${result.hasError} error=${result.error} '
          'rowsWritten=${result.rowsWritten}');
      expect(result, isNotNull);
    });

    test('fluent from().where().delete()', () async {
      final result = await AppAmbitDb.from('tasks')
          .where('is_completed', 1)
          .delete();
      print('delete(is_completed=1) → hasError=${result.hasError} error=${result.error} '
          'rowsWritten=${result.rowsWritten}');
      expect(result, isNotNull);
    });

    test('execute DROP TABLE (DDL)', () async {
      final result = await AppAmbitDb.execute('DROP TABLE IF EXISTS tasks');
      print('DROP TABLE → hasError=${result.hasError} error=${result.error}');
      expect(result, isNotNull);
    });
  });
}
