import UIKit
import DGCharts
import FirebaseFirestore
import FirebaseAuth

class ChartsViewController: UIViewController {
    
    @IBOutlet weak var caloriesChartView: LineChartView!
    @IBOutlet weak var waterChartView: LineChartView!
    
    var workoutLogs: [WorkoutLog] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChart(chartView: caloriesChartView, label: "Calories", color: .red)
        setupChart(chartView: waterChartView, label: "Water", color: .blue)
        
        fetchWorkoutLogs()
    }

    func setupChart(chartView: LineChartView, label: String, color: UIColor) {
        chartView.chartDescription.enabled = false
        chartView.legend.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.rightAxis.enabled = false
        chartView.leftAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        chartView.xAxis.granularity = 1
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

                for document in snapshot!.documents {
                    let data = document.data()
                    if let workoutType = data["workoutType"] as? String,
                       let duration = data["duration"] as? Int,
                       let calories = data["calories"] as? Int,
                       let water = data["water"] as? Int,
                       let timestamp = data["timestamp"] as? Timestamp {

                        let log = WorkoutLog(workoutType: workoutType, duration: duration, calories: calories, water: water, timestamp: timestamp)
                        self.workoutLogs.append(log)
                    }
                }

                // Update both charts
                self.updateChart(chartView: self.caloriesChartView, dataType: "calories", color: .red)
                self.updateChart(chartView: self.waterChartView, dataType: "water", color: .blue)
            }
    }

    func updateChart(chartView: LineChartView, dataType: String, color: UIColor) {
        var dataEntries: [ChartDataEntry] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayLogs = workoutLogs.filter { log in
                let logDate = log.timestamp.dateValue()
                return logDate >= dayStart && logDate < dayEnd
            }

            var dailyValue = 0
            for log in dayLogs {
                dailyValue += (dataType == "calories") ? log.calories : log.water
            }

            let dayIndex = Double(i)
            dataEntries.append(ChartDataEntry(x: dayIndex, y: Double(dailyValue)))
        }

        let dataSet = LineChartDataSet(entries: dataEntries, label: dataType.capitalized)
        dataSet.colors = [UIColor.black]
        dataSet.circleColors = [UIColor.black]
        dataSet.circleRadius = 6
        dataSet.drawCirclesEnabled = true
        dataSet.valueFont = .boldSystemFont(ofSize: 14)
        dataSet.lineDashLengths = [5, 5]
        dataSet.drawFilledEnabled = true

        let gradientColors = [color.cgColor, UIColor.clear.cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors, locations: [0.5, 1.0])!
        dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90)

        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
