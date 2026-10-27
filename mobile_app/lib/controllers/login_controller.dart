import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/login_access_model.dart';
import '../models/login_model.dart';
import '../services/demo_login_service.dart';
import '../services/firebase_account_service.dart';
import '../services/login_permissions_service.dart';

class LoginController extends GetxController {
  final LoginPermissions _permissions = Get.find();
  final DemoLoginService _demoLogin = Get.find();
  final FirebaseAccountService _accounts = Get.find();

  final login = const LoginModel().obs;
  final isLoading = false.obs;
  final startupPermissionsGranted = false.obs;
  final startupPermissionsChecked = false.obs;
  final showSettings = false.obs;
  final errorMessage = RxnString();

  bool isSupportedEmail(String email) => _demoLogin.isSupportedEmail(email);
  bool isValidCode(String code) => _demoLogin.isValidCode(code);

  @override
  void onReady() {
    super.onReady();
    requestStartupPermissions();
  }

  Future<void> requestStartupPermissions() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    showSettings.value = false;
    try {
      final access = await _permissions.request();
      startupPermissionsGranted.value = access.granted;
      startupPermissionsChecked.value = true;
      showSettings.value = access.needsSettings;
      if (!access.granted) {
        errorMessage.value = _permissionError(access, retryLabel: 'try again');
      }
    } on PlatformException {
      startupPermissionsChecked.value = true;
      errorMessage.value = 'Could not request access. Please try again.';
    } on MissingPluginException {
      startupPermissionsChecked.value = true;
      errorMessage.value =
          'Camera and location access require the Android or iOS app.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendOtp(String email) async {
    if (isLoading.value) return;
    if (!startupPermissionsGranted.value) {
      await requestStartupPermissions();
      if (!startupPermissionsGranted.value) return;
    }
    errorMessage.value = null;
    isLoading.value = true;
    final normalizedEmail = email.trim().toLowerCase();
    try {
      if (normalizedEmail != DemoLoginService.demoEmail) {
        final isRegistered = await _accounts.containsEmail(normalizedEmail);
        if (!isRegistered) {
          errorMessage.value =
              'This email is not registered. Ask your admin to add your account.';
          return;
        }
      }
      login.value = login.value.copyWith(
        step: LoginStep.verify,
        email: normalizedEmail,
      );
    } on FirebaseAccountLookupException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'Could not check this email with Firebase. Try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void verifyOtp(String code) {
    if (!_demoLogin.isValidCode(code)) return;
    errorMessage.value = null;
    login.value = login.value.copyWith(step: LoginStep.signedIn);
    Get.offAllNamed('/home');
  }

  void signOut() {
    errorMessage.value = null;
    login.value = const LoginModel(step: LoginStep.email);
    Get.offAllNamed('/login');
  }

  void backToEmail() {
    errorMessage.value = null;
    showSettings.value = false;
    login.value = const LoginModel(step: LoginStep.email);
  }

  Future<void> openSettings() async {
    try {
      final opened = await _permissions.openSettings();
      if (!opened) {
        errorMessage.value =
            'Open Settings to allow IDS camera and location access.';
      }
    } on PlatformException {
      errorMessage.value =
          'Open Settings to allow IDS camera and location access.';
    } on MissingPluginException {
      errorMessage.value = 'App settings are available on Android and iOS.';
    }
  }

  String _permissionError(
    LoginAccessModel access, {
    required String retryLabel,
  }) {
    if (access.location == LoginPermissionState.unavailable) {
      return 'Location services are unavailable. Enable them in Settings, '
          'then $retryLabel.';
    }
    return 'Allow camera and location access to continue.';
  }
}
