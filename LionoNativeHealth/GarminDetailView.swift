
import SwiftUI
import Charts

struct GarminDetailView: View {
    let activity: GarminActivity
    @StateObject private var manager = GarminManager() // Using a new instance or could be environment
    @State private var details: GarminActivityDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Stats
                VStack(alignment: .leading) {
                    Text(activity.startTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(activity.sport.capitalized, systemImage: "figure.run")
                        Spacer()
                        if let dist = activity.distance {
                            Text(String(format: "%.2f m", dist))
                        }
                    }
                    .font(.headline)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                
                // Heart Rate Chart
                VStack(alignment: .leading) {
                    Text("Heart Rate")
                        .font(.title2)
                        .bold()
                    
                    if isLoading {
                        ProgressView("Loading heart rate data...")
                            .frame(height: 200)
                    } else if let details = details, !details.records.isEmpty {
                        Chart {
                            ForEach(details.records) { record in
                                LineMark(
                                    x: .value("Time", record.date),
                                    y: .value("BPM", record.hr)
                                )
                                .foregroundStyle(.red)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Time", record.date),
                                    yStart: .value("Min", 0), // Or logical min like 40
                                    yEnd: .value("BPM", record.hr)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red.opacity(0.4), Color.red.opacity(0.0)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .frame(height: 250)
                        
                        // Stats
                        let hrs = details.records.map { $0.hr }
                        if let max = hrs.max(), let min = hrs.min() {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Max")
                                    Text("\(max)").font(.title3).bold()
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Min")
                                    Text("\(min)").font(.title3).bold()
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Avg")
                                    Text("\(Int(Double(hrs.reduce(0, +)) / Double(hrs.count)))").font(.title3).bold()
                                }
                            }
                            .padding(.top)
                        }
                        
                    } else if let error = errorMessage {
                        Text("Error loading chart: \(error)")
                            .foregroundColor(.red)
                    } else {
                        Text("No heart rate data available.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(activity.name)
        .task {
            await loadDetails()
        }
    }
    
    private func loadDetails() async {
        do {
            details = try await manager.getActivityDetails(id: activity.activityId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
