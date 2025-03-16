import UIKit
import FirebaseFirestore
import FirebaseAuth

// Model to store goal data
struct Goal {
    var type: String
    var target: Int
}

class GoalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var goalTypeButton: UIButton!
    @IBOutlet weak var targetField: UITextField!
    @IBOutlet weak var goalTable: UITableView!

    var goals: [Goal] = []  // Array to store goals
    var selectedGoalType: String = "Select Goal Type"
    var totalCalories: Int = 0
    var totalWater: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        goalTable.delegate = self
        goalTable.dataSource = self
        setupGoalMenu()
        fetchUserTotals() // Fetch initial data from Firestore
        fetchGoalsFromFirestore() // Fetch goals from Firestore
    }

    // Setup goal type menu for selection
    func setupGoalMenu() {
        let goalTypes = ["Steps to Take", "Calories to Burn", "Water to Drink"]

        let menuItems = goalTypes.map { type in
            UIAction(title: type, handler: { _ in
                self.selectedGoalType = type
                self.goalTypeButton.setTitle(type, for: .normal)
                self.goalTable.reloadData()  // Reload table when goal type changes
            })
        }

        let menu = UIMenu(title: "Select Goal Type", children: menuItems)
        goalTypeButton.menu = menu
        goalTypeButton.showsMenuAsPrimaryAction = true
    }

    @IBAction func saveGoal(_ sender: UIButton) {
        guard let targetText = targetField.text, let target = Int(targetText), target > 0 else {
            showAlert(title: "Invalid Input", message: "Please enter a valid goal target.")
            return
        }

        // Create new goal and append it to the goals array
        let newGoal = Goal(type: selectedGoalType, target: target)
        goals.append(newGoal)

        // Save new goal to Firestore
        saveGoalToFirestore(goal: newGoal)

        // Reload table and clear the input field
        goalTable.reloadData()
        targetField.text = ""  // Clear input field
    }

    // Fetch total calories & water from Firestore
    func fetchUserTotals() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user totals: \(error.localizedDescription)")
                return
            }

            if let data = document?.data() {
                self.totalCalories = data["totalCalories"] as? Int ?? 0
                self.totalWater = data["totalWater"] as? Int ?? 0
            }

            self.goalTable.reloadData()  // Reload table with updated values
        }
    }

    // Fetch goals from Firestore
    func fetchGoalsFromFirestore() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("goals").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching goals: \(error.localizedDescription)")
                return
            }

            self.goals.removeAll()  // Clear existing goals
            for document in snapshot!.documents {
                let data = document.data()
                if let type = data["type"] as? String,
                   let target = data["target"] as? Int {
                    let goal = Goal(type: type, target: target)
                    self.goals.append(goal)
                }
            }

            self.goalTable.reloadData()  // Reload table with fetched goals
        }
    }

    // Save the goal to Firestore
    func saveGoalToFirestore(goal: Goal) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User is not authenticated.")
            return
        }

        let db = Firestore.firestore()
        let goalRef = db.collection("users").document(user.uid).collection("goals").document()

        goalRef.setData([
            "type": goal.type,
            "target": goal.target
        ]) { error in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to save goal: \(error.localizedDescription)")
            } else {
                print("Goal saved successfully!")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GoalCell", for: indexPath) as? GoalTableViewCell else {
            return UITableViewCell()
        }

        let goal = goals[indexPath.row]

        let currentProgress: Int
        if goal.type == "Calories to Burn" {
            currentProgress = totalCalories  // Use the fetched totalCalories for progress
        } else if goal.type == "Water to Drink" {
            currentProgress = totalWater  // Use the fetched totalWater for progress
        } else {
            currentProgress = 0
        }

        // Configure the cell with the goal and current progress
        cell.configure(with: goal, currentProgress: currentProgress)

        return cell
    }

    // MARK: - Alert Method
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
