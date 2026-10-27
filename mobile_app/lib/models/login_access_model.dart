enum LoginPermissionState { granted, denied, blocked, unavailable }

class LoginAccessModel {
  const LoginAccessModel({required this.camera, required this.location});

  final LoginPermissionState camera;
  final LoginPermissionState location;

  bool get granted =>
      camera == LoginPermissionState.granted &&
      location == LoginPermissionState.granted;

  bool get needsSettings => [camera, location].any(
    (state) =>
        state == LoginPermissionState.blocked ||
        state == LoginPermissionState.unavailable,
  );
}
