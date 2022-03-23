import 'dart:io';

import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';

import 'logger.dart';

class Biometrics {
  static Future<bool> authenticate(
      {String cancelButtonText, String localizedReason, String title}) async {
    final LocalAuthentication localAuth = LocalAuthentication();

    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    if (canCheckBiometrics && isDeviceSupported) {
      List<BiometricType> availableSystems =
          await localAuth.getAvailableBiometrics();

      //TODO properly handle caught exceptions
      if (Platform.isIOS) {
        if (availableSystems.contains(BiometricType.face)) {
          //TODO implement iOS face id
        } else if (availableSystems.contains(BiometricType.fingerprint)) {
          try {
            bool didAuthenticate = await localAuth.authenticate(
              biometricOnly: true,
              localizedReason: localizedReason,
              stickyAuth: true,
              //TODO use ios auth strings?
              // iOSAuthStrings: IOSAuthMessages(),
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
