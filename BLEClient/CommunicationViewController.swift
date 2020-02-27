//
//  CommunicationViewController.swift
//  BLEClient
//
//  Created by Mickaël Debalme on 27/02/2020.
//  Copyright © 2020 Mickaël Debalme. All rights reserved.
//

import UIKit
import CoreBluetooth

class CommunicationViewController: UIViewController {

    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var sendTextField: UITextField!
    @IBOutlet weak var readTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        BLEManager.instance.setupDidDisconnectPeripheral { (p) in
            if let periph = BLEManager.instance.readyPeripherals.first {
                if p == periph {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        
        if let periph = BLEManager.instance.readyPeripherals.first,
            let name = periph.name {
                self.deviceNameLabel.text = name
            }
    }
    
    // On send button clicked
    @IBAction func sendButtonClicked(_ sender: Any) {
        
        sendTextField.text = ""
        
        if let text = sendTextField.text {
            if let periph = BLEManager.instance.readyPeripherals.first {
            
                let authUUID = CBUUID(string: "499D456C-8691-4D00-87E2-8A34FB7551A3")
                
                if let char = BLEManager.instance.getCharForUUID(authUUID, forPeripheral: periph),
                    let data = text.data(using: .utf8) {
                    periph.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
                }
            }
        }
    }
    
    @IBAction func readButtonClicked(_ sender: Any) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let periph = BLEManager.instance.readyPeripherals.first {
            BLEManager.instance.disconnectPeripheral(periph) { (p) in
                
                print("❌ " + (p.name ?? "Unknown") + " disconnected")
                
            }
        }
    }
}
