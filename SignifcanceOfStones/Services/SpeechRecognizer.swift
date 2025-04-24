import Foundation
import Speech
import AVFoundation
import SwiftUI
import os.log
import Combine

// Add notification for text changes
extension Notification.Name {
    static let recognizedTextDidChange = Notification.Name("recognizedTextDidChange")
}

class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    // Published properties for UI updates
    @Published var isRecording = false {
        didSet {
            print("isRecording changed to: \(isRecording)")
        }
    }
    @Published var text = ""
    @Published var recognizedText = "" {
        didSet {
            print("recognizedText updated: \(recognizedText)")
        }
    }
    @Published var error: Error?
    @Published var permissionDenied = false
    @Published var recordingTime: TimeInterval = 0
    
    // Debug information
    @Published var debugInfo: String = ""
    @Published var permissionStatus: String = "Not checked"
    @Published var audioEngineStatus: String = "Not started"
    @Published var recognitionStatus: String = "Not started"
    
    // Speech recognition components
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var timer: Timer?
    
    // Logger
    private let logger = Logger(subsystem: "com.significanceofstones", category: "SpeechRecognition")
    
    // Callback for when recording is finished
    var onFinishRecording: ((String) -> Void)?
    
    // Cancellables for publisher handling
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        // Initialize with the user's locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.current.identifier))
        super.init()
        speechRecognizer?.delegate = self
        
        // Check authorization status immediately
        checkInitialPermissions()
        
        // Initialize debug status
        updateDebugStatus()
        updateDebugInfo("SpeechRecognizer initialized")
        
        // Set up publisher to properly push updates
        $recognizedText
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] newText in
                guard let self = self else { return }
                if self.isRecording && !newText.isEmpty {
                    print("Publisher received new text: \(newText)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateDebugStatus() {
        DispatchQueue.main.async {
            // Update permission status based on current state
            let speechAuthStatus = SFSpeechRecognizer.authorizationStatus()
            let micAuthStatus: Bool
            
            if #available(iOS 17.0, *) {
                micAuthStatus = AVAudioApplication.shared.recordPermission == .granted
            } else {
                micAuthStatus = AVAudioSession.sharedInstance().recordPermission == .granted
            }
            
            self.permissionStatus = "Speech: \(speechAuthStatus), Mic: \(micAuthStatus)"
        }
    }
    
    private func updateDebugInfo(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let newDebugLine = "[\(timestamp)] \(message)"
        logger.debug("\(newDebugLine)")
        
        DispatchQueue.main.async {
            self.debugInfo += newDebugLine + "\n"
            // Limit debug info to last 15 lines
            let lines = self.debugInfo.components(separatedBy: "\n")
            if lines.count > 15 {
                self.debugInfo = lines.suffix(15).joined(separator: "\n")
            }
        }
    }
    
    private func checkInitialPermissions() {
        let speechAuthStatus = SFSpeechRecognizer.authorizationStatus()
        let micAuthStatus: Bool
        
        if #available(iOS 17.0, *) {
            micAuthStatus = AVAudioApplication.shared.recordPermission == .granted
        } else {
            micAuthStatus = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        
        DispatchQueue.main.async {
            self.permissionStatus = "Speech: \(speechAuthStatus), Mic: \(micAuthStatus)"
        }
        
        if speechAuthStatus != .authorized || !micAuthStatus {
            updateDebugInfo("Initial permission check: Speech auth: \(speechAuthStatus.rawValue), Mic auth: \(micAuthStatus)")
        } else {
            updateDebugInfo("Permissions already granted")
        }
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        updateDebugInfo("Requesting permissions")
        
        // First check if permissions are already granted
        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let micAuthorized: Bool
        
        if #available(iOS 17.0, *) {
            micAuthorized = AVAudioApplication.shared.recordPermission == .granted
        } else {
            micAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        
        if speechAuthorized && micAuthorized {
            updateDebugInfo("Permissions already granted")
            DispatchQueue.main.async {
                self.permissionStatus = "All permissions granted"
                completion(true)
            }
            return
        }
        
        updateDebugInfo("Need to request permissions - Speech: \(speechAuthorized), Mic: \(micAuthorized)")
        
        // Request microphone permissions
        if #available(iOS 17.0, *) {
            updateDebugInfo("Requesting iOS 17+ microphone permission")
            AVAudioApplication.requestRecordPermission { micAuthorized in
                self.updateDebugInfo("Microphone permission response: \(micAuthorized)")
                
                // Request speech recognition permissions
                self.updateDebugInfo("Requesting speech recognition permission")
                SFSpeechRecognizer.requestAuthorization { speechAuthStatus in
                    self.updateDebugInfo("Speech recognition permission response: \(speechAuthStatus.rawValue)")
                    
                    let authorized = micAuthorized && (speechAuthStatus == .authorized)
                    DispatchQueue.main.async {
                        self.permissionDenied = !authorized
                        self.permissionStatus = "Final: Speech: \(speechAuthStatus), Mic: \(micAuthorized)"
                        
                        if !authorized {
                            self.updateDebugInfo("Permission denied: Mic auth: \(micAuthorized), Speech auth: \(speechAuthStatus == .authorized)")
                        } else {
                            self.updateDebugInfo("All permissions granted")
                        }
                        completion(authorized)
                    }
                }
            }
        } else {
            // Fallback for iOS 16 and earlier
            updateDebugInfo("Requesting iOS 16 microphone permission")
            AVAudioSession.sharedInstance().requestRecordPermission { micAuthorized in
                self.updateDebugInfo("Microphone permission response: \(micAuthorized)")
                
                // Request speech recognition permissions
                self.updateDebugInfo("Requesting speech recognition permission")
                SFSpeechRecognizer.requestAuthorization { speechAuthStatus in
                    self.updateDebugInfo("Speech recognition permission response: \(speechAuthStatus.rawValue)")
                    
                    let authorized = micAuthorized && (speechAuthStatus == .authorized)
                    DispatchQueue.main.async {
                        self.permissionDenied = !authorized
                        self.permissionStatus = "Final: Speech: \(speechAuthStatus), Mic: \(micAuthorized)"
                        
                        if !authorized {
                            self.updateDebugInfo("Permission denied: Mic auth: \(micAuthorized), Speech auth: \(speechAuthStatus == .authorized)")
                        } else {
                            self.updateDebugInfo("All permissions granted")
                        }
                        completion(authorized)
                    }
                }
            }
        }
    }
    
    func startRecording() {
        updateDebugInfo("startRecording() called")
        
        // Reset state
        recognizedText = ""
        text = ""
        error = nil
        recordingTime = 0
        
        // Immediately update the visual status indicators
        DispatchQueue.main.async {
            self.audioEngineStatus = "Initializing..."
            self.recognitionStatus = "Starting..."
            // Ensure isRecording is true right away for UI feedback
            self.isRecording = true
        }
        
        // Check if we're already recording
        if audioEngine.isRunning {
            updateDebugInfo("Already recording - stopping first")
            stopRecording()
            return
        }
        
        // Log that we're starting the recording process
        updateDebugInfo("Starting recording process")
        
        // Request permissions
        requestPermissions { [weak self] authorized in
            guard let self = self else { return }
            
            if !authorized {
                self.updateDebugInfo("Recording permissions not authorized")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Recording permission denied"])
                    self.permissionDenied = true
                    self.audioEngineStatus = "Permission denied"
                    self.recognitionStatus = "Permission denied"
                    self.isRecording = false
                }
                return
            }
            
            // Reset audio session
            self.resetAudioSession()
            
            // Create a new recognition request
            self.updateDebugInfo("Creating recognition request")
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            // Check if the device supports speech recognition
            guard let recognitionRequest = self.recognitionRequest,
                  let speechRecognizer = self.speechRecognizer, speechRecognizer.isAvailable else {
                self.updateDebugInfo("Speech recognition not available")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not available"])
                    self.audioEngineStatus = "Not available"
                    self.recognitionStatus = "Not available"
                    self.isRecording = false
                }
                return
            }
            
            // Configure the audio session
            do {
                let audioSession = AVAudioSession.sharedInstance()
                self.updateDebugInfo("Setting audio session category")
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // Set up the audio engine and input node
                self.updateDebugInfo("Setting up audio engine")
                let inputNode = self.audioEngine.inputNode
                DispatchQueue.main.async {
                    self.audioEngineStatus = "Configuring..."
                }
                
                // Configure the request
                recognitionRequest.shouldReportPartialResults = true
                
                // Configure the recognition task
                self.updateDebugInfo("Setting up recognition task")
                DispatchQueue.main.async {
                    self.recognitionStatus = "Initializing..."
                }
                
                self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    var isFinal = false
                    
                    if let result = result {
                        // Update the recognized text
                        let transcription = result.bestTranscription.formattedString
                        self.updateDebugInfo("Recognition update: \(transcription)")
                        
                        // Always dispatch to main thread and ensure UI updates
                        DispatchQueue.main.async {
                            self.recognizedText = transcription
                            
                            // For debugging
                            print("RECOGNITION UPDATE: \(transcription)")
                            
                            self.recognitionStatus = "Active: \(transcription.count) chars"
                            
                            // Force UI update for SwiftUI
                            NotificationCenter.default.post(name: .recognizedTextDidChange, object: nil)
                        }
                        
                        isFinal = result.isFinal
                        
                        if isFinal {
                            self.updateDebugInfo("Recognition final: \(transcription)")
                            DispatchQueue.main.async {
                                // Make sure to update the final text property
                                self.text = transcription
                            }
                        }
                    }
                    
                    // Handle errors
                    if let error = error {
                        self.updateDebugInfo("Recognition error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.error = error
                            self.recognitionStatus = "Error: \(error.localizedDescription)"
                        }
                        isFinal = true
                    }
                    
                    // Handle completion
                    if isFinal {
                        self.updateDebugInfo("Recognition task marked as final")
                        DispatchQueue.main.async {
                            self.stopRecording()
                        }
                    }
                }
                
                // Configure the microphone input
                self.updateDebugInfo("Setting up microphone input tap")
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    // Check if we're still recording and have a valid request
                    if self.isRecording && self.recognitionRequest != nil {
                        self.recognitionRequest?.append(buffer)
                    }
                }
                
                // Start the audio engine
                self.updateDebugInfo("Preparing audio engine")
                self.audioEngine.prepare()
                
                self.updateDebugInfo("Starting audio engine")
                try self.audioEngine.start()
                DispatchQueue.main.async {
                    self.audioEngineStatus = "Running"
                }
                
                // Update state
                DispatchQueue.main.async {
                    // Confirm isRecording is true for UI
                    self.isRecording = true
                    
                    // Start a timer to track recording duration
                    self.updateDebugInfo("Starting recording timer")
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        self.recordingTime += 0.1
                        
                        // Update debug every second
                        if Int(self.recordingTime * 10) % 10 == 0 {
                            self.updateDebugInfo("Recording time: \(String(format: "%.1f", self.recordingTime))s")
                        }
                        
                        // Limit recording to 90 seconds
                        if self.recordingTime >= 90.0 {
                            self.updateDebugInfo("Recording time limit reached")
                            self.stopRecording()
                        }
                    }
                }
                
                self.updateDebugInfo("Started recording successfully")
            } catch {
                self.updateDebugInfo("Audio engine setup failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = error
                    self.audioEngineStatus = "Error: \(error.localizedDescription)"
                    self.isRecording = false
                }
            }
        }
    }
    
    private func resetAudioSession() {
        updateDebugInfo("Resetting audio session")
        // Reset the audio session to ensure a clean state
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            updateDebugInfo("Audio session reset successfully")
        } catch {
            updateDebugInfo("Failed to reset audio session: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        // Only execute if we're recording
        guard isRecording || audioEngine.isRunning else {
            updateDebugInfo("stopRecording() called but not recording")
            return
        }
        
        updateDebugInfo("Stopping recording - isRecording: \(isRecording), audioEngine running: \(audioEngine.isRunning)")
        
        // First, capture the final text from recognizedText (make sure we have it before cleanup)
        let finalText = recognizedText
        updateDebugInfo("Captured final text: \(finalText)")
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
        
        // Stop the audio engine and end the recognition session
        if audioEngine.isRunning {
            updateDebugInfo("Stopping audio engine")
            audioEngine.stop()
            DispatchQueue.main.async {
                self.audioEngineStatus = "Stopped"
            }
            
            updateDebugInfo("Ending audio recognition request")
            recognitionRequest?.endAudio()
            
            // Remove the tap on the audio input
            updateDebugInfo("Removing audio input tap")
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Clean up
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Ensure text gets saved
        updateDebugInfo("Saving final text: \(finalText)")
        
        // Update state
        DispatchQueue.main.async {
            // First, ensure final text is set before changing isRecording
            // This ensures observers see the final text
            self.text = finalText 
            
            // Delay turning off recording state slightly to ensure UI updates first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Then update recording state
                self.isRecording = false
                
                // Call the completion callback with the final text
                self.updateDebugInfo("Calling onFinishRecording callback with text: \(finalText)")
                if !finalText.isEmpty {
                    self.onFinishRecording?(finalText)
                } else {
                    self.updateDebugInfo("Skipping empty text callback")
                }
                
                self.recognitionStatus = "Completed"
            }
        }
        
        // Deactivate audio session
        do {
            updateDebugInfo("Deactivating audio session")
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = error
            updateDebugInfo("Error deactivating audio session: \(error.localizedDescription)")
        }
        
        updateDebugInfo("Recording stopped completely")
    }
    
    // Handle availability changes
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        updateDebugInfo("Speech recognition availability changed: \(available)")
    }
    
    deinit {
        updateDebugInfo("SpeechRecognizer being deallocated")
        stopRecording()
    }
} 