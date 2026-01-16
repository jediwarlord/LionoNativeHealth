import SwiftUI
import HealthKit
import Charts

struct SourceAnalysisView: View {
    @ObservedObject var healthManager: HealthKitManager
    let workout: HKWorkout
    
    @State private var sourceData: [HealthKitManager.HeartRateSourceData] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Analyzing Heart Rate Sources...")
            } else if sourceData.isEmpty {
                ContentUnavailableView("No Heart Rate Data", systemImage: "heart.slash", description: Text("No heart rate samples were found for this workout."))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Summary Cards
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                SummaryCard(title: "Total Samples", value: "\(totalSamples)", icon: "waveform.path.ecg")
                                SummaryCard(title: "Sources", value: "\(sourceData.count)", icon: "applewatch.watchface")
                                SummaryCard(title: "Duration", value: formatDuration(workout.duration), icon: "timer")
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                        
                        // Charts
                        ForEach(sourceData) { source in
                            VStack(alignment: .leading) {
                                Text(source.displayName)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Chart(source.samples, id: \.uuid) { sample in
                                    LineMark(
                                        x: .value("Time", sample.startDate),
                                        y: .value("BPM", sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                                    )
                                    .foregroundStyle(.red)
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
            // Load data asynchronously
            healthManager.fetchHeartRateSamples(for: workout) { data in
                self.sourceData = data
                self.isLoading = false
            }
        }
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
