import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var status: BLEStatus = .unknown
    @Published var discoveredDevices: [BLEDevice] = []
    @Published var humbleCodersDevices: [BLEDevice] = []
    @Published var isScanning: Bool = false
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private let targetDeviceName = "Humble Coders"
    private var scanTimer: Timer?
    
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
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("❌ Cannot start scanning - Bluetooth not powered on")
            return
        }
        
        // Clear previous discoveries older than 30 seconds
        cleanupOldDevices()
        
        // Start scanning for all devices (no service UUID filter)
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        
        isScanning = true
        status = .scanning
        
        print("🔍 Started scanning for BLE devices...")
        
        // Set up timer to refresh old devices
        setupScanTimer()
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        
        if !humbleCodersDevices.isEmpty {
            status = .deviceFound
        } else {
            status = .poweredOn
        }
        
        print("⏹️ Stopped scanning")
    }
    
    func restartScanning() {
        stopScanning()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startScanning()
        }
    }
    
    // MARK: - Private Methods
    private func setupScanTimer() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.cleanupOldDevices()
        }
    }
    
    private func cleanupOldDevices() {
        let thirtySecondsAgo = Date().addingTimeInterval(-30)
        
        discoveredDevices.removeAll { device in
            device.discoveredAt < thirtySecondsAgo
        }
        
        humbleCodersDevices.removeAll { device in
            device.discoveredAt < thirtySecondsAgo
        }
        
        // Update status if no devices remain
        if humbleCodersDevices.isEmpty && status == .deviceFound {
            status = isScanning ? .scanning : .poweredOn
        }
    }
    
    private func processDiscoveredDevice(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        
        // Get device name from advertisement data or peripheral name
        let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ??
                        peripheral.name ??
                        "Unknown Device"
        
        print("📱 Discovered device: \(deviceName) | RSSI: \(rssi)")
        
        // Check if this is our target device
        if deviceName.contains(targetDeviceName) {
            
            // Extract subject code from advertisement data
            let subjectData = SubjectData(from: advertisementData)
            
            let newDevice = BLEDevice(
                peripheral: peripheral,
                name: deviceName,
                rssi: rssi,
                advertisementData: advertisementData,
                subjectCode: subjectData.code,
                rawSubjectData: subjectData.rawData,
                discoveredAt: Date()
            )
            
            // Add to general discovered devices
            if let existingIndex = discoveredDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                discoveredDevices[existingIndex] = newDevice
            } else {
                discoveredDevices.append(newDevice)
            }
            
            // Add to Humble Coders specific devices
            if let existingIndex = humbleCodersDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                humbleCodersDevices[existingIndex] = newDevice
            } else {
                humbleCodersDevices.append(newDevice)
            }
            
            status = .deviceFound
            
            print("✅ Found Humble Coders device!")
            print("   📋 Subject Code: \(subjectData.code)")
            print("   📊 RSSI: \(rssi)")
            print("   📡 Advertisement Data: \(advertisementData)")
        }
    }
    
    deinit {
        scanTimer?.invalidate()
        if isScanning {
            centralManager?.stopScan()
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            status = .poweredOn
            print("✅ Bluetooth is powered on")
            // Auto-start scanning when Bluetooth becomes available
            startScanning()
            
        case .poweredOff:
            status = .poweredOff
            isScanning = false
            humbleCodersDevices.removeAll()
            discoveredDevices.removeAll()
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
        
        // Process all discovered devices
        processDiscoveredDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🔗 Connected to: \(peripheral.name ?? "Unknown")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to: \(peripheral.name ?? "Unknown") - \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected from: \(peripheral.name ?? "Unknown")")
    }
}
