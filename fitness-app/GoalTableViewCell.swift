import UIKit

class GoalTableViewCell: UITableViewCell {

    @IBOutlet weak var goalTypeLabel: UILabel!
    @IBOutlet weak var goalTargetLabel: UILabel!
    @IBOutlet weak var goalProgress: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // Configure the cell with goal data and current progress
    func configure(with goal: Goal, currentProgress: Int) {
        goalTypeLabel.text = goal.type
        goalTargetLabel.text = "Target: \(goal.target)"
        
        // Calculate the progress as a float (currentProgress/target)
        let progress = Float(currentProgress) / Float(goal.target)
        goalProgress.progress = min(progress, 1.0) // Ensure progress doesn't exceed 1.0

        // ✅ Print current progress and target values to console
        print("Goal Type: \(goal.type)")
        print("Current Progress Value: \(currentProgress)")
        print("Max Progress Value: \(goal.target)")
        print("Progress Bar Value: \(goalProgress.progress * 100)%")
    }
}
