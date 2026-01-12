import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    @Published var workouts: [HKWorkout] = []
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.errorMessage = "HealthKit is not available on this device."
            return
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let workoutType = HKObjectType.workoutType() as? HKWorkoutType else {
            self.errorMessage = "Health Data types unavailable."
            return
        }
        
        // Checking auth status for multiple types
        let hrStatus = healthStore.authorizationStatus(for: heartRateType)
        let workoutStatus = healthStore.authorizationStatus(for: workoutType)
        
        DispatchQueue.main.async {
            if hrStatus == .sharingAuthorized && workoutStatus == .sharingAuthorized {
                self.isAuthorized = true
                self.fetchWorkouts()
            } else if hrStatus == .sharingDenied || workoutStatus == .sharingDenied {
                self.isAuthorized = false
                self.errorMessage = "Access denied. Please enable Health access in Settings."
            } else {
                // .notDetermined, or mixed states
                self.isAuthorized = false
            }
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.errorMessage = "HealthKit is not available on this device."
            return
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let workoutType = HKObjectType.workoutType()
        
        let typesToShare: Set<HKSampleType> = [heartRateType, workoutType]
        let typesToRead: Set<HKObjectType> = [heartRateType, workoutType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.checkAuthorizationStatus()
                } else if let error = error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Workout Data
    
    func fetchWorkouts(limit: Int = 20) {
        print("DEBUG: fetching workouts...")
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: limit, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("DEBUG: Verify fetchWorkouts error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch workouts: \(error.localizedDescription)"
                    return
                }
                
                print("DEBUG: Fetched \(samples?.count ?? 0) workouts")
                if let workouts = samples as? [HKWorkout] {
                    self.workouts = workouts
                }
            }
        }
        healthStore.execute(query)
    }
    
    struct HeartRateSourceData: Identifiable {
        let id = UUID()
        let sourceName: String
        let deviceName: String?     // e.g. "Polar H10"
        let manufacturer: String?   // e.g. "Polar"
        let model: String?          // e.g. "H10"
        let count: Int
        let samples: [HKQuantitySample]
        
        var displayName: String {
            if let name = deviceName {
                return name
            } else if let manufact = manufacturer, let mod = model {
                return "\(manufact) \(mod)"
            } else {
                return sourceName
            }
        }
    }
    
    func fetchHeartRateSamples(for workout: HKWorkout, completion: @escaping ([HeartRateSourceData]) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // Group by a unique combination of Source and Device
            // We use a composite key to ensure distinct hardwares are separated
            struct GroupKey: Hashable {
                let sourceName: String
                let deviceName: String?
                let manufacturer: String?
                let model: String?
            }
            
            let grouped = Dictionary(grouping: samples) { sample -> GroupKey in
                let device = sample.device
                return GroupKey(
                    sourceName: sample.sourceRevision.source.name,
                    deviceName: device?.name,
                    manufacturer: device?.manufacturer,
                    model: device?.model
                )
            }
            
            let sourceData = grouped.map { (key, samples) in
                HeartRateSourceData(
                    sourceName: key.sourceName,
                    deviceName: key.deviceName,
                    manufacturer: key.manufacturer,
                    model: key.model,
                    count: samples.count,
                    samples: samples
                )
            }.sorted { $0.count > $1.count } // Most frequent source first
            
            DispatchQueue.main.async {
                completion(sourceData)
            }
        }
        
        healthStore.execute(query)
    }
}
