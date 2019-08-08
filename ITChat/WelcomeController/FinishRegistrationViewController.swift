//
//  FinishRegistrationViewController.swift
//  ITChat
//
//  Created by NeilPhung on 8/2/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit
import ProgressHUD

class FinishRegistrationViewController: UIViewController {
    
    var email: String!
    var password: String!
    
    var avatarImage: UIImage?
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(email)
        print(password)
    }
    
    //MARK: IBAction
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismissKeyboard()
        cleanTextfield()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        dismissKeyboard()
        ProgressHUD.show("Register...")
        
        if nameTextField.text != "" && surnameTextField.text != "" && cityTextField.text != "" && countryTextField.text != "" && cityTextField.text != "" {
            
            FirebaseUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!) { (error) in
                
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error?.localizedDescription)
                    return
                }
                self.registerUser()
            }
        }
            
        else {
            ProgressHUD.showError("all textfile enter")
        }
        
    }
    
    //MARK: Helper method
    
    func registerUser(){
        
        let fullName = nameTextField.text! + " " + surnameTextField.text!
        
        var tempDictinary: Dictionary = [kFIRSTNAME : nameTextField.text!, kLASTNAME : surnameTextField.text!, kFULLNAME : fullName, kCOUNTRY :  countryTextField.text!, kCITY : cityTextField.text!] as [String : Any]
        
        if avatarImage == nil {
            // create a image from fistName and surname
            imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!) { (avatarInit) in
                let avatarIMG = avatarInit.jpegData(compressionQuality: 0.7)
                //convert avatarIMG -> avartarData to save on firebase
                let avartar = avatarIMG!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                tempDictinary[kAVATAR] = avartar
                
                self.finishRegistration(withValues: tempDictinary)
            }
        }
            
        else {
            let avatarIMG = avatarImage!.jpegData(compressionQuality: 0.7)
            //convert avatarIMG -> avartarData to save on firebase
            let avartar = avatarIMG!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictinary[kAVATAR] = avartar
            
            self.finishRegistration(withValues: tempDictinary)
        }
    }
    
    func finishRegistration(withValues: [String : Any]) {
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                    
                    return
                }
            }
            
            self.goToMainApplication()
        }
    }
    
    func goToMainApplication(){
        cleanTextfield()
        dismissKeyboard()
        ProgressHUD.dismiss()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FirebaseUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }
    
    func dismissKeyboard(){
        view.endEditing(false)
    }
    
    func cleanTextfield(){
        nameTextField.text = ""
        surnameTextField.text = ""
        cityTextField.text = ""
        countryTextField.text = ""
        phoneTextField.text = ""
    }
    
}
