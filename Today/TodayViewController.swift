//
//  TodayViewController.swift
//  Today
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NotificationCenter
import NetworkExtension
import CloudKit
import CocoaLumberjackSwift
import Alamofire

class TodayViewController: UIViewController, NCWidgetProviding {
    //MARK: - OVERRIDES
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage.powerIconPadded
        toggleVPN?.setImage(image, for: .normal)
        
        self.toggleVPN.layer.borderWidth = 2.0
        self.toggleVPN.layer.borderColor = UIColor.tunnelsBlueColor.cgColor
        self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.size.width / 2.0
        self.toggleVPN?.tintColor = .tunnelsBlueColor
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: NEVPNManager.shared().connection, queue: OperationQueue.main) { (notification) -> Void in
            if NEVPNManager.shared().connection.status == .connected {
                self.setVPNButtonConnected()
            } else if NEVPNManager.shared().connection.status == .disconnected {
                self.setVPNButtonDisconnected()
            } else if NEVPNManager.shared().connection.status == .connecting {
                self.setVPNButtonConnecting()
            }
            else if NEVPNManager.shared().connection.status == .disconnecting {
                self.setVPNButtonDisconnecting()
            }
            DDLogInfo("VPN Status: \(NEVPNManager.shared().connection.status.rawValue)");
        }
        
        setupVPNButtons()
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        
    }
    
    @available(iOS 10.0, *)
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: 170)
        }else if activeDisplayMode == .compact{
            self.preferredContentSize = CGSize(width: maxSize.width, height: 110)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupVPNButtons()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - ACTION
    @IBAction func startSpeedTest (sender: UIButton) {
        UIView.transition(with: self.speedTestButton,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.speedTestButton.setTitle("Speed".localized() + ": ...", for: .normal)
            }, completion: nil)
        
        TunnelSpeed().testDownloadSpeedWithTimout(timeout: 10.0) { (megabytesPerSecond, error) -> () in
            if megabytesPerSecond > 0 {
                DispatchQueue.main.async {
                    UIView.transition(with: self.speedTestButton,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                                        self?.speedTestButton.setTitle("Speed".localized() + ": " + String(format: "%.1f", megabytesPerSecond) + " Mbps", for: .normal)
                        }, completion: nil)
                }
                
            } else {
                DDLogError("NETWORK ERROR: \(String(describing: error))")
                DispatchQueue.main.async {
                    UIView.transition(with: self.speedTestButton,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                                        self?.speedTestButton.setTitle("Speed".localized() + ": " + "N/A", for: .normal)
                        }, completion: nil)
                }
            }
        }
    }
    
    @IBAction func toggleVPNButton(sender: UIButton) {
        let manager = NEVPNManager.shared()
        
        if manager.isEnabled == false {
            openApp()
            return
        }
        
        self.toggleVPN.setImage(nil, for: .normal)
        toggleVPN.startLoadingAnimation()
        
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if manager.connection.status == .disconnected || manager.connection.status == .invalid {
                self.startVPN()
            }
            else {
                self.stopVPN()
            }
        })
      
    }
    
    func setupVPNButtons() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if manager.connection.status == .disconnected || manager.connection.status == .invalid {
                self.setVPNButtonDisconnected()
            }
            else if manager.connection.status == .connected {
                self.setVPNButtonConnected()
            }
            else {
                self.setVPNButtonConnecting()
            }
            self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.width / 2.0
        })
        
        determineIP()
    }
    
    func determineIP() {
        self.ipAddress?.text = "IP".localized() + ": ..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            let sessionManager = Alamofire.SessionManager.default
            sessionManager.retrier = nil
            URLCache.shared.removeAllCachedResponses()
            sessionManager.request(Global.getIPURL, method: .get).responseJSON { response in
                switch response.result {
                case .success:
                    if let json = response.result.value as? [String: Any], let publicIPAddress = json["ip"] as? String {
                        print(publicIPAddress)
                        self.ipAddress?.text = publicIPAddress
                    }
                    else {
                        self.ipAddress?.text = "IP".localized() + ": N/A"
                    }
                case .failure(let error):
                    DDLogError("Error loading IP Address \(error)")
                    self.ipAddress?.text = "IP".localized() + ": N/A"
                }
            }
        })
    }
    
    func openApp() {
        let tunnelsURL = URL.init(string: "tunnels://")
        self.extensionContext?.open(tunnelsURL!, completionHandler: nil)
    }
    
    @IBAction func changeCountry (sender: UIButton) {
        openApp()
    }
    
    func setVPNButtonConnected() {
        self.toggleVPN.setOriginalState()
        self.toggleVPN.layer.cornerRadius = self.toggleVPN.frame.width / 2.0
        let image = UIImage.powerIconPadded
        toggleVPN?.setImage(image, for: .normal)
        determineIP()
        UIView.transition(with: self.vpnStatusLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.protectedText
                            self?.toggleVPN?.tintColor = .tunnelsBlueColor
                            self?.toggleVPN.layer.borderColor = UIColor.tunnelsBlueColor.cgColor
                            
            }, completion: nil)
    }
    
    func setVPNButtonDisconnected() {
        self.toggleVPN.setOriginalState()
        let image = UIImage.powerIconPadded
        toggleVPN?.setImage(image, for: .normal)
        UIView.setAnimationsEnabled(true)
        determineIP()
        UIView.transition(with: self.vpnStatusLabel,
                         duration: 0.25,
                         options: .transitionCrossDissolve,
                         animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.disconnectedText
                            self?.toggleVPN?.tintColor = UIColor.darkGray
                            self?.toggleVPN?.layer.borderColor = UIColor.darkGray.cgColor
                            
            }, completion: nil)
       
    }
    
    func setVPNButtonConnecting() {
        UIView.transition(with: self.vpnStatusLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.connectingText
            }, completion: nil)
    }
    
    func setVPNButtonDisconnecting() {
        UIView.transition(with: self.vpnStatusLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            self?.vpnStatusLabel.text = Global.disconnectingText
            }, completion: nil)
    }
    
    func startVPN() {
        VPNController.connectToVPN()
        createRemoteRecord(recordName: Global.kOpenTunnelRecord)
    }
    
    func createRemoteRecord(recordName : String) {
        let privateDatabase = CKContainer.init(identifier: Global.kICloudContainer).privateCloudDatabase
        let myRecord = CKRecord(recordType: recordName, zoneID: CKRecordZone.default().zoneID)
        
        privateDatabase.save(myRecord, completionHandler: ({returnRecord, error in
            if let err = error {
                DDLogError("Error saving record \(err)")
                //if there is an error, open the app and close manually, internet could be down
                self.openApp()
            } else {
                DDLogInfo("Successfully saved record")
            }
            
        }))
    }
    
    func stopVPN() {
        VPNController.disconnectFromVPN()
        createRemoteRecord(recordName: Global.kCloseTunnelRecord)
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    //MARK: - VARIABLES
    @IBOutlet weak var toggleVPN: TKTransitionSubmitButton!
    @IBOutlet weak var vpnStatusLabel: UILabel!
    @IBOutlet weak var ipAddress: UILabel!
    @IBOutlet weak var speedTestButton: UIButton!
}
