import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.tag,
    required this.apkUrl,
    required this.sha256,
    required this.notes,
  });

  final String versionName;
  final int versionCode;
  final String tag;
  final String apkUrl;
  final String sha256;
  final String notes;
}

class AppUpdateService {
  static const latestManifestUrl =
      'https://github.com/ChuShiZ/accounting-app-design/releases/latest/download/latest.json';

  Future<AppUpdateInfo?> check() async {
    final package = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(package.buildNumber) ?? 0;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(latestManifestUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'jizhang-android-updater');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('更新服务返回 HTTP ${response.statusCode}', uri: Uri.parse(latestManifestUrl));
      }
      final body = await response.fold<List<int>>(<int>[], (previous, element) => previous..addAll(element));
      final json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
      final info = AppUpdateInfo(
        versionName: json['versionName'] as String? ?? '',
        versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
        tag: json['tag'] as String? ?? '',
        apkUrl: json['apkUrl'] as String? ?? '',
        sha256: json['sha256'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
      return info.versionCode > currentCode ? info : null;
    } finally {
      client.close(force: true);
    }
  }

  Future<String> currentVersion() async {
    final package = await PackageInfo.fromPlatform();
    return '${package.version}+${package.buildNumber}';
  }
}
