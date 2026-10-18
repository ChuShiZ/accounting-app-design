import 'dart:convert';
import 'dart:io';

class WebDavException implements Exception {
  WebDavException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class WebDavEntry {
  const WebDavEntry({
    required this.name,
    required this.path,
    required this.at,
    required this.size,
  });

  final String name;
  final String path;
  final String at;
  final int size;
}

class WebDavClient {
  WebDavClient({
    required String baseUrl,
    required this.username,
    required this.password,
  }) : baseUrl = _normalizeBase(baseUrl);

  final String baseUrl;
  final String username;
  final String password;

  static String _normalizeBase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) throw WebDavException('请填写 WebDAV 服务器地址');
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw WebDavException('服务器地址格式不正确');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw WebDavException('服务器地址需以 http(s):// 开头');
    }
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  String get _authorization => 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  Uri _uri(List<String> segments, {bool directory = false}) {
    final cleaned = segments
        .expand((value) => value.split('/'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    final suffix = cleaned.isEmpty ? '' : (directory ? '$cleaned/' : cleaned);
    return Uri.parse('$baseUrl$suffix');
  }

  Future<void> testConnection() async {
    final response = await _request('PROPFIND', _uri(const [], directory: true), headers: {'Depth': '0'});
    if (![200, 207].contains(response.statusCode)) {
      throw WebDavException('连接失败：HTTP ${response.statusCode}', statusCode: response.statusCode);
    }
  }

  Future<void> ensureDirectory(List<String> segments) async {
    final uri = _uri(segments, directory: true);
    final exists = await _request('PROPFIND', uri, headers: {'Depth': '0'});
    if (exists.statusCode == 207 || exists.statusCode == 200) return;
    if (exists.statusCode != 404) {
      throw WebDavException('读取目录失败：HTTP ${exists.statusCode}', statusCode: exists.statusCode);
    }
    final created = await _request('MKCOL', uri);
    if (![200, 201, 204, 405].contains(created.statusCode)) {
      throw WebDavException('创建目录失败：HTTP ${created.statusCode}', statusCode: created.statusCode);
    }
  }

  Future<void> upload(List<String> folder, String name, List<int> bytes) async {
    await ensureDirectory(folder);
    final response = await _request(
      'PUT',
      _uri([...folder, name]),
      headers: {'Content-Type': 'application/zip'},
      body: bytes,
    );
    if (![200, 201, 204].contains(response.statusCode)) {
      throw WebDavException('上传失败：HTTP ${response.statusCode}', statusCode: response.statusCode);
    }
  }

  Future<List<int>> download(List<String> folder, String name) async {
    final response = await _request('GET', _uri([...folder, name]));
    if (response.statusCode != 200) {
      throw WebDavException('下载失败：HTTP ${response.statusCode}', statusCode: response.statusCode);
    }
    return response.body;
  }

  Future<void> delete(List<String> folder, String name) async {
    final response = await _request('DELETE', _uri([...folder, name]));
    if (![200, 204, 404].contains(response.statusCode)) {
      throw WebDavException('删除失败：HTTP ${response.statusCode}', statusCode: response.statusCode);
    }
  }

  Future<List<WebDavEntry>> list(List<String> folder) async {
    final response = await _request(
      'PROPFIND',
      _uri(folder, directory: true),
      headers: {'Depth': '1'},
    );
    if (response.statusCode == 404) return const [];
    if (response.statusCode != 207 && response.statusCode != 200) {
      throw WebDavException('读取备份列表失败：HTTP ${response.statusCode}', statusCode: response.statusCode);
    }
    final xml = utf8.decode(response.body, allowMalformed: true);
    final blocks = RegExp(r'<(?:[A-Za-z0-9]+:)?response\b[^>]*>(.*?)</(?:[A-Za-z0-9]+:)?response>', dotAll: true)
        .allMatches(xml);
    final entries = <WebDavEntry>[];
    for (final block in blocks) {
      final content = block.group(1) ?? '';
      final hrefMatch = RegExp(r'<(?:[A-Za-z0-9]+:)?href\b[^>]*>(.*?)</(?:[A-Za-z0-9]+:)?href>', dotAll: true)
          .firstMatch(content);
      if (hrefMatch == null) continue;
      final href = _decodeHref(hrefMatch.group(1) ?? '');
      if (href.isEmpty || href.endsWith('/')) continue;
      final name = href.split('/').where((part) => part.isNotEmpty).last;
      if (!name.toLowerCase().endsWith('.zip')) continue;
      final sizeMatch = RegExp(r'<(?:[A-Za-z0-9]+:)?getcontentlength\b[^>]*>(\d+)</', caseSensitive: false)
          .firstMatch(content);
      final modifiedMatch = RegExp(r'<(?:[A-Za-z0-9]+:)?getlastmodified\b[^>]*>(.*?)</', caseSensitive: false)
          .firstMatch(content);
      final modified = modifiedMatch?.group(1)?.trim();
      entries.add(WebDavEntry(
        name: name,
        path: href,
        at: modified != null && modified.isNotEmpty ? _formatHttpDate(modified) : _dateFromName(name),
        size: int.tryParse(sizeMatch?.group(1) ?? '') ?? 0,
      ));
    }
    entries.sort((a, b) => b.name.compareTo(a.name));
    return entries;
  }

  Future<WebDavResponse> _request(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    List<int>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 18);
    try {
      final request = await client.openUrl(method, uri);
      request.followRedirects = true;
      request.headers.set(HttpHeaders.authorizationHeader, _authorization);
      headers.forEach(request.headers.set);
      if (body != null) {
        request.contentLength = body.length;
        request.add(body);
      }
      final response = await request.close();
      final bytes = await response.fold<List<int>>(<int>[], (previous, element) => previous..addAll(element));
      return WebDavResponse(statusCode: response.statusCode, body: bytes);
    } on SocketException catch (error) {
      throw WebDavException('网络连接失败：${error.message}');
    } on HandshakeException {
      throw WebDavException('TLS 连接失败，请检查网络或服务器证书');
    } finally {
      client.close(force: true);
    }
  }

  String _decodeHref(String value) {
    var result = value.trim();
    if (result.startsWith('http://') || result.startsWith('https://')) {
      result = Uri.parse(result).path;
    }
    try {
      return Uri.decodeFull(result);
    } catch (_) {
      return result;
    }
  }

  String _formatHttpDate(String value) {
    final parsed = HttpDate.parse(value);
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  String _dateFromName(String name) {
    final match = RegExp(r'backup_(\d{8})_(\d{6})').firstMatch(name);
    if (match == null) return '';
    final date = match.group(1)!;
    final time = match.group(2)!;
    return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)} ${time.substring(0, 2)}:${time.substring(2, 4)}';
  }
}

class WebDavResponse {
  const WebDavResponse({required this.statusCode, required this.body});

  final int statusCode;
  final List<int> body;
}
