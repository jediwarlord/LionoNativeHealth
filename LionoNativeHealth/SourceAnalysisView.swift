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
                        
                        // Summary Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Summary")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Samples")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(totalSamples)")
                                        .font(.title2)
                                        .bold()
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Sources")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(sourceData.count)")
                                        .font(.title2)
                                        .bold()
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Divider()
                        
                        // comparison chart
                        Text("Heart Rate Comparison")
                            .font(.title2)
                            .bold()
                        
                        Chart {
                            ForEach(sourceData) { source in
                                ForEach(source.samples, id: \.uuid) { sample in
                                    LineMark(
                                        x: .value("Time", sample.startDate),
                                        y: .value("BPM", sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                                    )
                                    .foregroundStyle(by: .value("Source", source.displayName))
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false)) // Don't start at 0 for HR
                        .frame(height: 250)
                        
                        Divider()
                        
                        Text("Device Breakdown")
                            .font(.title2)
                            .bold()
                        
                        Chart(sourceData) { data in
                            BarMark(
                                x: .value("Count", data.count),
                                y: .value("Source", data.displayName)
                            )
                            .foregroundStyle(by: .value("Source", data.displayName))
                            .annotation(position: .trailing) {
                                Text("\(data.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 200)
                        
                        Divider()
                        
                        Text("Detailed Source List")
                            .font(.title2)
                            .bold()
                        
                        ForEach(sourceData) { data in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(data.displayName)
                                        .font(.headline)
                                    
                                    if data.sourceName != data.displayName {
                                        Text("Source: \(data.sourceName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let manufacturer = data.manufacturer {
                                        Text("Manufacturer: \(manufacturer)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("\(data.count) samples")
                                        .font(.subheadline)
                                        .bold()
                                        .padding(.top, 2)
                                }
                                Spacer()
                                Image(systemName: "sensor.tag.radiowaves.forward")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Source Analysis")
        .task {
            healthManager.fetchHeartRateSamples(for: workout) { data in
                self.sourceData = data
                self.isLoading = false
            }
        }
    }
    
    var totalSamples: Int {
        sourceData.reduce(0) { $0 + $1.count }
    }
}
