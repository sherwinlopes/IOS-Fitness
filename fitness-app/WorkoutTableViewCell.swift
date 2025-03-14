import UIKit

class WorkoutTableViewCell: UITableViewCell {
    
    @IBOutlet weak var workoutTypeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var waterLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with workoutLog: WorkoutLog) {
        workoutTypeLabel.text = workoutLog.workoutType
        durationLabel.text = formatDuration(workoutLog.duration)
        caloriesLabel.text = "\(workoutLog.calories) kcal"
        waterLabel.text = "\(workoutLog.water) ml"
    }

    // Helper function to format duration
    private func formatDuration(_ duration: Int) -> String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}
