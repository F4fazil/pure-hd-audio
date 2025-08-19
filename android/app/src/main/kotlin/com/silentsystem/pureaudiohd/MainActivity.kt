package com.silentsystem.pureaudiohd

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothHeadset
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BLUETOOTH_CHANNEL = "bluetooth_discovery"
    private val EQ_CHANNEL = "global_equalizer"
    private val TAG = "MainActivity"
    
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Enable edge-to-edge for Android 15+ compatibility (API 35+)
        if (Build.VERSION.SDK_INT >= 35) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        super.onCreate(savedInstanceState)
    }
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var isDiscovering = false
    private var bluetoothA2dp: BluetoothA2dp? = null
    private var bluetoothHeadset: BluetoothHeadset? = null

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE).toInt()
                    
                    device?.let {
                        Log.d(TAG, "📱 Device found: ${it.name ?: "Unknown"} (${it.address})")
                        
                        // Show ALL devices for now - no filtering
                        val deviceInfo = mapOf(
                            "name" to (it.name ?: "Unknown Device"),
                            "address" to it.address,
                            "rssi" to rssi,
                            "isPaired" to (it.bondState == BluetoothDevice.BOND_BONDED),
                            "type" to "classic"
                        )
                        
                        Log.d(TAG, "✅ Sending device to Flutter: ${deviceInfo["name"]}")
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, BLUETOOTH_CHANNEL).invokeMethod("onDeviceFound", deviceInfo)
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    isDiscovering = false
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, BLUETOOTH_CHANNEL).invokeMethod("onDiscoveryFinished", null)
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        
        // Initialize Bluetooth profiles for checking connection status
        initializeBluetoothProfiles()
        
        // Bluetooth channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startDiscovery" -> startDiscovery(result)
                "stopDiscovery" -> stopDiscovery(result)
                "getBondedDevices" -> getBondedDevices(result)
                "pairDevice" -> pairDevice(call, result)
                "connectToDevice" -> connectToDevice(call, result)
                "disconnectFromDevice" -> disconnectFromDevice(call, result)
                "checkConnectionStatus" -> checkConnectionStatus(call, result)
                else -> result.notImplemented()
            }
        }
        
        // Global EQ channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EQ_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startGlobalEQ" -> startGlobalEQ(result)
                "stopGlobalEQ" -> stopGlobalEQ(result)
                "applyEQSettings" -> applyEQSettings(call, result)
                "setEQEnabled" -> setEQEnabled(call, result)
                "isEQEnabled" -> isEQEnabled(result)
                "getEqualizerInfo" -> getEqualizerInfo(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        Log.d(TAG, "🔍 Starting discovery...")
        
        if (bluetoothAdapter == null) {
            Log.e(TAG, "❌ Bluetooth adapter is null")
            result.error("NO_BLUETOOTH", "Bluetooth not available", null)
            return
        }

        if (!bluetoothAdapter!!.isEnabled) {
            Log.e(TAG, "❌ Bluetooth is disabled")
            result.error("BLUETOOTH_OFF", "Bluetooth is turned off", null)
            return
        }

        // Check permissions with detailed logging
        val bluetoothScanPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
        val locationPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
        val legacyBluetoothPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH)
        val legacyBluetoothAdminPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADMIN)
        
        Log.d(TAG, "🔐 Permission status:")
        Log.d(TAG, "  BLUETOOTH_SCAN: $bluetoothScanPermission (${if (bluetoothScanPermission == 0) "GRANTED" else "DENIED"})")
        Log.d(TAG, "  ACCESS_FINE_LOCATION: $locationPermission (${if (locationPermission == 0) "GRANTED" else "DENIED"})")
        Log.d(TAG, "  BLUETOOTH (legacy): $legacyBluetoothPermission (${if (legacyBluetoothPermission == 0) "GRANTED" else "DENIED"})")
        Log.d(TAG, "  BLUETOOTH_ADMIN (legacy): $legacyBluetoothAdminPermission (${if (legacyBluetoothAdminPermission == 0) "GRANTED" else "DENIED"})")
        Log.d(TAG, "  Android version: ${android.os.Build.VERSION.SDK_INT}")

        // Android 12+ requires BLUETOOTH_SCAN permission to be explicitly granted
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            if (bluetoothScanPermission != PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "❌ BLUETOOTH_SCAN permission not granted on Android 12+")
                result.error("PERMISSION_DENIED", "BLUETOOTH_SCAN permission required for Android 12+. Please grant in Settings > Apps > PURE HD Audio > Permissions.", null)
                return
            }
        } else {
            // Pre-Android 12 needs legacy permissions
            if (legacyBluetoothPermission != PackageManager.PERMISSION_GRANTED || legacyBluetoothAdminPermission != PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "❌ Legacy Bluetooth permissions not granted")
                result.error("PERMISSION_DENIED", "BLUETOOTH and BLUETOOTH_ADMIN permissions required. Please grant in Settings.", null)
                return
            }
        }

        if (locationPermission != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "❌ Location permission not granted")
            result.error("PERMISSION_DENIED", "Location permission required for Bluetooth discovery. Please grant in Settings > Apps > PURE HD Audio > Permissions.", null)
            return
        }

        try {
            Log.d(TAG, "📡 Registering broadcast receiver...")
            // Register receiver
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            registerReceiver(discoveryReceiver, filter)

            // Cancel any ongoing discovery
            if (bluetoothAdapter!!.isDiscovering) {
                Log.d(TAG, "🔄 Canceling existing discovery...")
                bluetoothAdapter!!.cancelDiscovery()
                Thread.sleep(1000)
            }

            Log.d(TAG, "🚀 Calling bluetoothAdapter.startDiscovery()...")
            Log.d(TAG, "  Bluetooth adapter enabled: ${bluetoothAdapter!!.isEnabled}")
            Log.d(TAG, "  Already discovering: ${bluetoothAdapter!!.isDiscovering}")
            Log.d(TAG, "  Bluetooth state: ${bluetoothAdapter!!.state}")
            
            val started = bluetoothAdapter!!.startDiscovery()
            Log.d(TAG, "📡 startDiscovery() returned: $started")
            
            if (started) {
                isDiscovering = true
                Log.d(TAG, "✅ Discovery started successfully")
                result.success("Discovery started successfully")
            } else {
                Log.e(TAG, "❌ startDiscovery() returned false")
                Log.e(TAG, "  This usually means:")
                Log.e(TAG, "  1. Another app is using Bluetooth discovery")
                Log.e(TAG, "  2. Bluetooth is busy with other operations")
                Log.e(TAG, "  3. System is preventing discovery")
                
                // Try to get more info
                Log.d(TAG, "🔍 Bluetooth adapter info:")
                Log.d(TAG, "  Name: ${bluetoothAdapter!!.name}")
                Log.d(TAG, "  Address: ${bluetoothAdapter!!.address}")
                Log.d(TAG, "  Scan mode: ${bluetoothAdapter!!.scanMode}")
                Log.d(TAG, "  Is discovering: ${bluetoothAdapter!!.isDiscovering}")
                
                result.error("DISCOVERY_FAILED", "startDiscovery() returned false. Another app might be using Bluetooth discovery, or the system is busy. Try again in a few seconds.", null)
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException: ${e.message}")
            result.error("PERMISSION_DENIED", "Missing Bluetooth permissions: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Discovery exception: ${e.message}")
            e.printStackTrace()
            result.error("DISCOVERY_ERROR", e.message, null)
        }
    }

    private fun stopDiscovery(result: MethodChannel.Result) {
        try {
            if (bluetoothAdapter?.isDiscovering == true) {
                bluetoothAdapter!!.cancelDiscovery()
            }
            
            try {
                unregisterReceiver(discoveryReceiver)
            } catch (e: IllegalArgumentException) {
                // Receiver wasn't registered, ignore
            }
            
            isDiscovering = false
            result.success("Discovery stopped")
        } catch (e: Exception) {
            result.error("STOP_ERROR", e.message, null)
        }
    }

    private fun getBondedDevices(result: MethodChannel.Result) {
        Log.d(TAG, "📱 Getting bonded (paired) devices...")
        
        if (bluetoothAdapter == null) {
            result.error("NO_BLUETOOTH", "Bluetooth not available", null)
            return
        }

        try {
            val bondedDevices = bluetoothAdapter!!.bondedDevices
            Log.d(TAG, "🔗 Found ${bondedDevices.size} bonded devices")
            
            val deviceList = mutableListOf<Map<String, Any>>()
            
            bondedDevices.forEach { device ->
                Log.d(TAG, "📱 Bonded device: ${device.name ?: "Unknown"} (${device.address})")
                
                val deviceInfo = mapOf(
                    "name" to (device.name ?: "Unknown Device"),
                    "address" to device.address,
                    "rssi" to -50, // Default value for bonded devices
                    "isPaired" to true,
                    "type" to "bonded"
                )
                deviceList.add(deviceInfo)
            }
            
            result.success(deviceList)
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException getting bonded devices: ${e.message}")
            result.error("PERMISSION_DENIED", "Missing Bluetooth permissions: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting bonded devices: ${e.message}")
            result.error("BONDED_ERROR", e.message, null)
        }
    }

    private fun pairDevice(call: MethodCall, result: MethodChannel.Result) {
        val deviceAddress = call.argument<String>("address")
        if (deviceAddress == null) {
            result.error("INVALID_ARGS", "Device address is required", null)
            return
        }

        Log.d(TAG, "🔗 Attempting to pair with device: $deviceAddress")

        if (bluetoothAdapter == null) {
            result.error("NO_BLUETOOTH", "Bluetooth not available", null)
            return
        }

        // Check permissions
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission required", null)
            return
        }

        try {
            val device = bluetoothAdapter!!.getRemoteDevice(deviceAddress)
            Log.d(TAG, "📱 Found device: ${device.name ?: "Unknown"}")
            
            when (device.bondState) {
                BluetoothDevice.BOND_BONDED -> {
                    Log.d(TAG, "✅ Device already paired")
                    result.success("Device already paired")
                }
                BluetoothDevice.BOND_BONDING -> {
                    Log.d(TAG, "🔄 Device is currently bonding")
                    result.success("Device is currently pairing")
                }
                else -> {
                    Log.d(TAG, "🔗 Starting pairing process...")
                    val pairResult = device.createBond()
                    if (pairResult) {
                        Log.d(TAG, "✅ Pairing initiated successfully")
                        result.success("Pairing initiated - check device for PIN/confirmation")
                    } else {
                        Log.e(TAG, "❌ Failed to initiate pairing")
                        result.error("PAIR_FAILED", "Failed to initiate pairing", null)
                    }
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException pairing device: ${e.message}")
            result.error("PERMISSION_DENIED", "Missing Bluetooth permissions: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error pairing device: ${e.message}")
            result.error("PAIR_ERROR", e.message, null)
        }
    }

    private fun connectToDevice(call: MethodCall, result: MethodChannel.Result) {
        val deviceAddress = call.argument<String>("address")
        if (deviceAddress == null) {
            result.error("INVALID_ARGS", "Device address is required", null)
            return
        }

        Log.d(TAG, "📱 Attempting to connect to device: $deviceAddress")

        if (bluetoothAdapter == null) {
            result.error("NO_BLUETOOTH", "Bluetooth not available", null)
            return
        }

        // Check permissions
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission required", null)
            return
        }

        try {
            val device = bluetoothAdapter!!.getRemoteDevice(deviceAddress)
            Log.d(TAG, "📱 Device: ${device.name ?: "Unknown"} - Bond state: ${device.bondState}")
            
            if (device.bondState != BluetoothDevice.BOND_BONDED) {
                Log.w(TAG, "⚠️ Device not paired - attempting to pair first")
                result.error("NOT_PAIRED", "Device must be paired first. Use pair button.", null)
                return
            }

            // Check if device is already connected
            var isAlreadyConnected = false
            var connectionType = "none"

            // Check A2DP connection
            bluetoothA2dp?.let { a2dp ->
                val connectionState = a2dp.getConnectionState(device)
                if (connectionState == BluetoothProfile.STATE_CONNECTED) {
                    isAlreadyConnected = true
                    connectionType = "a2dp"
                    Log.d(TAG, "✅ Device already connected via A2DP")
                }
            }

            // Check Headset connection
            if (!isAlreadyConnected) {
                bluetoothHeadset?.let { headset ->
                    val connectionState = headset.getConnectionState(device)
                    if (connectionState == BluetoothProfile.STATE_CONNECTED) {
                        isAlreadyConnected = true
                        connectionType = "headset"
                        Log.d(TAG, "✅ Device already connected via Headset")
                    }
                }
            }

            if (isAlreadyConnected) {
                Log.d(TAG, "✅ Device is already connected via $connectionType")
                result.success("Device is already connected and ready to use")
            } else {
                // Device is paired but not connected - try to trigger connection
                Log.d(TAG, "🔄 Device is paired but not connected. Attempting to connect...")
                
                // For audio devices, we can try to connect via A2DP
                bluetoothA2dp?.let { a2dp ->
                    try {
                        // Use reflection to call connect method (it's hidden in API)
                        val connectMethod = a2dp.javaClass.getMethod("connect", BluetoothDevice::class.java)
                        val connectResult = connectMethod.invoke(a2dp, device) as Boolean
                        
                        if (connectResult) {
                            Log.d(TAG, "✅ A2DP connection initiated successfully")
                            result.success("Connection initiated - device should connect shortly")
                        } else {
                            Log.w(TAG, "⚠️ A2DP connection failed to initiate")
                            result.success("Device is paired. Please manually connect from system settings or device.")
                        }
                        return
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠️ Could not use A2DP connect method: ${e.message}")
                    }
                }
                
                // Fallback: just inform that device is paired
                Log.d(TAG, "✅ Device is paired. Connection should be automatic or manual.")
                result.success("Device is paired and should connect automatically. If not, try connecting manually from system Bluetooth settings.")
            }
            
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException connecting to device: ${e.message}")
            result.error("PERMISSION_DENIED", "Missing Bluetooth permissions: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error connecting to device: ${e.message}")
            result.error("CONNECT_ERROR", e.message, null)
        }
    }

    private fun disconnectFromDevice(call: MethodCall, result: MethodChannel.Result) {
        val deviceAddress = call.argument<String>("address")
        if (deviceAddress == null) {
            result.error("INVALID_ARGS", "Device address is required", null)
            return
        }

        Log.d(TAG, "📱 Attempting to disconnect from device: $deviceAddress")

        if (bluetoothAdapter == null) {
            result.error("NO_BLUETOOTH", "Bluetooth not available", null)
            return
        }

        // Check permissions
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission required", null)
            return
        }

        try {
            val device = bluetoothAdapter!!.getRemoteDevice(deviceAddress)
            Log.d(TAG, "📱 Disconnecting from device: ${device.name ?: "Unknown"}")
            
            var disconnected = false

            // Try to disconnect via A2DP
            bluetoothA2dp?.let { a2dp ->
                try {
                    // Use reflection to call disconnect method (it's hidden in API)
                    val disconnectMethod = a2dp.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                    val disconnectResult = disconnectMethod.invoke(a2dp, device) as Boolean
                    
                    if (disconnectResult) {
                        Log.d(TAG, "✅ A2DP disconnection initiated")
                        disconnected = true
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ Could not use A2DP disconnect method: ${e.message}")
                }
            }

            // Try to disconnect via Headset
            if (!disconnected) {
                bluetoothHeadset?.let { headset ->
                    try {
                        // Use reflection to call disconnect method (it's hidden in API)
                        val disconnectMethod = headset.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                        val disconnectResult = disconnectMethod.invoke(headset, device) as Boolean
                        
                        if (disconnectResult) {
                            Log.d(TAG, "✅ Headset disconnection initiated")
                            disconnected = true
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠️ Could not use Headset disconnect method: ${e.message}")
                    }
                }
            }

            if (disconnected) {
                result.success("Disconnection initiated successfully")
            } else {
                result.success("Disconnection requested - device may disconnect automatically")
            }
            
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException disconnecting from device: ${e.message}")
            result.error("PERMISSION_DENIED", "Missing Bluetooth permissions: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error disconnecting from device: ${e.message}")
            result.error("DISCONNECT_ERROR", e.message, null)
        }
    }

    private fun initializeBluetoothProfiles() {
        if (bluetoothAdapter == null) return

        try {
            // Initialize A2DP profile for audio devices
            bluetoothAdapter!!.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.A2DP) {
                        bluetoothA2dp = proxy as BluetoothA2dp
                        Log.d(TAG, "✅ A2DP profile connected")
                    }
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.A2DP) {
                        bluetoothA2dp = null
                        Log.d(TAG, "❌ A2DP profile disconnected")
                    }
                }
            }, BluetoothProfile.A2DP)

            // Initialize Headset profile
            bluetoothAdapter!!.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.HEADSET) {
                        bluetoothHeadset = proxy as BluetoothHeadset
                        Log.d(TAG, "✅ Headset profile connected")
                    }
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.HEADSET) {
                        bluetoothHeadset = null
                        Log.d(TAG, "❌ Headset profile disconnected")
                    }
                }
            }, BluetoothProfile.HEADSET)

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing Bluetooth profiles: ${e.message}")
        }
    }

    private fun checkConnectionStatus(call: MethodCall, result: MethodChannel.Result) {
        val deviceAddress = call.argument<String>("address")
        if (deviceAddress == null) {
            result.error("INVALID_ARGS", "Device address is required", null)
            return
        }

        if (bluetoothAdapter == null) {
            result.error("NO_BLUETOOTH", "Bluetooth not available", null)
            return
        }

        // Check permissions
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "BLUETOOTH_CONNECT permission required", null)
            return
        }

        try {
            val device = bluetoothAdapter!!.getRemoteDevice(deviceAddress)
            var isConnected = false
            var connectionType = "none"

            // Check A2DP connection (audio streaming)
            bluetoothA2dp?.let { a2dp ->
                val connectionState = a2dp.getConnectionState(device)
                if (connectionState == BluetoothProfile.STATE_CONNECTED) {
                    isConnected = true
                    connectionType = "a2dp"
                    Log.d(TAG, "✅ Device is connected via A2DP: ${device.name}")
                }
            }

            // Check Headset connection (hands-free)
            if (!isConnected) {
                bluetoothHeadset?.let { headset ->
                    val connectionState = headset.getConnectionState(device)
                    if (connectionState == BluetoothProfile.STATE_CONNECTED) {
                        isConnected = true
                        connectionType = "headset"
                        Log.d(TAG, "✅ Device is connected via Headset: ${device.name}")
                    }
                }
            }

            val statusMap = mapOf(
                "isConnected" to isConnected,
                "connectionType" to connectionType,
                "deviceName" to (device.name ?: "Unknown"),
                "isPaired" to (device.bondState == BluetoothDevice.BOND_BONDED)
            )

            Log.d(TAG, "📊 Connection status for ${device.name}: $statusMap")
            result.success(statusMap)

        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SecurityException checking connection status: ${e.message}")
            result.error("PERMISSION_DENIED", "Missing Bluetooth permissions: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking connection status: ${e.message}")
            result.error("CONNECTION_CHECK_ERROR", e.message, null)
        }
    }

    // Global EQ Methods
    private fun startGlobalEQ(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "🎛️ Starting Global EQ Service...")
            GlobalEQService.startService(this)
            result.success("Global EQ Service started")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start Global EQ Service: ${e.message}")
            result.error("START_EQ_ERROR", e.message, null)
        }
    }
    
    private fun stopGlobalEQ(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "🎛️ Stopping Global EQ Service...")
            GlobalEQService.stopService(this)
            GlobalEQService.releaseEqualizer()
            result.success("Global EQ Service stopped")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to stop Global EQ Service: ${e.message}")
            result.error("STOP_EQ_ERROR", e.message, null)
        }
    }
    
    private fun applyEQSettings(call: MethodCall, result: MethodChannel.Result) {
        try {
            val bandValues = call.argument<List<Double>>("bandValues")
            if (bandValues == null) {
                result.error("INVALID_ARGS", "bandValues is required", null)
                return
            }
            
            val floatArray = bandValues.map { it.toFloat() }.toFloatArray()
            val success = GlobalEQService.applyEQSettings(floatArray)
            
            if (success) {
                result.success("EQ settings applied")
            } else {
                result.error("APPLY_EQ_ERROR", "Failed to apply EQ settings", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error applying EQ settings: ${e.message}")
            result.error("APPLY_EQ_ERROR", e.message, null)
        }
    }
    
    private fun setEQEnabled(call: MethodCall, result: MethodChannel.Result) {
        try {
            val enabled = call.argument<Boolean>("enabled") ?: false
            val success = GlobalEQService.setEQEnabled(enabled)
            
            if (success) {
                result.success("EQ ${if (enabled) "enabled" else "disabled"}")
            } else {
                result.error("SET_EQ_ERROR", "Failed to set EQ enabled state", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error setting EQ enabled: ${e.message}")
            result.error("SET_EQ_ERROR", e.message, null)
        }
    }
    
    private fun isEQEnabled(result: MethodChannel.Result) {
        try {
            val enabled = GlobalEQService.isEQEnabled()
            result.success(enabled)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking EQ enabled: ${e.message}")
            result.error("GET_EQ_STATUS_ERROR", e.message, null)
        }
    }
    
    private fun getEqualizerInfo(result: MethodChannel.Result) {
        try {
            val info = GlobalEQService.getEqualizerInfo()
            result.success(info)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting equalizer info: ${e.message}")
            result.error("GET_EQ_INFO_ERROR", e.message, null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (isDiscovering) {
                bluetoothAdapter?.cancelDiscovery()
                unregisterReceiver(discoveryReceiver)
            }
        } catch (e: Exception) {
            // Ignore cleanup errors
        }
    }
}
