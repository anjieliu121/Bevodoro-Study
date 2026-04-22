//
//  SignUpViewController.swift
//  Bevodoro Study
//
//  Created by Josceline M Roeper on 3/11/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var errorMsgLabel: UILabel!
    
    override var backgroundImageName: String { "texture_ut_dark" }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMsgLabel.text = ""
        emailField.delegate = self
        usernameField.delegate = self
        passwordField.delegate = self
        passwordField.isSecureTextEntry = true
        confirmPasswordField.isSecureTextEntry = true
        HapticsManager.shared.prepareForInteraction()
    }
    
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }


    @IBAction func registerButton(_ sender: Any) {
        guard let email = emailField.text, !email.isEmpty, let username = usernameField.text, !username.isEmpty, let password = passwordField.text, !password.isEmpty, let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
                errorMsgLabel.text = "Please fill in all fields."
                HapticsManager.shared.warning()
                return
            }
        guard password == confirmPassword else {
            errorMsgLabel.text = "Passwords do not match."
            HapticsManager.shared.warning()
            return
        }
            
        errorMsgLabel.text = ""

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                self.errorMsgLabel.text = "Error: \(error.localizedDescription)"
                HapticsManager.shared.error()
                return
            }

            guard let authResult = authResult else { return }
            let newUser = User(userID: authResult.user.uid, user: username)
            newUser.saveToFirestore()

            DispatchQueue.main.async {
                // Show success then pop back to login
                let alert = UIAlertController(
                    title: "Account Created",
                    message: "Your account has been created. Please log in.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                HapticsManager.shared.success()
                self.present(alert, animated: true)
            }
        }
    }
}
