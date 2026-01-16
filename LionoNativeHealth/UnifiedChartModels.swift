import Foundation

struct ChartDataSeries: Identifiable {
    let id = UUID()
    let name: String
    let points: [ChartPoint]
    let color: String // Optional color override
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let val: Double
}
