import UIKit

class GoalTableViewCell: UITableViewCell {

    @IBOutlet weak var goalTypeLabel: UILabel!
    @IBOutlet weak var goalTargetLabel: UILabel!
    @IBOutlet weak var goalProgress: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        goalProgress.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }

    func configure(with goal: Goal, currentProgress: Int) {
        goalTypeLabel.text = goal.type
        goalTargetLabel.text = "\(goal.target)"
        
        var progress: Float = 0.0
        
        switch goal.type {
        case "Calories to Burn":
            // Calculate progress for calories goal
            progress = Float(currentProgress) / Float(goal.target)
        case "Water to Drink":
            progress = Float(currentProgress) / Float(goal.target)
        case "Steps to Take":
            progress = Float(currentProgress) / Float(goal.target)
        default:
            progress = 0.0
        }
        
        goalProgress.progress = min(progress, 1.0)
        
        // Optional: Print the progress for debugging purposes
        print("Goal Type: \(goal.type)")
        print("Current Progress Value: \(currentProgress)")
        print("Max Progress Value: \(goal.target)")
        print("Progress Bar Value: \(goalProgress.progress * 100)%")
    }
}
