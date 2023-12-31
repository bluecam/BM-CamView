/* -LICENSE-START-
 ** Copyright (c) 2018 Blackmagic Design
 **
 ** Permission is hereby granted, free of charge, to any person or organization
 ** obtaining a copy of the software and accompanying documentation covered by
 ** this license (the "Software") to use, reproduce, display, distribute,
 ** execute, and transmit the Software, and to prepare derivative works of the
 ** Software, and to permit third-parties to whom the Software is furnished to
 ** do so, all subject to the following:
 **
 ** The copyright notices in the Software and this entire statement, including
 ** the above license grant, this restriction and the following disclaimer,
 ** must be included in all copies of the Software, in whole or in part, and
 ** all derivative works of the Software, unless such copies or derivative
 ** works are solely in the form of machine-executable object code generated by
 ** a source language processor.
 **
 ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 ** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 ** FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 ** SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 ** FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 ** ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 ** DEALINGS IN THE SOFTWARE.
 ** -LICENSE-END-
 */

import Foundation
import UIKit
import BluetoothControl
import CameraControlInterface

class SelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, InitialConnectionToUIDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    

    // IBOutlets
    @IBOutlet weak var cameraTableView: UITableView!
    @IBOutlet weak var messageLabel: UITextField!
    
    @IBOutlet weak var connectionBluetoothRadioButton: UIButton!
    @IBOutlet weak var connectionUSBRadioButton: UIButton!
    
    // Member variables
    weak var m_initialConnectionInterfaceDelegate: InitialConnectionFromUIDelegate?
    var m_bluetoothCameras = [DiscoveredPeripheral]()
    
    var m_selectedCameraIdentifier: UUID?
    var m_connectionButtons = [UIButton]()
    var m_connectionTypeBluetooth = true

    //==================================================
    //    UIViewController methods
    //==================================================
    override func viewDidLoad() {
        m_connectionButtons.append(connectionBluetoothRadioButton)
        m_connectionButtons.append(connectionUSBRadioButton)
       

        // Assign self as the UITableViewDelegate and UITableViewDataSource of our cameraTableView
        cameraTableView.delegate = self
        cameraTableView.dataSource = self
    }

    func viewWillAppear() {
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
            messageLabel.text = String.Localized("Information.USBConnect")
        }

        super.viewWillAppear(true)
    }

    //==================================================
    //    IBActions
    //==================================================
    @IBAction func onConnectButtonClicked(_: Any) {
        if m_connectionTypeBluetooth {
            // Obtain the peripheral UUID of the highlighted camera,
            // and attempt to establish a Bluetooth connection.
            let selectedIndex = cameraTableView.indexPathForSelectedRow
            if selectedIndex >= 0 {
                let uuid: UUID = m_bluetoothCameras[selectedIndex].peripheral.getPeripheralIdentifier()
                m_initialConnectionInterfaceDelegate?.attemptConnection(to: uuid)
                messageLabel.text = String.Localized("Information.Connecting")
            }
        }
        
        }
    }

    

    //==================================================
    //    UITableViewDelegate methods
    //==================================================
    func numberOfRows(in _: UITableView) -> Int {
        if (m_connectionTypeBluetooth) {
            return m_bluetoothCameras.count
        }
       
    }

    func tableView(_: UITableView, objectValueFor _: UITableViewCell, row: Int) -> Any? {
        if (m_connectionTypeBluetooth) {
            return m_bluetoothCameras[row].name
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

    func transitionToCameraControl() {
        if let baseViewController = self.parent as? BaseViewController? {
            baseViewController?.switchToContentView()
        }
    }

    func onPairingFailed(_ peripheralName: String, resolution: BluetoothPairingFailureType) {
        // Failed to pair with a camera. This is most often due to out-of-date bonding info,
        // and can be fixed by clearing Bluetooth device info on both the camera and the host.
        // Display an appropriate modal information window.
        let subtitle = String(format: String.Localized("FailedPairingModal.Subtitle"), peripheralName)
        PresentModal(title: String.Localized("FailedPairingModal.Title"), subtitle: subtitle)
        messageLabel.stringValue = ""
    }
    
    func onSuccessfulPairing(_: String) {
        messageLabel.stringValue = String.Localized("Information.Connected")
    }

    func onIncompatibleProtocolVersion(_: String, cameraVersion: Int, appVersion: Int) {
        // MacOS SDK and camera protocol versions are incompatible.
        // Display an appropriate modal information window.
        let message = cameraVersion > appVersion ? String.Localized("Version.UpdateSDK") : String.Localized("Version.UpdateFirmware")
        let title = cameraVersion > appVersion ? String.Localized("Version.OldSDK") : String.Localized("Version.OldFirmware")
        PresentModal(title: title, subtitle: message)
    }
    
    func updateDiscoveredUSBPTPDevices(_ usbPTPDevices: [USBControl.USBBulkDevice]) {
        // Remove all cached cameras.
        m_usbPtpCameras.removeAll()
        
        // Add all cameras from the updated discoveredPeripheralList.
        for ptpDevice in usbPTPDevices {
            m_usbPtpCameras.append(ptpDevice)
        }
        
        // Update UI to display our discovered cameras.
        cameraTableView.reloadData()
    }
    
    func onConnectionFailed() {
        messageLabel.stringValue = String.Localized("DisconnectedModal.Title")
    }
}
