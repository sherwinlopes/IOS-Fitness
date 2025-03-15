import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Missing Fields", message: "Please fill in both email and password.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // If an error occurs during login, show an alert
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
            } else {
                // Successfully logged in, navigate to ProfileDisplayViewController
                self.navigateToHome()
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
    
    func navigateToHome() {
        // Ensure the user is authenticated
        if Auth.auth().currentUser != nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                homeVC.modalPresentationStyle = .fullScreen
                self.present(homeVC, animated: true, completion: nil)
            }
        } else {
            showAlert(title: "Error", message: "User is not authenticated.")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func setupUI() {
        // Configure text fields
        configureTextField(emailTextField, placeholder: "Email")
        configureTextField(passwordTextField, placeholder: "Password", isSecure: true)
        
        // Customize buttons
        let buttonFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        loginButton.titleLabel?.font = buttonFont
        signupButton.titleLabel?.font = buttonFont
        
        // Set button styles
        loginButton.layer.cornerRadius = 10
        loginButton.layer.masksToBounds = true
        
        signupButton.layer.cornerRadius = 10
        signupButton.layer.masksToBounds = true
        
        // Set button heights (optional)
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signupButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func configureTextField(_ textField: UITextField, placeholder: String, isSecure: Bool = false) {
        textField.placeholder = placeholder
        textField.layer.borderColor = UIColor.darkGray.cgColor
        textField.layer.cornerRadius = 10  // Adding corner radius for rounded edges
        textField.layer.borderWidth = 1
        textField.isSecureTextEntry = isSecure
        textField.font = UIFont.systemFont(ofSize: 28)  // Set text size to 28
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Adjust text field height to 50 (or any height that works)
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 50) // Set text field height to 50
        ])
    }
}
