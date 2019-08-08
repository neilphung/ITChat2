//
//  WelcomeViewController.swift
//  ITChat
//
//  Created by NeilPhung on 8/2/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {
    
    
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    //MARK: IBAction
    
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            loginUser()
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != "" {
            
            if passwordTextField.text == repeatPasswordTextField.text {
                goToFinishRegister()
            }
            else {
                ProgressHUD.showError("Password and repeat password no same")
            }
        }
        else {
            ProgressHUD.showError("All textfile enter ")
        }
    }
    
    @IBAction func backgroundTap(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    //MARK: Helper Method
    
    func loginUser(){
        ProgressHUD.show("Login ...")
        FirebaseUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            self.goToApp()
            
        }
        
    }
    
    func goToFinishRegister(){
        performSegue(withIdentifier: "goToFinishRegister", sender: self)
        
        dismissKeyboard()
        cleanTextfield()
        
        
    }
    
    //MARK: - Go to App method
    func goToApp(){
        ProgressHUD.dismiss()
        cleanTextfield()
        dismissKeyboard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FirebaseUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
        
    }
    
    func dismissKeyboard(){
        view.endEditing(false)
    }
    
    func cleanTextfield(){
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }
    
    //MARK: Pass data to Finish Register View
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToFinishRegister" {
            
            let destinationVC = segue.destination as! FinishRegistrationViewController
            destinationVC.email = emailTextField.text
            destinationVC.password = passwordTextField.text
        }
    }
}
