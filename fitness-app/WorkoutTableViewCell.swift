import UIKit

class WorkoutTableViewCell: UITableViewCell {
    
    @IBOutlet weak var workoutTypeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var waterLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // Method to configure the cell with workout data
    func configure(with workoutLog: WorkoutLog) {
        workoutTypeLabel.text = workoutLog.workoutType
        durationLabel.text = "\(workoutLog.duration) min"
        caloriesLabel.text = "\(workoutLog.calories) kcal"
        waterLabel.text = "\(workoutLog.water) ml"
    }
}
