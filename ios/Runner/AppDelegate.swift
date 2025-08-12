import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var globalEQController: GlobalEQController?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configure audio session
    configureAudioSession()
    
    // Initialize global EQ controller
    globalEQController = GlobalEQController()
    
    // Set up method channel
    setupMethodChannel()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      
      // Use ambient category to avoid conflicts with EQ controller
      // This allows the EQ controller to reconfigure as needed
      try audioSession.setCategory(.ambient, 
                                 mode: .default, 
                                 options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
      
      // Set preferred sample rate - don't force buffer duration to avoid conflicts
      try audioSession.setPreferredSampleRate(44100.0)
      
      try audioSession.setActive(true)
      print("🎛️ iOS Audio session configured successfully (ambient mode)")
      print("   Sample Rate: \(audioSession.sampleRate)")
      print("   Buffer Duration: \(audioSession.ioBufferDuration)")
      print("   Category: \(audioSession.category)")
      print("   Mode: \(audioSession.mode)")
    } catch let error as NSError {
      print("❌ Failed to configure audio session: \(error)")
      print("   Error Code: \(error.code)")
      print("   Error Domain: \(error.domain)")
      print("   Error Description: \(error.localizedDescription)")
      
      // Decode common error codes
      switch error.code {
      case -50:
        print("   → kAudioServicesInvalidParameterError: Invalid parameter in audio session configuration")
        print("   → Trying with simpler configuration...")
      case -560557684: // kAudioServicesSystemSoundTryAgainError
        print("   → Audio services busy, trying again...")
      default:
        print("   → Unknown audio session error")
      }
      
      // Try fallback configuration
      configureFallbackAudioSession()
    }
  }
  
  private func configureFallbackAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      
      // Simple ambient configuration as fallback - most compatible
      try audioSession.setCategory(.ambient, options: [.mixWithOthers])
      try audioSession.setActive(true)
      print("✅ Fallback audio session configured (ambient)")
    } catch {
      print("❌ Fallback audio session also failed: \(error)")
    }
  }
  
  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    
    let methodChannel = FlutterMethodChannel(name: "global_equalizer", binaryMessenger: controller.binaryMessenger)
    
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call: call, result: result)
    }
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let eqController = globalEQController else {
      result(FlutterError(code: "EQ_NOT_INITIALIZED", message: "Equalizer not initialized", details: nil))
      return
    }
    
    switch call.method {
    case "startGlobalEQ":
      let success = eqController.startGlobalEQ()
      result(success)
      
    case "stopGlobalEQ":
      let success = eqController.stopGlobalEQ()
      result(success)
      
    case "applyEQSettings":
      if let args = call.arguments as? [String: Any],
         let bandValues = args["bandValues"] as? [Double] {
        let success = eqController.applyEQSettings(bandValues: bandValues)
        result(success)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for applyEQSettings", details: nil))
      }
      
    case "setEQEnabled":
      if let args = call.arguments as? [String: Any],
         let enabled = args["enabled"] as? Bool {
        let success = eqController.setEQEnabled(enabled: enabled)
        result(success)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for setEQEnabled", details: nil))
      }
      
    case "isEQEnabled":
      result(eqController.isEQEnabled())
      
    case "getEqualizerInfo":
      result(eqController.getEqualizerInfo())
      
    case "playTestTone":
      if let args = call.arguments as? [String: Any] {
        let frequency = (args["frequency"] as? Double) ?? 1000.0
        let duration = (args["duration"] as? Double) ?? 2.0
        print("🎵 Flutter requesting test tone: \(frequency)Hz for \(duration)s")
        eqController.playTestTone(frequency: Float(frequency), duration: duration)
        result(true)
      } else {
        print("🎵 Flutter requesting default test tone")
        eqController.playTestTone()
        result(true)
      }
      
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    globalEQController?.cleanup()
    super.applicationWillTerminate(application)
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Pause EQ processing when app goes to background to avoid conflicts
    globalEQController?.pauseProcessing()
    super.applicationDidEnterBackground(application)
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    // Resume EQ processing when app comes to foreground
    globalEQController?.resumeProcessing()
    super.applicationWillEnterForeground(application)
  }
}
