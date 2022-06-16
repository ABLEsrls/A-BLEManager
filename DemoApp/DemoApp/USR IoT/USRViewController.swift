//
//  LetsViewController.swift
//  DemoApp
//
//  Created by Riccardo Paolillo on 18/12/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation
import ABLEManager
import UIKit


class USRViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var deviceList = [PeripheralDevice]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        USRManager.shared.registerConnectionObserver { isConnected in
            print("USR is connected? \(isConnected)")
        }
        
        /*
         USRManagerManager.shared.searchAndConnect { (device) in
            print("Connesso con \(device.peripheralName)")
        }
        */
        
        USRManager.shared.scanning(["FE"]) { devices in
            self.deviceList = devices
            self.tableView.reloadData()
        }
    }
}


extension USRViewController {
    @IBAction func closePressed(_ sender: UIButton?) {
        self.dismiss(animated: true)
    }
    
    @IBAction func scanningPressed(_ sender: UIButton?) {
        USRManager.shared.stopScan()
        
        self.deviceList = [PeripheralDevice]()
        self.tableView.reloadData()
        
        USRManager.shared.scanning(["FE"]) { devices in
            self.deviceList = devices
            self.tableView.reloadData()
        }
    }
}


extension USRViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text       = self.deviceList[indexPath.row].peripheralName
        cell.detailTextLabel?.text = self.deviceList[indexPath.row].characteristics.representableString
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        USRManager.shared.stopScan()
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        cell.accessoryView = self.createSpinner()
        USRManager.shared.connect(to: self.deviceList[indexPath.row], timeout: 10) { device in
            cell.accessoryView = nil
            
            guard let device = device else {
                print("Unable to connect to selected device")
                return
            }
            print("Connected:       \(true)")
            print("Services:        \(device.services)")
            print("Characteristics: \(device.characteristics)")
            
            DispatchQueue.global().async {
                USRManager.shared.send(command: USRCommand.authCommand)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let choices = UIAlertController(title: "USR", message: "Scegli la modalità", preferredStyle: .actionSheet)
                choices.popoverPresentationController?.sourceView = cell
                choices.addAction(UIAlertAction(title: "One Message", style: .default) { action in
                    self.performSegue(withIdentifier: "kShowDetailMessage", sender: self)
                })
                choices.addAction(UIAlertAction(title: "Stream Messages", style: .default) { action in
                    self.performSegue(withIdentifier: "kShowDetailStream", sender: self)
                })
                choices.addAction(UIAlertAction(title: "Annulla", style: .destructive))
                self.present(choices, animated: true)
            }
        }
    }
    
    
    func createSpinner() -> UIActivityIndicatorView {
        let view             = UIActivityIndicatorView(style: .gray)
        view.backgroundColor = .clear
        view.style           = .gray
        view.tintColor       = .gray
        view.color           = .gray
        view.startAnimating()
        return view
    }
}
