import UIKit

// Define a struct to represent the workout log data
struct WorkoutLog {
    var workoutType: String
    var duration: Int // Duration in minutes
    var calories: Int
    var water: Int // Water intake in ml
}

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WorkoutViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView! // Reference to the table view
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var waterLabel: UILabel!

    var totalCalories: Int = 0
    var totalWater: Int = 0
    var workoutLogs: [WorkoutLog] = [] // Array to store workout logs

    override func viewDidLoad() {
        super.viewDidLoad()
        stepsLabel.text = "0"
        caloriesLabel.text = "0 kcal"
        waterLabel.text = "0 ml"

        // Set the table view's data source and delegate
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - UITableView DataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutLogs.count // Return the number of logs
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue the reusable cell using the correct identifier
        if let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as? WorkoutTableViewCell {
            
            // Get the workout log for the current index path
            let workoutLog = workoutLogs[indexPath.row]
            
            // Configure the cell with workout data
            cell.configure(with: workoutLog)
            
            return cell
        }
        
        // Fallback if the cell can't be dequeued (shouldn't happen if everything is set up correctly)
        return UITableViewCell()
    }

    // MARK: - WorkoutViewControllerDelegate Method

    func didLogWorkout(workoutType: String, duration: Int, calories: Int, water: Int) {
        // Create a new WorkoutLog and append it to the array
        let newLog = WorkoutLog(workoutType: workoutType, duration: duration, calories: calories, water: water)
        workoutLogs.append(newLog)

        // Update total calories and water
        totalCalories += calories
        totalWater += water

        // Update UI labels
        caloriesLabel.text = "\(totalCalories) kcal"
        waterLabel.text = "\(totalWater) ml"

        // Reload the table view to display the new log
        tableView.reloadData()
    }

    @IBAction func logWorkoutTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate WorkoutViewController from the storyboard
        if let workoutVC = storyboard.instantiateViewController(withIdentifier: "WorkoutViewController") as? WorkoutViewController {
            workoutVC.delegate = self // Assign the delegate
            present(workoutVC, animated: true, completion: nil)
        }
    }
}
