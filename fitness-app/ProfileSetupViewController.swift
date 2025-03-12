import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileSetupViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl! // IBOutlet for UISegmentedControl
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    
    // Store the selected gender
    var selectedGender = "Male"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the default selected gender (if needed)
        genderSegmentedControl.selectedSegmentIndex = 0 // Default to "Male"
    }

    @IBAction func genderChanged(_ sender: UISegmentedControl) {
        // Update the selectedGender based on the segment index
        switch sender.selectedSegmentIndex {
        case 0:
            selectedGender = "Male"
        case 1:
            selectedGender = "Female"
        default:
            break
        }
    }

    @IBAction func saveProfileTapped(_ sender: UIButton) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        guard let name = nameTextField.text, !name.isEmpty,
              let age = ageTextField.text, !age.isEmpty,
              let height = heightTextField.text, !height.isEmpty,
              let weight = weightTextField.text, !weight.isEmpty else {
            showAlert(title: "Missing Fields", message: "Please fill in all fields before proceeding.")
            return
        }

        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": name,
            "age": Int(age) ?? 0,
            "gender": selectedGender,
            "height": Double(height) ?? 0.0,
            "weight": Double(weight) ?? 0.0
        ]

        db.collection("users").document(userID).setData(userData) { error in
            if let error = error {
                self.showAlert(title: "Error Saving Data", message: error.localizedDescription)
            } else {
                self.navigateToProfileDisplay()
            }
        }
    }

    func navigateToProfileDisplay() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let profileDisplayVC = storyboard.instantiateViewController(withIdentifier: "ProfileDisplayViewController") as? ProfileDisplayViewController {
            profileDisplayVC.modalPresentationStyle = .fullScreen
            self.present(profileDisplayVC, animated: true, completion: nil)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
