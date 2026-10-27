import AVFoundation
import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var loginPermissions: LoginPermissionHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IdsLoginPermissions") {
      loginPermissions = LoginPermissionHandler(messenger: registrar.messenger())
    }
  }
}

private final class LoginPermissionHandler: NSObject, CLLocationManagerDelegate {
  private let channel: FlutterMethodChannel
  private let locationManager = CLLocationManager()
  private var pendingResult: FlutterResult?
  private var waitingForLocation = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "ids/login_permissions", binaryMessenger: messenger)
    super.init()
    locationManager.delegate = self
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "Permission service unavailable.", details: nil))
        return
      }
      switch call.method {
      case "requestPermissions":
        self.requestPermissions(result: result)
      case "openSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "busy", message: "A permission request is already open.", details: nil))
      return
    }
    pendingResult = result
    if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
      AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
        DispatchQueue.main.async { self?.requestLocation() }
      }
    } else {
      requestLocation()
    }
  }

  private func requestLocation() {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let enabled = CLLocationManager.locationServicesEnabled()
      DispatchQueue.main.async {
        guard let self, self.pendingResult != nil else { return }
        guard enabled else {
          self.finish(location: "unavailable")
          return
        }
        if self.locationManager.authorizationStatus == .notDetermined {
          self.waitingForLocation = true
          self.locationManager.requestWhenInUseAuthorization()
        } else {
          self.finish()
        }
      }
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard waitingForLocation, manager.authorizationStatus != .notDetermined else { return }
    finish()
  }

  private func finish(location: String? = nil) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    waitingForLocation = false
    result(["camera": cameraStatus(), "location": location ?? locationStatus()])
  }

  private func cameraStatus() -> String {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return "granted"
    case .denied: return "blocked"
    case .restricted: return "restricted"
    case .notDetermined: return "denied"
    @unknown default: return "unavailable"
    }
  }

  private func locationStatus() -> String {
    switch locationManager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse: return "granted"
    case .denied: return "blocked"
    case .restricted: return "restricted"
    case .notDetermined: return "denied"
    @unknown default: return "unavailable"
    }
  }
}
