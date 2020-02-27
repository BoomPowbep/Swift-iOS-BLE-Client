//
//  ViewController.swift
//  BLEClient
//
//  Created by Mickaël Debalme on 27/02/2020.
//  Copyright © 2020 Mickaël Debalme. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    var peripherals = [CBPeripheral]()
    
    @IBOutlet weak var startButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
//        BLEManager.instance.setupDidDisconnectPeripheral { (periph) in
//            print(periph.name ?? "Unknown" + " disconnected")
//        }
    }


    @IBAction func startButtonClicked(_ sender: Any) {
        let _ = BLEManager.instance
    }
    
    
    @IBAction func scanButtonClicked(_ sender: Any) {
        BLEManager.instance.scan { (periph) in
            if(!self.peripherals.contains(periph)) { // If not present
                self.peripherals.append(periph) // Add to the list of periphs
                self.tableView.reloadData() // Update table view
            }
        }
    }
}

extension ViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let periph = peripherals[indexPath.row]
        BLEManager.instance.connectPeripheral(periph) { connectedPeriph in
            if connectedPeriph.state == .connected {
                print(connectedPeriph.name ?? "Unknown" + " is connected")
                
                // Trigger discover (readyPeriph is the same periph)
                BLEManager.instance.discoverPeripheral(connectedPeriph) { (readyPeriph) in
                    
                    BLEManager.instance.stopScan() // Stop scan to avoid battery consumption
                    
                    print("✅ Periph is ready: \(readyPeriph.name ?? "Unknown")")
                
                    self.performSegue(withIdentifier: "toCommunication", sender: self)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension ViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tbCell", for: indexPath)
        
        cell.textLabel?.text = peripherals[indexPath.row].name ?? "Unknown"
        
        return cell
    }
}

