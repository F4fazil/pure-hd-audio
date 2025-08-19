package com.silentsystem.pureaudiohd

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.audiofx.Equalizer
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class GlobalEQService : Service() {
    companion object {
        private const val TAG = "GlobalEQService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "global_eq_channel"
        private const val CHANNEL_NAME = "Global EQ Service"
        
        // Static reference to keep EQ alive
        @Volatile
        private var globalEqualizer: Equalizer? = null
        
        fun getGlobalEqualizer(): Equalizer? = globalEqualizer
        
        fun startService(context: Context) {
            val intent = Intent(context, GlobalEQService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, GlobalEQService::class.java)
            context.stopService(intent)
        }
        
        fun applyEQSettings(bandValues: FloatArray): Boolean {
            return try {
                val eq = globalEqualizer ?: run {
                    Log.e(TAG, "❌ Global equalizer is null")
                    return false
                }
                
                if (!eq.enabled) {
                    eq.enabled = true
                }
                
                val numBands = eq.numberOfBands.toInt()
                val range = eq.bandLevelRange
                val minLevel = range[0]
                val maxLevel = range[1]
                
                Log.d(TAG, "🎛️ Applying global EQ settings:")
                Log.d(TAG, "   Bands: $numBands, Range: $minLevel to $maxLevel mB")
                
                for (i in 0 until minOf(numBands, bandValues.size)) {
                    try {
                        // Convert from dB to milliBel (multiply by 100)
                        val gainInMilliBel = (bandValues[i] * 100).toInt().toShort()
                        val clampedGain = gainInMilliBel.coerceIn(minLevel, maxLevel)
                        
                        eq.setBandLevel(i.toShort(), clampedGain)
                        Log.d(TAG, "   Band $i: ${bandValues[i]}dB -> ${clampedGain}mB")
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠️ Failed to set band $i: ${e.message}")
                    }
                }
                
                Log.d(TAG, "✅ Global EQ settings applied successfully")
                true
            } catch (e: UnsupportedOperationException) {
                Log.e(TAG, "❌ EQ operation not supported: ${e.message}")
                false
            } catch (e: IllegalStateException) {
                Log.e(TAG, "❌ EQ in illegal state: ${e.message}")
                false
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to apply EQ settings: ${e.message}")
                false
            }
        }
        
        fun setEQEnabled(enabled: Boolean): Boolean {
            return try {
                globalEqualizer?.enabled = enabled
                Log.d(TAG, "🎛️ Global EQ ${if (enabled) "enabled" else "disabled"}")
                true
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to set EQ enabled state: ${e.message}")
                false
            }
        }
        
        fun isEQEnabled(): Boolean {
            return globalEqualizer?.enabled ?: false
        }
        
        fun releaseEqualizer() {
            try {
                globalEqualizer?.release()
                globalEqualizer = null
                Log.d(TAG, "🎛️ Global Equalizer released")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error releasing equalizer: ${e.message}")
            }
        }
        
        fun getEqualizerInfo(): Map<String, Any>? {
            return try {
                val eq = globalEqualizer ?: return null
                mapOf(
                    "enabled" to eq.enabled,
                    "numberOfBands" to eq.numberOfBands.toInt(),
                    "bandLevelRange" to listOf(eq.bandLevelRange[0].toInt(), eq.bandLevelRange[1].toInt()),
                    "frequencies" to (0 until eq.numberOfBands.toInt()).map { 
                        eq.getCenterFreq(it.toShort()).toInt() 
                    }
                )
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting equalizer info: ${e.message}")
                null
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🎛️ GlobalEQService created")
        
        createNotificationChannel()
        initializeGlobalEqualizer()
        
        // Start foreground service with proper type for Android 14+
        if (Build.VERSION.SDK_INT >= 34) { // Android 14 (API 34)
            startForeground(NOTIFICATION_ID, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, createNotification())
        }
    }

    private fun initializeGlobalEqualizer() {
        try {
            // Release any existing equalizer
            globalEqualizer?.release()
            
            // Create equalizer with global session ID (0)
            // This affects ALL audio output on the device
            globalEqualizer = Equalizer(0, 0) // priority=0, sessionId=0 (global)
            
            // Check if equalizer was created successfully
            if (globalEqualizer == null) {
                Log.e(TAG, "❌ Failed to create Equalizer instance")
                return
            }
            
            globalEqualizer?.enabled = true
            
            Log.d(TAG, "✅ Global Equalizer initialized successfully")
            Log.d(TAG, "   Session ID: 0 (global)")
            Log.d(TAG, "   Number of bands: ${globalEqualizer?.numberOfBands}")
            Log.d(TAG, "   Frequency range: ${globalEqualizer?.bandLevelRange?.joinToString(" to ")}")
            
            // Log band frequencies safely
            try {
                for (i in 0 until (globalEqualizer?.numberOfBands ?: 0)) {
                    val freq = globalEqualizer?.getCenterFreq(i.toShort())
                    Log.d(TAG, "   Band $i: ${freq?.div(1000)}Hz")
                }
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Could not read band frequencies: ${e.message}")
            }
            
        } catch (e: UnsupportedOperationException) {
            Log.e(TAG, "❌ Global Equalizer not supported on this device: ${e.message}")
            Log.e(TAG, "   This device may not support system-wide audio effects.")
            Log.e(TAG, "   The equalizer may only work with apps that support audio effects.")
        } catch (e: IllegalStateException) {
            Log.e(TAG, "❌ Equalizer in illegal state: ${e.message}")
            Log.e(TAG, "   Another app may be using the global equalizer.")
        } catch (e: RuntimeException) {
            Log.e(TAG, "❌ Equalizer runtime error: ${e.message}")
            Log.e(TAG, "   Global equalizer may not be supported on this device.")
            Log.e(TAG, "   Note: Most Android devices don't support system-wide EQ for apps like Spotify.")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to initialize Global Equalizer: ${e.message}")
            Log.e(TAG, "   Device limitation: Global EQ may not affect external apps.")
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the global equalizer running"
                setShowBadge(false)
                setSound(null, null)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Global EQ Active")
            .setContentText("System-wide equalizer is running")
            .setSmallIcon(android.R.drawable.ic_media_ff) // Using system icon
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setShowWhen(false)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "🎛️ GlobalEQService onStartCommand")
        
        // Ensure equalizer is still active
        if (globalEqualizer == null || !globalEqualizer!!.enabled) {
            initializeGlobalEqualizer()
        }
        
        // Return START_STICKY to restart service if killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "🎛️ GlobalEQService destroyed")
        
        // Don't release the equalizer here - keep it alive!
        // Only release when explicitly requested via static method
        
        super.onDestroy()
    }
}