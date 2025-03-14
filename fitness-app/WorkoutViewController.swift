import UIKit
import FirebaseFirestore
import FirebaseAuth

// Delegate protocol to send workout data back
protocol WorkoutViewControllerDelegate: AnyObject {
    func didLogWorkout(workoutType: String, duration: Int, calories: Int, water: Int)
}

class WorkoutViewController: UIViewController {

    @IBOutlet weak var workoutTypeButton: UIButton!
    @IBOutlet weak var durationField: UITextField!
    @IBOutlet weak var caloriesField: UITextField!
    @IBOutlet weak var waterField: UITextField!

    var selectedWorkoutType: String = ""
    weak var delegate: WorkoutViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWorkoutMenu()
    }

    // Setup workout type menu
    func setupWorkoutMenu() {
        let workoutTypes = ["Running", "Cycling", "Walking", "Swimming", "Workout"]
        
        let menuItems = workoutTypes.map { type in
            UIAction(title: type, handler: { _ in
                self.selectedWorkoutType = type
                self.workoutTypeButton.setTitle(type, for: .normal)
            })
        }
        
        let menu = UIMenu(title: "Select Workout", children: menuItems)
        workoutTypeButton.menu = menu
        workoutTypeButton.showsMenuAsPrimaryAction = true
    }

    // Log Workout and store in Firestore
    @IBAction func logWorkout(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User is not authenticated.")
            return
        }
        
        guard !selectedWorkoutType.isEmpty,
              let durationText = durationField.text, let duration = Int(durationText),
              let caloriesText = caloriesField.text, let calories = Int(caloriesText),
              let waterText = waterField.text, let water = Int(waterText) else {
            showAlert(title: "Invalid Input", message: "Please fill all fields correctly.")
            return
        }

        let db = Firestore.firestore()
        let workoutData: [String: Any] = [
            "workoutType": selectedWorkoutType,
            "duration": duration,
            "calories": calories,
            "water": water,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("users").document(user.uid).collection("workoutLogs").addDocument(data: workoutData) { error in
            if let error = error {
                print("Error saving workout log: \(error.localizedDescription)")
            } else {
                print("Workout log saved successfully!")
                self.navigateToHome()
            }
        }
      
    }
    
    func navigateToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
        }else {
            showAlert(title: "Error", message: "User is not authenticated.")
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
