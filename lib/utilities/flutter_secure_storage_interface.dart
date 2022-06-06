import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class FlutterSecureStorageInterface {
  Future<void> write({
    @required String key,
    @required String value,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  });

  Future<String> read({
    @required String key,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  });

  Future<void> delete({
    @required String key,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  });
}

class SecureStorageWrapper implements FlutterSecureStorageInterface {
  final FlutterSecureStorage secureStore;

  const SecureStorageWrapper(this.secureStore);

  @override
  Future<String> read({
    @required String key,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  }) {
    return secureStore.read(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  @override
  Future<void> write({
    @required String key,
    @required String value,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  }) {
    return secureStore.write(
      key: key,
      value: value,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }

  Future<void> delete({
    @required String key,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  }) async {
    await secureStore.delete(
      key: key,
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
  }
}

// Mock class for testing purposes
class FakeSecureStorage implements FlutterSecureStorageInterface {
  Map<String, String> _store = {};

  @override
  Future<String> read({
    @required String key,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    @required String key,
    @required String value,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  }) async {
    _store[key] = value;
  }

  @override
  Future<void> delete({
    @required String key,
    IOSOptions iOptions,
    AndroidOptions aOptions,
    LinuxOptions lOptions,
    WebOptions webOptions,
    MacOsOptions mOptions,
    WindowsOptions wOptions,
  }) async {
    _store.remove(key);
  }
}
