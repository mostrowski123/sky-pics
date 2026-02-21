import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A saved login credential pair.
class SavedCredential {
  final String handle;
  final String appPassword;

  const SavedCredential({required this.handle, required this.appPassword});
}

/// Abstraction for securely storing and retrieving login credentials.
abstract class CredentialService {
  /// Load saved credentials, or null if none exist.
  Future<SavedCredential?> load();

  /// Save credentials for auto-login.
  Future<void> save(String handle, String appPassword);

  /// Clear all saved credentials.
  Future<void> clear();
}

/// Implementation backed by [FlutterSecureStorage].
class SecureCredentialService implements CredentialService {
  static const _keyHandle = 'cred_handle';
  static const _keyPassword = 'cred_password';

  final FlutterSecureStorage _storage;

  SecureCredentialService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<SavedCredential?> load() async {
    final handle = await _storage.read(key: _keyHandle);
    final password = await _storage.read(key: _keyPassword);
    if (handle == null || password == null) return null;
    return SavedCredential(handle: handle, appPassword: password);
  }

  @override
  Future<void> save(String handle, String appPassword) async {
    await _storage.write(key: _keyHandle, value: handle);
    await _storage.write(key: _keyPassword, value: appPassword);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _keyHandle);
    await _storage.delete(key: _keyPassword);
  }
}
