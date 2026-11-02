package com.artkids.artkids_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.artkids.artkids_app/screen_share"
        private const val REQUEST_MEDIA_PROJECTION = 49021
    }

    private var methodChannel: MethodChannel? = null
    private var pendingStartResult: MethodChannel.Result? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var projectionCallback: MediaProjection.Callback? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var latestFrameBase64: String? = null
    private var captureWidth: Int = 540
    private var captureHeight: Int = 960
    private var lastFrameConvertMs: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlatformCapabilities" -> {
                    result.success(
                        mapOf(
                            "supported" to true,
                            "platform" to "android",
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "supportsSystemScreenShare" to true,
                            "supportsDeviceAudio" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q),
                            "scopeDescription" to "Trên Android, hệ điều hành sẽ mở hộp thoại bảo mật để bạn chọn chia sẻ Toàn bộ màn hình hoặc Một ứng dụng. Camera và Microphone vẫn hoạt động độc lập.",
                            "deviceAudioNotice" to "Âm thanh nội bộ của thiết bị (System Audio) là quyền riêng trên Android 10+; mặc định chỉ truyền hình ảnh màn hình và âm thanh từ Microphone của bạn."
                        )
                    )
                }
                "startScreenShare" -> {
                    if (pendingStartResult != null) {
                        result.error("BUSY", "Đang chờ xác nhận hộp thoại chia sẻ màn hình.", null)
                        return@setMethodCallHandler
                    }
                    // Clean up any previous projection before launching a new OS capture prompt
                    stopProjectionInternal(notifyFlutter = false)

                    val manager =
                        getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                    if (manager == null) {
                        result.success(
                            mapOf(
                                "started" to false,
                                "reason" to "unsupported",
                                "message" to "Thiết bị không hỗ trợ dịch vụ MediaProjection."
                            )
                        )
                        return@setMethodCallHandler
                    }
                    pendingStartResult = result
                    try {
                        val captureIntent = manager.createScreenCaptureIntent()
                        @Suppress("DEPRECATION")
                        startActivityForResult(captureIntent, REQUEST_MEDIA_PROJECTION)
                    } catch (e: Exception) {
                        pendingStartResult = null
                        result.success(
                            mapOf(
                                "started" to false,
                                "reason" to "exception",
                                "message" to "Không thể mở hộp thoại cấp quyền chia sẻ màn hình: ${e.message}"
                            )
                        )
                    }
                }
                "captureFrame" -> {
                    val frame = latestFrameBase64 ?: captureActivityWindowBase64()
                    result.success(
                        mapOf(
                            "active" to (mediaProjection != null),
                            "width" to captureWidth,
                            "height" to captureHeight,
                            "frameBase64" to frame
                        )
                    )
                }
                "stopScreenShare" -> {
                    stopProjectionInternal(notifyFlutter = false)
                    result.success(mapOf("stopped" to true))
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_MEDIA_PROJECTION) return

        val callbackResult = pendingStartResult
        pendingStartResult = null
        if (callbackResult == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            callbackResult.success(
                mapOf(
                    "started" to false,
                    "reason" to "user_cancelled",
                    "message" to "Bạn đã từ chối hoặc hủy xác nhận chia sẻ màn hình trên hệ điều hành."
                )
            )
            return
        }

        try {
            val handled = AtomicBoolean(false)
            val initProjection = Runnable {
                if (!handled.compareAndSet(false, true)) return@Runnable
                ScreenShareForegroundService.onForegroundReadyCallback = null
                try {
                    val manager =
                        getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    val projection = manager.getMediaProjection(resultCode, data)
                    if (projection == null) {
                        stopProjectionInternal(notifyFlutter = false)
                        callbackResult.success(
                            mapOf(
                                "started" to false,
                                "reason" to "projection_null",
                                "message" to "Hệ điều hành không cấp phiên MediaProjection."
                            )
                        )
                        return@Runnable
                    }
                    setupVirtualDisplay(projection)
                    val initialFrame = latestFrameBase64 ?: captureActivityWindowBase64()
                    callbackResult.success(
                        mapOf(
                            "started" to true,
                            "scope" to "entire_screen",
                            "width" to captureWidth,
                            "height" to captureHeight,
                            "frameBase64" to initialFrame,
                            "includeDeviceAudio" to false
                        )
                    )
                } catch (e: Exception) {
                    stopProjectionInternal(notifyFlutter = false)
                    callbackResult.success(
                        mapOf(
                            "started" to false,
                            "reason" to "start_failed",
                            "message" to "Không thể khởi tạo thu màn hình: ${e.message}"
                        )
                    )
                }
            }

            ScreenShareForegroundService.onForegroundReadyCallback = {
                mainHandler.post(initProjection)
            }

            val serviceIntent = Intent(this, ScreenShareForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }

            // Fallback in case onStartCommand ran synchronously or is delayed
            mainHandler.postDelayed(initProjection, 450L)
        } catch (e: Exception) {
            stopProjectionInternal(notifyFlutter = false)
            callbackResult.success(
                mapOf(
                    "started" to false,
                    "reason" to "service_failed",
                    "message" to "Không thể khởi chạy dịch vụ chia sẻ màn hình: ${e.message}"
                )
            )
        }
    }

    private fun setupVirtualDisplay(projection: MediaProjection) {
        // IMPORTANT: Do NOT call stopService(ScreenShareForegroundService) here!
        // Stopping the foreground service invalidates the active MediaProjection on Android 14+.
        releaseCaptureResourcesOnly()
        mediaProjection = projection

        val metrics = resources.displayMetrics
        val rawW = metrics.widthPixels.coerceAtLeast(360)
        val rawH = metrics.heightPixels.coerceAtLeast(640)
        val scale = (540.0 / rawW.coerceAtMost(rawH).toDouble()).coerceAtMost(1.0)
        captureWidth = ((rawW * scale).toInt() / 2 * 2).coerceAtLeast(320)
        captureHeight = ((rawH * scale).toInt() / 2 * 2).coerceAtLeast(480)

        val cb = object : MediaProjection.Callback() {
            override fun onStop() {
                mainHandler.post {
                    if (mediaProjection === projection) {
                        stopProjectionInternal(notifyFlutter = true)
                    }
                }
            }
        }
        projectionCallback = cb
        projection.registerCallback(cb, mainHandler)

        val reader = ImageReader.newInstance(
            captureWidth,
            captureHeight,
            PixelFormat.RGBA_8888,
            2
        )
        imageReader = reader
        reader.setOnImageAvailableListener({ r ->
            val image = try {
                r.acquireLatestImage()
            } catch (_: Exception) {
                null
            } ?: return@setOnImageAvailableListener

            try {
                val now = System.currentTimeMillis()
                if (now - lastFrameConvertMs >= 350L || latestFrameBase64 == null) {
                    lastFrameConvertMs = now
                    val plane = image.planes[0]
                    val buffer = plane.buffer
                    val pixelStride = plane.pixelStride
                    val rowStride = plane.rowStride
                    val rowPadding = rowStride - pixelStride * captureWidth
                    val bitmapWidth = captureWidth + rowPadding / pixelStride
                    val bmp = Bitmap.createBitmap(
                        bitmapWidth,
                        captureHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    bmp.copyPixelsFromBuffer(buffer)
                    val cropped = if (bitmapWidth != captureWidth) {
                        Bitmap.createBitmap(bmp, 0, 0, captureWidth, captureHeight)
                    } else {
                        bmp
                    }
                    val out = ByteArrayOutputStream()
                    cropped.compress(Bitmap.CompressFormat.JPEG, 62, out)
                    latestFrameBase64 = Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
                    if (cropped !== bmp) {
                        cropped.recycle()
                    }
                    bmp.recycle()
                }
            } catch (_: Exception) {
            } finally {
                image.close()
            }
        }, mainHandler)

        virtualDisplay = projection.createVirtualDisplay(
            "ArtKidsLiveScreenShare",
            captureWidth,
            captureHeight,
            metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            reader.surface,
            null,
            mainHandler
        )
    }

    private fun captureActivityWindowBase64(): String? {
        return try {
            val rootView = window?.decorView?.rootView ?: return null
            if (rootView.width <= 0 || rootView.height <= 0) return null
            val bmp = Bitmap.createBitmap(captureWidth, captureHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            val sx = captureWidth.toFloat() / rootView.width.toFloat()
            val sy = captureHeight.toFloat() / rootView.height.toFloat()
            canvas.scale(sx, sy)
            rootView.draw(canvas)
            val out = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, 60, out)
            bmp.recycle()
            val encoded = Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
            latestFrameBase64 = encoded
            encoded
        } catch (_: Exception) {
            latestFrameBase64
        }
    }

    private fun releaseCaptureResourcesOnly() {
        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        }
        virtualDisplay = null

        try {
            imageReader?.setOnImageAvailableListener(null, null)
            imageReader?.close()
        } catch (_: Exception) {
        }
        imageReader = null

        val proj = mediaProjection
        mediaProjection = null
        val cb = projectionCallback
        projectionCallback = null
        if (proj != null) {
            try {
                if (cb != null) {
                    proj.unregisterCallback(cb)
                }
                proj.stop()
            } catch (_: Exception) {
            }
        }
    }

    private fun stopProjectionInternal(notifyFlutter: Boolean) {
        ScreenShareForegroundService.onForegroundReadyCallback = null
        releaseCaptureResourcesOnly()
        latestFrameBase64 = null
        try {
            stopService(Intent(this, ScreenShareForegroundService::class.java))
        } catch (_: Exception) {
        }

        if (notifyFlutter) {
            try {
                methodChannel?.invokeMethod(
                    "onScreenShareStoppedBySystem",
                    mapOf("reason" to "os_stopped")
                )
            } catch (_: Exception) {
            }
        }
    }

    override fun onDestroy() {
        stopProjectionInternal(notifyFlutter = false)
        super.onDestroy()
    }
}
