import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Any additional setup if required
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Missing Fields", message: "Please fill in both email and password.")
            return
        }
        
        // Sign in the user using Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // If an error occurs during login, show an alert
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
            } else {
                // Successfully logged in, navigate to ProfileDisplayViewController
                self.navigateToProfileDisplay()
            }
        }
    }
    
    @IBAction func signupTapped(_ sender: UIButton) {
          // Navigate to SignupViewController
          let storyboard = UIStoryboard(name: "Main", bundle: nil)
          if let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController {
              signupVC.modalPresentationStyle = .fullScreen
              self.present(signupVC, animated: true, completion: nil)
          }
      }
    
    func navigateToProfileDisplay() {
        // Make sure the user is authenticated before navigating
        if Auth.auth().currentUser != nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let profileDisplayVC = storyboard.instantiateViewController(withIdentifier: "ProfileDisplayViewController") as? ProfileDisplayViewController {
                profileDisplayVC.modalPresentationStyle = .fullScreen
                self.present(profileDisplayVC, animated: true, completion: nil)
            }
        } else {
            // User is not authenticated, show alert
            showAlert(title: "Error", message: "User is not authenticated.")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
