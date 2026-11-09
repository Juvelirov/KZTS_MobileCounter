package com.example.yolo_tracker_app_5x

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.yolo_tracker_app_5x/screen_recorder"
    private val REQUEST_CODE = 1001

    companion object {
        private var staticResultCode: Int = -1
        private var staticData: Intent? = null
        private var staticIsPermissionGranted = false
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (staticIsPermissionGranted && staticData != null) {
                        result.success(true)
                    } else {
                        val projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        val permissionIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val config = MediaProjectionConfig.createConfigForDefaultDisplay()
                            projectionManager.createScreenCaptureIntent(config)
                        } else {
                            projectionManager.createScreenCaptureIntent()
                        }
                        startActivityForResult(permissionIntent, REQUEST_CODE)
                        result.success(true)
                    }
                }
                "startRecording" -> {
                    if (staticIsPermissionGranted && staticData != null) {
                        val serviceIntent = Intent(this, ScreenRecordService::class.java).apply {
                            action = "START"
                            putExtra("resultCode", staticResultCode)
                            putExtra("data", staticData)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } else {
                        result.error("NO_PERMISSION", "Разрешение не получено", null)
                    }
                }
                "stopRecording" -> {
                    val serviceIntent = Intent(this, ScreenRecordService::class.java).apply {
                        action = "STOP"
                    }
                    startService(serviceIntent)
                    result.success(true)
                }
                "stopProjection" -> {
                    val serviceIntent = Intent(this, ScreenRecordService::class.java).apply {
                        action = "STOP_PROJECTION"
                    }
                    startService(serviceIntent)
                    staticIsPermissionGranted = false
                    staticData = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            staticResultCode = resultCode
            staticData = data
            staticIsPermissionGranted = true
        }
    }
}