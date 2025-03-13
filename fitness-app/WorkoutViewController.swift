import UIKit

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
    weak var delegate: WorkoutViewControllerDelegate? // Delegate property
    
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

    // Handle logging the workout
    @IBAction func logWorkout(_ sender: UIButton) {
        // Directly check if the workoutType is empty
        guard !selectedWorkoutType.isEmpty,
              let durationText = durationField.text, let duration = Int(durationText),
              let caloriesText = caloriesField.text, let calories = Int(caloriesText),
              let waterText = waterField.text, let water = Int(waterText) else {
            // Handle invalid input
            let alert = UIAlertController(title: "Invalid Input", message: "Please fill all fields correctly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Send data back to HomeViewController via the delegate
        delegate?.didLogWorkout(workoutType: selectedWorkoutType, duration: duration, calories: calories, water: water)
        
        // Dismiss the current view
        dismiss(animated: true, completion: nil)
    }
}
