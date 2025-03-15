import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "All fields are required.")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match!")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                self?.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                return
            }
            print("Successful sign-up")
            self?.navigateTo("ProfileSetupViewController")
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        navigateTo("LoginViewController")
    }
    
    private func navigateTo(_ viewControllerID: String) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: viewControllerID) {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupUI() {
        configureTextField(emailTextField, placeholder: "Email")
        configureTextField(passwordTextField, placeholder: "Password", isSecure: true)
        configureTextField(confirmPasswordTextField, placeholder: "Confirm Password", isSecure: true)
        
        // Configure Sign Up Button
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        
        signUpButton.layer.masksToBounds = true
        
        signUpButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        loginButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        loginButton.setTitleColor(.systemBlue, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .medium)
    }
    
    private func configureTextField(_ textField: UITextField, placeholder: String, isSecure: Bool = false) {
        textField.placeholder = placeholder
        textField.layer.borderColor = UIColor.darkGray.cgColor
        textField.layer.cornerRadius = 10  // Adding corner radius for rounded edges
        textField.layer.borderWidth = 1
        textField.isSecureTextEntry = isSecure
        textField.font = UIFont.systemFont(ofSize: 26)  // Set text size to 28
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Adjust text field height to 50 (or any height that works)
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 50) // Set text field height to 50 (can be adjusted as per needs)
        ])
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
