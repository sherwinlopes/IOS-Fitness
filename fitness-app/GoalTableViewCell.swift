import UIKit

class GoalTableViewCell: UITableViewCell {

    @IBOutlet weak var goalTypeLabel: UILabel!
    @IBOutlet weak var goalTargetLabel: UILabel!
    @IBOutlet weak var goalProgress: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        goalProgress.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }

    func configure(with goal: Goal, currentProgress: Int) {
        goalTypeLabel.text = goal.type
        goalTargetLabel.text = "\(goal.target)"
        
        var progress: Float = 0.0
        
        // Calculate the progress for "Calories to Burn" and "Water to Drink"
        if goal.type == "Calories to Burn" {
            // Ensure that the totalCalories is used for progress calculation
            progress = Float(currentProgress) / Float(goal.target)
        } else if goal.type == "Water to Drink" {
            // Use the totalWater for water progress
            progress = Float(currentProgress) / Float(goal.target)
        }

        // Set the progress value to the progress bar, ensuring it doesn't exceed 1.0
        goalProgress.progress = min(progress, 1.0)
        
        // Optional: Print the progress for debugging purposes
        print("Goal Type: \(goal.type)")
        print("Current Progress Value: \(currentProgress)")
        print("Max Progress Value: \(goal.target)")
        print("Progress Bar Value: \(goalProgress.progress * 100)%")
    }
}
