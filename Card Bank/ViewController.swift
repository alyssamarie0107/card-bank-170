//
//  ViewController.swift
//  Card Bank
//
//  Created by Alyssa Rodriguez on 1/18/21.
//

import UIKit
import PhoneNumberKit

class ViewController: UIViewController {

    let phoneNumberKit = PhoneNumberKit()
    
    var isValidPhoneNumber = false
    var e164PhoneNumber = "" // this will store the e164 version of the number entered

    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var errInfoLabel: UILabel!
    @IBOutlet weak var phoneNumberField: PhoneNumberTextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.activityIndicator.stopAnimating()
        
        errInfoLabel.isHidden = true
        
        clearButton.isHidden = true
        
        arrowButton.layer.cornerRadius = 10.0
        
        // check if there is a number stored in storage
        // if there is, prefill the phoneNumberField
        if (Storage.phoneNumberInE164 != "") {
            clearButton.isHidden = false
            // string manipulation to get rid of the region code
            let strippedStorageNumber = String(Storage.phoneNumberInE164?.dropFirst(2) ?? "")
            phoneNumberField.text = strippedStorageNumber
        }
        else {
            phoneNumberField.text = ""
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self , action: #selector(dismissKeyboard)))
    }
    
    // handles the dismissal of the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // handles when the phoneNumberTextField changes, the error,info label hide
    @IBAction func phoneNumberFieldChanged() {
        errInfoLabel.isHidden = true // when user edits this field, hide errInfo label
        clearButton.isHidden = false
        
        if (phoneNumberField.text == "") {
            clearButton.isHidden = true
        }
    }
    
    // handles clearing the phone number field when clear button pressed upon
    @IBAction func clearButtonPressed() {
        phoneNumberField.text = ""
        
        if (phoneNumberField.text == "") {
            clearButton.isHidden = true
        }
    }
    
    // if arrow button is pressed show the valid number in e164 format if valid, show error if invalid
    @IBAction func arrowButtonPressed() {
        self.dismissKeyboard() // dismiss keyboard when user presses the arrow button
        
        guard let userInput = phoneNumberField.text else { return } // this stores the userInput
        print("user entered: \(userInput)")
        
        var phoneNumberKitValidation = true // phoneNumberKit does an automatic hard type validation

        do {
            let phoneNumber = try phoneNumberKit.parse(userInput) // parse function should return phoneNumber to be of type 'PhoneNumber'
            self.e164PhoneNumber = phoneNumberKit.format(phoneNumber, toType: .e164) // this formats phoneNumber to be in e164 format
        }
        catch {
            phoneNumberKitValidation = false
            print("Input valid: \(phoneNumberKitValidation)")
        }
        
        // removes all of the parentheses, white spaces, and the dash in userInput
        let userPhoneNumber = userInput
            .components(separatedBy:CharacterSet.decimalDigits.inverted)
            .joined()
        print("userPhoneNumber: \(userPhoneNumber)")
        
        // error if user inpput is less than 10
        if(userPhoneNumber.count < 10) {
            self.isValidPhoneNumber = false
            print("isValidPhoneNumber: \(self.isValidPhoneNumber)")
            errInfoLabel.isHidden = false
            errInfoLabel.textColor = UIColor.red
            self.errInfoLabel.text = "Too Short. Please enter a valid number."
        }
        // error if user input is greater than 10
        else if (userPhoneNumber.count > 10) {
            self.isValidPhoneNumber = false
            print("isValidPhoneNumber: \(self.isValidPhoneNumber)")
            errInfoLabel.isHidden = false
            errInfoLabel.textColor = UIColor.red
            self.errInfoLabel.text = "Too Long. Please enter a valid number."
        }
        // captures errors that phoneNumberKit detects (e.g (555) 555-5555)
        else if (phoneNumberKitValidation == false) {
            self.isValidPhoneNumber = false
            print("isValid: \(self.isValidPhoneNumber)")
            errInfoLabel.isHidden = false
            errInfoLabel.textColor = UIColor.red
            self.errInfoLabel.text = "Please enter a valid number."
        }
        else {
            self.isValidPhoneNumber = true
            print("isValid: \(self.isValidPhoneNumber)")
            errInfoLabel.isHidden = false
            errInfoLabel.textColor = UIColor.white
            self.errInfoLabel.text = "You submitted \(self.e164PhoneNumber)"
        }
        
        // only if phone number is valid and presses the arrow btn
        if (self.isValidPhoneNumber == true) {
            // check if current user is the last successfully logged in user
            if (Storage.authToken != nil && Storage.phoneNumberInE164 == self.e164PhoneNumber) {
                // this user is the last successfully logged in user, thus skip verification and go to home view
                print("user is the last successfully logged in user -> home view")
                
                // old user: login view - (valid last user) -> wallet view - (logout) -> login view
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let homeViewController = storyboard.instantiateViewController(withIdentifier: "homeViewController")
                let viewControllers = [homeViewController] // set the stack so that it only contains home and animate it

                self.navigationController?.setViewControllers(viewControllers, animated: true)
                self.navigationController?.setNavigationBarHidden(false, animated: true) // hiding nav bar for UI aesthetics
            }
            else {
                // this user is not the last sucessfully logged in user, thus send them a verification code and switch to verification view
                print("user is not the last successfully logged in user -> verification view")
                
                self.stopView() // about to send verification code
                
                // send user the verification code using the testSendVerificationCode from Api.swift
                Api.sendVerificationCode(phoneNumber: self.e164PhoneNumber, completion: { response, error in
                    // check if there is a error (success = error is nil)
                    if (error?.code != nil) {
                        print("error: text with verification code not sent")
                    } else {
                        print("success: user will receive text with verification code")
                    }
                    
                    // new user: login view - (valid number) -> verify view - (valid code) -> wallet view - (logout) -> login view
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    // use string to identify which view controller you want to hydrate at this point
                    guard let verificationViewController = storyboard.instantiateViewController(withIdentifier: "verificationViewController") as? VerificationViewController
                        else {
                            assertionFailure("couldn't find vc")
                            self.startView()
                            return
                    }
                    // passing the e164 phone number format to verificationViewController
                    verificationViewController.e164PhoneNumber = self.e164PhoneNumber
                    
                    self.navigationController?.pushViewController(verificationViewController, animated: true)
                    
                    self.startView()
                })
            }
        }
    }
    
    // stops user from interacting with the view and waits until the completion call is finished
    func stopView () {
        self.activityIndicator.startAnimating()
        
        // nothing in the view will be able to be interacted with
        self.view.isUserInteractionEnabled = false
    }
    
    // starts the view again
    func startView () {
        self.activityIndicator.stopAnimating()
        
        // allow user to interact with view again
        self.view.isUserInteractionEnabled = true
    }
    
}
