import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthManager = HealthKitManager()

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            
            Text("Liono Native Health")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if healthManager.isAuthorized {
                Text("HealthKit Authorized ✅")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Text("Permission Required")
                    .foregroundColor(.orange)
                    .font(.headline)
                
                if let errorMessage = healthManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Button(action: {
                    healthManager.requestAuthorization()
                }) {
                    Text("Request HealthKit Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            healthManager.checkAuthorizationStatus()
        }
    }
}
