import UIKit
import FirebaseFirestore
import FirebaseAuth

struct WorkoutLog {
    var workoutType: String
    var duration: Int
    var calories: Int
    var water: Int
}

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WorkoutViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var waterLabel: UILabel!

    var totalCalories: Int = 0
    var totalWater: Int = 0
    var workoutLogs: [WorkoutLog] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        fetchWorkoutLogs()
    }

    // Fetch workouts from Firestore for the authenticated user
    func fetchWorkoutLogs() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User is not authenticated.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("workoutLogs")
            .order(by: "timestamp", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching workouts: \(error.localizedDescription)")
                    return
                }

                self.workoutLogs.removeAll()
                self.totalCalories = 0
                self.totalWater = 0

                for document in snapshot!.documents {
                    let data = document.data()
                    if let workoutType = data["workoutType"] as? String,
                       let duration = data["duration"] as? Int,
                       let calories = data["calories"] as? Int,
                       let water = data["water"] as? Int {
                        
                        let log = WorkoutLog(workoutType: workoutType, duration: duration, calories: calories, water: water)
                        self.workoutLogs.append(log)
                        
                        self.totalCalories += calories
                        self.totalWater += water
                    }
                }

                self.caloriesLabel.text = "\(self.totalCalories) kcal"
                self.waterLabel.text = "\(self.totalWater) ml"
                self.tableView.reloadData()
            }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutLogs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as? WorkoutTableViewCell {
            let workoutLog = workoutLogs[indexPath.row]
            cell.configure(with: workoutLog)
            return cell
        }
        return UITableViewCell()
    }

    func didLogWorkout(workoutType: String, duration: Int, calories: Int, water: Int) {
        fetchWorkoutLogs()
    }

    @IBAction func logWorkoutTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let workoutVC = storyboard.instantiateViewController(withIdentifier: "WorkoutViewController") as? WorkoutViewController {
            workoutVC.delegate = self
            present(workoutVC, animated: true, completion: nil)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
