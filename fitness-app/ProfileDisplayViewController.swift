import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileDisplayViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profilename: UILabel!
    @IBOutlet weak var profileage: UILabel!
    @IBOutlet weak var profilegender: UILabel!
    @IBOutlet weak var profileheight: UILabel!
    @IBOutlet weak var profileweight: UILabel!
    
    @IBOutlet weak var logoutButton: UIButton!  // Add the logout button outlet
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserProfileData()
        
        // Style the logout button
        styleButton(logoutButton)
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            navigateToLogin()
        } catch let error {
            showAlert(title: "Logout Failed", message: error.localizedDescription)
        }
    }

    func fetchUserProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(userID).getDocument { document, error in
            if let error = error {
                self.showAlert(title: "Error", message: "Error fetching data: \(error.localizedDescription)")
                return
            }
            guard let data = document?.data() else {
                self.showAlert(title: "No Data", message: "No profile data found.")
                return
            }
            
            if let gender = data["gender"] as? String {
                if gender == "Male" {
                    self.profileImageView.image = UIImage(named: "male.png")
                } else if gender == "Female" {
                    self.profileImageView.image = UIImage(named: "female.png")
                } else {
                    self.profileImageView.image = UIImage(named: "default.png") // Use a default image if gender is not recognized
                }
            }

            self.profilename.text = data["name"] as? String ?? "No Name"
            self.profileage.text = "\(data["age"] as? Int ?? 0)"
            self.profilegender.text = data["gender"] as? String ?? "No Gender"
            self.profileheight.text = "\(data["height"] as? Double ?? 0.0)"
            self.profileweight.text = "\(data["weight"] as? Double ?? 0.0)"
        }
    }

    func navigateToLogin() {
        if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: true)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Button styling method
    func styleButton(_ button: UIButton) {
        let buttonFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        button.titleLabel?.font = buttonFont
        
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}
