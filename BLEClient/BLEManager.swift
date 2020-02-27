//
//  BLEManager.swift
//  BLEClient
//
//  Created by Mickaël Debalme on 27/02/2020.
//  Copyright © 2020 Mickaël Debalme. All rights reserved.
//

import Foundation
import CoreBluetooth

// 1. Scanner
// 2. Demande de connexion
// 3. Discovery
// 4. Communication

class BLEManager:NSObject {
    static let instance = BLEManager()
    
    var centralManager:CBCentralManager?
    
    var isBLEEnabled = false
    var isScanning = false
    
    var scanCallback: ((CBPeripheral) -> ())?
    var connectCallback: ((CBPeripheral) -> ())?
    var disconnectCallback: ((CBPeripheral) -> ())?
    var globalDisconnectCallback: ((CBPeripheral) -> ())?
    var didFinishDiscoveryCallback: ((CBPeripheral) -> ())?
    
    var connectedPeripherals = [CBPeripheral]()
    var readyPeripherals = [CBPeripheral]()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Scan for BLE devices
    func scan(callback:@escaping (CBPeripheral) -> ()) {
        scanCallback = callback
        isScanning = true
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // Stop the scan
    func stopScan() {
        isScanning = false
        centralManager?.stopScan()
    }
    
    // Connect to peripheral
    func connectPeripheral(_ periph: CBPeripheral, callback:@escaping (CBPeripheral) -> ()) {
        connectCallback = callback
        centralManager?.connect(periph, options: nil)
    }
    
    // On device disconnected
    func setupDidDisconnectPeripheral(callback:@escaping (CBPeripheral) -> ()) {
        globalDisconnectCallback = callback
    }
    
    // Inentional disconnect
    func disconnectPeripheral(_ periph: CBPeripheral, callback:@escaping (CBPeripheral) -> ()) {
        disconnectCallback = callback
        centralManager?.cancelPeripheralConnection(periph)
    }
    
    // Trigger discover
    func discoverPeripheral(_ periph: CBPeripheral, callback:@escaping (CBPeripheral) -> ()) {
        didFinishDiscoveryCallback = callback
        periph.delegate = self
        periph.discoverServices(nil)
    }
    
    
    func getCharForUUID(_ uuid:CBUUID, forPeripheral peripheral:CBPeripheral) -> CBCharacteristic? {
        
        if let services = peripheral.services {
            for service in services {
                if let characteristics = service.characteristics {
                    for char in characteristics {
                        if char.uuid == uuid {
                            return char
                        }
                    }
                }
            }
        }
        
        return nil
    }
}


extension BLEManager:CBPeripheralDelegate {
    
    // On serivces discovered (response from discoverPeripheral() above)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // On characteristics discovered (response from discoverCharacteristics() above)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let services = peripheral.services {
            let count = services.filter{ $0.characteristics == nil }.count
            if count == 0 {
                readyPeripherals.append(peripheral)
                didFinishDiscoveryCallback?(peripheral)
            }
        }
    }
}


extension BLEManager:CBCentralManagerDelegate {
    
    // On bluetooth state update (activated or deactivated)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            isBLEEnabled = true
        } else {
            isBLEEnabled = false
        }
        
        print("isBLEEnabled " + String(self.isBLEEnabled))
    }
    
    // On device discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        scanCallback?(peripheral)
    }
    
    // On device connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if !connectedPeripherals.contains(peripheral) {
            connectedPeripherals.append(peripheral)
            connectCallback?(peripheral)
        }
    }
    
    // On device disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // Remove all periphs that match the disconnected periph (supposed to be only one)
//            connectedPeripherals.removeAll { (periph) -> Bool in
//                periph == peripheral
//            }
        // Identical
        connectedPeripherals.removeAll { $0 == peripheral }
        readyPeripherals.removeAll { $0 == peripheral }
        
        disconnectCallback?(peripheral)
        globalDisconnectCallback?(peripheral)
    }
}
