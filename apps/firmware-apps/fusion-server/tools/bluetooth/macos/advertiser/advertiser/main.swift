import CoreBluetooth
import Foundation

class BluetoothAdvertiser: NSObject, CBPeripheralManagerDelegate {
  private var peripheralManager: CBPeripheralManager?
  private var transferCharacteristic: CBMutableCharacteristic?
  private var serviceUUID: CBUUID
  private var characteristicUUID: CBUUID
  private var isRunning = true
  private let advertisedName = "Bose Fusion Mini"

  override init() {
    self.serviceUUID = CBUUID(string: "B053")
    self.characteristicUUID = CBUUID(string: "AD10")
    super.init()
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    NSLog("[Bluetooth] State Changed")
    switch peripheral.state {
    case .poweredOn:
      NSLog("[Bluetooth] Powered on ✅")
      setupService()
    case .poweredOff:
      NSLog("[Bluetooth] Powered off ❌")
      exit(1)
    case .unsupported:
      NSLog("[Bluetooth] Unsupported ❌")
      exit(1)
    case .unauthorized:
      NSLog("[Bluetooth] Unauthorized ❌")
      exit(1)
    case .resetting:
      NSLog("[Bluetooth] Resetting ⚠️")
    case .unknown:
      NSLog("[Bluetooth] Unknown state ⚠️")
    @unknown default:
      NSLog("[Bluetooth] Unknown default state ⚠️")
    }
  }

  private func setupService() {
    transferCharacteristic = CBMutableCharacteristic(
      type: characteristicUUID,
      properties: [.read, .notify, .write],
      value: nil,
      permissions: [.readable, .writeable]
    )

    let transferService = CBMutableService(type: serviceUUID, primary: true)
    transferService.characteristics = [transferCharacteristic!]

    peripheralManager?.add(transferService)
    startAdvertising()
  }

  private func startAdvertising() {
    let advertisingData: [String: Any] = [
      CBAdvertisementDataLocalNameKey: advertisedName,
      CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
    ]

    peripheralManager?.startAdvertising(advertisingData)
    NSLog("[Bluetooth] Started advertising as '%@'", advertisedName)
    NSLog("[Bluetooth] Service UUID: %@", serviceUUID.uuidString)
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]
  ) {
    guard let request = requests.first else { return }

    NSLog("[Bluetooth] Write Request from %@", request.central.identifier.description)

    if let value = request.value,
      let receivedString = String(data: value, encoding: .utf8)
    {
      NSLog("[Bluetooth] Received data: %@", receivedString)
      NSLog("[Bluetooth] Data (Hex): %@", value.map { String(format: "%02hhx", $0) }.joined())
    }

    peripheral.respond(to: request, withResult: .success)
    NSLog("[Bluetooth] Write request handled successfully")
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    NSLog("[Bluetooth] Read Request from %@", request.central.identifier.description)

    let responseData = "Hello from \(advertisedName)!".data(using: .utf8)
    request.value = responseData

    peripheral.respond(to: request, withResult: .success)
    NSLog("[Bluetooth] Read request handled successfully")
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral,
    didSubscribeTo characteristic: CBCharacteristic
  ) {
    NSLog("[Bluetooth] Device %@ subscribed to updates", central.identifier.description)
    NSLog("[Bluetooth] Maximum update length: %d bytes", central.maximumUpdateValueLength)

    let welcomeData = "Welcome to \(advertisedName)!".data(using: .utf8)!
    peripheralManager?.updateValue(
      welcomeData, for: transferCharacteristic!, onSubscribedCentrals: [central])
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral,
    didUnsubscribeFrom characteristic: CBCharacteristic
  ) {
    NSLog("[Bluetooth] Device %@ unsubscribed", central.identifier.description)
  }

  func stopAdvertising() {
    peripheralManager?.stopAdvertising()
    NSLog("[Bluetooth] Stopped advertising")
    isRunning = false
  }
}

// Main program
NSLog("[Bluetooth] Starting advertiser")
let advertiser = BluetoothAdvertiser()

signal(SIGINT) { _ in
  NSLog("[Bluetooth] Stopping advertiser...")
  advertiser.stopAdvertising()
  exit(0)
}

RunLoop.main.run()
