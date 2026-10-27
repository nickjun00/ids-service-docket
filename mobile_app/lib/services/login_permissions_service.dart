import 'package:flutter/services.dart';

import '../models/login_access_model.dart';

class LoginPermissions {
  static const channel = MethodChannel('ids/login_permissions');

  Future<LoginAccessModel> request() async {
    final result = await channel.invokeMapMethod<String, String>(
      'requestPermissions',
    );
    return LoginAccessModel(
      camera: _state(result?['camera']),
      location: _state(result?['location']),
    );
  }

  Future<bool> openSettings() async =>
      await channel.invokeMethod<bool>('openSettings') ?? false;

  LoginPermissionState _state(String? value) => switch (value) {
    'granted' => LoginPermissionState.granted,
    'denied' => LoginPermissionState.denied,
    'blocked' || 'restricted' => LoginPermissionState.blocked,
    _ => LoginPermissionState.unavailable,
  };
}
