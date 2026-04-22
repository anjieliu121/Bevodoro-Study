//
//  LoginViewController.swift
//  Bevodoro Study
//
//  Created by Josceline M Roeper on 2/25/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorMsgLabel: UILabel!
    
    override var backgroundImageName: String { "texture_ut_dark" }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMsgLabel.text = ""
        emailField.delegate = self
        passwordField.delegate = self
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

    @IBAction func signInButton(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) {
            authResult, error in
            if let error = error as NSError? {
                HapticsManager.shared.error()
                let authError = AuthErrorCode(rawValue: error.code)
                switch authError {
                case .userNotFound:
                    self.errorMsgLabel.text = "Email not registered to an account."
                case .wrongPassword:
                    self.errorMsgLabel.text = "Incorrect password. Please try again."
                case .invalidEmail:
                    self.errorMsgLabel.text = "Please enter a valid email."
                default:
                    self.errorMsgLabel.text = "Error: \(error.localizedDescription)"
                }
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
                    HapticsManager.shared.success()
                    MusicManager.shared.playMusic()
                    self.emailField.text = ""
                    self.passwordField.text = ""
                    let loadingVC = LoadingViewController()
                    loadingVC.modalPresentationStyle = .fullScreen
                    self.present(loadingVC, animated: true)
                }
            }
        }
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        performSegue(withIdentifier: "signUpSegue", sender: self)
    }
}
