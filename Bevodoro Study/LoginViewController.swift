//
//  LoginViewController.swift
//  Bevodoro Study
//
//  Created by Josceline M Roeper on 2/25/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorMsgLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMsgLabel.text = ""
        emailField.delegate = self
        passwordField.delegate = self
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

    @IBAction func signInButton(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) {
            authResult, error in
            if let error = error as NSError? {
                self.errorMsgLabel.text = "Error: \(error.localizedDescription)"
                return
            }

            self.errorMsgLabel.text = ""
            guard let uid = authResult?.user.uid else { return }
            let email = authResult?.user.email ?? ""

            User.fetch(uid: uid) { fetchedUser in
                if var user = fetchedUser {
                    user.lastLogin = Timestamp(date: Date())
                    UserManager.shared.currentUser = user
                    user.saveToFirestore()
                } else {
                    let newUser = User(userID: uid, user: email)
                    UserManager.shared.currentUser = newUser
                    newUser.saveToFirestore()
                }

                DispatchQueue.main.async {
                    MusicManager.shared.playMusic()
                    self.performSegue(withIdentifier: "loginSegue", sender: self)
                    self.emailField.text = ""
                    self.passwordField.text = ""
                }
            }
        }
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        performSegue(withIdentifier: "signUpSegue", sender: self)
    }
}
