import 'dart:io';

import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';

class Biometrics {
  static Future<bool> authenticate(
      {String cancelButtonText, String localizedReason, String title}) async {
    final LocalAuthentication localAuth = LocalAuthentication();

    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    if (canCheckBiometrics && isDeviceSupported) {
      List<BiometricType> availableSystems =
          await localAuth.getAvailableBiometrics();

      //TODO implement iOS biometrics
      if (Platform.isIOS) {
        if (availableSystems.contains(BiometricType.face)) {
          // Write iOS specific code when required
        } else if (availableSystems.contains(BiometricType.fingerprint)) {
          // Write iOS specific code when required
        }
      } else if (Platform.isAndroid) {
        if (availableSystems.contains(BiometricType.fingerprint)) {
          //TODO catch and handle errors/exceptions
          bool didAuthenticate = await localAuth.authenticate(
            biometricOnly: true,
            localizedReason: localizedReason,
            stickyAuth: true,
            androidAuthStrings: AndroidAuthMessages(
              // biometricRequiredTitle: "hello",
              // biometricNotRecognized: "biometric not recognized",
              biometricHint: "",
              // biometricSuccess: "bio successsss",
              // cancelButton: "SKIP",
              cancelButton: cancelButtonText,
              // deviceCredentialsRequiredTitle: "dev cred req title",
              signInTitle: title,
            ),
          );

          if (didAuthenticate) {
            return true;
          }
        }
      }
    }

    // authentication failed
    return false;
  }
}
