//
//  ConfirmedAccountViewController.swift
//  
//
//

import UIKit
import Alamofire
import NVActivityIndicatorView
import CocoaLumberjackSwift

class ConfirmedAccountViewController: ConfirmedBaseViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {

    //MARK: - OVERRIDE
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        tableView?.tableFooterView = UIView(frame: .zero)
        reloadSubscriptionData()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showAddEmailScreen" {
            if let vc = segue.destination as? AddEmailViewController {
                vc.isFromAccountPage = true
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - TABLEVIEW
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let email = Global.keychain[Global.kConfirmedEmail]
            let password = Global.keychain[Global.kConfirmedPassword]
            
            if email == nil || password == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddEmailCell") as! AccountAddEmailCell
                cell.addEmailButton?.addTarget(self, action: #selector(showAddEmailView), for: .touchUpInside)
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmailCell") as! AccountEmailCell
                cell.tableText?.text = email
                return cell
            }
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell") as! AccountPlanCell
                cell.planText?.text = planTitle
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlanDescriptionCell") as! AccountPlanCell
                cell.planText?.text = planDescription
                return cell
            }
            if indexPath.row == 2 {
                if isAllDevicesPlan() && isMonthlyPlan() {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradeAnnualCell") as! AccountUpgradeCell
                    cell.planUpgrade?.addTarget(self, action: #selector(upgradeToAnnualAllDevices), for: .touchUpInside)
                    return cell
                }
                else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradePlanCell") as! AccountUpgradeCell
                    cell.planUpgrade?.addTarget(self, action: #selector(upgradeToAllDevices), for: .touchUpInside)
                    return cell
                }
                
            }
            if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradeAnnualCell") as! AccountUpgradeCell
                cell.planUpgrade?.addTarget(self, action: #selector(upgradeToAnnualiOSDevices), for: .touchUpInside)
                return cell
            }
            
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SignoutCell") as! AccountSignoutCell
            return cell
        }
        
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 2 {
            return 1
        }
        
        if section == 1 {
            if isMonthlyPlan() && isAllDevicesPlan() {
                return 3
            }
            
            if isMonthlyPlan() && isIOSPlan() { //only show upgrade plan for ios-monthly
                return 4
            }
            
            if !isMonthlyPlan() && !isIOSPlan() { //don't show upgrade plan for ios annual
                return 2
            }
        }
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            if indexPath.row == 1 {
                return 100
            }
            if indexPath.row == 2 || indexPath.row == 3 {
                return 125
            }
        }
        return 75
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let email = Global.keychain[Global.kConfirmedEmail]
        let password = Global.keychain[Global.kConfirmedPassword]
        
        if email == nil || password == nil {
            return 2 //don't show sign out button unless they are signed in
        }
        return 3
    }
    
    //MARK: - ACTION
    func reloadSubscriptionData() {
        //load subscriptions
        //CACHE THIS IN THE FUTURE??
        
        Auth.getActiveSubscriptions { (status, didCompleteCall, error, json) in
            if status {
                if let jsonPlanType = json![0]["planType"] as? String {
                    self.planType = jsonPlanType
                    if self.planType == "ios-monthly" {
                        self.planTitle = "iOS Only".localized()
                        self.planDescription = "Up to three of your iPhones and iPads".localized()
                    }
                    else if self.planType == "ios-annual" {
                        self.planTitle = "iOS Only".localized()
                        self.planDescription = "Up to three of your iPhones and iPads".localized()
                    }
                    else if self.planType == "all-annual" {
                        self.planTitle = "All Devices".localized()
                        self.planDescription = "Up to five devices on any platform".localized()
                    }
                    else {
                        self.planTitle = "All Devices".localized()
                        self.planDescription = "Up to five devices on any platform".localized()
                        
                    }
                }
                else {
                    self.planTitle = "Couldn't load plan".localized()
                    self.planDescription = "Couldn't load plan description".localized()
                }
                
                self.tableView?.reloadData()
            }
        }
        
    }
    
    func isAllDevicesPlan() -> Bool {
        if planType == "all-annual" || planType == "all-monthly" {
            return true
        }
        return false
    }
    
    func isMonthlyPlan() -> Bool {
        if planType == "ios-monthly" || planType == "all-monthly" {
            return true
        }
        return false
    }
    
    func isIOSPlan() -> Bool {
        if planType == "ios-monthly" || planType == "ios-annual" {
            return true
        }
        return false
    }
    
    
    @objc func showAddEmailView() {
        self.performSegue(withIdentifier: "showAddEmailScreen", sender: self)
    }
    
    func showLoadingScreen() {
        let size = CGSize(width: 60, height: 60)
        
        startAnimating(size, message: "Processing...".localized(), type: NVActivityIndicatorType.circleStrokeSpin, color:UIColor.darkGray, backgroundColor: UIColor.clear)
        blurredEffectView.frame = self.view.frame
        view.addSubview(blurredEffectView)
    }
    
    func stopLoadingScreen() {
        stopAnimating()
        blurredEffectView.removeFromSuperview()
    }
    
    func purchaseTunnels() {
        showLoadingScreen()
        
        TunnelsSubscription.purchaseTunnels(
            succeeded : {
                DDLogInfo("User did upgrade - \(TunnelsSubscription.getProductID())")
                TunnelsSubscription.refreshAndUploadReceipt()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.reloadSubscriptionData()
                    self.stopLoadingScreen()
                }
        },
            errored: {
                DDLogWarn("Subscription upgrade error")
                SCLAlertView(appearance: defaultAlertAppearance).showError("Hold On...".localized(), subTitle:"Please make sure your Internet connection is active. Otherwise, please e-mail team@confirmedvpn.com".localized(), closeButtonTitle:"OK")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.reloadSubscriptionData()
                    self.stopLoadingScreen()
                }
        })
    }
    
    @IBAction func upgradeToAllDevices() {
        TunnelsSubscription.productType = 1
        DDLogInfo("User trying to upgrade - All Devices")
        
        purchaseTunnels()
    }
    
    @IBAction func upgradeToAnnualAllDevices() {
        TunnelsSubscription.productType = 3
        DDLogInfo("User trying to upgrade - All Annual")
        
        purchaseTunnels()
    }
    
    @IBAction func upgradeToAnnualiOSDevices() {
        TunnelsSubscription.productType = 2
        DDLogInfo("User trying to upgrade - iOS Annual")
        showLoadingScreen()
        purchaseTunnels()
    }
    
    @IBAction func signoutAccount() {
        //confirm they want to sign out
        
        let noEmailAlert = UIAlertController(title: "Sign Out", message: "Are you sure you want to log out of your account?", preferredStyle: UIAlertController.Style.alert)
        noEmailAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { action in
            Auth.signoutUser() //delete Keys
            self.dismiss(animated: true, completion: nil)
            TunnelsSubscription.isSubscribed = .NotSubscribed
            TunnelsSubscription.isSubscribed(refreshITunesIfNeeded: false, isSubscribed: {}, isNotSubscribed: {})
        }))
        noEmailAlert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: { action in
            
        }))
        self.present(noEmailAlert, animated: true, completion: nil)
    }
    
    @IBAction func dismissAccountPage() {
        self.dismiss(animated: true, completion: {})
    }
    

    //MARK: - VARIABLES
    var planTitle = "Loading".localized() + "..."
    var planDescription = ""
    var planType = ""
    
    let blurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var signoutButton: UIButton?
    
    @IBOutlet weak var emailLabel: UILabel?
    @IBOutlet weak var addEmailButton: UIButton?
    

}
