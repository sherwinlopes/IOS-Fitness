import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileDisplayViewController: UIViewController {

    @IBOutlet weak var profilename: UILabel!
    @IBOutlet weak var profileage: UILabel!
    @IBOutlet weak var profilegender: UILabel!
    @IBOutlet weak var profileheight: UILabel!
    @IBOutlet weak var profileweight: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch user data from Firestore
        fetchUserProfileData()
    }
    
    @IBAction func logoutTapped(_ sender: UIButton) {
           // Sign out the user from Firebase
           do {
               try Auth.auth().signOut()
               // Navigate back to the LoginViewController after logout
               navigateToLogin()
           } catch let signOutError as NSError {
               showAlert(title: "Logout Failed", message: signOutError.localizedDescription)
           }
       }
    
    func fetchUserProfileData() {
        // Ensure that the user is logged in
        guard let userID = Auth.auth().currentUser?.uid else { return }

        // Reference to Firestore
        let db = Firestore.firestore()
        
        // Fetch the user's profile data from the "users" collection
        db.collection("users").document(userID).getDocument { (document, error) in
            if let error = error {
                self.showAlert(title: "Error", message: "Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            // Check if document exists
            if let document = document, document.exists {
                // Parse the data into the corresponding fields
                let data = document.data()
                self.profilename.text = data?["name"] as? String ?? "No Name"
                self.profileage.text = "\(data?["age"] as? Int ?? 0)"
                self.profilegender.text = data?["gender"] as? String ?? "No Gender"
                self.profileheight.text = "\(data?["height"] as? Double ?? 0.0)"
                self.profileweight.text = "\(data?["weight"] as? Double ?? 0.0)"
            } else {
                self.showAlert(title: "No Data", message: "No profile data found.")
            }
        }
    }
    
    func navigateToLogin() {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
               loginVC.modalPresentationStyle = .fullScreen
               self.present(loginVC, animated: true, completion: nil)
           }
       }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
