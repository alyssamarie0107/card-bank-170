//
//  VerificationViewController.swift
//  Card Bank
//
//  Created by Alyssa Rodriguez on 1/22/21.
//

import UIKit

class VerificationViewController: UIViewController, PinTexFieldDelegate {
    var e164PhoneNumber: String? // holds the e164 format of phone number (received from login view)
    var userCodeInput = "" // holds the code the user inputs
    var pressedBackspace = false
    
    @IBOutlet weak var instructLabel: UILabel!
    @IBOutlet var otpFields: [PinTextField]! // outlet collection of the six text fields
    @IBOutlet weak var verifErrLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.activityIndicator.stopAnimating()
        
        verifErrLabel.isHidden = true
        
        resendButton.layer.cornerRadius = 10.0
        
        self.instructLabel.text = "Enter the code sent to \(self.e164PhoneNumber ?? "your phone")"
        
        // handles when user taps outside of the text field
        view.addGestureRecognizer(UITapGestureRecognizer(target: self , action: #selector(dismissKeyboard)))
        
        // handles assigning the same action method to each otpField in otpFields
        for otpField in otpFields {
            if (otpField.tag == 0) {
                otpField.becomeFirstResponder()
            }
            else {
                otpField.isUserInteractionEnabled = false
            }
            otpField.delegate = self

            otpField.addTarget(self, action: #selector(otpFieldChanged), for: .editingChanged)
        }
    }
    
    // handles the dismissal of the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: -PinTextField implementation
    // handles when user presses backspace
    func didPressBackspace(textField: PinTextField) {
        print("pressed backspace deteced")
        
        self.verifErrLabel.isHidden = true

        var tag = textField.tag
        
        if (tag == 0) {
            // check if there is content in otpField0, if there is remove the first digit in user code input
            if (otpFields[tag].text != "") {
                otpFields[tag].text = ""
                self.userCodeInput.removeFirst()
            }
            // if otpField0 is empty, program should not crash when user presses backspace more than once
            else {
                print("cannot backspace any futher")
                otpFields[tag].becomeFirstResponder()
            }
        }
        else {
            // if otpField[tag] is not empty, remain in same otpField after deletion
            if (otpFields[tag].text != "") {
                otpFields[tag].text = ""
                otpFields[tag].becomeFirstResponder()
            }
            // if the otpField is empty, go to the previous otpField and delete its content
            else {
                otpFields[tag].resignFirstResponder()
                tag -= 1
                otpFields[tag].text = ""
                otpFields[tag].becomeFirstResponder()
            }
            // get the index of the digit the user deleted
            let deletedDigitIndex = self.userCodeInput.index(self.userCodeInput.startIndex, offsetBy: tag)
                
            // remove the digit from the userInput
            self.userCodeInput.remove(at: deletedDigitIndex)
            print("editedUserCodeInput: \(self.userCodeInput)")
        }
    }
    
    // handles when the otpFields change
    @objc func otpFieldChanged(textField: PinTextField) {
        self.verifErrLabel.isHidden = true
        
        var tag = textField.tag // assigned each otpField in otpFields a unique tag in attribute inspector
        
        if (textField.text?.count ?? 0 >= 1) {
            if (tag == 0) {
                print("entered otpField0")
                
                // enable all the fields to be interacted with again since we can do partial deletion now
                for optField in otpFields {
                    optField.isUserInteractionEnabled = true
                }
                
                // get the index of the digit the user added
                let addedDigitIndex = self.userCodeInput.index(self.userCodeInput.startIndex, offsetBy: tag)
                
                // insert the digit the user added to user code input
                self.userCodeInput.insert(Character(otpFields[tag].text ?? ""), at: addedDigitIndex)
                print("userCodeInput: \(self.userCodeInput)")
                
                otpFields[tag].resignFirstResponder()
                otpFields[tag+1].becomeFirstResponder()
                
            }
            // this otpfield5 does not have to worry about resigning/setting next first responder
            else if (tag == 5) {
                print("entered otpField5")
                
                // check if the content in otpField5 is of length 1
                if (otpFields[tag].text?.count == 1) {
                    let addedDigitIndex = self.userCodeInput.index(self.userCodeInput.startIndex, offsetBy: tag)
                    
                    self.userCodeInput.insert(Character(otpFields[tag].text ?? ""), at: addedDigitIndex)
                    
                    print("userCodeInput: \(self.userCodeInput)")
                }
                // if not, when user tries to enter another digit, remove it from textfield and do nothing to user code input
                else {
                    otpFields[tag].text?.removeLast()
                    
                    print("userCodeInput: \(self.userCodeInput)")
                }
               // last field should stay being first responder
                otpFields[tag].becomeFirstResponder()
            }
            // case where tag is (1-4)
            else {
                let addedDigitIndex = self.userCodeInput.index(self.userCodeInput.startIndex, offsetBy: tag)
                
                self.userCodeInput.insert(Character(otpFields[tag].text ?? ""), at: addedDigitIndex)
                print("userCodeInput: \(self.userCodeInput)")
                
                // the middle fields needs to be able to resign/set another first responder
                otpFields[tag].resignFirstResponder()
                otpFields[tag+1].becomeFirstResponder()
            }
            
            // this gets executed by all otpfields
            // when the user enters 6 digits, verify if it is the correct code
            if (self.userCodeInput.count == 6) {
                tag = 5
                otpFields[tag].becomeFirstResponder() // set cursor at the end of textfield
                
                verifyHelper()
            }
        }
    }
    
    // handles verifying the user input code
    // takes necessary actions if error
    // if no error, user is sent to HomeView (unable to return to any other views)
    func verifyHelper () {
        self.stopView() // about to verify code
        
        Api.verifyCode(phoneNumber: self.e164PhoneNumber ?? "", code: self.userCodeInput, completion: { response, error in
            // handle the response and error here
            // check if there is a error (success = error is nil)
            if (error?.code != nil) {
                print("error: user entered incorrect code")
                
                // display the error message
                self.verifErrLabel.isHidden = false
                self.verifErrLabel.text = error?.message
            }
            else {
                print("success: user entered correct code -> take to HomeView")
                print("verification response: \(response ?? ["":""])")
                
                // handles not moving from the HomeView to any other view once user enters this view
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                guard let homeViewController = storyboard.instantiateViewController(withIdentifier: "homeViewController") as? HomeViewController
                else {
                    assertionFailure("couldn't find vc")
                    return
                }
                
                let viewControllers = [homeViewController] // set the stack so that it only contains main and animate it
                
                self.navigationController?.setViewControllers(viewControllers, animated: true)
                self.navigationController?.setNavigationBarHidden(true, animated: true) // hiding nav bar for UI aesthetics
                
                // after sucessfully verified the code, store the e164 phone number and auth token using Storage
                // this makes sure that i get the user information and update the user name by Api call in the future steps.
                guard let user = response?["user"] as? [String: Any] else {return}
                
                Storage.phoneNumberInE164 = user["e164_phone_number"] as? String
                print("storage number: \(Storage.phoneNumberInE164 ?? "")")
                
                Storage.authToken = response?["auth_token"] as? String
                print("storage auth token: \(Storage.authToken ?? "")")
                
                let isNewUser = response?["is_new_user"] as? Int // stores if this is a new user 
                print(isNewUser ?? -1) 
                
                homeViewController.isNewUser = isNewUser // passing the isNewUser to home view 
            }
            self.startView()
        })
    }
    
    // if resend button is pressed, resend text with verification code
    @IBAction func resendButtonPressed() {
        print("resending text with verification code")
        
        self.stopView() // about to resend verification code
        
        Api.sendVerificationCode(phoneNumber: self.e164PhoneNumber ?? "", completion: { response, error in
            // handle the response and error here
            // check if there is a error (success = error is nil)
            if (error?.code != nil) {
                print("error: user did not get another text with verification code")
            } else {
                print("success: user will receive another text with verification code")
            }
            self.startView()
        })
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
