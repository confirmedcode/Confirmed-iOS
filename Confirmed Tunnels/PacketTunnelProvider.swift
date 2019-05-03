//
//  PacketTunnelProvider.swift
//  ConfirmedTunnel
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import TunnelKit
import NetworkExtension
import NEKit

class PacketTunnelProvider: TunnelKitProvider {
    
    //MARK: - OVERRIDES
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        if SharedUtils.getActiveProtocol() == OpenVPN.protocolName {
            super.startTunnel(options: options, completionHandler: completionHandler)
        }

        if proxyServer != nil {
            proxyServer.stop()
        }
        proxyServer = nil
        
        let settings = NEPacketTunnelNetworkSettings.init(tunnelRemoteAddress: proxyServerAddress)
        let ipv4Settings = NEIPv4Settings.init(addresses: ["10.0.0.8"], subnetMasks: ["255.255.255.0"])
        settings.ipv4Settings = ipv4Settings;
        settings.mtu = NSNumber.init(value: 1500)
        
        let proxySettings = NEProxySettings.init()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer.init(address: proxyServerAddress, port: Int(proxyServerPort))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        proxySettings.matchDomains = getProxyRules()
        proxySettings.autoProxyConfigurationEnabled = true
        proxySettings.proxyAutoConfigurationJavaScript = getJavascriptProxyForRules()
        
        settings.proxySettings = proxySettings;
        RawSocketFactory.TunnelProvider = self
        
        self.setTunnelNetworkSettings(settings, completionHandler: { error in
            self.proxyServer = GCDHTTPProxyServer.init(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
            try! self.proxyServer.start()
            completionHandler(error)
        })
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        interface = nil
        DNSServer.currentServer = nil
        RawSocketFactory.TunnelProvider = nil
        proxyServer.stop()
        proxyServer = nil
        
        completionHandler()
        exit(EXIT_SUCCESS)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        super.handleAppMessage(messageData, completionHandler: completionHandler)
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        super.sleep(completionHandler: completionHandler)
        completionHandler()
    }
    
    override func wake() {
        super.wake()
        return
    }
    
    //MARK: - ACTION

    func getJavascriptProxyForRules () -> String {
        let domains = getProxyRules()
        
        if domains.count == 0 {
            return "function FindProxyForURL(url, host) { return \"DIRECT\";}"
        }
        else {
            
            //forced URLs to go through VPN (right now just IP address to show to user)
            let forcedVPNConditions = "dnsDomainIs(host, \"ip.confirmedvpn.com\")"
            
            var conditions = ""
            for (index, domain) in domains.enumerated() {
                if index > 0 {
                    conditions = conditions + " || "
                }
                let formattedDomain = domain.replacingOccurrences(of: "*.", with: "")
                conditions = conditions + "dnsDomainIs(host, \"" + formattedDomain + "\")"
            }
            
            return "function FindProxyForURL(url, host) { if (\(forcedVPNConditions)) { return \"DIRECT\";} else if (\(conditions)) { return \"PROXY \(self.proxyServerAddress):\(self.proxyServerPort); DIRECT\"; } return \"DIRECT\";}"
        }
    }
    
    func getProxyRules() -> Array<String> {
        let domains = Utils.getConfirmedWhitelist()
        let userDomains = Utils.getUserWhitelist()
        
        var whitelistedDomains = Array<String>.init()
        
        //combine user rules with confirmed rules
        for (key, value) in domains {
            if (value as AnyObject).boolValue { //filter for approved by user
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key //wildcard for two part domains
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        for (key, value) in userDomains {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        return whitelistedDomains
    }
    
    //MARK: - VARIABLES
    
    let proxyServerPort : UInt16 = 9090;
    let proxyServerAddress = "127.0.0.1";
    var interface: TUNInterface!
    var proxyServer: ProxyServer!

}

