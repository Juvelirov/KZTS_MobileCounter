package com.example.yolo_tracker_app_5x

import android.app.*
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.util.DisplayMetrics
import android.util.Log
import android.view.Surface
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ScreenRecordService : Service() {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    private var currentVideoUri: Uri? = null
    private var pfd: ParcelFileDescriptor? = null
    
    // Фоновый приемник для удержания сессии живой
    private var backgroundImageReader: ImageReader? = null
    private var backgroundSurface: Surface? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "START") {
            val resultCode = intent.getIntExtra("resultCode", -1)
            val data = intent.getParcelableExtra<Intent>("data")
            
            if (data != null) {
                val notification = createNotification()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
                } else {
                    startForeground(1, notification)
                }

                if (mediaProjection == null) {
                    val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    try {
                        mediaProjection = projectionManager.getMediaProjection(resultCode, data)
                        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                            override fun onStop() {
                                Log.e("ScreenRecordService", "Система принудительно остановила проекцию!")
                                stopRecordingInternal()
                                cleanup()
                                stopSelf()
                            }
                        }, null)
                    } catch (e: Exception) {
                        Log.e("ScreenRecordService", "Ошибка получения проекции: ${e.message}")
                        stopSelf()
                        return START_NOT_STICKY
                    }
                }
                
                if (virtualDisplay == null) {
                    initVirtualDisplay()
                }
                
                if (mediaRecorder == null) {
                    startRecordingInternal()
                }
            }
        } else if (action == "STOP") {
            stopRecordingInternal()
        } else if (action == "STOP_PROJECTION") {
            stopRecordingInternal()
            cleanup()
            stopForeground(true)
            stopSelf()
        }
        return START_STICKY
    }

    private fun initVirtualDisplay() {
        val metrics = DisplayMetrics()
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.defaultDisplay.getRealMetrics(metrics)
        
        val width = 640
        val height = 480
        val density = metrics.densityDpi

        // Создаем фоновый ImageReader, который будет "съедать" кадры, чтобы система видела активность
        backgroundImageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        backgroundImageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            image?.close() // Сразу закрываем, чтобы не забивать память
        }, null)
        
        backgroundSurface = backgroundImageReader?.surface

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenRecord",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            backgroundSurface, null, null
        )
        Log.d("ScreenRecordService", "VirtualDisplay создан с фоновым Surface")
    }

    private fun startRecordingInternal() {
        val metrics = DisplayMetrics()
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.defaultDisplay.getRealMetrics(metrics)
        
        val width = 640
        val height = 480
        
        val dateFormat = SimpleDateFormat("ddMMyyyy", Locale.US)
        val dateStr = dateFormat.format(Date())
        val dirStr = "${Environment.DIRECTORY_MOVIES}/YoloCounter/$dateStr"
        val fileName = "yolo_record_${System.currentTimeMillis()}.mp4"

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = contentResolver
                val contentValues = ContentValues().apply {
                    put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                    put(MediaStore.Video.Media.RELATIVE_PATH, dirStr)
                    put(MediaStore.Video.Media.IS_PENDING, 1)
                }
                val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                currentVideoUri = resolver.insert(collection, contentValues)

                mediaRecorder = MediaRecorder(this).apply {
                    setVideoSource(MediaRecorder.VideoSource.SURFACE)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                    setVideoSize(width, height)
                    setVideoFrameRate(30)
                    setVideoEncodingBitRate(2000000)
                    currentVideoUri?.let {
                        pfd = resolver.openFileDescriptor(it, "w")
                        setOutputFile(pfd?.fileDescriptor)
                    }
                    prepare()
                }
            } else {
                val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "YoloCounter/$dateStr")
                if (!dir.exists()) dir.mkdirs()
                val file = File(dir, fileName)
                
                mediaRecorder = MediaRecorder().apply {
                    setVideoSource(MediaRecorder.VideoSource.SURFACE)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                    setVideoSize(width, height)
                    setVideoFrameRate(30)
                    setVideoEncodingBitRate(2000000)
                    setOutputFile(file.absolutePath)
                    prepare()
                }
            }

            // Переключаем VirtualDisplay на записывающий Surface
            virtualDisplay?.setSurface(mediaRecorder?.surface)
            mediaRecorder?.start()
            Log.d("ScreenRecordService", "Запись запущена: $dirStr/$fileName")
        } catch (e: Exception) {
            Log.e("ScreenRecordService", "Ошибка при запуске записи: ${e.message}")
            stopRecordingInternal()
        }
    }

    private fun stopRecordingInternal() {
        if (mediaRecorder != null) {
            try {
                mediaRecorder?.stop()
                mediaRecorder?.reset()
                mediaRecorder?.release()
            } catch (e: Exception) {
                Log.e("ScreenRecordService", "Ошибка остановки: ${e.message}")
            }
            mediaRecorder = null
        }
        
        // Возвращаем VirtualDisplay на фоновый Surface, чтобы токен не умер
        virtualDisplay?.setSurface(backgroundSurface)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && currentVideoUri != null) {
            val contentValues = ContentValues().apply {
                put(MediaStore.Video.Media.IS_PENDING, 0)
            }
            contentResolver.update(currentVideoUri!!, contentValues, null, null)
            currentVideoUri = null
        }
        
        try { pfd?.close() } catch (e: Exception) {}
        pfd = null
        
        Log.d("ScreenRecordService", "Запись остановлена (сессия сохранена в фоне)")
    }

    private fun cleanup() {
        virtualDisplay?.release()
        virtualDisplay = null
        backgroundSurface?.release()
        backgroundSurface = null
        backgroundImageReader?.close()
        backgroundImageReader = null
        mediaProjection?.stop()
        mediaProjection = null
    }

    override fun onDestroy() {
        stopRecordingInternal()
        cleanup()
        super.onDestroy()
    }

    private fun createNotification(): Notification {
        val channelId = "screen_record_channel"
        val channelName = "Screen Recording"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(chan)
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Счетчик изделий")
            .setContentText("Идет запись экрана...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()
    }
}