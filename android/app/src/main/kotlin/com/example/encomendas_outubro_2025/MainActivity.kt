package com.example.encomendas_outubro_2025

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.encomendas_outubro_2025/badge"
    private val TAG = "BadgeDebug"
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "badge_channel"
    private var ultimoBadge = -1  // ← RASTREIA último valor

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Method called: ${call.method}")
            when (call.method) {
                "setBadge" -> {
                    val count = call.argument<Int>("count") ?: 0
                    Log.d(TAG, "setBadge called with count: $count")
                    Log.d(TAG, "ultimoBadge ANTES: $ultimoBadge")
                    
                    try {
                        // ✅ Apenas atualiza se mudou
                        if (count != ultimoBadge) {
                            showBadgeNotification(count)
                            ultimoBadge = count
                            Log.d(TAG, "Badge atualizado de $ultimoBadge para $count")
                        } else {
                            Log.d(TAG, "Badge já é $count, ignorando")
                        }
                        
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error setting badge: ${e.message}")
                        result.error("BADGE_ERROR", e.message, null)
                    }
                }
                "removeBadge" -> {
                    Log.d(TAG, "removeBadge called")
                    try {
                        removeBadgeNotification()
                        ultimoBadge = 0
                        Log.d(TAG, "Badge removed successfully")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error removing badge: ${e.message}")
                        result.error("BADGE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Badge Channel",
                NotificationManager.IMPORTANCE_MIN
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showBadgeNotification(count: Int) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // ✅ Se count é 0, cancela
        if (count == 0) {
            manager.cancel(NOTIFICATION_ID)
            Log.d(TAG, "🔴 Badge notification CANCELLED (count=0)")
            return
        }
        
        // ✅ Se count é 1, mostra
        if (count == 1) {
            val intent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("📦 Encomendas")
                .setContentText("Você tem 1 encomenda")
                .setNumber(1)
                .setBadgeIconType(NotificationCompat.BADGE_ICON_LARGE)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(false)
                .setShowWhen(false)
                .build()

            manager.notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "🔴 Badge notification UPDATED with count: $count")
        }
    }

    private fun removeBadgeNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
        ultimoBadge = 0
        Log.d(TAG, "🔴 Badge removed")
    }
}