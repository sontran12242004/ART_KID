package com.artkids.artkids_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

class ScreenShareForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "artkids_screen_share_channel"
        private const val NOTIFICATION_ID = 1002

        @Volatile
        var isForegroundActive: Boolean = false

        var onForegroundReadyCallback: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureNotificationChannel()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        isForegroundActive = true
        val callback = onForegroundReadyCallback
        onForegroundReadyCallback = null
        callback?.invoke()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isForegroundActive = false
        onForegroundReadyCallback = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Chia sẻ màn hình lớp học",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Duy trì phiên chia sẻ màn hình trong phòng học trực tuyến ArtKids"
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    private fun buildNotification(): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("ArtKids — Đang chia sẻ màn hình")
                .setContentText("Phiên trình bày màn hình trong lớp học trực tuyến đang hoạt động.")
                .setSmallIcon(android.R.drawable.presence_video_online)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("ArtKids — Đang chia sẻ màn hình")
                .setContentText("Phiên trình bày màn hình trong lớp học trực tuyến đang hoạt động.")
                .setSmallIcon(android.R.drawable.presence_video_online)
                .setOngoing(true)
                .build()
        }
    }
}
