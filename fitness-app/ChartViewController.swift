import UIKit
import DGCharts
import FirebaseFirestore
import FirebaseAuth

class ChartsViewController: UIViewController {

    @IBOutlet weak var caloriesChartView: LineChartView!
    @IBOutlet weak var waterChartView: LineChartView!
    @IBOutlet weak var stepsChartView: LineChartView!

    var dailyCalories: [Int] = Array(repeating: 0, count: 7)
    var dailyWater: [Int] = Array(repeating: 0, count: 7)
    var dailySteps: [Int] = Array(repeating: 0, count: 7)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Bright Red, Green, Blue colors for the charts
        setupChart(chartView: caloriesChartView, label: "Calories", color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)) // Bright Red
        setupChart(chartView: waterChartView, label: "Water", color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1)) // Bright Blue
        setupChart(chartView: stepsChartView, label: "Steps", color: UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)) // Bright Green

        fetchUserTotals()
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

    func fetchUserTotals() {
        guard let user = Auth.auth().currentUser else {
            generateFakeData()
            return
        }

        let db = Firestore.firestore()
        let calendar = Calendar.current
        let today = Date()

        // Get data for the last 7 days
        var dateRange: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dateRange.append(date)
            }
        }

        // Fetch daily totals for each day in the last week
        let dispatchGroup = DispatchGroup()

        for (index, date) in dateRange.enumerated() {
            dispatchGroup.enter()
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            db.collection("users")
                .document(user.uid)
                .collection("dailyTotals")
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("timestamp", isLessThan: Timestamp(date: endOfDay))
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error fetching daily totals: \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }

                    var totalCaloriesForDay = 0
                    var totalWaterForDay = 0
                    var totalStepsForDay = 0

                    for document in snapshot!.documents {
                        let data = document.data()
                        totalCaloriesForDay += data["totalCalories"] as? Int ?? 0
                        totalWaterForDay += data["totalWater"] as? Int ?? 0
                        totalStepsForDay += data["totalSteps"] as? Int ?? 0
                    }

                    self.dailyCalories[index] = totalCaloriesForDay
                    self.dailyWater[index] = totalWaterForDay
                    self.dailySteps[index] = totalStepsForDay

                    dispatchGroup.leave()
                }
        }

        dispatchGroup.notify(queue: .main) {
            self.updateChart(chartView: self.caloriesChartView, data: self.dailyCalories, color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)) // Bright Red
            self.updateChart(chartView: self.waterChartView, data: self.dailyWater, color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1)) // Bright Blue
            self.updateChart(chartView: self.stepsChartView, data: self.dailySteps, color: UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)) // Bright Green
        }
    }

    func generateFakeData() {
        for i in 0..<7 {
            self.dailyCalories[i] = Int.random(in: 1500...3000)
            self.dailyWater[i] = Int.random(in: 1500...4000)
            self.dailySteps[i] = Int.random(in: 5000...20000)
        }

        self.updateChart(chartView: self.caloriesChartView, data: self.dailyCalories, color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)) // Bright Red
        self.updateChart(chartView: self.waterChartView, data: self.dailyWater, color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1)) // Bright Blue
        self.updateChart(chartView: self.stepsChartView, data: self.dailySteps, color: UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)) // Bright Green
    }

    func updateChart(chartView: LineChartView, data: [Int], color: UIColor) {
        var dataEntries: [ChartDataEntry] = []

        for (index, value) in data.enumerated() {
            dataEntries.append(ChartDataEntry(x: Double(index), y: Double(value)))
        }

        let dataSet = LineChartDataSet(entries: dataEntries, label: "Total")
        dataSet.colors = [color]
        dataSet.circleColors = [color]
        dataSet.circleRadius = 2
        dataSet.drawCirclesEnabled = true
        dataSet.valueFont = .boldSystemFont(ofSize: 14)
        dataSet.lineDashLengths = [] // Remove the dotted line (make it solid)
        dataSet.drawFilledEnabled = true

        // Create the gradient fade effect (from transparent to solid color, bottom to top)
        let gradientColors = [UIColor.clear.cgColor, color.cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors, locations: [0.0, 0.6])!
        dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90) // Reverse gradient (bottom to top)

        // Set data to the chart
        let chartData = LineChartData(dataSet: dataSet)
        chartView.data = chartData
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
