import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol WorkoutViewControllerDelegate: AnyObject {
    func didLogWorkout(workoutType: String, duration: Int, calories: Int, water: Int)
}

class WorkoutViewController: UIViewController {
    @IBOutlet weak var workoutTypeButton: UIButton!
    @IBOutlet weak var durationField: UITextField!
    @IBOutlet weak var caloriesField: UITextField!
    @IBOutlet weak var waterField: UITextField!
    @IBOutlet weak var additionalField: UITextView!
    @IBOutlet weak var saveButton: UIButton!

    var selectedWorkoutType = ""
    weak var delegate: WorkoutViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWorkoutMenu()
        setupUI()
    }

    func setupWorkoutMenu() {
        let workoutTypes = ["Walking", "Cycling", "Running", "Swimming", "Workout"]
        workoutTypeButton.menu = UIMenu(title: "Select Workout", children:
            workoutTypes.map { type in UIAction(title: type) { _ in
                self.selectedWorkoutType = type
                self.workoutTypeButton.setTitle(type, for: .normal)
            }}
        )
        workoutTypeButton.showsMenuAsPrimaryAction = true
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        workoutTypeButton.backgroundColor = UIColor.orange
        workoutTypeButton.setTitleColor(.white, for: .normal)
        workoutTypeButton.layer.cornerRadius = 10
        workoutTypeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        saveButton.backgroundColor = UIColor.systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        [durationField, caloriesField, waterField, additionalField].forEach {
            $0?.backgroundColor = UIColor.systemGray6
            $0?.layer.cornerRadius = 8
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray4.cgColor
            $0?.clipsToBounds = true
        }
    }

    @IBAction func logWorkout(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser, let duration = Int(durationField.text ?? ""),
              let calories = Int(caloriesField.text ?? ""), let water = Int(waterField.text ?? ""),
              !selectedWorkoutType.isEmpty else {
            return showAlert("Invalid Input", "Please fill all fields correctly.")
        }
        
        Firestore.firestore().collection("users").document(user.uid)
            .collection("workoutLogs").addDocument(data: [
                "workoutType": selectedWorkoutType,
                "duration": duration,
                "calories": calories,
                "water": water,
                "timestamp": Timestamp(date: Date())
            ]) { error in
                error == nil ? self.navigateToHome() : print("Error: \(error!.localizedDescription)")
            }
    }
    
    func navigateToHome() {
        if let homeVC = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") {
            homeVC.modalPresentationStyle = .fullScreen
            present(homeVC, animated: true)
        }
    }
    
    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
