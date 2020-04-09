//
//  VPNViewController.swift
//
//
//
//
// https://thenounproject.com/search/?q=lightning%20icon&i=152895 - Dilon Choudry
// https://thenounproject.com/search/?q=lightning%20icon&i=1074945 - Mello

import UIKit
import NetworkExtension
import LGSideMenuController
import StoreKit
import MessageUI
import StoreKit
import AVFoundation
import AVKit
import SwiftyStoreKit
import NVActivityIndicatorView
import KeychainAccess
import CocoaLumberjackSwift
import SwiftMessages
import Reachability
import PopupDialog

class VPNViewController: ConfirmedBaseViewController, BWWalkthroughViewControllerDelegate {
    
    @objc func showWhitelisting() {
        self.performSegue(withIdentifier: "showWhitelistingPage", sender: self)
    }
    
    @objc func showInternetDownNotification() {
        //no need for this for now with status bar notification
    }
    
    @objc func showContentBlocker() {
        self.performSegue(withIdentifier: "showContentBlockerPage", sender: self)
    }
    
    @objc func showAccount() {
        DispatchQueue.main.async {
            self.hideLeftViewAnimated(self)
            
            self.performSegue(withIdentifier: "showAccountPage", sender: self)
        }
    }

    
    @objc func startSpeedTest() {
        DispatchQueue.main.async {
            self.hideLeftViewAnimated(self)
            
            self.speedTestLabel?.text = "Running Speed Test..."
            self.speedTestLabel?.alpha = 0.2
            
            UIView.animate(withDuration: 0.65, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
                self.speedTestLabel?.alpha = 1.0
            })
            
            TunnelSpeed().testDownloadSpeedWithTimout(timeout: 10.0) { (megabytesPerSecond, error) -> () in
                if megabytesPerSecond > 0 {
                    
                    DispatchQueue.main.async {
                        self.speedTestLabel?.layer.removeAllAnimations()
                        self.speedTestLabel?.text = String(format: "%.1f", megabytesPerSecond)
                            + " Mbps"
                        
                        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
                            self.speedTestLabel?.alpha = 1.0
                        })
                    }
                    
                } else {
                    DDLogWarn("NETWORK ERROR: \(error)")
                    self.speedTestLabel?.text = "..."
                }
            }
        }
    }
    
    override func awakeFromNib() {
        
        Global.reachability?.whenReachable = { reachability in
            if TunnelsSubscription.isSubscribed == .Loading { //reload subscription status once reachable
                TunnelsSubscription.isSubscribed(refreshITunesIfNeeded: false, isSubscribed:{}, isNotSubscribed:{})
            }
            
            SwiftMessages.hide()
        }
        Global.reachability?.whenUnreachable = { _ in
            DDLogInfo("Internet not reachable")
            self.noInternetMessageView.backgroundView.backgroundColor = UIColor.orange
            self.noInternetMessageView.bodyLabel?.textColor = UIColor.white
            self.noInternetMessageView.configureContent(body: "No Internet detected.")
            var noInternetMessageViewConfig = SwiftMessages.defaultConfig
            noInternetMessageViewConfig.presentationContext = .window(windowLevel: UIWindow.Level(rawValue: 0))
            noInternetMessageViewConfig.preferredStatusBarStyle = .lightContent
            noInternetMessageViewConfig.duration = .forever
            SwiftMessages.show(config: noInternetMessageViewConfig, view: self.noInternetMessageView)
        }
        
        do {
            try Global.reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.checkForSwitchedEnvironments()
        Utils.setupWhitelistedDomains()
        self.speedTestLabel?.alpha = 0
        
        //check subscription
        let image = UIImage(named: "power_button")?.withRenderingMode(.alwaysTemplate)
        vpnPowerButton?.setImage(image, for: .normal)
        setupVPNButtons()
        
        countrySelection.initializeCountries(self.view)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(dismissOnboarding), name: .dismissOnboarding, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareApp), name: NSNotification.Name(rawValue: "Share App"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(askForHelp), name: NSNotification.Name(rawValue: "Ask For Help"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showPrivacyPolicy), name: NSNotification.Name(rawValue: "Show Privacy Policy"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startSpeedTest), name: .runSpeedTest, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showAccount), name: NSNotification.Name(rawValue: "Show Account"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VPNViewController.didSelectCountry(notification:)), name: .changeCountry, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showWhitelisting), name: .showWhitelistDomains, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showContentBlocker), name: .showContentBlocker, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startVPN), name: .setupVPN, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showInternetDownNotification), name: .internetDownNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadServerEndpoints), name: .switchingAPIVersions, object: nil)
        
        NotificationCenter.default.addObserver(forName: .showTutorial, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            self.showOnboarding()
        }
        
        self.vpnLoadingView?.layer.shadowOffset = CGSize(width:0, height:20);
        self.vpnLoadingView?.layer.shadowRadius = 15;
        self.vpnLoadingView?.layer.shadowOpacity = 0.1;
        self.vpnLoadingView?.layer.cornerRadius = (self.vpnLoadingView?.frame.size.width)! / 2.0;  // half the width/height

        updateActiveCountry()
        
        self.vpnPowerButton?.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusDidChange(_:)), name: .vpnStatusChanged, object: nil)
    
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Global.fetchingP12Notification), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            self.setVPNButtonGettingP12()
        }
        
        
        //subscription dialog test - If still loading, use notifications
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: TunnelsSubscription.TunnelsNotSubscribed), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            DDLogInfo("Not subscribed when notified")
            self.showOnboarding()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: TunnelsSubscription.TunnelsIsSubscribed), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            DDLogInfo("Subbed Notif")
            self.vpnPowerButton?.isEnabled = true
        }
        
    }
    
    func updateActiveCountry() {
        DispatchQueue.main.async {
            let regions = self.countrySelection.items
            let selectedRegion = Utils.getSavedRegion()
            for serverRegion in regions  {
                let meta = regionMetadata[serverRegion]!
                
                if serverRegion == selectedRegion {
                    self.countryFlag?.image = UIImage.init(named: meta.flagImagePath)
                    self.countryButton?.setTitle(meta.countryName, for: .normal)
                }
            }
        }
    }
    
    @objc func reloadServerEndpoints(notification: Notification) {
        countrySelection.loadEndpoints()
    }
    
    @objc func didSelectCountry(notification: Notification) {
        stopVPN()
        DDLogInfo("Selected country")
        var obj = notification.object as! ServerRegion
        let meta = regionMetadata[obj]!
        self.countryFlag?.image = UIImage.init(named: meta.flagImagePath)
        self.countryButton?.setTitle(meta.countryName, for: .normal)
        Utils.setSavedRegion(region: obj)
        
        VPNController.shared.connectToVPN()
        //showCountryList()
        
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            self.countrySelectionLayout?.constant = 0.0;
            self.view?.layoutIfNeeded()
            
            //self.countrySelectionButton?.frame = CGRect(x: 0, y: self.view.frame.height - (self.countrySelectionButton?.frame.size.height)!, width: (self.countrySelectionButton?.frame.size.width)!, height: (self.countrySelectionButton?.frame.size.height)!)
            self.countrySelection.tableView.frame = CGRect(x: 0, y: self.view.frame.height, width: (self.countrySelection.tableView.frame.size.width), height: (self.countrySelection.tableView.frame.size.height))
            self.sideMenuButton?.alpha = 1.0
            self.sideOOButton?.alpha = 1.0
            self.countryLine?.alpha = 0.0
            self.countryArrowButton?.transform = CGAffineTransform(rotationAngle: 0)
        })
    }
    
    @objc func vpnStatusDidChange(_ notification: Notification) {
        if notification.object is NETunnelProviderSession {
            return;
        }
        DispatchQueue.main.async {
            self.updateActiveCountry()
            VPNController.shared.vpnState(completion: { status in
                if status == .connected {
                    self.vpnPowerButton?.isEnabled = true
                    self.setVPNButtonEnabled()
                } else if status == .disconnected {
                    self.setVPNButtonDisabled()
                } else if status == .connecting {
                    self.vpnPowerButton?.isEnabled = true
                    self.setVPNButtonConnecting()
                }
                else if status == .disconnecting {
                    self.setVPNButtonConnecting()
                }
            })
        }
        
        DDLogInfo("VPN Status: \(NEVPNManager.shared().connection.status.rawValue)")
    }
    
    func showPostboarding() {
        let stb = UIStoryboard(name: "Main", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "postboarding") as! BWWalkthroughViewController
        
        let page_zero = stb.instantiateViewController(withIdentifier: "postboarding1")
        let page_one = stb.instantiateViewController(withIdentifier: "contentBlocker") as! ContentBlockerViewController
        let page_two = stb.instantiateViewController(withIdentifier: "whitelisting") as! WhitelistingViewController
        let page_three = stb.instantiateViewController(withIdentifier: "addEmail") as! AddEmailViewController
        page_one.isPostboarding = true
        page_two.isPostboarding = true
        page_three.isPostboarding = true
        
        // Attach the pages to the master
        walkthrough.delegate = self
        walkthrough.add(viewController:page_zero)
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        //walkthrough.add(viewController:page_four)
        //walkthrough.view.bringSubview(toFront: walkthrough.scrollview)
        walkthrough.modalTransitionStyle = .crossDissolve

        self.modalTransitionStyle = .crossDissolve
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func showOnboarding() {
        
        UserDefaults.standard.set(true, forKey: "onboardedUser")
        UserDefaults.standard.synchronize()
        
        let stb = UIStoryboard(name: "Main", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "walk") as! WalkthroughViewController
        if (TunnelsSubscription.isSubscribed != .Subscribed) {
            VPNController.shared.forceVPNOff()
            walkthrough.setupOnboardingMode()
        }
        else {
            walkthrough.setupWalkthroughMode()
        }
        
        let page_zero = stb.instantiateViewController(withIdentifier: "walk1")
        let page_one = stb.instantiateViewController(withIdentifier: "walk2")
        let page_two = stb.instantiateViewController(withIdentifier: "walk3")
        let page_three = stb.instantiateViewController(withIdentifier: "walk4")
        let page_four = stb.instantiateViewController(withIdentifier: "walk5")
        
        // Attach the pages to the master
        walkthrough.delegate = self
        walkthrough.add(viewController:page_zero)
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        walkthrough.add(viewController:page_four)
        walkthrough.view.bringSubviewToFront(walkthrough.scrollview)
        
        self.modalTransitionStyle = .crossDissolve
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    /*
        * hide country table on transition
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        self.countrySelection.tableView.frame = CGRect(x: 0, y: max(size.height, size.width), width: size.width, height: (self.countrySelection.tableView.frame.size.height))
        
        
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            self.countrySelectionLayout?.constant = 0.0;
            self.view?.layoutIfNeeded()
            
            self.countrySelection.tableView.frame = CGRect(x: 0, y: max(size.height, size.width), width: size.width, height: (self.countrySelection.tableView.frame.size.height))
            self.sideMenuButton?.alpha = 1.0
            self.sideOOButton?.alpha = 1.0
            self.countryLine?.alpha = 0.0
            self.countryArrowButton?.transform = CGAffineTransform(rotationAngle: 0)
        })
        
    }
    
    @IBAction func showCountryList() {
        
        if (Double((self.countrySelectionLayout?.constant)!) > 150.0) {
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
                self.countrySelectionLayout?.constant = 0.0;
                self.view?.layoutIfNeeded()
                
                self.countrySelection.tableView.frame = CGRect(x: 0, y: self.view.frame.height, width: (self.countrySelection.tableView.frame.size.width), height: (self.countrySelection.tableView.frame.size.height))
                self.sideMenuButton?.alpha = 1.0
                self.sideOOButton?.alpha = 1.0
                self.countryLine?.alpha = 0.0
                self.countryArrowButton?.transform = CGAffineTransform(rotationAngle: 0)
            })
        }
        else {
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
                
                var heightAdjustment : CGFloat = 50
                let window = UIApplication.shared.keyWindow
                
                if UIDevice().userInterfaceIdiom == .pad {
                    heightAdjustment = 400
                }
                
                if #available(iOS 11.0, *) {
                    self.countrySelectionLayout?.constant = self.view.frame.height - (self.countrySelectionButton?.frame.size.height)! - heightAdjustment - (window?.safeAreaInsets.bottom)!
                } else {
                    self.countrySelectionLayout?.constant = self.view.frame.height - (self.countrySelectionButton?.frame.size.height)! - heightAdjustment
                }
                
                self.view?.layoutIfNeeded()
                
                self.countrySelection.tableView.frame = CGRect(x: 0, y: /*self.view.frame.height - */ (self.countrySelectionButton?.frame.size.height)! + heightAdjustment, width: (self.countrySelectionButton?.frame.size.width)!, height: (self.view.frame.size.height - heightAdjustment - (self.countrySelectionButton?.frame.size.height)!))
                self.sideMenuButton?.alpha = 0.0
                self.sideOOButton?.alpha = 0.0
                self.countryLine?.alpha = 1.0
                self.countryArrowButton?.transform = CGAffineTransform(rotationAngle: 3.1415)
            })
        }
    }
    
    @IBAction func showSideMenu() {
    
    }
    
    @IBAction func showAuditAsk(_ sender: Any) {
        guard let url = URL(string: "https://openlyoperated.org/report/confirmedvpn") else {
            return //be safe
        }
        UIApplication.shared.openURL(url)
    }
    
    @IBAction func toggleVPN() {
        
        // If greater than 3 days since install, then ask for rating. Otherwise, check if 8th time connecting.
        if let installDate = (try! FileManager.default.attributesOfItem(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.path)[FileAttributeKey.creationDate]) as? Date {
            print("This app was installed on \(installDate)")
            if let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day {
                print("Days since install \(daysSinceInstall)");
                if (daysSinceInstall > 3) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        SKStoreReviewController.requestReview();
                    }
                }
                else {
                    let ratingCount = UserDefaults.standard.integer(forKey: "rating")
                    print("Rating Count: " + String(ratingCount));
                    UserDefaults.standard.set(ratingCount + 1, forKey: "rating");
                    if (ratingCount != 0 && ratingCount % 8 == 0) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            SKStoreReviewController.requestReview();
                        }
                    }
                }
            }
        }
        
        VPNController.shared.vpnState(completion: { status in
            if status == .disconnected || status == .invalid {
                self.startVPN()
            }
            else {
                self.stopVPN()
            }
        })
    }

    
    @IBAction func startVPN() {
        VPNController.shared.connectToVPN()
    }
    
    @IBAction func stopVPN() {
        VPNController.shared.disconnectFromVPN()
    }
    
    func setupVPNButtons() {
        VPNController.shared.vpnState(completion: { status in
            if status == .disconnected || status == .invalid {
                self.setVPNButtonDisabled()
            }
            else if status == .connected {
                self.setVPNButtonEnabled()
            }
            else {
                self.setVPNButtonConnecting()
            }
        })
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateActiveCountry()
        self.vpnLoadingView?.addSubview(CircularSpinner.sharedInstance)
        CircularSpinner.useContainerView(self.vpnLoadingView)
        CircularSpinner.trackLineWidth = 3
        CircularSpinner.trackPgColor = UIColor.init(red: 91/255.0, green: 209/255.0, blue: 120/255.0, alpha: 1.0)
        CircularSpinner.sharedInstance.appearanceProgressLayer()
        CircularSpinner.trackBgColor = UIColor.init(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        CircularSpinner.show("", animated: true, type: .indeterminate, showDismissButton: false)
        self.vpnLoadingView?.sendSubviewToBack(CircularSpinner.sharedInstance)
        setupVPNButtons()
        
        if UserDefaults.standard.bool(forKey: "userSuccessfullyConnected") {
            vpnBenefitsButton?.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NSLog("VPN view appearing here")
        
        super.viewDidAppear(animated)
        VPNController.shared.syncVPNAndWhitelistingProxy()
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "onboardedUser") && Global.keychain[Global.kConfirmedEmail] == nil && Global.keychain[Global.kConfirmedID] == nil {
            showOnboarding()
        }
        else {
            /*UIView.animate(withDuration: 0.4, animations: {
             self.vpnPowerButton?.tintColor = UIColor.gray
             })*/
            
            //fetchP12(shouldConnect: false); // domain is the region
            if (TunnelsSubscription.isSubscribed == .NotSubscribed) {
                DDLogInfo("Not subscribed when view did load")
                self.showOnboarding()
            }
            else if (TunnelsSubscription.isSubscribed == .Subscribed) {
                DDLogInfo("Subbed View Did Load")
                self.vpnPowerButton?.isEnabled = true
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - BWWalkThrough Delegate
    func walkthroughPageDidChange(_ pageNumber: Int) {
        
    }
    
    @objc func dismissOnboarding() {
        self.dismiss(animated: true, completion: nil)
        
        if (TunnelsSubscription.isSubscribed == .NotSubscribed) {
            DDLogInfo("Not subscribed when dismissing onboarding")
            self.showOnboarding()
        }
        else if (TunnelsSubscription.isSubscribed == .Loading) {
            //somehow still loading, we should present the subscription dialog?
        }
    }
    
    // MARK: VPN Power Button
    
    func setVPNButtonEnabled() {
        
        UIView.animate(withDuration: 0.4, animations: {
            self.vpnPowerButton?.tintColor = .tunnelsLightBlueColor
            CircularSpinner.sharedInstance.pgColor = .tunnelsLightBlueColor
            self.vpnStatusLabel?.textColor = UIColor.white
        })
        
        
        if CircularSpinner.sharedInstance.type == .indeterminate {
            CircularSpinner.sharedInstance.type = .determinate
        }
        self.vpnStatusLabel?.text = "PROTECTED".localized()
        //CircularSpinner.sharedInstance.appearanceProgressLayer()
        
        DDLogInfo("Connected")
        
        //if this is the first connection, show whitelisting
        //show push request the first time
        UserDefaults.standard.set(true, forKey: "userSuccessfullyConnected")
        UserDefaults.standard.synchronize()
        
        if UserDefaults.standard.object(forKey: "showedWhitelisting") == nil {
            UserDefaults.standard.set(true, forKey: "showedWhitelisting")
            UserDefaults.standard.synchronize()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                //self.showWhitelisting()
                self.vpnBenefitsButton?.alpha = 0
                self.vpnBenefitsButton?.isHidden = false
                UIView.animate(withDuration: 0.3, animations: {
                    self.vpnBenefitsButton?.alpha = 1.0
                })
            }
        }
        
    }
    
    func setVPNButtonGettingP12() {
        DDLogInfo("Connecting")
        UIView.animate(withDuration: 0.4, animations: {
            self.vpnPowerButton?.tintColor = UIColor.gray
            self.vpnStatusLabel?.textColor = UIColor.white
            CircularSpinner.sharedInstance.pgColor = .tunnelsLightBlueColor
        })
        CircularSpinner.trackPgColor = UIColor.init(red: 91/255.0, green: 209/255.0, blue: 120/255.0, alpha: 1.0)
        if CircularSpinner.sharedInstance.type == .determinate {
            CircularSpinner.sharedInstance.type = .indeterminate
        }
        self.vpnStatusLabel?.text = "INITIALIZING"
        //CircularSpinner.sharedInstance.appearanceProgressLayer()
        
    }
    
    func setVPNButtonConnecting() {
        DDLogInfo("Connecting")
        
        UIView.animate(withDuration: 0.4, animations: {
            self.vpnPowerButton?.tintColor = UIColor.gray
            self.vpnStatusLabel?.textColor = UIColor.white
            CircularSpinner.sharedInstance.pgColor = .tunnelsLightBlueColor
        })
        CircularSpinner.trackPgColor = UIColor.init(red: 91/255.0, green: 209/255.0, blue: 120/255.0, alpha: 1.0)
        
        if CircularSpinner.sharedInstance.type == .determinate {
            CircularSpinner.sharedInstance.type = .indeterminate
        }
        
        self.vpnStatusLabel?.text = "CONNECTING".localized()
        CircularSpinner.sharedInstance.appearanceProgressLayer()
        
    }
    
    func setVPNButtonDisabled() {
        DDLogInfo("DISCONNECTED")
        
        UIView.animate(withDuration: 0.4, animations: {
            self.vpnPowerButton?.tintColor = UIColor.gray
            CircularSpinner.sharedInstance.pgColor = UIColor.gray
            self.vpnStatusLabel?.textColor = UIColor.white
        })
        
        if CircularSpinner.sharedInstance.type == .indeterminate {
            CircularSpinner.sharedInstance.type = .determinate
        }
        
        self.vpnStatusLabel?.text = "DISCONNECTED".localized()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    
    // MARK: - Side menu functions

    
    func sendSupportRequest() {
        DDLogInfo("API VERSION: \(UserDefaults.standard.string(forKey: Global.kConfirmedAPIVersion))")
        if (MFMailComposeViewController.canSendMail()) {
            self.emailTeam()
        }
        else {
            let noEmailAlert = UIAlertController(title: "E-mail Us", message: "Please e-mail us at team@confirmedvpn.com and we will fix your issue immediately.", preferredStyle: UIAlertController.Style.alert)
            noEmailAlert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: { action in
                
            }))
            self.present(noEmailAlert, animated: true, completion: nil)
        }
    }
    
    @objc func askForHelp() {
        hideLeftViewAnimated(self)
        self.sendSupportRequest()
    }
    
    @objc func showPrivacyPolicy() {
        hideLeftViewAnimated(self)
        self.performSegue(withIdentifier: "showPrivacyPolicy", sender: nil)
    }
    
    @objc func shareApp() {
        hideLeftViewAnimated(self)
        let message = "You have to check this out - https://confirmedvpn.com";
        let shareItems = [message];
        let avc = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        
        avc.modalPresentationStyle = .popover;
        //avc.popoverPresentationController
        
        if (avc.responds(to: #selector(getter: UIViewController.popoverPresentationController))) {
            avc.popoverPresentationController?.sourceView = self.view
            avc.popoverPresentationController?.sourceRect = self.view.frame
        }
        
        avc.excludedActivityTypes = [.airDrop, .print, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo];
        
        self.present(avc, animated: true, completion: nil)
    }
    
    //MARK: - VARIABLES
    
    @IBOutlet weak var countryLine: UIView!
    @IBOutlet weak var sideOOButton: UIButton!
    @IBOutlet weak var countryArrowButton: UIImageView?
    @IBOutlet weak var sideMenuButton: UIButton?
    @IBOutlet weak var vpnPowerButton: UIButton?
    @IBOutlet weak var vpnLoadingView: UIView?
    @IBOutlet weak var vpnStatusLabel: UILabel?
    @IBOutlet weak var countrySelectionButton: UIView?
    
    @IBOutlet weak var countryButton: UIButton?
    @IBOutlet weak var countryFlag: UIImageView?
    
    @IBOutlet weak var countrySelectionLayout: NSLayoutConstraint?
    
    @IBOutlet weak var speedTestLabel: UILabel?
    
    @IBOutlet weak var vpnBenefitsButton: UIButton?
    
    let countrySelection = CountrySelection()
    let noInternetMessageView = MessageView.viewFromNib(layout: .statusLine)
    
}
