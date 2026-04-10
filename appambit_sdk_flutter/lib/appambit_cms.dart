import 'package:appambit_sdk_flutter/appambit_sdk_flutter_platform_interface.dart';

class AppAmbitCmsQuery<T> {
  final String _contentType;
  final T Function(Map<String, dynamic>)? _fromJson;
  final List<Map<String, dynamic>> _filters = [];
  int? _page;
  int? _perPage;
  String? _orderBy;
  String? _orderDir;

  AppAmbitCmsQuery(this._contentType, {T Function(Map<String, dynamic>)? fromJson}) : _fromJson = fromJson;

  AppAmbitCmsQuery<T> search(String query) {
    _filters.add({'type': 'search', 'query': query});
    return this;
  }

  AppAmbitCmsQuery<T> equals(String field, String value) {
    _filters.add({'type': 'equals', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> notEquals(String field, String value) {
    _filters.add({'type': 'notEquals', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> contains(String field, String value) {
    _filters.add({'type': 'contains', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> startsWith(String field, String value) {
    _filters.add({'type': 'startsWith', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> greaterThan(String field, num value) {
    _filters.add({'type': 'greaterThan', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> greaterThanOrEqual(String field, num value) {
    _filters.add({'type': 'greaterThanOrEqual', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> lessThan(String field, num value) {
    _filters.add({'type': 'lessThan', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> lessThanOrEqual(String field, num value) {
    _filters.add({'type': 'lessThanOrEqual', 'field': field, 'value': value});
    return this;
  }

  AppAmbitCmsQuery<T> inList(String field, List<String> values) {
    _filters.add({'type': 'inList', 'field': field, 'value': values});
    return this;
  }

  AppAmbitCmsQuery<T> notInList(String field, List<String> values) {
    _filters.add({'type': 'notInList', 'field': field, 'value': values});
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
      filters: _filters,
      page: _page,
      perPage: _perPage,
      orderBy: _orderBy,
      orderDir: _orderDir,
    );

    final parser = _fromJson;
    if (parser != null) {
      return rawList.map((e) => parser(e)).toList();
    }
    
    // Fallback to casting if T is Map<String, dynamic> or dynamic, and fromJson is not provided
    return rawList.cast<T>();
  }
}

class AppAmbitCms {
  /// Start building a query for a particular content type.
  static AppAmbitCmsQuery<T> content<T>(String contentType, {T Function(Map<String, dynamic>)? fromJson}) {
    return AppAmbitCmsQuery<T>(contentType, fromJson: fromJson);
  }

  /// Remove the local cache for a given content type.
  static Future<void> clearCache(String contentType) {
    return AppAmbitSdkFlutterPlatform.instance.clearCmsCache(contentType);
  }

  /// Remove the local cache across all content types.
  static Future<void> clearAllCache() {
    return AppAmbitSdkFlutterPlatform.instance.clearAllCmsCache();
  }
}
