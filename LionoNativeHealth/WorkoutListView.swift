import SwiftUI
import HealthKit

struct WorkoutListView: View {
    @ObservedObject var healthManager: HealthKitManager
    @StateObject private var garminManager = GarminManager()
    
    var body: some View {
        List {
            Section(header: Text("Garmin Activities (Remote)")) {
                if garminManager.isLoading {
                    ProgressView()
                } else if let error = garminManager.errorMessage {
                    Text("Error: \(error)").foregroundColor(.red)
                } else {
                    ForEach(garminManager.activities) { activity in
                         NavigationLink(destination: GarminDetailView(activity: activity)) {
                             VStack(alignment: .leading) {
                                Text(activity.name).font(.headline)
                                HStack {
                                    Text(activity.sport)
                                    Spacer()
                                    if let hr = activity.avgHr {
                                        Text("\(hr) bpm").foregroundColor(.red)
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                Text(activity.startTime).font(.caption2).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Local HealthKit Workouts")) {
                ForEach(healthManager.workouts, id: \.uuid) { workout in
                    NavigationLink(destination: SourceAnalysisView(healthManager: healthManager, workout: workout)) {
                        VStack(alignment: .leading) {
                            Text(workout.workoutActivityType.name)
                                .font(.headline)
                            Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "timer")
                                Text(formatDuration(workout.duration))
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .navigationTitle("Your Activity")
        .refreshable {
            healthManager.fetchWorkouts()
            garminManager.fetchActivities()
        }
        .onAppear {
            garminManager.fetchActivities()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Workout"
        }
    }
}
