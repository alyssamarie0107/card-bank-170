# Homework 3

## Student Name
Alyssa Rodriguez

## Student ID
917730599

## OTP Textfield: PinTextField Implementation
### didPressBackspace(textField: PinTextField)
I changed the class of all my textfields to **PinTextField** and implemented the
**PinTextFieldDelegate** protocol to fix the deletion bug from HW2 by
implementing `didPressBackspace()`. This function handles when the user presses
the backspace key in the keyboard. 

When this function is triggered, it gets the tag of the textfield in which the
user pressed the backspace in. It then checks first if this tag matches 0, which
indicates the user pressed the backspace in the first textfield box. I check if
the tag is 0 because I noticed that when the user does delete the content in
this field, and presses the backspace again when the textfield is empty, the
program crashes. Hence, I handled this case by checking if the tag is 0 and then
checking whether or not there is content in this first field. If there is
content in this field, I remove the content and remove the first digit in the
user code input by utilizing, `removeFirst()`. Now, if the first field is empty,
to prevent the program crashing when the user keeps entering backspace, I simply
set the first field to keep being the first responder.

If the tag is not equal to 0, I check if the field the user pressed backspace in
has content in it. If it is not empty, then I remain in the same field after
deletion. For instance, if I press backspace in the last field and it has
content, then I simply just delete that content and remain in the last field. If
the field is empty, I go to the previous field and delete its content. 

Since partial deletion is allowed in this OTP field, I get the index of the
textbox the user deleted in. This is achieved by the following code: 
```
let deletedDigitIndex = self.userCodeInput.index(self.userCodeInput.startIndex,offsetBy: tag)
```
I then remove this digit in the user code input by utilizing
`self.userCodeInput.remove(at: deletedDigitIndex)`. This is effective, because
for example, if the user enters: 1 2 0 4 5 6 in the OTP field, and they tap on
the third text field box with content 0, and delete it then the user code input
looks would be: 12456.

In regard to the UI of when the user does press backspace in the middle of the
OTP field, I leave the field in which they pressed backspace in blank. Thus,
going back to the example, even though the user code input looks like 12456, the
OTP field visually, looks like 1 2 _ 4 5 6. This makes sense to me because it
shows the user which field they deleted in and clearly shows where they need to
enter another number.

In regard to partial insertion, I handle this in `otpFieldChanged()`. This
function changed compared to how I implemented it in HW2. In
`otpFieldChanged()`, I similarly get the tag of the textfield the user edited
in. I then check if the textfield that they edited in, has a count >= 1. If it
does, then it checks if the tag is equal to 0, which again indicates that the
user entered a digit in the first field. I enable user interaction for all the
fields once the user edits the first field because I want the user to always
start in the first field. Now, in HW2 I simply adding the digit the user entered
in the field by using `self.userCodeInput += textField.text ?? ""`, which always
adds the digit to the end of the user code input string. This is not effective
for partial insertion because if I kept doing this and the did a partial
deletion and then entered a digit, it would add that digit to the end of the
user input. Therefore, I similarly got the index of the field the user entered a
digit in like how I did for partial deletion. However, instead of removing the
digit at that index in the user code input, I add the digit at that index I got.

```
let addedDigitIndex = self.userCodeInput.index(self.userCodeInput.startIndex, offsetBy: tag)

self.userCodeInput.insert(Character(otpFields[tag].text ?? ""), at: addedDigitIndex)
```
Let's refer back to the example of the user entering 1 2 0 4 5 6 and deleting 0,
which makes the OTP Field UI look like 1 2 _ 4 5 6. Now the user enters 3,
hence, the user code input will output 123456. 

If the tag is equal to (1-4), then it does the same thing as the case of tag
equaling 0, but it does not enable all the other fields for user interaction.
However, if the tag is equal to 5, the only difference is that it checks if the
content in this field is of length 1. If it is, then it does the same thing as
the case of the tag equaling (1-4). However, if the content in this last field
is not length of 1, then it removes whatever the user tried to enter by
utilizing `removeLast()`. I did this because I noticed that when a user enters a
verification code and it is incorrect, the field is still the first responder
and I did not limit the user from entering more digits in this field. Hence,
when the user enters 1 2 3 4 5 5, and it does not match the verification code
sent, then the user can do the following: 1 2 3 4 5 5555555. Thus, I used,
`otpFields[tag].text?.removeLast()` to prevent that from happening. 

Lastly, when the user code input has 6 digits, I then call `verifyHelper()`,
which handles verifying the code the user entered. 

## Username Update & Wallet View: Username Display
In the home view, I have a label that welcomes the user. Right next to this
label, I have a textfield, **usernameField**, that a user can edit to enter a
username. The function, `usernameFieldEditEnd()`, handles updating the username.
It is triggered when the user is done editing the field. 

Moreover, by default, the e164 format of the user's phone number is displayed in
this textfield if the user didn't set a name or if the user set the username as
a empty string. If the user does enter a username, I update the username that is
on the server using the Api function, `Api.setName(name: self.username,
completion: {...})`. If the user does not set a username, then again, I display
by default, the e164 format of the user's phone number.

When the user is presented with the home view, I call `initializeWallet()` in
`viewDidLoad()`. This function not only handles initializing the wallet, but it
checks if the user is a new user or an existing. This is achieved by using the
`Api.verifyCode(...)` response that is in the VerificationViewController. The
response includes `is_new_user` and it is set to 0 if the user is not new and is
set to 1 if the user is new. Since this is in the VerificationViewController and
I need to utilize it in the HomeViewController, I pass this value by having `var
isNewUser: Int?` in the HomeViewController and having the following code in the
VerificationViewController: 
```
let isNewUser = response?["is_new_user"] as? Int
            
homeViewController.isNewUser = isNewUser 
```
In `initializeWallet()`, I check if **isNewUser** is equal to 1, which indicates
that the user is new. In this case, since the user is new and the view just
loaded, I display the e164 format of the user's phone number. If isNewUser is
not equal to 1, then I check if they set a username by utilizing both
`Api.user()`, which gets the user's information from server and use its response
in `Wallet.init()`. If the username in `Wallet.init()` is not empty, I display
the username in the textfield, and if it is empty, I display the e164 format of
their phone number in the textfield. 

## Wallet View: Total Amount Display
Below the usernameField, I have a label called **totalAmountLabel**. This label,
displays the total amount of money the user has in all their accounts. For new
users, I set the total amount to be 0.0. If the user is an existing user, I
utilize `Wallet.init()` again and I set the total amount to be whatever the
total amount is in `Wallet.init()` and display it in the **totalAmountLabel**. 

## Wallet View: List of Accounts
To display the user's accounts, I utilize `UITableView` and
`UITableViewDatasource`. To customize the cells of the UITableView, I add a
Prototype Cell in the Attributes Inspector. Inside of the Prototype Cell, I add
2 labels: one label that is positioned to the far left that represents the
account name and the other label is positioned to the far right and it
represents the accountAmount. I used the following link as a reference and guide
to show me how to customize cells and display data in the UITableView:
https://developer.apple.com/documentation/uikit/views_and_controls/table_views/configuring_the_cells_for_your_table.
According to this reference, for custom cells, you need to define a
UITableViewCell subclass to access the cell’s views. Thus, I made a new class
called **AccountsCell**. It also stated to add outlets to the subclass and
connect those outlets to the corresponding views in your prototype cell.
Overall, this is what my class looks like in HomeViewController.swift: 
```
class AccountsCell: UITableViewCell {
    @IBOutlet weak var accountName: UILabel!
    @IBOutlet weak var accountAmount: UILabel!
}
```
I have two functions for the **-UITableViewDataSource implementation** One of
the functions returns the number of rows for the table. Thus, I return the count
of `accounts: [Accounts]`, which is an array of type Accounts. The other
function is one where the table view gets the actual cells itself that it is
going to display. I create a cell and fetch the data for the row by accessing
the **accounts** array. I then set the label outlets, **accountName** and
**accountAmount**, like so: 
```
cell.accountName.text = theAccount.name
cell.accountAmount.text = String(theAccount.amount)
```
I then return the cell at the end of this function. 

## Simplified Login
### Pre-fill
Pre-filling the phone number textfield on the login view with the last logged in
user's phone number was implemented by checking if there was a number stored in
storage, (`Storage.phoneNumberInE164`). If there was, before displaying it in
the textfield, some string maniputlation on the phone number was performed since
it was formatted in E164 and it needed to be displayed in the phone number
textfield as a phone number. I utilized `dropFirst(2)` to remove the region code
of the E164 phone number. If there was no phone number found in storage, then I
simply did not display anything in the phone number textfield(except the
placeholder would be triggered to display). 

### Skip verification
Once the user enters a phone number and it is confirmed that it is valid, I
check if the user is the last successfully logged in user by using the
following: 
```
if (Storage.authToken != nil && Storage.phoneNumberInE164 == self.e164PhoneNumber) {...}
```
This checks if there is an authentication token and if the phone number in
storage matches the phone number the user entered. If so, then the user is the
last successfully logged in user, thus, verification is skipped and they are
brought to the home view. This was achieved by setting the viewController stack
such that it only contains the home view. Hence, the flow for the last
successfully logged in user is: Login View (valid last user) -> Wallet View -
(logout) -> Login View. 

However, if the user is a new user or they are not the last successfully logged
in user, then a verification code does need to be sent to their phone and they
do have to go through the verification view to enter the code. The user can
still toggle between the login view and the verification view, thus instead of
setting the viewController stack such that it only had a certain view, the
verification view was pushed to the view controller. The screen flow for users
who were not the last successfully logged in user or for new users is the
following: Login View - (valid number) -> Verify View - (valid code) -> Wallet
View - (logout) -> Login View.

## Logout
In the home view, there is a logout button. When it is pressed it triggers the
`logoutButtonPressed()` function, which handles taking the user back to the
login view. This is not a push onto the viewController, thus the viewController
stack is set such that it only contains the login view. The phone number field
should be pre-filled with the phone number of the user that was last logged in.
The implementation of this is at the beginning of the report. 
