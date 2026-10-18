import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

const _webDavPasswordKey = 'webdav_password';

Future<String?> readWebDavPassword() async {
  try {
    return await _storage.read(key: _webDavPasswordKey);
  } catch (_) {
    return null;
  }
}

Future<void> saveWebDavPassword(String password) async {
  try {
    await _storage.write(key: _webDavPasswordKey, value: password);
  } catch (_) {
    // 某些模拟器/系统可能没有可用的 Keystore；本次运行仍可继续使用内存密码。
  }
}

Future<void> deleteWebDavPassword() async {
  try {
    await _storage.delete(key: _webDavPasswordKey);
  } catch (_) {}
}
