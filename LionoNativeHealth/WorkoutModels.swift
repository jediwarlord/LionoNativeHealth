
import Foundation
import HealthKit

enum UnifiedWorkout: Identifiable {
    case local(HKWorkout)
    case remote(GarminActivity)
    case matched(local: HKWorkout, remote: GarminActivity)
    
    var id: String {
        switch self {
        case .local(let w): return w.uuid.uuidString
        case .remote(let a): return a.activityId
        case .matched(let w, _): return w.uuid.uuidString // Favor local ID for matched
        }
    }
    
    var date: Date {
        switch self {
        case .local(let w): return w.startDate
        case .remote(let a): return a.date
        case .matched(let w, _): return w.startDate
        }
    }
    
    var displayName: String {
        switch self {
        case .local(let w): return w.workoutActivityType.name
        case .remote(let a): return a.name
        case .matched(let w, _): return "\(w.workoutActivityType.name) + Garmin"
        }
    }
    
    var duration: TimeInterval? {
        switch self {
        case .local(let w): return w.duration
        case .remote(_): return nil // Parsing duration string '00:30:00' is annoying, skipping for now
        case .matched(let w, _): return w.duration
        }
    }
}
