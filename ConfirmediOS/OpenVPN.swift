//
//  OpenVPN.swift
//  ConfirmediOS
//
//  Created by Rahul Dewan on 1/3/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import UIKit
import TunnelKit
import NetworkExtension

class OpenVPN: NSObject, ConfirmedVPNProtocol {
    var supportedRegions: Array<ServerRegion> = [ServerRegion.usEast]
    
    static let protocolName: String = "Open VPN"
    static let localizedName: String = "Confirmed Open VPN"
    let staticKeyString = "045cd8efa373fa1957cb073995d7ca329b05471a0cb9fcbdbab8de8ecdb7448b7644c43709f317e386d74b904f06419942a77c6e3804ecc779896d522ac48af46e440881fb9fb013f7bee0faf0526ef7b9daaff723b9c921eb839414c8d08ff59b43fefb7c1acbc53788388f230300ae6acb0859e31b50e6d620ea89f2982dd481c442f9c809bafe6661a0d1f0792202e9830c3d55aead977a20515c46944814d2ae176af66ebe77759f07bab5b4e399d0bc977d0963079b16a63185f94b71d19cdf6f823b1fbc697afbe14bfd8a93226cb37bf1962c9f7f9a60c3c9e7b5ab2db732841366bdd2a9c75f094afe7a7658e0735aa56db9b5b01d076f42a46bdd76"
    
    
    override init() {
        super.init()
        
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                return
            }
            
            var manager: NETunnelProviderManager?
            
            for m in managers! {
                if let p = m.protocolConfiguration as? NETunnelProviderProtocol {
                    if (p.providerBundleIdentifier == "com.confirmed.tunnels.Confirmed-Tunnels") {
                        self.ovpnManager = m
                        break
                    }
                }
            }
        }
        
        sleep(1)
    }
    
    func endpointForRegion(region : ServerRegion) -> String {
        if supportedRegions.contains(region) {
            return "\(region.rawValue)-open\(Global.sourceID).\(Global.vpnDomain)"
        }
        else {
            let firstRegion = supportedRegions[0] //should intelligently find best region in future
            Utils.setSavedRegion(region: firstRegion)
            return "\(firstRegion)-open\(Global.sourceID).\(Global.vpnDomain)"
        }
    }
    
    func disableWhitelistingProxy(completion: @escaping (Error?) -> Void) {
        
    }
    
    func setupVPN(completion: @escaping (Error?) -> Void) {
       
        guard let privateKeyValue = Global.keychain[Global.kConfirmedPrivateKey], let caCertValue = Global.keychain[Global.kConfirmedCACertKey], let clCertValue = Global.keychain[Global.kConfirmedCLCertKey] else {
            return
        }
        
        let privateKeyContainer = CryptoContainer(pem: privateKeyValue)
        let clCertContainer = CryptoContainer(pem: clCertValue)
        let caCertKeyContainer = CryptoContainer(pem: caCertValue)
        
        let hostname = endpointForRegion(region: Utils.getSavedRegion())
        let port = UInt16(443)
        var sessionBuilder = SessionProxy.ConfigurationBuilder(ca: caCertKeyContainer)
        sessionBuilder.cipher = .aes256gcm
        sessionBuilder.digest = .sha512
        sessionBuilder.renegotiatesAfter = 3600
        sessionBuilder.usesPIAPatches = false
        sessionBuilder.clientCertificate = clCertContainer
        sessionBuilder.clientKey = privateKeyContainer
        sessionBuilder.compressionFraming = .disabled
        sessionBuilder.keepAliveInterval = nil
        
        
        let key = StaticKey.init(data: Data(hex: staticKeyString), direction: StaticKey.Direction.client)
        sessionBuilder.tlsWrap = SessionProxy.TLSWrap(strategy: .crypt, key: key)
        var builder = TunnelKitProvider.ConfigurationBuilder(sessionConfiguration: sessionBuilder.build())
        let socketType: SocketType = .tcp //switchTCP.isOn ? .tcp : .udp
        
        builder.endpointProtocols = [EndpointProtocol(socketType, port)]
        //builder.mtu = 1350
        builder.shouldDebug = true
        builder.debugLogKey = "Log"
        
        let configuration = builder.build()
        
        let ovpnTunnel = try! configuration.generatedTunnelProtocol(
            withBundleIdentifier: "com.confirmed.tunnels.Confirmed-Tunnels",
            appGroup: "group.com.confirmed",
            hostname: hostname
        )
        
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                completion(error)
                return
            }
            
            var manager: NETunnelProviderManager?
            
            for m in managers! {
                if let p = m.protocolConfiguration as? NETunnelProviderProtocol {
                    if (p.providerBundleIdentifier == "com.confirmed.tunnels.Confirmed-Tunnels") {
                        manager = m
                        break
                    }
                }
            }
            
            if (manager == nil) {
                manager = NETunnelProviderManager()
            }
            
            manager?.loadFromPreferences(completionHandler: { error in
                if let error = error {
                    print("error reloading preferences: \(error)")
                    completion(error)
                    return
                }
                
                manager?.protocolConfiguration = ovpnTunnel
                manager?.localizedDescription = OpenVPN.localizedName
                
                manager?.saveToPreferences { (error) in
                    print("saving preferences")
                    if let error = error {
                        print("error saving preferences: \(error)")
                    }
                    completion(error)
                    self.ovpnManager = manager
                }
            })
        }
    }
    
    func connectToVPN() {
        setupVPN(completion: { error in
            NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
                if let error = error {
                    return
                }
                
                var manager: NETunnelProviderManager?
                
                for m in managers! {
                    if let p = m.protocolConfiguration as? NETunnelProviderProtocol {
                        if (p.providerBundleIdentifier == "com.confirmed.tunnels.Confirmed-Tunnels") {
                            manager = m
                            break
                        }
                    }
                }
                manager?.loadFromPreferences(completionHandler: { error in
                    manager?.isEnabled = true
                    manager?.isOnDemandEnabled = true
                    manager?.saveToPreferences { (error) in
                        print("saving preferences")
                        try? self.ovpnManager?.connection.startVPNTunnel()
                        if let error = error {
                            print("error saving preferences: \(error)")
                        }
                        self.ovpnManager = manager
                    }
                })
            }
            
        })
    }
    
    func disconnectFromVPN() {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                return
            }
            
            var manager: NETunnelProviderManager?
            
            for m in managers! {
                if let p = m.protocolConfiguration as? NETunnelProviderProtocol {
                    if (p.providerBundleIdentifier == "com.confirmed.tunnels.Confirmed-Tunnels") {
                        manager = m
                        break
                    }
                }
            }
            manager?.isEnabled = false
            manager?.isOnDemandEnabled = false
            manager?.saveToPreferences { (error) in
                print("saving preferences")
                if let error = error {
                    print("error saving preferences: \(error)")
                }
                self.ovpnManager = manager
            }
        }
    }
    
    func getStatus(completion: @escaping (_ status: NEVPNStatus) -> Void) -> Void {
        if let manager = ovpnManager {
            completion(manager.connection.status)
        }
        else {
            completion(.disconnected)
        }
    }
    
    var ovpnManager: NETunnelProviderManager?

}
