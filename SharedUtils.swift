//
//  SharedUtils.swift
//
//  Shared functions between Mac & iOS
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit
#endif
import Foundation
import NetworkExtension
import CocoaLumberjackSwift
import CoreTelephony

class SharedUtils: NSObject {
    
    #if os(iOS)
    static let userDefaultsSuite = "group.com.confirmed"
    #else
    static let userDefaultsSuite = "group.com.confirmed.tunnelsMac"
    #endif
    
    public static let kActiveProtocol = "ConfirmedActiveProtocol"
    
    static func getSavedRegion() -> ServerRegion {
        DDLogInfo("API Version - \(Global.vpnSavedRegionKey)")
        if let reg = UserDefaults.standard.string(forKey: Global.vpnSavedRegionKey), let serverRegion = ServerRegion.init(rawValue: reg) {
            DDLogInfo("Getting saved region - \(reg)")
            return serverRegion
        }
        else {
            //intelligently determine area based on current region
            let theLocale = NSLocale.autoupdatingCurrent
            
            var nearestRegion = ServerRegion.usWest
            
            if theLocale.regionCode! == "US" {
                let theTZ = TimeZone.autoupdatingCurrent.abbreviation()!
                if theTZ == "EST" || theTZ == "EDT" || theTZ == "CST" {
                    nearestRegion = ServerRegion.usEast
                }
            }
            if theLocale.regionCode! == "GB" {
                nearestRegion = ServerRegion.euLondon
            }
            if theLocale.regionCode! == "IE" {
                nearestRegion = ServerRegion.euLondon
            }
            if theLocale.regionCode! == "CA"  {
                nearestRegion = ServerRegion.canada
            }
            if theLocale.regionCode! == "KO"  {
                nearestRegion = ServerRegion.seoul
            }
            if theLocale.regionCode! == "ID" /* Indonesia */ || theLocale.regionCode! == "SG" /* Singapore */ || theLocale.regionCode! == "MY" /* Malaysia */ || theLocale.regionCode! == "PH" /* Phillipines */ || theLocale.regionCode! == "TH" /* Thailand */ || theLocale.regionCode! == "TW" /* Taiwan */ || theLocale.regionCode! == "VN" /* Vietnam */ {
                nearestRegion = ServerRegion.singapore
            }
            if theLocale.regionCode! == "DE" || theLocale.regionCode! == "FR" || theLocale.regionCode! == "IT" || theLocale.regionCode! == "PT" || theLocale.regionCode! == "ES" || theLocale.regionCode! == "AT" || theLocale.regionCode! == "PL" || theLocale.regionCode! == "RU" || theLocale.regionCode! == "UA" || theLocale.regionCode! == "NG" || theLocale.regionCode! == "TR" /* Turkey */ || theLocale.regionCode! == "ZA" /* South Africa */  {
                nearestRegion = ServerRegion.euFrankfurt
            }
            if theLocale.regionCode! == "AU" || theLocale.regionCode! == "NZ" {
                nearestRegion = ServerRegion.sydney
            }
            if theLocale.regionCode! == "AE" || theLocale.regionCode! == "IN" || theLocale.regionCode! == "PK" || theLocale.regionCode! == "BD" || theLocale.regionCode! == "QA" /* Qatar */ || theLocale.regionCode! == "SA" /* Saudi */{ //UAE
                nearestRegion = ServerRegion.mumbai
            }
            if theLocale.regionCode! == "EG" { //EGYPT
                nearestRegion = ServerRegion.euFrankfurt
            }
            if theLocale.regionCode! == "JP" {
                nearestRegion = ServerRegion.tokyo
            }
            if theLocale.regionCode! == "BR" || theLocale.regionCode! == "CO" || theLocale.regionCode! == "VE" || theLocale.regionCode! == "AR" {
                nearestRegion = ServerRegion.brazil
            }
            
            setSavedRegion(region: nearestRegion);
            return nearestRegion; // default region
        }
    }
    
    static func setSavedRegion(region: ServerRegion) {
        let defaults = UserDefaults.standard
        defaults.set(region.rawValue, forKey: Global.vpnSavedRegionKey)
        defaults.synchronize()
    }
    
    static func setKeyForDefaults(inDomain : Dictionary<String, Any>, key : String, val : NSNumber, defaultKey : String) {
        var domain = inDomain
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        domain[key] = val
        defaults.set(domain, forKey: defaultKey)
        defaults.synchronize()
    }
    
    static func removeKeyForDefaults(inDomain : Dictionary<String, Any>, key : String, defaultKey : String) {
        var domain = inDomain
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        domain[key] = nil
        defaults.set(domain, forKey: defaultKey)
        
        defaults.synchronize()
    }
    
    //MARK: - Whitelisting helper functions
    
    static func getUserWhitelist() -> Dictionary<String, Any> {
        let defaults = Global.sharedUserDefaults()
        
        if let domains = defaults.dictionary(forKey:Global.kUserWhitelistedDomains) as? Dictionary<String, Bool> {
            return domains;
        }
        return Dictionary();
    }
    
    static func getUserWhitelistAsArray() -> [(String, Any)] {
        let defaults = Global.sharedUserDefaults()
        
        if let domains = defaults.dictionary(forKey:Global.kUserWhitelistedDomains) as? Dictionary<String, Any> {
            return domains.sorted { $0.key < $1.key };
        }
        return []
    }
    
    static func getConfirmedWhitelist() -> Dictionary<String, Any> {
        let defaults = Global.sharedUserDefaults()
        
        if let domains = defaults.dictionary(forKey:Global.kConfirmedWhitelistedDomains) as? Dictionary<String, Bool> {
            return domains;
        }
        return Dictionary();
        
    }
    
    static func getConfirmedWhitelistAsArray() -> [(String, Any)] {
        let defaults = Global.sharedUserDefaults()
        
        if let domains = defaults.dictionary(forKey:Global.kConfirmedWhitelistedDomains) as? Dictionary<String, Any> {
            return domains.sorted { $0.key < $1.key };
        }
        return []
    }
    
    static func addDomainToUserWhitelist(key : String) {
        var domains = getUserWhitelist()
        
        domains[key] = NSNumber.init(value: true)
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserWhitelistedDomains)
        defaults.synchronize()
    }
    
    static func removeDomainFromUserWhitelist(key : String) {
        var domains = getUserWhitelist()
        domains[key] = nil
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserWhitelistedDomains)
        defaults.synchronize()
    }
    
    static func setDomainForUserWhitelist(key : String, val : NSNumber?) {
        var domains = getUserWhitelist()
        domains[key] = val
        
        let defaults = Global.sharedUserDefaults()
        defaults.set(domains, forKey: Global.kUserWhitelistedDomains)
        defaults.synchronize()
    }
    
    static func addKeyToDefaults(inDomain : Dictionary<String, Any>, key : String) -> Dictionary<String, Any> {
        var domains = inDomain
        if domains[key] == nil {
            domains[key] = NSNumber.init(value: true)
        }
        
        return domains
    }
    
    /*
     * called frequently to allow updates
     */
    static func setupWhitelistedDefaults() {
        let defaults = Global.sharedUserDefaults()
        var domains = defaults.dictionary(forKey:"whitelisted_domains")
        
        if domains == nil {
            domains = Dictionary()
        }
        
        //add default keys
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "aiv-cdn.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "akamaihd.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "akamaized.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "amazon.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "api.twitter.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "apple-cloudkit.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "apple.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "apple.news")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "archive.is")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "att.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "att.com.edgesuite.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "att.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "bamgrid.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "brightcove.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cbs.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cbsaavideo.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cbsi.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cbsi.video")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cbsnews.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cdn-apple.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cloudfront.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "cloudfront.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "coinbase.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "comcast.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "confirmedvpn.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "creditkarma.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "digicert.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "disney-plus.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "disneyplus.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "ebtedge.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "espn.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "fastly.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "fastly.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "firstdata.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "gamestop.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "go.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "googlevideo.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "hbc.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "hbo.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "hbomax.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "houzz.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "hulu.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "huluim.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "icloud-content.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "icloud.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "kroger.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "letsencrypt.org")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "lowes.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "lync.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "m.twitter.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "marcopolo.me")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "mbanking-services.mobi")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "microsoft.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "mobile.twitter.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "mzstatic.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "nbcuni.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "netflix.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "nflxvideo.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "office.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "office.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "office365.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "outlook.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "peacocktv.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "quibi.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "quickplay.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "saks.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "saksfifthavenue.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "skype.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "skypeforbusiness.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "slickdeals.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "southwest.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "spotify.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "stan.com.au")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "stan.video")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "syncbak.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "t.co")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "tapbots.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "tapbots.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "telegram.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "teslamotors.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "ttvnw.net")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "twimg.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "twitter.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "uplynk.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "usbank.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "verisign.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "vudu.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "xfinity.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "youtube.com")
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "zoom.us")
        
        domains = Utils.addKeyToDefaults(inDomain: domains!, key: "confirmedvpn.co") //deprecated API versions
        
        defaults.set(domains, forKey: "whitelisted_domains")
        defaults.synchronize()
    }
    
    static func setupWhitelistedDomains() {
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        var domains = defaults.dictionary(forKey:"whitelisted_domains")
        
        if domains == nil {
            domains = Dictionary()
        }
        
        defaults.set(domains, forKey: "whitelisted_domains")
        defaults.synchronize()
        
        var userDomains = defaults.dictionary(forKey:"whitelisted_domains_user")
        
        if userDomains == nil {
            userDomains = Dictionary()
        }
        
        defaults.set(userDomains, forKey: "whitelisted_domains_user")
        defaults.synchronize()
        
        setupWhitelistedDefaults()
    }
    
    // return an error message or a nil string
    static func validateCredentialFormat(email : String, password : String, passwordConfirmation : String) -> String? {
        if !Utils.isValidEmail(emailAddress: email) {
            return "Please enter a valid e-mail."
        }
        
        if password != passwordConfirmation {
            return "Your passwords do not match."
        }
        
        if password.count < 5 {
            return "Please use a password with at least 8 letters."
        }
        
        return nil
    }
    
    static func isValidEmail(emailAddress:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailAddress)
    }
    
    static func getVersionString() -> String {
        return "v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) + "-" + Global.apiVersionPrefix()
    }
    
    static func setupRules() -> Array<String> {
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        var domains = defaults.dictionary(forKey:"whitelisted_domains") as? Dictionary<String, Any>
        
        if domains == nil {
            domains = Dictionary()
        }
        
        defaults.set(domains, forKey: "whitelisted_domains")
        defaults.synchronize()
        
        var userDomains = defaults.dictionary(forKey:"whitelisted_domains_user") as? Dictionary<String, Any>
        
        if userDomains == nil {
            userDomains = Dictionary()
        }
        
        defaults.set(userDomains, forKey: "whitelisted_domains_user")
        defaults.synchronize()
        
        var whitelistedDomains = Array<String>.init()
        
        for (key, value) in domains! {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(formattedKey)
            }
        }
        
        for (key, value) in userDomains! {
            if (value as AnyObject).boolValue {
                var formattedKey = key
                if key.split(separator: ".").count == 1 {
                    formattedKey = "*." + key
                }
                whitelistedDomains.append(key)
            }
        }
        
        return whitelistedDomains
    }
    
    static func checkForSwitchedEnvironments() {
        if !Utils.isAppInProduction() {
            let defaults = UserDefaults.standard
            if let lastEnvironment = defaults.string(forKey: Global.kLastEnvironment) {
                if lastEnvironment != Global.vpnDomain {
                    Global.keychain[Global.kConfirmedReceiptKey] = nil
                    Global.keychain[Global.kConfirmedP12Key] = nil
                    Global.keychain[Global.kConfirmedID] = nil
                    Global.keychain[Global.kConfirmedEmail] = nil
                    Global.keychain[Global.kConfirmedPassword] = nil
                    Auth.clearCookies()
                    defaults.removeObject(forKey: Global.vpnSavedRegionKey)
                    defaults.set(Global.vpnDomain, forKey: Global.kLastEnvironment)
                    defaults.synchronize()
                }
            }
            else {
                defaults.set(Global.vpnDomain, forKey: Global.kLastEnvironment)
                defaults.synchronize()
            }
        }
    }
    
    static func isAppInProduction() -> Bool {
        #if os(iOS)
            if Config.appConfiguration == AppConfiguration.AppStore || Global.forceProduction {
                return true
            }
            else {
                return false
            }
        #else
            #if DEBUG
                if !Global.forceProduction {
                    return false
                }
                else {
                    return true
                }
            #else
                return true
            #endif
        #endif
    }
    
    static func getSource() -> String {
        if Global.isVersion(version: .v1API) {
            return "both"
        }
        return ""
    }
    
    /*
     * decide API version if not chosen
     * maximize V2 users
     * base on whether last saved region exists, and whether it had a source ID
     */
    static func chooseAPIVersion() {
        if UserDefaults.standard.string(forKey: Global.kConfirmedAPIVersion) == nil {
            UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion)
            UserDefaults.standard.synchronize()
            
            NotificationCenter.post(name: .switchingAPIVersions)
        }
        
    }
    
    static func setActiveProtocol(activeProtocol : String) {
      if let defaults = UserDefaults(suiteName: SharedUtils.userDefaultsSuite) {
        defaults.set(activeProtocol, forKey: kActiveProtocol)
        defaults.synchronize()
      }
    }
    
    static func getActiveProtocol() -> String {
        return IPSecV3.protocolName
    }
}

