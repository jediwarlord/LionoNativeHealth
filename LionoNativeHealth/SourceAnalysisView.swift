import SwiftUI
import HealthKit
import Charts

struct SourceAnalysisView: View {
    @ObservedObject var healthManager: HealthKitManager
    let workout: HKWorkout
    var garminActivity: GarminActivity? // Optional matched activity
    
    @State private var garminManager = GarminManager()
    @State private var unifiedChartData: [ChartDataSeries] = []
    @State private var sourceData: [HealthKitManager.HeartRateSourceData] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Analyzing Heart Rate Sources...")
            } else if sourceData.isEmpty && garminActivity == nil {
                ContentUnavailableView("No Heart Rate Data", systemImage: "heart.slash", description: Text("No heart rate samples were found for this workout."))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Summary Cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                SummaryCard(title: "Total Samples", value: "\(totalSamples)", icon: "waveform.path.ecg")
                                SummaryCard(title: "Sources", value: "\(sourceData.count + (garminActivity != nil ? 1 : 0))", icon: "applewatch.watchface")
                                SummaryCard(title: "Duration", value: formatDuration(workout.duration), icon: "timer")
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                        
                        // Main Unified Chart
                        Text("Heart Rate Comparison")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(unifiedChartData) { series in
                                ForEach(series.points) { point in
                                    LineMark(
                                        x: .value("Time", point.date),
                                        y: .value("BPM", point.val)
                                    )
                                    .foregroundStyle(by: .value("Source", series.name))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 250)
                        .padding(.horizontal)
                        
                        Divider()

                        // Individual Source Breakdowns (HealthKit)
                        ForEach(sourceData) { source in
                            VStack(alignment: .leading) {
                                Text("Local: \(source.displayName)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Chart(source.samples, id: \.uuid) { sample in
                                    LineMark(
                                        x: .value("Time", sample.startDate),
                                        y: .value("BPM", sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                                    )
                                    .foregroundStyle(.blue)
                                    .interpolationMethod(.catmullRom)
                                }
                                .chartYScale(domain: .automatic(includesZero: false))
                                .frame(height: 150)
                                .padding(.horizontal)
                                
                                Text("\(source.count) samples")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                            }
                            .padding(.bottom)
                        }
                    }
                }
            }
        }
        .navigationTitle("Source Analysis")
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        
        // 1. Fetch Local Data
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            healthManager.fetchHeartRateSamples(for: workout) { data in
                self.sourceData = data
                continuation.resume()
            }
        }
        
        var allSeries: [ChartDataSeries] = []
        
        // Convert Local Data to Unified Series
        for source in sourceData {
            let points = source.samples.map { sample in
                ChartPoint(date: sample.startDate, val: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            allSeries.append(ChartDataSeries(name: "LO: \(source.displayName)", points: points, color: "blue"))
        }
        
        // 2. Fetch Garmin Data if available
        if let gActivity = garminActivity {
            do {
                let details = try await garminManager.getActivityDetails(id: gActivity.activityId)
                let gPoints = details.records.map { record in
                    ChartPoint(date: record.date, val: Double(record.hr))
                }
                allSeries.append(ChartDataSeries(name: "Garmin Connect", points: gPoints, color: "red"))
            } catch {
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    // Task cancelled, ignore
                } else {
                    print("Failed to load Garmin details: \(error)")
                }
            }
        }
        
        self.unifiedChartData = allSeries
        isLoading = false
    }
    
    var totalSamples: Int {
        sourceData.reduce(0) { $0 + $1.count }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .bold()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
