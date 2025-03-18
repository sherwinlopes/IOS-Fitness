import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Goal {
    var type: String
    var target: Int
}

class GoalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var goalTypeButton: UIButton!
    @IBOutlet weak var targetField: UITextField!
    @IBOutlet weak var goalTable: UITableView!
    @IBOutlet weak var saveButton: UIButton!

    var goals: [Goal] = []
    var selectedGoalType = ""
    var totalCalories = 0
    var totalWater = 0
    var totalSteps = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        goalTable.delegate = self
        goalTable.dataSource = self
        setupGoalMenu()
        setupUI()
        fetchUserTotals()
        fetchGoalsFromFirestore()
    }

    func setupGoalMenu() {
        let goalTypes = ["Steps to Take", "Calories to Burn", "Water to Drink"]
        goalTypeButton.menu = UIMenu(title: "Select Goal Type", children:
            goalTypes.map { type in UIAction(title: type) { _ in
                self.selectedGoalType = type
                self.goalTypeButton.setTitle(type, for: .normal)
            }}
        )
        goalTypeButton.showsMenuAsPrimaryAction = true
    }

    func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        goalTypeButton.backgroundColor = UIColor.systemGreen
        goalTypeButton.setTitleColor(.white, for: .normal)
        goalTypeButton.layer.cornerRadius = 10
        goalTypeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        saveButton.backgroundColor = UIColor.systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        [targetField].forEach {
            $0?.backgroundColor = UIColor.systemGray6
            $0?.layer.cornerRadius = 8
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray4.cgColor
            $0?.clipsToBounds = true
        }
    }

    @IBAction func saveGoal(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser, let target = Int(targetField.text ?? ""), target > 0, !selectedGoalType.isEmpty else {
            return showAlert("Invalid Input", "Please enter a valid goal target and select a goal type.")
        }

        let newGoal = Goal(type: selectedGoalType, target: target)
        goals.append(newGoal)

        Firestore.firestore().collection("users").document(user.uid)
            .collection("goals").addDocument(data: [
                "type": selectedGoalType,
                "target": target,
                "timestamp": Timestamp(date: Date())
            ]) { error in
                error == nil ? self.goalTable.reloadData() : print("Error: \(error!.localizedDescription)")
            }
        targetField.text = ""
    }

    func fetchUserTotals() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let dateString = getCurrentDateString()

        db.collection("users").document(user.uid).collection("dailyTotals").document(dateString).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching daily totals: \(error.localizedDescription)")
                return
            }

            if let data = document?.data() {
                self.totalCalories = data["totalCalories"] as? Int ?? 0
                self.totalWater = data["totalWater"] as? Int ?? 0
                self.totalSteps = data["totalSteps"] as? Int ?? 0
            } else {
                print("No daily totals found for today's date.")
            }

            self.goalTable.reloadData()
        }
    }

    func fetchGoalsFromFirestore() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore().collection("users").document(user.uid).collection("goals").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching goals: \(error.localizedDescription)")
                return
            }
            
            self.goals.removeAll()
            snapshot?.documents.forEach { document in
                let data = document.data()
                if let type = data["type"] as? String, let target = data["target"] as? Int {
                    self.goals.append(Goal(type: type, target: target))
                }
            }
            self.goalTable.reloadData()
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
        
        switch goal.type {
        case "Calories to Burn":
            currentProgress = totalCalories
        case "Water to Drink":
            currentProgress = totalWater
        case "Steps to Take":
            currentProgress = totalSteps
        default:
            currentProgress = 0
        }
        
        cell.configure(with: goal, currentProgress: currentProgress)
        return cell
    }

    func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    @IBAction func backTapped(_ sender: Any) {
        if let homeDisplay = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") {
            homeDisplay.modalPresentationStyle = .fullScreen
            present(homeDisplay, animated: true)
        }
    }
    

    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
