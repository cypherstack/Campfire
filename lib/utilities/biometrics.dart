import 'dart:io';

import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';

import 'logger.dart';

class Biometrics {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");

  const Biometrics();

  Future<bool> authenticate(
      {String cancelButtonText, String localizedReason, String title}) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      Logger.print(
          "Tried to use Biometrics.authenticate() on a platform that is not Android or iOS! ...returning false.");
      return false;
    }
    if (integrationTestFlag) {
      Logger.print(
          "Tried to use Biometrics.authenticate() during integration testing. Returning false.");
      return false;
    }

    final LocalAuthentication localAuth = LocalAuthentication();

    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    if (canCheckBiometrics && isDeviceSupported) {
      List<BiometricType> availableSystems =
          await localAuth.getAvailableBiometrics();

      //TODO properly handle caught exceptions
      if (Platform.isIOS) {
        if (availableSystems.contains(BiometricType.face)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              iOSAuthStrings: IOSAuthMessages(),
            );

            if (didAuthenticate) {
              return true;
            }
          } catch (e) {
            Logger.print(
                "local_auth exception caught in Biometrics.authenticate(), e: $e");
          }
        } else if (availableSystems.contains(BiometricType.fingerprint)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              iOSAuthStrings: IOSAuthMessages(),
            );

            if (didAuthenticate) {
              return true;
            }
          } catch (e) {
            Logger.print(
                "local_auth exception caught in Biometrics.authenticate(), e: $e");
          }
        }
      } else if (Platform.isAndroid) {
        if (availableSystems.contains(BiometricType.fingerprint)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              androidAuthStrings: AndroidAuthMessages(
                biometricHint: "",
                cancelButton: cancelButtonText,
                signInTitle: title,
              ),
            );

            if (didAuthenticate) {
              return true;
            }
          } catch (e) {
            Logger.print(
                "local_auth exception caught in Biometrics.authenticate(), e: $e");
          }
        }
      }
    }

    // authentication failed
    return false;
  }
}
