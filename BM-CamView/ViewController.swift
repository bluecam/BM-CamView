//
//  ViewController.swift
//  BM-CamView
//
//  Created by John Sherman on 10/1/23.
//

import Foundation
import UIKit
import BluetoothControl
import CameraControlInterface

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, InitialConnectionToUIDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_bluetoothCameras.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = m_bluetoothCameras.description
        return cell
    }
    
    
    @IBOutlet var cameraTableView : UITableView!
    @IBOutlet weak var messageLabel: UITextField!
    
    weak var m_initialConnectionInterfaceDelegate: InitialConnectionFromUIDelegate?
    var m_bluetoothCameras = [DiscoveredPeripheral]()
    var m_selectedCameraIdentifier: UUID?
    var m_connectionButtons = [UIButton]()
    var m_connectionTypeBluetooth = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraTableView.delegate = self
        cameraTableView.dataSource = self
        
        // Register as a InitialConnectionToUIDelegate with the CameraControlInterface,
        // and assign CameraControlInterface as our InitialConnectionFromUIDelegate.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cameraControlInterface: CameraControlInterface = appDelegate.cameraControlInterface
        cameraControlInterface.m_initialConnectionToUIDelegate = self
        m_initialConnectionInterfaceDelegate = cameraControlInterface
        
        // Disconnect any current connections
        m_initialConnectionInterfaceDelegate?.disconnect()
        
        // Clear cached cameras
        m_bluetoothCameras.removeAll()
        
        
        // Refresh both Bluetooth and USB connections
        m_initialConnectionInterfaceDelegate?.refreshDeviceList()
        
        if m_connectionTypeBluetooth {
            messageLabel.text = String.Localized("Information.Searching")
        } else {
            messageLabel.text = String.Localized("Information.OOPS")
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onConnectButtonClicked(_: Any) {
        if m_connectionTypeBluetooth {
            // Obtain the peripheral UUID of the highlighted camera,
            // and attempt to establish a Bluetooth connection.
            let selectedIndex = cameraTableView.indexPathForSelectedRow?.row
            if selectedIndex! >= 0 {
                let uuid: UUID = m_bluetoothCameras[selectedIndex!].peripheral.getPeripheralIdentifier()
                m_initialConnectionInterfaceDelegate?.attemptConnection(to: uuid)
                messageLabel.text = String.Localized("Information.Connecting")
            }
        }
        
    }
    //==================================================
    //    InitialConnectionToUIDelegate methods
    //==================================================
    func updateDiscoveredPeripheralList(_ discoveredPeripheralList: [DiscoveredPeripheral]) {
        // Remove all cached cameras.
        m_bluetoothCameras.removeAll()
        
        // Add all cameras from the updated discoveredPeripheralList.
        for peripheral in discoveredPeripheralList {
            m_bluetoothCameras.append(peripheral)
        }
        
        // Update UI to display our discovered cameras.
        cameraTableView.reloadData()
    }
    func onPairingFailed(_ peripheralName: String, resolution: BluetoothPairingFailureType) {
        // Failed to pair with a camera. This is most often due to out-of-date bonding info,
        // and can be fixed by clearing Bluetooth device info on both the camera and the host.
        // Display an appropriate modal information window.
        let subtitle = String(format: String.Localized("FailedPairingModal.Subtitle"), peripheralName)
        PresentModal(title: String.Localized("FailedPairingModal.Title"), subtitle: subtitle)
        messageLabel.text = ""
    }
    
    func onSuccessfulPairing(_: String) {
        messageLabel.text = String.Localized("Information.Connected")
    }
    
    func onIncompatibleProtocolVersion(_: String, cameraVersion: Int, appVersion: Int) {
        // MacOS SDK and camera protocol versions are incompatible.
        // Display an appropriate modal information window.
        let message = cameraVersion > appVersion ? String.Localized("Version.UpdateSDK") : String.Localized("Version.UpdateFirmware")
        let title = cameraVersion > appVersion ? String.Localized("Version.OldSDK") : String.Localized("Version.OldFirmware")
        PresentModal(title: title, subtitle: message)
    }
}

