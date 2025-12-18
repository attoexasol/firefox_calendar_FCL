import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
// <-- IMPORTANT

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      print('Biometric availability check error: $e');
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Available biometrics error: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication is successful
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      // Authenticate
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          useErrorDialogs: useErrorDialogs,
        ),
        authMessages: <AuthMessages>[
          const AndroidAuthMessages(
            signInTitle: 'Biometric Authentication Required',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription:
                'Please set up device credentials',
            goToSettingsButton: 'Go to settings',
            goToSettingsDescription:
                'Please set up device credentials in settings',
          ),
          // const DarwinAuthMessages(
          //   cancelButton: 'Cancel',
          //   goToSettingsButton: 'Settings',
          //   goToSettingsDescription:
          //       'Please set up biometric authentication in settings',
          //   lockOut: 'Too many failed attempts. Please try again later.',
          // ),
        ],
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  /// Authenticate for login
  Future<bool> authenticateForLogin() async {
    return await authenticate(
      reason: 'Authenticate to login to your account',
      useErrorDialogs: true,
      stickyAuth: true,
      biometricOnly: true,
    );
  }

  /// Authenticate to enable biometric
  Future<bool> authenticateToEnable() async {
    return await authenticate(
      reason: 'Authenticate to enable biometric login',
      useErrorDialogs: true,
      stickyAuth: true,
      biometricOnly: true,
    );
  }

  /// Stop authentication
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      print('Stop authentication error: $e');
    }
  }

  /// Get biometric type string for display
  String getBiometricTypeString(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get available biometric types as readable string
  Future<String> getAvailableBiometricsString() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return 'No biometric authentication available';
    }
    return biometrics.map((type) => getBiometricTypeString(type)).join(', ');
  }
}
