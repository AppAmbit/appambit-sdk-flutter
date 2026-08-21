import 'dart:async';
import 'dart:convert';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:appambit_sdk_push_notifications/appambit_sdk_push_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum _CloudCodeAction {
  setupDatabase,
  createTask,
  listTasks,
  completeTask,
  deleteTask,
  createOrder,
  summary,
  publishPost,
  readPosts,
  push,
  inspector,
  jsonValues,
  nullContract,
  responseShapes,
  controlledError,
  timeout,
  runtimeContext,
}

class _CloudCodeDemo {
  const _CloudCodeDemo({
    required this.id,
    required this.section,
    required this.title,
    required this.slug,
    required this.detail,
    required this.prerequisite,
    required this.action,
    this.confirm = false,
  });

  final String id;
  final String section;
  final String title;
  final String slug;
  final String detail;
  final String prerequisite;
  final _CloudCodeAction action;
  final bool confirm;
}

class _CloudCodeSummary {
  const _CloudCodeSummary({
    required this.taskCount,
    required this.databaseAvailable,
    required this.databaseTablesReady,
    required this.posts,
    required this.platform,
  });

  final int? taskCount;
  final bool databaseAvailable;
  final bool databaseTablesReady;
  final List<Object?>? posts;
  final String platform;

  factory _CloudCodeSummary.fromJson(Object? value) {
    final map = value is Map ? value : const <Object?, Object?>{};
    final posts = map['posts'];
    return _CloudCodeSummary(
      taskCount: _asInt(map['task_count']),
      databaseAvailable: map['database_available'] == true,
      databaseTablesReady: map['database_tables_ready'] == true,
      posts: posts is List ? List<Object?>.from(posts) : null,
      platform: map['platform']?.toString() ?? '',
    );
  }
}

typedef _RequestConfiguration = ({
  String slug,
  CloudCodeHttpMethod method,
  Map<String, String>? query,
  Map<String, dynamic>? body,
  Map<String, String> headers,
});

class CloudCodeView extends StatefulWidget {
  const CloudCodeView({super.key});

  @override
  State<CloudCodeView> createState() => _CloudCodeViewState();
}

class _CloudCodeViewState extends State<CloudCodeView> {
  final TextEditingController _taskTitleController = TextEditingController(
    text: 'Buy coffee',
  );
  final TextEditingController _taskIdController = TextEditingController();
  final TextEditingController _postUuidController = TextEditingController();
  final TextEditingController _publishTitleController = TextEditingController(
    text: 'Cloud Code sample post',
  );
  final TextEditingController _publishBodyController = TextEditingController(
    text: 'Published through an HTTP Cloud Function.',
  );

  late final List<_CloudCodeDemo> _demos = _buildDemos();
  bool _isRunning = false;
  bool _isVerifyingBackend = false;
  bool _databaseAvailable = false;
  bool _databaseTablesReady = false;
  String _databaseStatus = 'Not available';
  String _cmsStatus = 'Not available';
  String? _lastResultDemoId;
  String _resultTitle = 'Latest result';
  String _resultText = 'Run a function to see its response here.';
  bool _resultExpanded = true;
  CloudCodeRequest<dynamic>? _pendingRequest;

  String get _platformSuffix =>
      defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';

  String get _sampleClient => 'flutter-$_platformSuffix';

  @override
  void initState() {
    super.initState();
    unawaited(_verifyBackend());
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskIdController.dispose();
    _postUuidController.dispose();
    _publishTitleController.dispose();
    _publishBodyController.dispose();
    super.dispose();
  }

  List<_CloudCodeDemo> _buildDemos() {
    final suffix = _platformSuffix;
    return [
      _CloudCodeDemo(
        id: 'setup-database',
        section: 'Database',
        title: 'Setup database',
        slug: 'cloud-demo-setup-database-$suffix',
        detail: 'Provision the tables used by the Database examples.',
        prerequisite: 'Existing linked Database',
        action: _CloudCodeAction.setupDatabase,
      ),
      _CloudCodeDemo(
        id: 'create-task',
        section: 'Database',
        title: 'Create task',
        slug: 'cloud-demo-create-task-$suffix',
        detail: 'Insert a task for the signed-in consumer.',
        prerequisite: 'cloud_demo_tasks_$suffix',
        action: _CloudCodeAction.createTask,
      ),
      _CloudCodeDemo(
        id: 'list-tasks',
        section: 'Database',
        title: 'List tasks',
        slug: 'cloud-demo-list-tasks-$suffix',
        detail: 'Read the current consumer\'s tasks.',
        prerequisite: 'cloud_demo_tasks_$suffix',
        action: _CloudCodeAction.listTasks,
      ),
      _CloudCodeDemo(
        id: 'complete-task',
        section: 'Database',
        title: 'Complete task',
        slug: 'cloud-demo-complete-task-$suffix',
        detail: 'Update one task with consumer ownership.',
        prerequisite: 'Task id',
        action: _CloudCodeAction.completeTask,
      ),
      _CloudCodeDemo(
        id: 'delete-task',
        section: 'Database',
        title: 'Delete task',
        slug: 'cloud-demo-delete-task-$suffix',
        detail: 'Delete one task owned by the consumer.',
        prerequisite: 'Task id + confirmation',
        action: _CloudCodeAction.deleteTask,
        confirm: true,
      ),
      _CloudCodeDemo(
        id: 'order',
        section: 'Database',
        title: 'Create idempotent order',
        slug: 'cloud-demo-create-order-$suffix',
        detail: 'Create an order without duplicate idempotency keys.',
        prerequisite: 'cloud_demo_orders_$suffix',
        action: _CloudCodeAction.createOrder,
      ),
      _CloudCodeDemo(
        id: 'summary',
        section: 'Database',
        title: 'Dashboard summary',
        slug: 'cloud-demo-dashboard-summary-$suffix',
        detail: 'Combine Database and CMS in one typed response.',
        prerequisite: 'Database + CMS',
        action: _CloudCodeAction.summary,
      ),
      _CloudCodeDemo(
        id: 'create-sample-content',
        section: 'CMS',
        title: 'Create sample content',
        slug: 'cloud-demo-publish-post-$suffix',
        detail: 'Create a published CMS entry.',
        prerequisite: 'Confirmation',
        action: _CloudCodeAction.publishPost,
        confirm: true,
      ),
      _CloudCodeDemo(
        id: 'read-posts',
        section: 'CMS',
        title: 'Read CMS posts',
        slug: 'cloud-demo-read-posts-$suffix',
        detail: 'List published entries using only CMS data.',
        prerequisite: 'cloud_code_demo_posts_$suffix',
        action: _CloudCodeAction.readPosts,
      ),
      _CloudCodeDemo(
        id: 'push',
        section: 'Push',
        title: 'Send push notification',
        slug: 'cloud-demo-send-push-$suffix',
        detail: 'Send a notification to the target platform consumers.',
        prerequisite: 'Permission + push credentials',
        action: _CloudCodeAction.push,
        confirm: true,
      ),
      const _CloudCodeDemo(
        id: 'inspector',
        section: 'HTTP',
        title: 'Inspect HTTP context',
        slug: 'cloud-demo-http-inspector',
        detail: 'Inspect method, query, body and consumer context.',
        prerequisite: 'HTTP trigger',
        action: _CloudCodeAction.inspector,
      ),
      const _CloudCodeDemo(
        id: 'json-values',
        section: 'HTTP',
        title: 'JSON values',
        slug: 'cloud-demo-json-values',
        detail: 'Return common JSON value types.',
        prerequisite: 'HTTP trigger',
        action: _CloudCodeAction.jsonValues,
      ),
      const _CloudCodeDemo(
        id: 'null-contract',
        section: 'HTTP',
        title: 'Null contract',
        slug: 'cloud-demo-null-contract',
        detail: 'Compare raw null and an explicit value.',
        prerequisite: 'HTTP trigger',
        action: _CloudCodeAction.nullContract,
      ),
      const _CloudCodeDemo(
        id: 'response-shapes',
        section: 'HTTP',
        title: 'HTTP response shapes',
        slug: 'cloud-demo-response-shapes',
        detail: 'Demonstrate statuses, body and headers.',
        prerequisite: 'HTTP trigger',
        action: _CloudCodeAction.responseShapes,
      ),
      const _CloudCodeDemo(
        id: 'controlled-error',
        section: 'HTTP',
        title: 'Controlled error',
        slug: 'cloud-demo-error-response',
        detail: 'Return a safe client error response.',
        prerequisite: 'HTTP trigger',
        action: _CloudCodeAction.controlledError,
      ),
      const _CloudCodeDemo(
        id: 'timeout',
        section: 'HTTP',
        title: 'Backend timeout',
        slug: 'cloud-demo-timeout-10s',
        detail: 'Observe the configured function timeout.',
        prerequisite: 'Function timeout = 10 s',
        action: _CloudCodeAction.timeout,
      ),
      const _CloudCodeDemo(
        id: 'runtime-context',
        section: 'HTTP',
        title: 'Runtime context',
        slug: 'cloud-demo-runtime-context',
        detail: 'Use environment values, secrets and logs safely.',
        prerequisite: 'DEMO_REGION + DEMO_SECRET',
        action: _CloudCodeAction.runtimeContext,
      ),
    ];
  }

  Future<void> _verifyBackend() async {
    if (_isVerifyingBackend) return;
    setState(() {
      _isVerifyingBackend = true;
      _databaseStatus = 'Checking...';
      _cmsStatus = 'Checking...';
    });

    final demo = _demos.firstWhere(
      (item) => item.action == _CloudCodeAction.summary,
    );
    final request = CloudCode.callTyped<_CloudCodeSummary>(
      demo.slug,
      method: CloudCodeHttpMethod.get,
      headers: _headers,
      fromJson: _CloudCodeSummary.fromJson,
    );
    _pendingRequest = request;
    try {
      final result = await request.future;
      if (!mounted) return;
      setState(() {
        _databaseAvailable = result.data?.databaseAvailable == true;
        _databaseTablesReady = result.data?.databaseTablesReady == true;
        _databaseStatus = _databaseStatusText(
          _databaseAvailable,
          _databaseTablesReady,
        );
        _cmsStatus = result.data?.posts != null ? 'Available' : 'Not available';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _databaseAvailable = false;
        _databaseTablesReady = false;
        _databaseStatus = 'Not available';
        _cmsStatus = 'Not available';
      });
    } finally {
      if (identical(_pendingRequest, request)) _pendingRequest = null;
      if (mounted) setState(() => _isVerifyingBackend = false);
    }
  }

  String _databaseStatusText(bool available, bool tablesReady) {
    if (!available) return 'Not available';
    return tablesReady ? 'Tables ready' : 'Available';
  }

  Map<String, String> get _headers => {'X-Sample-Client': _sampleClient};

  Future<void> _runOrConfirm(_CloudCodeDemo demo) async {
    if (demo.action == _CloudCodeAction.setupDatabase &&
        (!_databaseAvailable || _databaseTablesReady)) {
      return;
    }
    if (demo.confirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Cloud Code action'),
          content: const Text(
            'This calls a real backend operation. Continue only if the required service is configured.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Run'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _run(demo);
  }

  Future<void> _run(_CloudCodeDemo demo) async {
    if (_isRunning || _isVerifyingBackend) return;
    final taskId = int.tryParse(_taskIdController.text.trim());
    if ((demo.action == _CloudCodeAction.completeTask ||
            demo.action == _CloudCodeAction.deleteTask) &&
        taskId == null) {
      _showResult(demo.id, 'Input required', 'Enter a numeric task id first.');
      return;
    }

    setState(() {
      _isRunning = true;
      _lastResultDemoId = demo.id;
      _resultTitle = 'Result - ${demo.slug}';
      _resultText = 'Calling ${demo.slug}...';
      _resultExpanded = true;
    });

    if (demo.action == _CloudCodeAction.push) {
      final granted = await _ensurePushReady();
      if (!mounted) return;
      if (!granted) {
        setState(() {
          _isRunning = false;
          _resultText =
              'Notification permission is required. Enable notifications and try again.';
        });
        return;
      }
    }

    final configuration = _configurationFor(demo.action, taskId);
    final started = Stopwatch()..start();
    if (demo.action == _CloudCodeAction.summary) {
      await _runTyped(demo, configuration, started);
    } else {
      await _runDynamic(demo, configuration, started);
    }
  }

  Future<bool> _ensurePushReady() async {
    await PushNotificationsSdk.start();
    if (await PushNotificationsSdk.hasNotificationPermission()) {
      await PushNotificationsSdk.setNotificationsEnabled(true);
      return true;
    }

    final completer = Completer<bool>();
    await PushNotificationsSdk.requestNotificationPermission(
      callback: (granted) {
        if (!completer.isCompleted) completer.complete(granted);
      },
    );
    final granted = await completer.future;
    if (granted) await PushNotificationsSdk.setNotificationsEnabled(true);
    return granted;
  }

  Future<void> _runDynamic(
    _CloudCodeDemo demo,
    _RequestConfiguration configuration,
    Stopwatch stopwatch,
  ) async {
    final request = CloudCode.call(
      configuration.slug,
      method: configuration.method,
      query: configuration.query,
      body: configuration.body,
      headers: configuration.headers,
    );
    _pendingRequest = request;
    try {
      final response = await request.future;
      if (!mounted) return;
      _showResult(
        demo.id,
        'Result - ${configuration.slug}',
        _formatResponse(response, stopwatch.elapsed),
      );
    } catch (error) {
      if (!mounted) return;
      _showResult(
        demo.id,
        'Result - ${configuration.slug}',
        _formatError(error, stopwatch.elapsed),
      );
    } finally {
      if (identical(_pendingRequest, request)) _pendingRequest = null;
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<void> _runTyped(
    _CloudCodeDemo demo,
    _RequestConfiguration configuration,
    Stopwatch stopwatch,
  ) async {
    final request = CloudCode.callTyped<_CloudCodeSummary>(
      configuration.slug,
      method: configuration.method,
      query: configuration.query,
      body: configuration.body,
      headers: configuration.headers,
      fromJson: _CloudCodeSummary.fromJson,
    );
    _pendingRequest = request;
    try {
      final result = await request.future;
      final data = {
        'task_count': result.data?.taskCount,
        'database_available': result.data?.databaseAvailable,
        'database_tables_ready': result.data?.databaseTablesReady,
        'posts': result.data?.posts ?? const <Object?>[],
        'platform': result.data?.platform,
      };
      if (!mounted) return;
      _showResult(
        demo.id,
        'Result - ${configuration.slug}',
        _formatMetadata(
          statusCode: result.statusCode,
          requestId: result.requestId,
          headers: result.headers,
          body: data,
          elapsed: stopwatch.elapsed,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showResult(
        demo.id,
        'Result - ${configuration.slug}',
        _formatError(error, stopwatch.elapsed),
      );
    } finally {
      if (identical(_pendingRequest, request)) _pendingRequest = null;
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<void> _cancelRequest() async {
    final request = _pendingRequest;
    if (request == null) return;
    try {
      await request.cancel();
    } catch (_) {
      // The public request is already completed as cancelled; native cleanup
      // failures should not replace that result in the sample UI.
    }
  }

  _RequestConfiguration _configurationFor(
    _CloudCodeAction action,
    int? taskId,
  ) {
    final suffix = _platformSuffix;
    final headers = _headers;
    switch (action) {
      case _CloudCodeAction.setupDatabase:
        return (
          slug: 'cloud-demo-setup-database-$suffix',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.createTask:
        return (
          slug: 'cloud-demo-create-task-$suffix',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: {'title': _taskTitleController.text},
          headers: headers,
        );
      case _CloudCodeAction.listTasks:
        return (
          slug: 'cloud-demo-list-tasks-$suffix',
          method: CloudCodeHttpMethod.get,
          query: {'limit': '20'},
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.completeTask:
        return (
          slug: 'cloud-demo-complete-task-$suffix',
          method: CloudCodeHttpMethod.patch,
          query: null,
          body: {'task_id': taskId ?? 0},
          headers: headers,
        );
      case _CloudCodeAction.deleteTask:
        return (
          slug: 'cloud-demo-delete-task-$suffix',
          method: CloudCodeHttpMethod.delete,
          query: null,
          body: {'task_id': taskId ?? 0},
          headers: headers,
        );
      case _CloudCodeAction.createOrder:
        return (
          slug: 'cloud-demo-create-order-$suffix',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: {'idempotency_key': _newIdempotencyKey(), 'amount': 100},
          headers: headers,
        );
      case _CloudCodeAction.summary:
        return (
          slug: 'cloud-demo-dashboard-summary-$suffix',
          method: CloudCodeHttpMethod.get,
          query: null,
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.publishPost:
        return (
          slug: 'cloud-demo-publish-post-$suffix',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: {
            'title': _publishTitleController.text,
            'body': _publishBodyController.text,
          },
          headers: headers,
        );
      case _CloudCodeAction.readPosts:
        final uuid = _postUuidController.text.trim();
        return (
          slug: 'cloud-demo-read-posts-$suffix',
          method: CloudCodeHttpMethod.get,
          query: uuid.isEmpty ? null : {'uuid': uuid},
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.push:
        return (
          slug: 'cloud-demo-send-push-$suffix',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: {
            'title':
                'Cloud Code ${suffix == 'android' ? 'Android' : 'iOS'} demo',
            'body': 'Push from Flutter sample',
          },
          headers: headers,
        );
      case _CloudCodeAction.inspector:
        return (
          slug: 'cloud-demo-http-inspector',
          method: CloudCodeHttpMethod.post,
          query: {'source': _platformSuffix},
          body: {'message': 'hello', 'count': 2},
          headers: headers,
        );
      case _CloudCodeAction.jsonValues:
        return (
          slug: 'cloud-demo-json-values',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.nullContract:
        return (
          slug: 'cloud-demo-null-contract',
          method: CloudCodeHttpMethod.get,
          query: null,
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.responseShapes:
        return (
          slug: 'cloud-demo-response-shapes',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.controlledError:
        return (
          slug: 'cloud-demo-error-response',
          method: CloudCodeHttpMethod.post,
          query: null,
          body: {'invalid': true},
          headers: headers,
        );
      case _CloudCodeAction.timeout:
        return (
          slug: 'cloud-demo-timeout-10s',
          method: CloudCodeHttpMethod.get,
          query: null,
          body: null,
          headers: headers,
        );
      case _CloudCodeAction.runtimeContext:
        return (
          slug: 'cloud-demo-runtime-context',
          method: CloudCodeHttpMethod.get,
          query: null,
          body: null,
          headers: headers,
        );
    }
  }

  void _showResult(String demoId, String title, String text) {
    if (!mounted) return;
    setState(() {
      _lastResultDemoId = demoId;
      _resultTitle = title;
      _resultText = text;
      _resultExpanded = true;
    });
  }

  String _formatResponse(CloudCodeResponse response, Duration elapsed) {
    return _formatMetadata(
      statusCode: response.statusCode,
      requestId: response.requestId,
      headers: response.headers,
      body: response.data,
      elapsed: elapsed,
    );
  }

  String _formatMetadata({
    required int statusCode,
    required String? requestId,
    required Map<String, String> headers,
    required Object? body,
    required Duration elapsed,
  }) {
    final lines = <String>[
      'HTTP $statusCode',
      'Duration: ${_formatDuration(elapsed)}',
      'requestId: ${requestId ?? 'none'}',
    ];
    if (headers.isNotEmpty) {
      lines.add('Headers: ${_jsonText(headers)}');
    }
    lines.add('Body: ${_jsonText(body)}');
    return lines.join('\n');
  }

  String _formatError(Object error, Duration elapsed) {
    if (error is CloudCodeError) {
      final lines = <String>[
        'Duration: ${_formatDuration(elapsed)}',
        'Code: ${error.code.name}',
      ];
      if (error.statusCode != null) lines.add('HTTP: ${error.statusCode}');
      lines.add('requestId: ${error.requestId ?? 'none'}');
      if (error.body != null) {
        lines.add('HTTP error body: ${_jsonText(error.body)}');
      }
      if (error.rawBody != null) lines.add('Raw body: ${error.rawBody}');
      lines.add('Error: ${error.message}');
      return lines.join('\n');
    }
    return 'Duration: ${_formatDuration(elapsed)}\nError: $error';
  }

  String _formatDuration(Duration duration) {
    return '${(duration.inMicroseconds / 1000000).toStringAsFixed(2)} s';
  }

  String _jsonText(Object? value) {
    if (value == null) return 'null';
    try {
      return const JsonEncoder.withIndent('  ').convert(_normalise(value));
    } catch (_) {
      return value.toString();
    }
  }

  Object? _normalise(Object? value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalise(item)),
      );
    }
    if (value is Iterable) return value.map(_normalise).toList(growable: false);
    return value;
  }

  String _newIdempotencyKey() {
    return 'flutter-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  Widget _statusCard({
    required String title,
    required String status,
    required Color color,
  }) {
    return Card(
      color: color.withAlpha(20),
      child: ListTile(
        leading: Icon(
          status == 'Available' || status == 'Tables ready'
              ? Icons.check_circle
              : Icons.info_outline,
          color: color,
        ),
        title: Text(title),
        subtitle: Text(status),
        trailing: _isVerifyingBackend
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }

  Widget _demoCard(_CloudCodeDemo demo) {
    final canRun =
        demo.action != _CloudCodeAction.setupDatabase ||
        (_databaseAvailable && !_databaseTablesReady && !_isVerifyingBackend);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demo.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      SelectableText(
                        demo.slug,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _isRunning || !canRun
                      ? null
                      : () => unawaited(_runOrConfirm(demo)),
                  tooltip: 'Run ${demo.title}',
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(demo.detail),
            const SizedBox(height: 3),
            Text(
              demo.prerequisite,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (_lastResultDemoId == demo.id) _resultCard(),
          ],
        ),
      ),
    );
  }

  Widget _resultCard() {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        initiallyExpanded: _resultExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => _resultExpanded = expanded),
        title: Text(_resultTitle),
        subtitle: Text(_resultExpanded ? 'Tap to collapse' : 'Tap to expand'),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(
              _resultText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const sections = ['Database', 'CMS', 'Push', 'HTTP'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Text('Cloud Code', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'HTTP-triggered functions using the native consumer token on $_platformSuffix.',
        ),
        const SizedBox(height: 12),
        _statusCard(
          title: 'Database',
          status: _databaseStatus,
          color: Colors.blue,
        ),
        _statusCard(title: 'CMS', status: _cmsStatus, color: Colors.purple),
        if (_isRunning || _isVerifyingBackend)
          Card(
            child: ListTile(
              leading: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(
                _isRunning ? 'Calling Cloud Code...' : 'Checking Cloud Code...',
              ),
              trailing: TextButton(
                onPressed: _cancelRequest,
                child: const Text('Cancel'),
              ),
            ),
          ),
        for (final section in sections) ...[
          const SizedBox(height: 16),
          Text(section, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          if (section == 'Database') ...[
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Task id for update/delete',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (section == 'CMS') ...[
            TextField(
              controller: _postUuidController,
              decoration: const InputDecoration(
                labelText: 'CMS post UUID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _publishTitleController,
              decoration: const InputDecoration(
                labelText: 'Sample CMS title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _publishBodyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Sample CMS body',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final demo in _demos.where((item) => item.section == section))
            _demoCard(demo),
        ],
      ],
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
