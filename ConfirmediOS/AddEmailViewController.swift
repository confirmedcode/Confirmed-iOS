//
//  AddEmailViewController.swift
//  Confirmed VPN
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit
import TextFieldEffects

class AddEmailViewController: ConfirmedBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        if !isPostboarding {
            self.emailTextField?.becomeFirstResponder()
        }
    }
    
    func showInfoMessage(infoString : String) {
        let appearance = SCLAlertView.SCLAppearance(
            kCircleBackgroundTopPosition: -100,
            kTitleTop: 50,
            //kWindowHeight: 240,
            //kTextFieldHeight: 160,
            //kButtonHeight: 28,
            kTitleFont: UIFont(name: "AvenirNext-Regular", size: 20)!,
            kTextFont: UIFont(name: "AvenirNext-Regular", size: 14)!,
            kButtonFont: UIFont(name: "AvenirNext-Regular", size: 14)!,
            showCloseButton: true
        )
        
        let alertView = SCLAlertView(appearance: appearance)
        alertView.yOffset = 100
        alertView.textViewToButtonPadding = 20
        alertView.showInfo("One More Thing...", subTitle:infoString, closeButtonTitle:"OK")
        
        NotificationCenter.post(name: .dismissOnboarding)
        self.dismiss(animated: true, completion: {})
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            //self.createSigninButton?.normalCornerRadius = 4
            self.createSigninButton?.isUserInteractionEnabled = true
            self.createSigninButton?.setOriginalState()
            self.createSigninButton?.layer.cornerRadius = 4
        }
    }
    
    func showErrorMessage(errorString : String) {
        
        let alertView = SCLAlertView(appearance: defaultAlertAppearance)
        alertView.yOffset = 100
        alertView.textViewToButtonPadding = 20
        alertView.showError("Hold On...".localized(), subTitle:errorString, closeButtonTitle:"OK")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            //self.createSigninButton?.normalCornerRadius = 4
            self.createSigninButton?.isUserInteractionEnabled = true
            self.createSigninButton?.setOriginalState()
            self.createSigninButton?.layer.cornerRadius = 4
        }
    }
    
    @IBAction func addEmailLater () {
        if isFromAccountPage {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            NotificationCenter.post(name: .dismissOnboarding)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showAddEmailScreen" {
            isFromAccountPage = true
        }
        else {
            isFromAccountPage = false
        }
    }
    
    @IBAction func createSignInPressed () {
        self.createSigninButton?.isUserInteractionEnabled = false
        self.createSigninButton?.startLoadingAnimation()
        
        let email = self.emailTextField?.text
        let password = self.passwordTextField?.text
        
        if (!Utils.isValidEmail(emailAddress: email!) || email == nil) || (password == nil || password!.count < 8) {
            showErrorMessage(errorString: "Please make sure to enter a valid e-mail and at least eight characters for your password.")
            
            return
        }
        
        Auth.convertShadowUser(email: email!, password: password!, passwordConfirmation: password!, createUserCallback: {(_ status: Bool, _ reason: String) -> Void in
            
            if status {
                self.showInfoMessage(infoString: "Please check your e-mail for a confirmation link and your sign-in will be enabled")
            }
            else {
                self.showErrorMessage(errorString: reason)
            }
        })
        
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var isFromAccountPage = false
    var isPostboarding : Bool = false
    
    @IBOutlet var createSigninButton: TKTransitionSubmitButton?
    @IBOutlet var emailTextField: HoshiTextField?
    @IBOutlet var passwordTextField: HoshiTextField?

}
