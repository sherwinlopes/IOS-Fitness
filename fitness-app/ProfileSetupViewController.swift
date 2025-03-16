import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileSetupViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var selectedGender = "Male"

    override func viewDidLoad() {
        super.viewDidLoad()
        genderSegmentedControl.selectedSegmentIndex = 0
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        [nameTextField, ageTextField, heightTextField, weightTextField].forEach {
            $0?.backgroundColor = UIColor.systemGray6
            $0?.layer.cornerRadius = 8
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray4.cgColor
            $0?.clipsToBounds = true
        }
    }

    @IBAction func genderChanged(_ sender: UISegmentedControl) {
        selectedGender = sender.selectedSegmentIndex == 0 ? "Male" : "Female"
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

        let userData: [String: Any] = [
            "name": name,
            "age": Int(age) ?? 0,
            "gender": selectedGender,
            "height": Double(height) ?? 0.0,
            "weight": Double(weight) ?? 0.0
        ]

        Firestore.firestore().collection("users").document(userID).setData(userData) { error in
            if let error = error {
                self.showAlert(title: "Error Saving Data", message: error.localizedDescription)
            } else {
                self.navigateToProfileDisplay()
            }
        }
    }

    func navigateToProfileDisplay() {
        if let profileDisplayVC = storyboard?.instantiateViewController(withIdentifier: "ProfileDisplayViewController") {
            profileDisplayVC.modalPresentationStyle = .fullScreen
            present(profileDisplayVC, animated: true)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
