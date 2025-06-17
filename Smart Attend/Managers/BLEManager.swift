import Foundation
import CoreBluetooth
import Combine
import UIKit

class StudentBLEManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var status: BLEStatus = .unknown
    @Published var isScanning: Bool = false
    @Published var targetRoomDetected: Bool = false
    @Published var detectedDevice: BLEDevice?
    @Published var showingBluetoothPrompt: Bool = false
    @Published var bluetoothPromptType: BluetoothPromptType = .poweredOff
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var targetRoom: String = ""
    private var scanTimer: Timer?
    private let scanTimeout: TimeInterval = 30.0
    private var hasRequestedPermission: Bool = false
    
    // Callbacks
    var onRoomDetected: ((BLEDevice) -> Void)?
    var onBluetoothIssue: ((BluetoothPromptType) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCentralManager()
    }
    
    // MARK: - Setup Methods
    private func setupCentralManager() {
        // Initialize WITHOUT automatic permission request and native alerts
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: [
            CBCentralManagerOptionShowPowerAlertKey: false // Suppress native power alerts
        ])
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for specific room with correct permission handling
    func startScanningForRoom(_ room: String) {
        // Clean room name
        targetRoom = room.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        print("🔍 Attempting to start BLE scan for room: \(targetRoom)")
        
        // Check current Bluetooth state
        switch centralManager.state {
        case .poweredOn:
            performScan()
            
        case .poweredOff:
            print("❌ Bluetooth is powered off (permission granted)")
            showBluetoothPrompt(type: .poweredOff)
            
        case .unauthorized:
            print("❌ Bluetooth permission denied")
            showBluetoothPrompt(type: .unauthorized)
            
        case .unsupported:
            print("❌ Bluetooth not supported")
            showBluetoothPrompt(type: .unsupported)
            
        case .unknown, .resetting:
            print("⚠️ Bluetooth state unknown/resetting - waiting for state...")
            status = .unknown
            // Will handle when state becomes known
            
        @unknown default:
            print("⚠️ Unknown Bluetooth state")
            status = .unknown
        }
    }
    
    /// Retry scanning after user handles Bluetooth issue
    func retryScanning() {
        guard !targetRoom.isEmpty else {
            print("❌ No target room set for retry")
            return
        }
        
        dismissBluetoothPrompt()
        
        // Small delay to allow UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startScanningForRoom(self.targetRoom)
        }
    }
    
    /// Stop scanning
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        
        if targetRoomDetected {
            status = .deviceFound
        } else {
            status = centralManager.state == .poweredOn ? .poweredOn : .poweredOff
        }
        
        print("⏹️ Stopped BLE scanning")
    }
    
    /// Reset detection state
    func resetDetection() {
        targetRoomDetected = false
        detectedDevice = nil
        targetRoom = ""
        dismissBluetoothPrompt()
    }
    
    /// Show Bluetooth prompt
    func showBluetoothPrompt(type: BluetoothPromptType) {
        DispatchQueue.main.async {
            self.bluetoothPromptType = type
            self.showingBluetoothPrompt = true
            self.onBluetoothIssue?(type)
        }
    }
    
    /// Dismiss Bluetooth prompt
    func dismissBluetoothPrompt() {
        DispatchQueue.main.async {
            self.showingBluetoothPrompt = false
        }
    }
    
    /// Open iOS Settings (only for permission issues)
    func openBluetoothSettings() {
        // Only open settings for permission-related issues
        guard bluetoothPromptType == .unauthorized else {
            print("ℹ️ Settings not needed for simple Bluetooth off prompt")
            return
        }
        
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            print("❌ Failed to create settings URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { success in
                print(success ? "✅ Opened App Settings for permission" : "❌ Failed to open Settings")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performScan() {
        print("🔍 Starting BLE scan for room: \(targetRoom)")
        
        // Reset detection state
        targetRoomDetected = false
        detectedDevice = nil
        
        // Start scanning for all devices
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        
        isScanning = true
        status = .scanning
        
        // Set timeout for scanning
        setupScanTimeout()
    }
    
    private func setupScanTimeout() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanTimeout, repeats: false) { _ in
            if self.isScanning && !self.targetRoomDetected {
                print("⏰ BLE scan timeout - no target room found")
                self.stopScanning()
            }
        }
    }
    
    private func processDiscoveredDevice(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        // Get device name from advertisement data or peripheral name
        let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ??
                        peripheral.name ??
                        "Unknown Device"
        
        // Check if this device matches our target room
        if doesDeviceMatchTargetRoom(deviceName: deviceName) {
            print("🎯 Target room device detected!")
            print("   📱 Device Name: \(deviceName)")
            print("   🏢 Target Room: \(targetRoom)")
            print("   📶 RSSI: \(rssi)")
            
            // Extract subject code from advertisement data
            let subjectData = SubjectData(from: advertisementData)
            
            let detectedBLEDevice = BLEDevice(
                peripheral: peripheral,
                name: deviceName,
                rssi: rssi,
                advertisementData: advertisementData,
                subjectCode: subjectData.code,
                rawSubjectData: subjectData.rawData,
                discoveredAt: Date()
            )
            
            // Update detection state
            targetRoomDetected = true
            detectedDevice = detectedBLEDevice
            status = .deviceFound
            
            // Stop scanning once we find our target
            stopScanning()
            
            // Notify callback
            onRoomDetected?(detectedBLEDevice)
        }
    }
    
    private func doesDeviceMatchTargetRoom(deviceName: String) -> Bool {
        let cleanDeviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cleanDeviceName.hasPrefix(targetRoom) {
            let remainingPart = String(cleanDeviceName.dropFirst(targetRoom.count))
            
            if remainingPart.count == 3 && remainingPart.allSatisfy({ $0.isNumber }) {
                return true
            }
            
            if cleanDeviceName == targetRoom {
                return true
            }
        }
        
        return false
    }
    
    deinit {
        scanTimer?.invalidate()
        if isScanning {
            centralManager?.stopScan()
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension StudentBLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            status = .poweredOn
            print("✅ Bluetooth is powered on")
            
            // If we were waiting to scan, start now
            if !targetRoom.isEmpty && !isScanning {
                performScan()
            }
            
        case .poweredOff:
            status = .poweredOff
            isScanning = false
            targetRoomDetected = false
            detectedDevice = nil
            print("❌ Bluetooth is powered off (permission exists)")
            
            // Show simple turn-on prompt (permission already granted)
            if !targetRoom.isEmpty {
                showBluetoothPrompt(type: .poweredOff)
            }
            
        case .unauthorized:
            status = .unauthorized
            isScanning = false
            print("❌ Bluetooth permission denied by user")
            
            // Show permission prompt (user denied access)
            if !targetRoom.isEmpty {
                showBluetoothPrompt(type: .unauthorized)
            }
            
        case .unsupported:
            status = .unsupported
            isScanning = false
            print("❌ Bluetooth not supported on this device")
            
            if !targetRoom.isEmpty {
                showBluetoothPrompt(type: .unsupported)
            }
            
        case .resetting:
            status = .unknown
            isScanning = false
            print("🔄 Bluetooth is resetting...")
            
        case .unknown:
            status = .unknown
            print("⚠️ Bluetooth state unknown - waiting for permission response...")
            // Don't show prompts here - let iOS handle initial permission request
            
        @unknown default:
            status = .unknown
            print("⚠️ Unknown Bluetooth state encountered")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Only process if we're actively scanning for a target room
        guard isScanning && !targetRoom.isEmpty && !targetRoomDetected else {
            return
        }
        
        processDiscoveredDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
}

// MARK: - Bluetooth Prompt Types
enum BluetoothPromptType {
    case poweredOff        // Bluetooth is off but permission granted
    case unauthorized      // Bluetooth permission denied
    case unsupported      // Device doesn't support Bluetooth
    
    var title: String {
        switch self {
        case .poweredOff:
            return "Bluetooth is Off"
        case .unauthorized:
            return "Bluetooth Permission Required"
        case .unsupported:
            return "Bluetooth Not Supported"
        }
    }
    
    var message: String {
        switch self {
        case .poweredOff:
            return "Please turn on Bluetooth to detect classroom devices for attendance marking."
        case .unauthorized:
            return "Smart Attend needs Bluetooth access to detect classroom devices. Please enable Bluetooth permission in Settings."
        case .unsupported:
            return "This device doesn't support Bluetooth, which is required for attendance marking."
        }
    }
    
    var actionTitle: String {
        switch self {
        case .poweredOff:
            return "Open Settings"
        case .unauthorized:
            return "Open Settings"
        case .unsupported:
            return "OK"
        }
    }
    
    var showSettings: Bool {
        switch self {
        case .poweredOff, .unauthorized:
            return true
        case .unsupported:
            return false
        }
    }
    
    var isSimplePrompt: Bool {
        switch self {
        case .poweredOff:
            return true  // Simple turn-on prompt
        case .unauthorized, .unsupported:
            return false // Full permission prompt
        }
    }
}
