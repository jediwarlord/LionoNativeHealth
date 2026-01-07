import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.errorMessage = "HealthKit is not available on this device."
            return
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            self.errorMessage = "Heart Rate type is unavailable."
            return
        }
        
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        DispatchQueue.main.async {
            switch status {
            case .sharingAuthorized:
                self.isAuthorized = true
            case .sharingDenied:
                self.isAuthorized = false
                self.errorMessage = "Access denied."
            case .notDetermined:
                self.isAuthorized = false
            @unknown default:
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
        
        let typesToShare: Set<HKSampleType> = [heartRateType]
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
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
}
