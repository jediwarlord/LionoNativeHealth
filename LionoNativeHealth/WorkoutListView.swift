import SwiftUI
import HealthKit

struct WorkoutListView: View {
    @ObservedObject var healthManager: HealthKitManager
    
    var body: some View {
        List(healthManager.workouts, id: \.uuid) { workout in
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
        .navigationTitle("Recent Workouts")
        .refreshable {
            healthManager.fetchWorkouts()
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
