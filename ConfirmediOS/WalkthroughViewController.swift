//
//  WalkthroughViewController.swift
//  TunnelsiOS
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//

import UIKit

class WalkthroughViewController: BWWalkthroughViewController {

    func setupWalkthroughMode() {
        currentMode = WalkthroughViewController.walkthroughMode
    }
    
    func setupOnboardingMode() {
        currentMode = WalkthroughViewController.onboardingMode
    }
        
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.signinButton?.layer.borderColor = UIColor.tunnelsLightBlueColor.cgColor
        self.signinButton?.layer.borderWidth = 1.0
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.dismissOnboarding),
            name: .dismissOnboarding,
            object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if currentMode == WalkthroughViewController.walkthroughMode {
            self.signinButton?.isHidden = true
            self.signupButton?.isHidden = true
            self.closeWalkthroughButton?.isHidden = false
        }
        else {
            self.signinButton?.isHidden = false
            self.signupButton?.isHidden = false
            self.closeWalkthroughButton?.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.bringSubviewToFront(self.signupButton!)
        self.view.bringSubviewToFront(self.signinButton!)
        self.view.bringSubviewToFront(self.closeWalkthroughButton!)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func dismissOnboarding() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView?.alpha = 0.0
            self.view.alpha = 0.0
        })
    }
    
    @IBAction func dismissViewController () {
        self.dismiss(animated: true, completion: {})
    }
    
    @IBAction func showSigninController() {
        self.performSegue(withIdentifier: "showSignInView", sender: self)
    }
    
    @IBAction func showSignupController() {
        self.performSegue(withIdentifier: "showSignUpView", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static let onboardingMode = 0
    static let walkthroughMode = 1
    var currentMode = onboardingMode
    @IBOutlet weak var backgroundView: UIImageView?
    @IBOutlet weak var signupButton: UIButton?
    @IBOutlet weak var signinButton: UIButton?
    @IBOutlet weak var closeWalkthroughButton: UIButton?

}
