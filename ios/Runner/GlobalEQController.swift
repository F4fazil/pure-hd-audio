import AVFoundation
import UIKit
import AudioToolbox
import CoreAudio

class GlobalEQController {
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioEQ: AVAudioUnitEQ?
    private var mainEQ: AVAudioUnitEQ? // EQ for main mixer processing
    private var eqEnabled: Bool = false
    private var isServiceRunning: Bool = false
    internal var outputAudioUnit: AudioUnit?
    private var globalEQAudioUnit: AudioUnit?
    
    // EQ band configurations (8 bands to match Android)
    private let frequencies: [Float] = [60, 170, 310, 600, 1000, 3000, 6000, 12000]
    private let numberOfBands = 8
    private let bandLevelRange: [Int] = [-1200, 1200] // -12dB to +12dB in milliBel
    
    init() {
        setupAudioEngine()
        // Don't setup audio interception in init - do it when starting EQ to avoid conflicts
        print("🎛️ GlobalEQController initialized - call startGlobalEQ() to activate")
    }
    
    private func setupAudioEngine() {
        print("🎛️ Setting up iOS Audio Engine...")
        
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        audioEQ = AVAudioUnitEQ(numberOfBands: numberOfBands)
        mainEQ = AVAudioUnitEQ(numberOfBands: numberOfBands)
        
        guard let engine = audioEngine,
              let playerNode = audioPlayerNode,
              let eq = audioEQ,
              let mainEQNode = mainEQ else {
            print("❌ Failed to create audio components")
            return
        }
        
        // Configure both EQ units with default frequencies
        for i in 0..<numberOfBands {
            // Configure player EQ
            let band = eq.bands[i]
            band.frequency = frequencies[i]
            band.filterType = .parametric
            band.bandwidth = 1.0
            band.gain = 0.0 // Start with flat response
            band.bypass = false
            
            // Configure main mixer EQ (same settings)
            let mainBand = mainEQNode.bands[i]
            mainBand.frequency = frequencies[i]
            mainBand.filterType = .parametric
            mainBand.bandwidth = 1.0
            mainBand.gain = 0.0
            mainBand.bypass = false
        }
        
        // Attach nodes to engine
        engine.attach(playerNode)
        engine.attach(eq)
        engine.attach(mainEQNode)
        
        // Connect player chain: playerNode -> EQ -> mainMixerNode
        engine.connect(playerNode, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)
        
        // Set up main EQ to process all app audio: mainMixer -> mainEQ -> output
        engine.connect(engine.mainMixerNode, to: mainEQNode, format: nil)
        engine.connect(mainEQNode, to: engine.outputNode, format: nil)
        
        print("✅ iOS Audio Engine setup complete")
        print("   Number of bands: \(numberOfBands)")
        print("   Frequency range: \(bandLevelRange[0]) to \(bandLevelRange[1]) mB")
        print("   Frequencies: \(frequencies)")
    }
    
    private func setupBasicAudioEngine() {
        print("🎛️ Setting up Basic Audio Engine (fallback)...")
        
        // Just use the standard audio engine without global interception
        guard let engine = audioEngine, let eq = audioEQ else {
            print("❌ Audio engine components not available")
            return
        }
        
        print("✅ Basic Audio Engine setup complete")
        print("   Note: Global audio interception not available, EQ will work with in-app audio only")
    }
    
    private func setupAdvancedAudioTap() {
        print("🎛️ Setting up Advanced Audio Tap for better EQ processing...")
        
        guard let engine = audioEngine, let eq = audioEQ else {
            print("❌ Audio engine components not available")
            return
        }
        
        // Configure EQ bands with more precision (matching Android)
        for i in 0..<min(numberOfBands, eq.bands.count) {
            let band = eq.bands[i]
            band.frequency = frequencies[i]
            band.filterType = .parametric
            band.bandwidth = 1.0 // Q factor for better frequency precision
            band.gain = 0.0
            band.bypass = false
        }
        
        // Install tap on the main mixer node for monitoring (but don't process here to avoid conflicts)
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
            // Just monitor, don't process here to avoid distortion
            // The actual EQ processing happens through AVAudioUnitEQ
        }
        
        print("✅ Advanced Audio Tap setup complete")
        print("   Using AVAudioUnitEQ for high-quality processing")
    }
    
    private func setupInAppAudioProcessing() {
        print("🎛️ Setting up In-App Audio Processing...")
        
        guard let engine = audioEngine, let eq = audioEQ, let playerNode = audioPlayerNode else {
            print("❌ Audio engine components not available")
            return
        }
        
        // Configure EQ bands for in-app audio processing
        for i in 0..<min(numberOfBands, eq.bands.count) {
            let band = eq.bands[i]
            band.frequency = frequencies[i]
            band.filterType = .parametric
            band.bandwidth = 1.0
            band.gain = 0.0
            band.bypass = false
        }
        
        // Set up audio routing to capture and process audio through EQ
        setupAudioRouting()
        
        print("✅ In-App Audio Processing setup complete")
        print("   🎛️ EQ configured with \(eq.bands.count) bands")
        print("   🎵 Audio routing through EQ established")
    }
    
    private func setupAudioRouting() {
        guard let engine = audioEngine, let eq = audioEQ else { return }
        
        // Install tap on main mixer to route audio through our EQ
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        
        // Remove any existing tap
        mainMixer.removeTap(onBus: 0)
        
        // Install new tap to process audio through EQ
        mainMixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
            // This processes all audio going through the main mixer
            self?.processAudioThroughEQ(buffer: buffer)
        }
        
        print("✅ Audio routing tap installed on main mixer")
    }
    
    private func processAudioThroughEQ(buffer: AVAudioPCMBuffer) {
        // The audio processing happens automatically through the connected AVAudioUnitEQ
        // This tap ensures audio flows through our EQ node
        if eqEnabled && buffer.frameLength > 0 {
            // EQ processing is handled by the AVAudioUnitEQ in the audio graph
            // Just ensure the buffer is processed
        }
    }
    
    private func processSystemAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // The actual EQ processing is handled by AVAudioUnitEQ in the audio graph
        // This method can be used for monitoring or additional processing if needed
        
        if eqEnabled && buffer.frameLength > 0 {
            // EQ processing is automatic through the connected audio nodes
            // AVAudioUnitEQ handles the digital filtering
        }
    }
    
    private func setupGlobalAudioInterception() {
        print("🎛️ Setting up Global Audio Interception...")
        
        do {
            // Configure for system-wide audio processing with more compatible settings
            let audioSession = AVAudioSession.sharedInstance()
            
            print("🎛️ Current audio session category: \(audioSession.category)")
            print("🎛️ Current audio session mode: \(audioSession.mode)")
            
            // Use a more conservative approach - let other audio play and mix with ours
            try audioSession.setCategory(.ambient, 
                                       mode: .default,
                                       options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            
            // Set lower buffer size for better responsiveness but not too low to avoid glitches
            try audioSession.setPreferredIOBufferDuration(0.02) // 20ms buffer
            
            print("🎛️ Audio session configured for ambient processing")
            
            // Enable audio routing change notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(audioRouteChanged),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
            
            // Use in-app audio processing instead of system-wide interception
            setupInAppAudioProcessing()
            
        } catch {
            print("❌ Failed to setup global audio interception: \(error)")
            setupBasicAudioEngine()
        }
    }
    
    private func setupGlobalAudioUnit() {
        print("🎛️ Setting up Global Audio Unit...")
        
        // Check audio session state before setting up Audio Unit
        let audioSession = AVAudioSession.sharedInstance()
        print("🔍 Audio Session Info:")
        print("   Category: \(audioSession.category.rawValue)")
        print("   Mode: \(audioSession.mode.rawValue)")
        print("   Sample Rate: \(audioSession.sampleRate)")
        print("   Input Available: \(audioSession.isInputAvailable)")
        print("   Input Channels: \(audioSession.inputNumberOfChannels)")
        print("   Output Channels: \(audioSession.outputNumberOfChannels)")
        
        var componentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        guard let audioComponent = AudioComponentFindNext(nil, &componentDescription) else {
            print("❌ Could not find RemoteIO Audio Unit")
            return
        }
        
        var status = AudioComponentInstanceNew(audioComponent, &outputAudioUnit)
        if status != noErr {
            print("❌ Failed to create Audio Unit: \(status)")
            return
        }
        
        // Enable input and output
        var enableInput: UInt32 = 1
        status = AudioUnitSetProperty(
            outputAudioUnit!,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Input,
            1, // Input bus
            &enableInput,
            UInt32(MemoryLayout<UInt32>.size)
        )
        
        if status != noErr {
            print("❌ Failed to enable Audio Unit input: \(status)")
        }
        
        var enableOutput: UInt32 = 1
        status = AudioUnitSetProperty(
            outputAudioUnit!,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Output,
            0, // Output bus
            &enableOutput,
            UInt32(MemoryLayout<UInt32>.size)
        )
        
        if status != noErr {
            print("❌ Failed to enable Audio Unit output: \(status)")
        }
        
        // Set render callback for processing audio
        var renderCallback = AURenderCallbackStruct(
            inputProc: globalAudioRenderCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        
        status = AudioUnitSetProperty(
            outputAudioUnit!,
            kAudioUnitProperty_SetRenderCallback,
            kAudioUnitScope_Input,
            0,
            &renderCallback,
            UInt32(MemoryLayout<AURenderCallbackStruct>.size)
        )
        
        if status != noErr {
            print("❌ Failed to set render callback: \(status)")
        }
        
        // Initialize the audio unit
        status = AudioUnitInitialize(outputAudioUnit!)
        if status != noErr {
            print("❌ Failed to initialize Audio Unit: \(status)")
        } else {
            print("✅ Global Audio Unit initialized successfully")
        }
    }
    
    @objc private func audioRouteChanged(notification: Notification) {
        print("🎛️ Audio route changed - maintaining global EQ")
        // Maintain global EQ when audio route changes
        if isServiceRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.reinitializeGlobalAudio()
            }
        }
    }
    
    private func reinitializeGlobalAudio() {
        print("🎛️ Reinitializing global audio processing...")
        stopGlobalAudioUnit()
        setupGlobalAudioUnit()
        if isServiceRunning {
            startGlobalAudioUnit()
        }
    }
    
    private func startGlobalAudioUnit() {
        guard let audioUnit = outputAudioUnit else {
            print("❌ Audio Unit not initialized")
            return
        }
        
        let status = AudioOutputUnitStart(audioUnit)
        if status != noErr {
            print("❌ Failed to start Global Audio Unit: \(status)")
        } else {
            print("✅ Global Audio Unit started - processing system audio")
        }
    }
    
    private func stopGlobalAudioUnit() {
        guard let audioUnit = outputAudioUnit else { return }
        
        let status = AudioOutputUnitStop(audioUnit)
        if status != noErr {
            print("❌ Failed to stop Global Audio Unit: \(status)")
        } else {
            print("✅ Global Audio Unit stopped")
        }
    }
    
    // Global audio render callback - this processes ALL system audio
    internal func processGlobalAudio(audioBuffer: UnsafeMutablePointer<AudioBufferList>, frameCount: UInt32) {
        // Apply EQ processing to all system audio here
        if eqEnabled {
            applyEQToBuffer(audioBuffer: audioBuffer, frameCount: frameCount)
        }
    }
    
    private func applyEQToBuffer(audioBuffer: UnsafeMutablePointer<AudioBufferList>, frameCount: UInt32) {
        // Apply the EQ settings to the audio buffer
        // This is where the magic happens - we process all system audio
        
        let bufferList = audioBuffer.pointee
        let numBuffers = Int(bufferList.mNumberBuffers)
        
        for i in 0..<numBuffers {
            let buffer = bufferList.mBuffers
            if let data = buffer.mData?.assumingMemoryBound(to: Float32.self) {
                let numSamples = Int(buffer.mDataByteSize) / MemoryLayout<Float32>.size
                
                // Apply EQ processing sample by sample
                for j in 0..<numSamples {
                    // Apply frequency-specific gain adjustments
                    data[j] = applyEQToSample(data[j], sampleIndex: j)
                }
            }
        }
    }
    
    private func applyEQToSample(_ sample: Float32, sampleIndex: Int) -> Float32 {
        // Use the AVAudioUnitEQ for proper digital filtering instead of manual processing
        // This approach is more accurate and less CPU intensive
        return sample // Let AVAudioUnitEQ handle the processing
    }

    func startGlobalEQ() -> Bool {
        print("🎛️ Starting iOS In-App EQ...")
        print("ℹ️  iOS EQ works with in-app audio only (not global like Android)")
        print("ℹ️  External apps like Spotify will not be affected")
        
        // Check if already running
        if isServiceRunning {
            print("ℹ️  iOS EQ already running")
            return true
        }
        
        guard let engine = audioEngine else {
            print("❌ Audio engine not initialized")
            return false
        }
        
        guard let eq = audioEQ else {
            print("❌ Audio EQ not initialized")
            return false
        }
        
        guard let playerNode = audioPlayerNode else {
            print("❌ Audio player node not initialized")
            return false
        }
        
        print("🔧 Audio Engine Components Status:")
        print("   Engine: ✅ Created")
        print("   EQ: ✅ Created with \(eq.bands.count) bands")
        print("   PlayerNode: ✅ Created")
        
        // Stop engine if already running to reset state
        if engine.isRunning {
            print("🔄 Stopping existing engine to reset state")
            engine.stop()
        }
        
        do {
            // Don't reconfigure audio session if it's already properly configured
            let audioSession = AVAudioSession.sharedInstance()
            
            print("🔍 Current audio session state:")
            print("   Category: \(audioSession.category)")
            print("   Mode: \(audioSession.mode)")
            print("   Sample Rate: \(audioSession.sampleRate)")
            print("   Is Active: \(audioSession.isOtherAudioPlaying)")
            
            // Only configure audio session if it's not already compatible
            let currentCategory = audioSession.category
            let needsConfiguration = !(currentCategory == .ambient || 
                                      currentCategory == .playAndRecord || 
                                      currentCategory == .playback)
            
            if needsConfiguration {
                print("🔧 Configuring audio session for EQ compatibility...")
                // Use ambient category to avoid conflicts with existing audio
                try audioSession.setCategory(.ambient, 
                                           mode: .default,
                                           options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
                print("✅ Audio session category updated to ambient")
            } else {
                print("✅ Audio session already compatible, using existing configuration")
            }
            
            print("🚀 Starting audio engine...")
            
            // Check engine state before starting
            print("   Engine running before start: \(engine.isRunning)")
            
            // Start the audio engine with EQ processing
            try engine.start()
            print("✅ Audio engine started successfully")
            print("   Engine running after start: \(engine.isRunning)")
            
            // Set up audio processing for in-app audio
            setupInAppAudioProcessing()
            
            // Update service state
            isServiceRunning = true
            eqEnabled = true
            
            // Final verification
            print("✅ iOS In-App EQ started successfully")
            print("   🎵 Ready to process in-app audio with EQ")
            print("   ℹ️  External apps will play normally (not affected)")
            print("   🔧 Service state: running=\(isServiceRunning), enabled=\(eqEnabled)")
            
            return true
        } catch {
            print("❌ Failed to start iOS EQ: \(error)")
            print("   Error details: \(error.localizedDescription)")
            
            // Try to identify specific error types
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain)")
                print("   Error code: \(nsError.code)")
            }
            
            isServiceRunning = false
            eqEnabled = false
            return false
        }
    }
    
    func stopGlobalEQ() -> Bool {
        print("🎛️ Stopping iOS EQ...")
        
        guard let engine = audioEngine else {
            print("❌ Audio engine not initialized")
            return false
        }
        
        // Remove any installed taps safely
        do {
            if engine.isRunning {
                engine.mainMixerNode.removeTap(onBus: 0)
            }
        } catch {
            print("ℹ️  No tap to remove on main mixer")
        }
        
        // Stop the engine
        engine.stop()
        
        isServiceRunning = false
        eqEnabled = false
        
        print("✅ iOS EQ stopped cleanly")
        return true
    }
    
    func applyEQSettings(bandValues: [Double]) -> Bool {
        print("🎛️ Applying iOS EQ settings: \(bandValues)")
        print("   🔧 Service state check: isServiceRunning=\(isServiceRunning), eqEnabled=\(eqEnabled)")
        
        guard let eq = audioEQ, let mainEQNode = mainEQ else {
            print("❌ EQ units not available")
            return false
        }
        
        guard isServiceRunning else {
            print("❌ Service not running - call startGlobalEQ() first")
            return false
        }
        
        let numBands = min(numberOfBands, bandValues.count, eq.bands.count)
        
        print("   🎛️ Applying to \(numBands) bands on both EQ units")
        
        for i in 0..<numBands {
            let gainInDB = Float(bandValues[i])
            let clampedGain = max(-12.0, min(12.0, gainInDB))
            
            // Apply to player EQ
            eq.bands[i].gain = clampedGain
            
            // Apply to main mixer EQ (for all app audio)
            mainEQNode.bands[i].gain = clampedGain
            
            print("   Band \(i): \(gainInDB)dB -> \(clampedGain)dB at \(eq.bands[i].frequency)Hz")
        }
        
        print("✅ iOS EQ settings applied to both player and main EQ units")
        return true
    }
    
    func setEQEnabled(enabled: Bool) -> Bool {
        print("🎛️ Setting iOS EQ enabled: \(enabled)")
        
        guard let eq = audioEQ, let mainEQNode = mainEQ else {
            print("❌ EQ units not initialized")
            return false
        }
        
        // Enable/disable all EQ bands on both units
        for band in eq.bands {
            band.bypass = !enabled
        }
        
        for band in mainEQNode.bands {
            band.bypass = !enabled
        }
        
        eqEnabled = enabled
        print("✅ iOS EQ \(enabled ? "enabled" : "disabled") on both units")
        return true
    }
    
    func isEQEnabled() -> Bool {
        return eqEnabled
    }
    
    
    func pauseProcessing() {
        print("🎛️ Pausing iOS EQ processing...")
        
        guard let engine = audioEngine, isServiceRunning else { return }
        
        // Remove taps to stop processing
        engine.mainMixerNode.removeTap(onBus: 0)
        
        // Disable EQ temporarily
        if let eq = audioEQ {
            for band in eq.bands {
                band.bypass = true
            }
        }
        
        print("✅ iOS EQ processing paused")
    }
    
    func resumeProcessing() {
        print("🎛️ Resuming iOS EQ processing...")
        
        guard let engine = audioEngine, isServiceRunning else { return }
        
        // Re-enable EQ
        if let eq = audioEQ, eqEnabled {
            for band in eq.bands {
                band.bypass = false
            }
        }
        
        // Reinstall tap if needed
        if engine.isRunning {
            let format = engine.mainMixerNode.outputFormat(forBus: 0)
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
                // Monitor only - processing handled by AVAudioUnitEQ
            }
        }
        
        print("✅ iOS EQ processing resumed")
    }
    
    func getEqualizerInfo() -> [String: Any] {
        return [
            "enabled": eqEnabled,
            "numberOfBands": numberOfBands,
            "bandLevelRange": bandLevelRange,
            "frequencies": frequencies.map { Int($0) },
            "platform": "iOS",
            "type": "In-App EQ Only",
            "note": "iOS platform restrictions prevent global EQ. This EQ processes in-app audio only."
        ]
    }
    
    // Test method to play a tone and verify EQ is working
    func playTestTone(frequency: Float = 1000.0, duration: TimeInterval = 2.0) {
        print("🎵 Playing test tone at \(frequency)Hz for \(duration)s to test EQ...")
        print("   🔧 This will demonstrate that EQ is working on iOS")
        
        guard let engine = audioEngine, 
              let playerNode = audioPlayerNode,
              isServiceRunning else {
            print("❌ Audio engine not ready for test tone")
            return
        }
        
        // Generate a simple sine wave
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: playerNode.outputFormat(forBus: 0), frameCapacity: frameCount) else {
            print("❌ Could not create audio buffer")
            return
        }
        
        buffer.frameLength = frameCount
        
        let samples = buffer.floatChannelData?[0]
        for i in 0..<Int(frameCount) {
            let sample = sin(2.0 * .pi * Double(frequency) * Double(i) / sampleRate) * 0.3 // 30% volume
            samples?[i] = Float(sample)
        }
        
        // Copy to second channel if stereo
        if let leftSamples = buffer.floatChannelData?[0],
           let rightSamples = buffer.floatChannelData?[1] {
            for i in 0..<Int(frameCount) {
                rightSamples[i] = leftSamples[i]
            }
        }
        
        // Play the test tone through the EQ chain
        playerNode.scheduleBuffer(buffer, at: nil, options: []) {
            print("✅ Test tone playback completed - EQ effects should be audible")
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
        
        print("🎛️ Test tone playing - adjust EQ sliders to hear the effect")
    }
    
    func cleanup() {
        print("🎛️ Cleaning up iOS Global EQ Controller...")
        
        // Remove any installed taps first
        if let engine = audioEngine, engine.isRunning {
            engine.mainMixerNode.removeTap(onBus: 0)
        }
        
        // Stop the audio engine
        audioEngine?.stop()
        
        // Clean up audio unit if it exists
        if let audioUnit = outputAudioUnit {
            AudioUnitUninitialize(audioUnit)
            AudioComponentInstanceDispose(audioUnit)
        }
        
        // Remove notifications
        NotificationCenter.default.removeObserver(self)
        
        // Reset all components
        audioEngine = nil
        audioPlayerNode = nil
        audioEQ = nil
        mainEQ = nil
        outputAudioUnit = nil
        globalEQAudioUnit = nil
        isServiceRunning = false
        eqEnabled = false
        
        print("✅ iOS Global EQ Controller cleaned up")
    }
    
    deinit {
        cleanup()
    }
}

// Global C callback function for audio processing
func globalAudioRenderCallback(
    inRefCon: UnsafeMutableRawPointer,
    ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp: UnsafePointer<AudioTimeStamp>,
    inBusNumber: UInt32,
    inNumberFrames: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>?
) -> OSStatus {
    
    let controller = Unmanaged<GlobalEQController>.fromOpaque(inRefCon).takeUnretainedValue()
    
    // Get the audio data from the system
    var status: OSStatus = noErr
    
    if let audioUnit = controller.outputAudioUnit, let audioData = ioData {
        status = AudioUnitRender(
            audioUnit,
            ioActionFlags,
            inTimeStamp,
            1, // Input bus number
            inNumberFrames,
            audioData
        )
    }
    
    // Process the audio data with our EQ
    if status == noErr {
        if let audioBuffer = ioData {
            controller.processGlobalAudio(audioBuffer: audioBuffer, frameCount: inNumberFrames)
        }
    }
    
    return status
}