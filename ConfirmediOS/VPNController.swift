//
//  VPNController.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import CocoaLumberjackSwift

class VPNController: NSObject {
    
    
    //MARK: - PROXY METHODS
    /*
        * proxy is used for whitelisting
        * route traffic directly to site for approved domains
     */
    static func setupWhitelistingProxy() {
        
        Utils.setupWhitelistedDefaults()
        let vpnManager = NEVPNManager.shared()
        vpnManager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if !vpnManager.isEnabled {
                return
            }
            
            NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
                if let managers = managers {
                    let manager: NETunnelProviderManager
                    if managers.count > 0 {
                        manager = managers[0]
                    } else {
                        manager = NETunnelProviderManager()
                        manager.protocolConfiguration = NETunnelProviderProtocol()
                    }
                    
                    manager.localizedDescription = "Confirmed VPN Configuration"
                    manager.protocolConfiguration?.serverAddress = "Confirmed VPN"
                    manager.isEnabled = true
                    manager.isOnDemandEnabled = true
                    
                    let connectRule = NEOnDemandRuleConnect()
                    connectRule.interfaceTypeMatch = .any
                    manager.onDemandRules = [connectRule]
                    manager.saveToPreferences(completionHandler: { (error) -> Void in
                        
                    })
                }else{
                    
                }
            }
        })
    }
    
    /*
        * disable & re-enable proxy
        * primarily to reload whitelist rules
     */
    static func toggleWhitelistingProxy() {
        disableWhitelistingProxy(proxyDisabledCallback: {(error) -> Void in
            setupWhitelistingProxy()
        })
    }
    
    /*
        * disable proxy
        * should be synchronized with VPN state
     */
    static func disableWhitelistingProxy(proxyDisabledCallback: ((_ error: Error?) -> Void)? = nil) {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in

            NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
                if let managers = managers {
                    let manager: NETunnelProviderManager
                    if managers.count > 0 {
                        manager = managers[0]
                    }else{
                        manager = NETunnelProviderManager()
                        manager.protocolConfiguration = NETunnelProviderProtocol()
                    }
                    
                    manager.isEnabled = false
                    manager.isOnDemandEnabled = false
                    let connectRule = NEOnDemandRuleConnect()
                    connectRule.interfaceTypeMatch = .any
                    manager.onDemandRules = [connectRule]
                    manager.saveToPreferences(completionHandler: { (error) -> Void in
                        proxyDisabledCallback?(error)
                    })
                }else{
                    proxyDisabledCallback?(error)
                }
            }
        })
        
    }
    
    //MARK: - VPN FUNCTIONS
    
    /*
        * only called internally
        * check for appropriate parameters and set up/install
        * enable on completion of setup
    */
    private static func setupAndEnableVPN() -> Bool {
        let domain = Utils.getSavedRegion()
        
        if let p12base64 = Global.keychain[Global.kConfirmedP12Key], let UUID = Global.keychain[Global.kConfirmedID], let dataEncoded = Data(base64Encoded: p12base64, options: .ignoreUnknownCharacters)  {
            self.setupVPN(ipAddress: domain, p12data: dataEncoded, p12Pass: Global.vpnPassword, localId: UUID, completion: {
                self.enableVPN()
            })
                
            return true
        }
        
        return false
    }
    
    /*
        * master function for initiating VPN connections
     */
    static  func connectToVPN() { //if we have a valid P12 file, attempt connection
        
        //try to setup VPN
        if !setupAndEnableVPN() {
            //if fails, try to recover with a sign in
            Auth.getKey(callback: {(_ status: Bool, _ reason: String, errorCode : Int) -> Void in
                if status {
                    let didSetupVPN = setupAndEnableVPN()
                    print("Did setup VPN \(didSetupVPN)")
                }
                else {
                    if errorCode == Global.kInternetDownError {
                        NotificationCenter.post(name: .internetDownNotification)
                    }
                }
            })
        }
        
    }
    
    static func disconnectFromVPN() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            NEVPNManager.shared().isOnDemandEnabled = false
            manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                do {
                    NEVPNManager.shared().connection.stopVPNTunnel();
                }
            })
        })
        disableWhitelistingProxy()
    }
    
    /*
        * ensure the VPN & whitelisting proxy are in sync
        * proxy follows status of VPN
     */
    static func syncVPNAndWhitelistingProxy() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if manager.connection.status == .connected || manager.connection.status == .connecting || manager.isOnDemandEnabled {
                VPNController.setupWhitelistingProxy()
            }
            else {
                VPNController.disableWhitelistingProxy()
            }
        })
    }
    
    static func forceVPNOff() {
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            if !manager.isEnabled {
                return
            }
            DDLogInfo("Loading Error \(String(describing: error))")
            var p = NEVPNProtocolIKEv2()
            if let pc = manager.protocolConfiguration {
                p = pc as! NEVPNProtocolIKEv2
            }
            
            //null the address
            p.serverAddress = "local." + Global.vpnDomain
            p.serverCertificateIssuerCommonName = "local." + Global.vpnDomain
            p.remoteIdentifier = "local." + Global.vpnDomain
            
            p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.high
           
            manager.protocolConfiguration = p
            manager.isOnDemandEnabled = false
            manager.isEnabled = false
            manager.localizedDescription! = Global.vpnName
            
            manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                if let e = error {
                    DDLogError("Error with saving config \(e)")
                }
            })
        })
        
        disableWhitelistingProxy()
    }
    
    private static func enableVPN() {
        let manager = NEVPNManager.shared()
        
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            manager.isOnDemandEnabled = true
            manager.isEnabled = true
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            manager.onDemandRules = [connectRule]
            
            manager.protocolConfiguration?.disconnectOnSleep = false
            manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                do {
                    DDLogInfo("Starting VPN")
                    try NEVPNManager.shared().connection.startVPNTunnel();
                }
                catch {
                    DDLogError("Failed to start vpn: \(error)")
                }
            })
        })
        
        setupWhitelistingProxy()
    }
    
    static func reloadWhitelistRules() {
        VPNController.disconnectFromVPN()
        DispatchQueue.main.async {
            VPNController.connectToVPN()
            VPNController.toggleWhitelistingProxy()
        }
    }
    
    private  static func setupVPN(ipAddress : String, p12data : Data, p12Pass : String, localId: String, completion: @escaping () -> Void) {
        let manager = NEVPNManager.shared()
        
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            let p = NEVPNProtocolIKEv2()
            
            p.serverAddress = ipAddress
            p.serverCertificateIssuerCommonName = Global.remoteIdentifier
            p.remoteIdentifier = Global.remoteIdentifier
            
            p.certificateType = NEVPNIKEv2CertificateType.ECDSA256
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate
            p.localIdentifier = localId
            p.useExtendedAuthentication = false
            p.disconnectOnSleep = false
            p.enablePFS = true
            
            p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group19
            p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
            p.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA512
            p.childSecurityAssociationParameters.lifetimeMinutes = 1440
            
            p.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group19
            p.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
            p.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA512
            p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
            
            p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.high
            p.identityData = p12data
            p.identityDataPassword = p12Pass
            
            manager.protocolConfiguration = p
            manager.isOnDemandEnabled = true
            
            
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            
            manager.onDemandRules = [connectRule]
            DDLogInfo("VPN status:  \(manager.connection.status)")
            manager.localizedDescription! = Global.vpnName
            
            manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                if let e = error {
                    DDLogError("Saving Error \(e)")
                    
                    if ((error! as NSError).code == 4) { //if config is stale, probably multithreading bug. Can this be fixed w/ a lock?
                        DDLogInfo("Trying again")
                        self.setupVPN(ipAddress: ipAddress, p12data: p12data, p12Pass: p12Pass, localId: localId, completion: {
                            completion()
                        })
                    }
                }
                else {
                    completion()
                }
            })
        })
    }

}
