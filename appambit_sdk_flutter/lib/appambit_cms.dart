import 'package:appambit_sdk_flutter/appambit_sdk_flutter_platform_interface.dart';

class AppAmbitCmsQuery<T> {
  final String _contentType;
  final T Function(Map<String, dynamic>) _fromJson;
  final List<Map<String, dynamic>> _nativeFilters = [];
  final List<Map<String, dynamic>> _dartFilters = [];
  int? _page;
  int? _perPage;
  String? _orderBy;
  String? _orderDir;

  AppAmbitCmsQuery(this._contentType, {required T Function(Map<String, dynamic>) fromJson})
      : _fromJson = fromJson;

  AppAmbitCmsQuery<T> search(String query) {
    _nativeFilters.add({'type': 'search', 'query': query});
    return this;
  }

  AppAmbitCmsQuery<T> equals(String field, String value) {
    _nativeFilters.add({'type': 'equals', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> notEquals(String field, String value) {
    _nativeFilters.add({'type': 'notEquals', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> contains(String field, String value) {
    _nativeFilters.add({'type': 'contains', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> startsWith(String field, String value) {
    _nativeFilters.add({'type': 'startsWith', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> greaterThan(String field, num value) {
    _nativeFilters.add({'type': 'greaterThan', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> greaterThanOrEqual(String field, num value) {
    _nativeFilters.add({'type': 'greaterThanOrEqual', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> lessThan(String field, num value) {
    _nativeFilters.add({'type': 'lessThan', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> lessThanOrEqual(String field, num value) {
    _nativeFilters.add({'type': 'lessThanOrEqual', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> inList(String field, List<String> values) {
    _dartFilters.add({'type': 'inList', 'field': field, 'value': values});
    return this;
  }

  AppAmbitCmsQuery<T> notInList(String field, List<String> values) {
    _dartFilters.add({'type': 'notInList', 'field': field, 'value': values});
    return this;
  }

  AppAmbitCmsQuery<T> orderByAscending(String field) {
    _orderBy = field;
    _orderDir = 'asc';
    return this;
  }

  AppAmbitCmsQuery<T> orderByDescending(String field) {
    _orderBy = field;
    _orderDir = 'desc';
    return this;
  }

  AppAmbitCmsQuery<T> getPage(int page) {
    _page = page;
    return this;
  }

  AppAmbitCmsQuery<T> getPerPage(int perPage) {
    _perPage = perPage;
    return this;
  }

  Future<List<T>> getList() async {
    final rawList = await AppAmbitSdkFlutterPlatform.instance.getCmsList(
      contentType: _contentType,
      filters: _nativeFilters,
      page: _dartFilters.isEmpty ? _page : null,
      perPage: _dartFilters.isEmpty ? _perPage : null,
      orderBy: _orderBy,
      orderDir: _orderDir,
    );

    var filtered = rawList;

    for (final f in _dartFilters) {
      final field = f['field'] as String;
      final values = (f['value'] as List).map((e) => e.toString()).toList();
      final negate = f['type'] == 'notInList';

      filtered = filtered.where((item) {
        final fieldVal = item[field];
        final bool matches;

        if (fieldVal is List) {
          matches = fieldVal.any((v) => values.contains(v.toString()));
        } else {
          matches = values.contains(fieldVal?.toString());
        }

        return negate ? !matches : matches;
      }).toList();
    }

    return filtered.map(_fromJson).toList();
  }
}

class AppAmbitCms {
  static AppAmbitCmsQuery<T> content<T>(
    String contentType, {
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return AppAmbitCmsQuery<T>(contentType, fromJson: fromJson);
  }
}
