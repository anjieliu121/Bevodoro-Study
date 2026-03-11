//
//  LoginViewController.swift
//  Bevodoro Study
//
//  Created by Josceline M Roeper on 2/25/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorMsgLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMsgLabel.text = ""
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                // User is signed in, but we avoid auto-navigation here to prevent auto-login.
            }
        }
    }

    @IBAction func signInButton(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) {
            authResult, error in
                if let error = error as NSError? {
                    self.errorMsgLabel.text = "Error: \(error.localizedDescription)"
                } else {
                    self.errorMsgLabel.text = ""
                    self.performSegue(withIdentifier: "loginSegue", sender: self)
                    self.emailField.text = ""
                    self.passwordField.text = ""
                }
        }
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        // Borrowed code from class
        let alert = UIAlertController(
            title: "Register",
            message: "Sign up to Bevodoro here!",
            preferredStyle: .alert)
        
        alert.addTextField() { tfEmail in
            tfEmail.placeholder = "Enter your email"
        }
        
        alert.addTextField() { tfUser in
            tfUser.placeholder = "Enter your username"
        }
        
        alert.addTextField(){ tfPassword in
            tfPassword.placeholder = "Enter your password"
            tfPassword.isSecureTextEntry = true
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            let emailField = alert.textFields![0]
            let userField = alert.textFields![1]
            let passwordField = alert.textFields![2]
            
            // create a new user auth here
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { authResult, error in
                if let error = error as NSError? {
                    self.errorMsgLabel.text = "Error: \(error.localizedDescription)"
                } else if let authResult = authResult {
                    let newUser = User(userUID: authResult.user.uid, username: userField.text!)
                    newUser.uploadChangesToFirebase()
                    self.errorMsgLabel.text = ""
//                    let newUser = User(userUID: authResult.user.uid, username: userField.text!)
//                    
//                    let db = Firestore.firestore()
//                    do {
//                        try db.collection("users")
//                            .document(authResult.user.uid)
//                            .setData(from: newUser)
//                        self.errorMsgLabel.text = ""
//                    } catch let firestoreError {
//                        self.errorMsgLabel.text = "Error: \(firestoreError.localizedDescription)"
//                    }
                    
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

