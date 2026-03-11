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
        let alert = UIAlertController(
            title: "Register",
            message: "Sign up to Bevodoro here!",
            preferredStyle: .alert)
        
        alert.addTextField() { tfEmail in
            tfEmail.placeholder = "Enter your email"
        }
        
        alert.addTextField() { tfPassword in
            tfPassword.placeholder = "Enter your password"
            tfPassword.isSecureTextEntry = true
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { authResult, error in
                if let error = error as NSError? {
                    self.errorMsgLabel.text = "Error: \(error.localizedDescription)"
                } else {
                    self.errorMsgLabel.text = ""
                    MusicManager.shared.playMusic()

                    guard let uid = authResult?.user.uid else { return }
                    let email = authResult?.user.email ?? ""
                    let newUser = User(userID: uid, user: email)
                    UserManager.shared.currentUser = newUser
                    newUser.saveToFirestore()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

