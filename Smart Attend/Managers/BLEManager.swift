import Foundation
import CoreBluetooth
import Combine

class StudentBLEManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var status: BLEStatus = .unknown
    @Published var isScanning: Bool = false
    @Published var targetRoomDetected: Bool = false
    @Published var detectedDevice: BLEDevice?
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var targetRoom: String = ""
    private var scanTimer: Timer?
    private let scanTimeout: TimeInterval = 30.0
    
    // Callbacks
    var onRoomDetected: ((BLEDevice) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCentralManager()
    }
    
    // MARK: - Setup Methods
    private func setupCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for specific room
    func startScanningForRoom(_ room: String) {
        guard centralManager.state == .poweredOn else {
            print("❌ Cannot start scanning - Bluetooth not powered on")
            return
        }
        
        // Clean room name (remove any spaces/special chars and convert to uppercase)
        targetRoom = room.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
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
    
    /// Stop scanning
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        
        if targetRoomDetected {
            status = .deviceFound
        } else {
            status = .poweredOn
        }
        
        print("⏹️ Stopped BLE scanning")
    }
    
    /// Reset detection state
    func resetDetection() {
        targetRoomDetected = false
        detectedDevice = nil
        targetRoom = ""
    }
    
    // MARK: - Private Methods
    
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
        // Device name format: "ROOM123" where ROOM is the room name and 123 are 3 digits
        // We need to match the room part (ignoring the 3 digits at the end)
        
        let cleanDeviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // If the device name starts with our target room, it's a match
        // This handles cases like "LT101123" matching target "LT101"
        if cleanDeviceName.hasPrefix(targetRoom) {
            // Check if the remaining part is exactly 3 digits
            let remainingPart = String(cleanDeviceName.dropFirst(targetRoom.count))
            
            // If remaining part is exactly 3 digits, it's a match
            if remainingPart.count == 3 && remainingPart.allSatisfy({ $0.isNumber }) {
                return true
            }
            
            // Also accept if the device name is exactly the target room
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
            
        case .poweredOff:
            status = .poweredOff
            isScanning = false
            targetRoomDetected = false
            detectedDevice = nil
            print("❌ Bluetooth is powered off")
            
        case .unauthorized:
            status = .unauthorized
            print("❌ Bluetooth permission denied")
            
        case .unsupported:
            status = .unsupported
            print("❌ Bluetooth not supported on this device")
            
        default:
            status = .unknown
            print("⚠️ Bluetooth state unknown")
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
