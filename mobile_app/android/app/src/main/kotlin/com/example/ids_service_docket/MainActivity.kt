package com.example.ids_service_docket

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val requestCode = 4170
    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null
    private val preferences by lazy { getSharedPreferences("login_permissions", MODE_PRIVATE) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ids/login_permissions")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> requestLoginPermissions(result)
                "openSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")))
                        result.success(true)
                    } catch (_: android.content.ActivityNotFoundException) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isGranted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun cameraStatus(): String = when {
        isGranted(Manifest.permission.CAMERA) -> "granted"
        preferences.getBoolean("camera_requested", false) &&
            !shouldShowRequestPermissionRationale(Manifest.permission.CAMERA) -> "blocked"
        else -> "denied"
    }

    private fun locationStatus(): String = when {
        isGranted(Manifest.permission.ACCESS_COARSE_LOCATION) ||
            isGranted(Manifest.permission.ACCESS_FINE_LOCATION) -> "granted"
        preferences.getBoolean("location_requested", false) &&
            !shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_COARSE_LOCATION) &&
            !shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION) -> "blocked"
        else -> "denied"
    }

    private fun requestLoginPermissions(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A permission request is already open.", null)
            return
        }
        val requested = mutableListOf<String>()
        if (cameraStatus() == "denied") {
            requested.add(Manifest.permission.CAMERA)
        }
        if (locationStatus() == "denied") {
            requested.add(Manifest.permission.ACCESS_COARSE_LOCATION)
            requested.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        if (requested.isEmpty()) {
            result.success(permissionStatuses())
            return
        }
        pendingResult = result
        requestPermissions(requested.toTypedArray(), requestCode)
    }

    private fun permissionStatuses() = mapOf(
        "camera" to cameraStatus(),
        "location" to locationStatus()
    )

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != this.requestCode) return
        val result = pendingResult ?: return
        pendingResult = null
        if (grantResults.isEmpty()) {
            result.error("cancelled", "The permission request was interrupted. Please try again.", null)
        } else {
            val editor = preferences.edit()
            if (permissions.contains(Manifest.permission.CAMERA)) {
                editor.putBoolean("camera_requested", true)
            }
            if (permissions.contains(Manifest.permission.ACCESS_COARSE_LOCATION) ||
                permissions.contains(Manifest.permission.ACCESS_FINE_LOCATION)) {
                editor.putBoolean("location_requested", true)
            }
            editor.apply()
            result.success(permissionStatuses())
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        pendingResult?.error("cancelled", "The permission request was interrupted.", null)
        pendingResult = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
