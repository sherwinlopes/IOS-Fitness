import UIKit
import FirebaseFirestore
import FirebaseAuth
import HealthKit

struct WorkoutLog {
    var workoutType: String
    var duration: Int
    var calories: Int
    var water: Int
    var timestamp: Timestamp
}

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WorkoutViewControllerDelegate {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var waterLabel: UILabel!
    @IBOutlet weak var goalName: UILabel!
    @IBOutlet weak var goalTargetValue: UILabel!
    @IBOutlet weak var goalProgress: UIProgressView!
    
    let healthStore = HKHealthStore()

    var totalCalories: Int = 0
    var totalWater: Int = 0
    var workoutLogs: [WorkoutLog] = []
    var goals: [Goal] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        fetchWorkoutLogs()
        fetchGoalsFromFirestore()
        fetchUserProfile()
        requestHealthKitAuthorization()

        // Increase the height of progress bar (UIProgressView)
        goalProgress.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }

    func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User is not authenticated.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let error = error {
                self.showAlert(title: "Error", message: "Error fetching user data: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                self.username.text = data?["name"] as? String ?? "No Name"
            } else {
                self.showAlert(title: "Error", message: "User data not found.")
            }
        }
    }

    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available on this device.")
            return
        }

        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let dataTypesToRead: Set<HKObjectType> = [stepCountType]

        healthStore.requestAuthorization(toShare: nil, read: dataTypesToRead) { success, error in
            if let error = error {
                print("Error requesting authorization: \(error.localizedDescription)")
            }
            if success {
                print("HealthKit authorization successful.")
                self.fetchStepsData()  // Fetch steps data after getting permission
            }
        }
    }

    func fetchStepsData() {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            DispatchQueue.main.async {
                self.stepsLabel.text = "0 steps"  // Display 0 steps if HealthKit is unavailable
            }
            return
        }

        // Define the step count type
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        // Get the current date and the start of today
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        // Create a predicate for the date range (start of the day to now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictEndDate)

        // Create a query to get the cumulative sum of steps
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, statistics, error in
            guard let statistics = statistics, error == nil else {
                // If there's an error, print the error and set steps to 0
                print("Error fetching steps data: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.stepsLabel.text = "0 steps"  // Set to zero if there is an error
                }
                return
            }

            // Get the total number of steps from the query
            let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0

            // Update the stepsLabel on the main thread
            DispatchQueue.main.async {
                self.stepsLabel.text = "\(Int(steps)) steps"
            }
        }

        // Execute the query
        healthStore.execute(query)
    }


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
                       let water = data["water"] as? Int,
                       let timestamp = data["timestamp"] as? Timestamp {

                        let log = WorkoutLog(workoutType: workoutType, duration: duration, calories: calories, water: water, timestamp: timestamp)
                        self.workoutLogs.append(log)

                        self.totalCalories += calories
                        self.totalWater += water
                    }
                }

                self.caloriesLabel.text = "\(self.totalCalories) kcal"
                self.waterLabel.text = "\(self.totalWater) ml"
                self.updateTotalStatsInFirestore()
                self.tableView.reloadData()

                self.updateGoalProgress()
            }
    }

    func fetchGoalsFromFirestore() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("goals").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching goals: \(error.localizedDescription)")
                return
            }

            self.goals.removeAll()

            for document in snapshot!.documents {
                let data = document.data()
                if let type = data["type"] as? String,
                   let target = data["target"] as? Int {
                    let goal = Goal(type: type, target: target)
                    self.goals.append(goal)
                }
            }

            self.updateGoalProgress()
        }
    }

    func updateGoalProgress() {
        var mostProgressedGoal: Goal?
        var highestProgress: Float = 0

        for goal in goals {
            let progress: Float
            if goal.type == "Calories" {
                progress = Float(totalCalories) / Float(goal.target)
            } else if goal.type == "Water" {
                progress = Float(totalWater) / Float(goal.target)
            } else {
                continue
            }

            if progress > highestProgress {
                highestProgress = progress
                mostProgressedGoal = goal
            }
        }

        if let goal = mostProgressedGoal {
            goalName.text = "Goal: \(goal.type)"
            goalTargetValue.text = "Target: \(goal.target)"
            goalProgress.progress = min(highestProgress, 1.0)
        }
    }

    func updateTotalStatsInFirestore() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).updateData([
            "totalCalories": totalCalories,
            "totalWater": totalWater
        ]) { error in
            if let error = error {
                print("Error updating total stats: \(error.localizedDescription)")
            } else {
                print("Total calories & water updated successfully!")
            }
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

    // Action method to navigate to Goals screen
    @IBAction func goalsWorkoutTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let goalVC = storyboard.instantiateViewController(withIdentifier: "GoalViewController") as? GoalViewController {
            present(goalVC, animated: true, completion: nil)
        }
    }

    @IBAction func progressTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let chartVC = storyboard.instantiateViewController(withIdentifier: "ChartsViewController") as? ChartsViewController {
            present(chartVC, animated: true, completion: nil)
        }
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
