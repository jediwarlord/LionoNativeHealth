
import Foundation
import Combine

struct GarminActivity: Identifiable, Codable {
    let activityId: String
    let name: String
    let startTime: String // "2025-12-07 09:27:35.000000"
    let sport: String
    let distance: Double?
    let avgHr: Int?
    
    var id: String { activityId }
    
    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case name
        case startTime = "start_time"
        case sport
        case distance
        case avgHr = "avg_hr"
    }
    
    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.000000"
        return formatter.date(from: startTime) ?? Date.distantPast
    }
}

class GarminManager: ObservableObject {
    @Published var activities: [GarminActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Using the temporary Cloudflare Tunnel URL
    private let baseURL = "https://bigger-military-skip-cold.trycloudflare.com/garmin"
    
    func fetchActivityDetails(id: String) {
        // Clear previous details or manage state separately if needed
        // For simplicity, we might just return the result via a completion handler or publish to a separate property
    }
    
    // Better approach: async/await for cleaner usage in new views
    func getActivityDetails(id: String) async throws -> GarminActivityDetails {
        guard let url = URL(string: "\(baseURL)/activities/\(id)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(GarminActivityDetails.self, from: data)
    }
    
    func fetchActivities() {
        guard let url = URL(string: "\(baseURL)/activities") else { return }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    // Date decoding strategy might be needed depending on the exact format if we parse to Date objects
                    // For now, keeping as String to match simplest JSON structure
                    self?.activities = try decoder.decode([GarminActivity].self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    self?.errorMessage = "Failed to decode data"
                }
            }
        }.resume()
    }
}

struct GarminActivityDetails: Codable {
    let activityId: String
    let records: [ActivityRecord]
    
    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case records
    }
}

struct ActivityRecord: Codable, Identifiable {
    let timestamp: String
    let hr: Int
    
    var id: String { timestamp }
    
    // Helper to convert string timestamp to Date for Charts
    var date: Date {
        // Approx format: "2025-12-07 09:27:38.000000"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.000000"
        return formatter.date(from: timestamp) ?? Date()
    }
}
