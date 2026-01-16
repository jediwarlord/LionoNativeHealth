import SwiftUI
import HealthKit

struct WorkoutListView: View {
    @ObservedObject var healthManager: HealthKitManager
    @StateObject private var garminManager = GarminManager()
    
    // Unified Workout Model moved to local private struct or extension for now if not global
    // Using the one defined in WorkoutModels.swift or inline if simple
    
    var body: some View {
        List {
            let unifiedWorkouts = correlateWorkouts(local: healthManager.workouts, remote: garminManager.activities)
            
            ForEach(unifiedWorkouts) { uWorkout in
                switch uWorkout {
                case .matched(let local, let remote):
                    NavigationLink(destination: SourceAnalysisView(healthManager: healthManager, workout: local, garminActivity: remote)) {
                        UnifiedWorkoutRow(local: local, remote: remote)
                    }
                    
                case .local(let local):
                    NavigationLink(destination: SourceAnalysisView(healthManager: healthManager, workout: local)) {
                        LocalWorkoutRow(workout: local)
                    }
                    
                case .remote(let remote):
                    NavigationLink(destination: GarminDetailView(activity: remote)) {
                        RemoteWorkoutRow(activity: remote)
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
    
    func correlateWorkouts(local: [HKWorkout], remote: [GarminActivity]) -> [UnifiedWorkout] {
        var unified: [UnifiedWorkout] = []
        var consumedRemoteIds: Set<String> = []
        
        let sortedLocal = local.sorted { $0.startDate > $1.startDate }
        let sortedRemote = remote.sorted { $0.date > $1.date }
        
        // Match local to remote
        for lWorkout in sortedLocal {
            // Find a remote workout that starts within 15 mins (900s)
            if let match = sortedRemote.first(where: { rActivity in
                abs(rActivity.date.timeIntervalSince(lWorkout.startDate)) < 900
            }) {
                unified.append(.matched(local: lWorkout, remote: match))
                consumedRemoteIds.insert(match.activityId)
            } else {
                unified.append(.local(lWorkout))
            }
        }
        
        // Add remaining remote
        for rActivity in sortedRemote {
            if !consumedRemoteIds.contains(rActivity.activityId) {
                unified.append(.remote(rActivity))
            }
        }
        
        return unified.sorted { $0.date > $1.date }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

// Row Views
struct UnifiedWorkoutRow: View {
    let local: HKWorkout
    let remote: GarminActivity
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(local.workoutActivityType.name)
                    .font(.headline)
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Garmin Data")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(local.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "timer")
                Text(formatDuration(local.duration))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct LocalWorkoutRow: View {
    let workout: HKWorkout
    
    var body: some View {
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
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct RemoteWorkoutRow: View {
    let activity: GarminActivity
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(activity.name).font(.headline)
                Spacer()
                Image(systemName: "globe")
                    .foregroundColor(.orange)
            }
            
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
        .padding(.vertical, 5)
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
