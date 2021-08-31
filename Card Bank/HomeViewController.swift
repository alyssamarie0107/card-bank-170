//
//  HomeViewController.swift
//  Card Bank
//
//  Created by Alyssa Rodriguez on 1/26/21.
//

import UIKit

// for custom cells, defined a UITableViewCell subclass to access cell’s views
class AccountsCell: UITableViewCell {
    @IBOutlet weak var accountName: UILabel!
    @IBOutlet weak var accountAmount: UILabel!
}

class HomeViewController: UIViewController, UITableViewDataSource {
    
    var isNewUser: Int? // stores if this is a new user (received from verification view)
    var e164PhoneNumber = Storage.phoneNumberInE164 // get e164 number from storage
    var username = "" // stores the username entered in textfield
    var totalAmount: Double = 0.0
    var accounts: [Account] = []
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var accountsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = nil // removes navigation bar title
        
        print("storageE164PhoneNumber: \(self.e164PhoneNumber ?? "")")
        
        usernameField.isHidden = true
        
        // viewcontroller is now also a model for the table view
        accountsTableView.dataSource = self
        
        // initializes wallet object
        initializeWallet()
        
        // handles when user taps outside of the text field
        view.addGestureRecognizer(UITapGestureRecognizer(target: self , action: #selector(dismissKeyboard)))
    }
    
    // handles initializing wallet object
    func initializeWallet () {
        // use Api.user to get the user information from server on this view
        Api.user(completion: { response, error in
            print("initialize response: \(response ?? ["":""])")
            // check if this is a new user
            if (self.isNewUser == 1) {
                // initialize new user's wallet object
                let newUserWallet = Wallet.init()
                
                self.username = newUserWallet.userName ?? ""
                self.accounts = newUserWallet.accounts
                self.totalAmount = newUserWallet.totalAmount
                
                guard let user = response?["user"] as? [String: Any] else {return}
                
                self.e164PhoneNumber = user["e164_phone_number"] as? String
                
                // since this a new user, username is not set yet so display their phone number
                self.usernameField.text = "\(self.e164PhoneNumber ?? "")"
            }
            else {
                /*
                 initialize existing user's wallet object using random generating init function (ifGenerateAccounts: true)
                 my phone number account info: totalAmount - $70290.56, # of Accounts - 12
                
                 set ifGenerateAccounts: false after initialized existingUserwallet sucessfully the first time
                 when log back in, my account info should match account info above
                 existings users, such as my Google Voice #, will see their wallet as empty (even though it is now a existing user)
                 since I changed ifGenerateAccounts: false
                */
                let existingUserWallet = Wallet.init(data: response ?? ["": ""], ifGenerateAccounts: false)
                
                self.username = existingUserWallet.userName ?? existingUserWallet.phoneNumber
                self.accounts = existingUserWallet.accounts
                self.totalAmount = existingUserWallet.totalAmount
                self.e164PhoneNumber = existingUserWallet.phoneNumber
                
                // save the wallet on the server using Api function setAccounts
                Api.setAccounts(accounts: self.accounts, completion: { response, error in
                    if (error != nil) {
                        print("error: did not save accounts")
                    }
                    else {
                        print("success: accounts saved")
                    }
                })
                
                // check if user set a username
                if (self.username != "") {
                    // if so, display the username in usernameField
                    self.usernameField.text = "\(self.username)"
                }
                else {
                    // if the user didn't set a name present user's number in e164 as the default username
                    self.usernameField.text = "\(self.e164PhoneNumber ?? "")"
                }
            }
            
            // show the username field now
            self.usernameField.isHidden = false
            
            // update total amount label (display totalAmount value rounded to two decimals)
            self.totalAmountLabel.text = "Total Amount: $\(String(format:"%.2f", self.totalAmount))"
            
            // reloads the rows and sections of the table view.
            self.accountsTableView.reloadData()
        })
    }
    
    // handles the dismissal of the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // handles updating the username
    @IBAction func usernameFieldEditEnd() {
        // check if user entered some text
        if (usernameField.text != "") {
            self.username = usernameField.text ?? "" // set username to whatever user entered
            print("username entered: \(self.username)")
            
            // update username that is on the server using Api function setName
            Api.setName(name: self.username, completion: { response, error in
                if (error != nil) {
                    print("error: name was not updated sucessfully")
                }
                else {
                    print("success: name was updated, next time user logs in, this name should be displayed in Welcome string")
                    print("response: \(response ?? ["":""])")
                }
            })
        }
        else {
            // if user set the name as empty present user's number in e164 as default name
            usernameField.text = "\(self.e164PhoneNumber ?? "New user")"
            print("user entered empty string, default to displaying e164 number")
        }
    }
    
    // handles case when user presses the logout button
    @IBAction func logoutButtonPressed() {
        // reset back to opening login view
        // not a push onto the viewcontroller, it is a new stack
        print("logout button pressed -> reset back to login view")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginViewController")
        let viewControllers = [loginViewController] // set the stack so that it only contains main and animate it
        
        self.navigationController?.setViewControllers(viewControllers, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: true) // hiding nav bar for UI aesthetics
    }
    
    // MARK: -UITableViewDataSource implementation
    // return the number of rows for the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        return self.accounts.count
    }
    
    // second function is one where the table view gets the actual cells itself that it is going to display
    // provide a cell object for each row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as! AccountsCell
        
        // fetch data for the row
        let theAccount = accounts[indexPath.row]
        
        cell.accountName.text = theAccount.name
        cell.accountAmount.text = String(theAccount.amount)
        
        return cell
    }
    
}
