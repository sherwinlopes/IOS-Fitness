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

    @IBOutlet weak var stepsView: UIView!
    @IBOutlet weak var caloriesView: UIView!
    @IBOutlet weak var waterView: UIView!
    @IBOutlet weak var goalView: UIView!
    @IBOutlet weak var activitiesView: UIView!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var waterLabel: UILabel!
    @IBOutlet weak var goalName: UILabel!
    @IBOutlet weak var goalTargetValue: UILabel!
    @IBOutlet weak var goalProgress: UIProgressView!
    
    @IBOutlet weak var goalsButton: UIButton!
    @IBOutlet weak var logButton: UIButton!
    @IBOutlet weak var progressButton: UIButton!
    
    let healthStore = HKHealthStore()

    var totalCalories: Int = 0
    var totalWater: Int = 0
    var totalSteps: Int = 0
    var workoutLogs: [WorkoutLog] = []
    var goals: [Goal] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        applyGradient(to: stepsView, colors: [UIColor.green.withAlphaComponent(0.5), UIColor.green])
        applyGradient(to: caloriesView, colors: [UIColor.systemRed, UIColor.orange])
        applyGradient(to: waterView, colors: [UIColor.systemTeal, UIColor.blue.withAlphaComponent(0.7)])
        
        let goldColor = UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0)  // Custom gold color
        applyGradient(to: goalView, colors: [goldColor.withAlphaComponent(0.8), UIColor.yellow])

        applyGradient(to: activitiesView, colors: [UIColor.purple.withAlphaComponent(0.5), UIColor.systemBlue.withAlphaComponent(0.3)])
        
        applyGradient(to: tableView, colors: [UIColor.purple.withAlphaComponent(0.5), UIColor.systemBlue.withAlphaComponent(0.3)])

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let progressImage = UIImage(systemName: "chart.line.uptrend.xyaxis", withConfiguration: symbolConfig)

        progressButton.setImage(progressImage, for: .normal)
        progressButton.setTitle(" Progress", for: .normal) // Space before text for spacing
        progressButton.tintColor = .green  // Ensure symbol color matches text
        progressButton.setTitleColor(.green, for: .normal)

        // Adjust spacing between icon and text
        progressButton.semanticContentAttribute = .forceLeftToRight
        progressButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        
        fetchWorkoutLogs()
        fetchGoalsFromFirestore()
        fetchUserProfile()
        requestHealthKitAuthorization()
        fetchDailyTotals()  // Fetch daily totals

        // Increase the height of progress bar (UIProgressView)
        goalProgress.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        // Add gesture recognizer to the profile image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }
    

    @objc func profileImageTapped() {
        // Navigate to the ProfileDisplayViewController
        navigateToProfileDisplay()
    }
    
    func applyGradient(to view: UIView, colors: [UIColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5) // Left to right gradient
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.cornerRadius = view.layer.cornerRadius
        view.layer.insertSublayer(gradientLayer, at: 0)
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
            
            // Check if the document exists
            if let document = document, document.exists {
                let data = document.data()
                
                // Set the image based on gender
                if let gender = data?["gender"] as? String {
                    if gender == "Male" {
                        self.profileImageView.image = UIImage(named: "male.png")
                    } else if gender == "Female" {
                        self.profileImageView.image = UIImage(named: "female.png")
                    } else {
                        self.profileImageView.image = UIImage(named: "default.png") // Use a default image if gender is not recognized
                    }
                }
                
                // Set other profile information
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
        #if targetEnvironment(simulator)
        // If running on a simulator, set default steps to 1200
        DispatchQueue.main.async {
            self.totalSteps = 1200
            self.stepsLabel.text = "\(self.totalSteps) steps"
        }
        #else
        // If running on a physical device, check for HealthKit availability
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.totalSteps = 0  // Set steps to 0 if HealthKit is unavailable
                self.stepsLabel.text = "0 steps"
            }
            return
        }

        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictEndDate)

        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
            guard let statistics = statistics, error == nil else {
                DispatchQueue.main.async {
                    self.totalSteps = 0
                    self.stepsLabel.text = "0 steps"
                }
                return
            }

            let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                self.totalSteps = Int(steps)
                self.stepsLabel.text = "\(self.totalSteps) steps"
            }
        }

        healthStore.execute(query)
        #endif
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

    func fetchDailyTotals() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User is not authenticated.")
            return
        }

        // Format current date as "yyyy-MM-dd" to get today's data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("dailyTotals").document(dateString).getDocument { (document, error) in
            if let error = error {
                print("Error fetching daily totals: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                
                self.totalCalories = data?["totalCalories"] as? Int ?? 0
                self.totalWater = data?["totalWater"] as? Int ?? 0
                self.totalSteps = data?["totalSteps"] as? Int ?? 0

                self.caloriesLabel.text = "\(self.totalCalories) kcal"
                self.waterLabel.text = "\(self.totalWater) ml"
                self.stepsLabel.text = "\(self.totalSteps) steps"
                
                self.updateGoalProgress()
            } else {
                // Handle case where data is not found
                print("No daily totals found for today.")
                self.caloriesLabel.text = "0 kcal"
                self.waterLabel.text = "0 ml"
            }
        }
    }

    func updateGoalProgress() {
        var filteredGoals: [(goal: Goal, progress: Float)] = []

        for goal in goals {
            let progress: Float
            if goal.type == "Calories to Burn" {
                progress = Float(totalCalories) / Float(goal.target)
            } else if goal.type == "Water to Drink" {
                progress = Float(totalWater) / Float(goal.target)
            } else if goal.type == "Steps to Take" {
                progress = Float(totalSteps) / Float(goal.target)
            } else {
                continue
            }

            if progress < 1.0 {
                filteredGoals.append((goal, progress))
            }
        }

        filteredGoals.sort { $0.progress > $1.progress }

        if let firstGoal = filteredGoals.first {
            goalName.text = firstGoal.goal.type
            goalTargetValue.text = "\(firstGoal.goal.target)"
            goalProgress.progress = firstGoal.progress
        } else {
            goalName.text = "No Active Goals"
            goalTargetValue.text = ""
            goalProgress.progress = 0
        }

        tableView.reloadData()
    }


    func updateTotalStatsInFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let timestamp = Timestamp(date: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: timestamp.dateValue())

        db.collection("users").document(user.uid).collection("dailyTotals").document(dateString).setData([
            "totalCalories": totalCalories,
            "totalWater": totalWater,
            "totalSteps": totalSteps,
            "timestamp": timestamp
        ], merge: true) { error in
            if let error = error {
                print("Error updating daily totals: \(error.localizedDescription)")
            } else {
                print("Daily totals updated successfully!")
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
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true
            return cell
        }
        return UITableViewCell()
    }

    func didLogWorkout(workoutType: String, duration: Int, calories: Int, water: Int) {
        fetchWorkoutLogs()
    }

    func navigateToProfileDisplay() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileDisplayViewController") as? ProfileDisplayViewController {
            self.present(profileVC, animated: true, completion: nil)
        }
    }

    @IBAction func goalsWorkoutTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let goalVC = storyboard.instantiateViewController(withIdentifier: "GoalViewController") as? GoalViewController {
            goalVC.modalPresentationStyle = .fullScreen  // Set the presentation style to full screen
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
            workoutVC.modalPresentationStyle = .fullScreen  // Set the presentation style to full screen
            present(workoutVC, animated: true, completion: nil)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension Date {
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}
