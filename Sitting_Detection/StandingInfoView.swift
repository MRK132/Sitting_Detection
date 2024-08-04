import SwiftUI
import HealthKit

struct StandingInfoView: View {
    @StateObject private var viewModel = StandingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Standing Info")
                .font(.largeTitle)
            
            if viewModel.isAuthorized {
                Text("Current hour standing complete: \(viewModel.isCurrentHourComplete ? "Yes" : "No")")
                    .font(.headline)
                
                Text("Continuous sitting hours (9AM-6PM): \(viewModel.continuousSittingHours)")
                    .font(.headline)
            } else {
                Text("HealthKit access not authorized")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Button("Request Authorization") {
                    viewModel.requestAuthorization()
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.setup()
        }
    }
}

class StandingViewModel: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var isCurrentHourComplete = false
    @Published var continuousSittingHours = 0
    
    func setup() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let standingType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!
        
        healthStore.requestAuthorization(toShare: nil, read: [standingType]) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchStandingData()
                } else {
                    print("HealthKit authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func fetchStandingData() {
        let healthStore = HKHealthStore()
        let standingType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!
        
        // Check if the current hour's standing goal is complete
        let now = Date()
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: calendar.component(.hour, from: now), minute: 0, second: 0, of: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfHour, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: standingType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch standing data: \(error?.localizedDescription ?? "")")
                return
            }
            
            let standingTime = sum.doubleValue(for: HKUnit.minute())
            DispatchQueue.main.async {
                self.isCurrentHourComplete = standingTime >= 1.0 // Apple considers 1 minute of standing as completing the hour
            }
        }
        
        healthStore.execute(query)
        
        // Calculate continuous sitting hours (9AM-6PM)
        let calendar9AM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let calendar6PM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        
        let predicateWorkHours = HKQuery.predicateForSamples(withStart: calendar9AM, end: calendar6PM, options: .strictStartDate)
        
        let queryWorkHours = HKSampleQuery(sampleType: standingType, predicate: predicateWorkHours, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                print("Error fetching samples: \(error?.localizedDescription ?? "")")
                return
            }
            
            var lastStandingTime = calendar9AM
            var maxSittingHours = 0
            
            for sample in samples {
                let hoursBetween = calendar.dateComponents([.hour], from: lastStandingTime, to: sample.startDate).hour ?? 0
                maxSittingHours = max(maxSittingHours, hoursBetween)
                lastStandingTime = sample.startDate
            }
            
            // Check if currently sitting
            let currentSittingHours = calendar.dateComponents([.hour], from: lastStandingTime, to: min(now, calendar6PM)).hour ?? 0
            maxSittingHours = max(maxSittingHours, currentSittingHours)
            
            DispatchQueue.main.async {
                self.continuousSittingHours = maxSittingHours
            }
        }
        
        healthStore.execute(queryWorkHours)
    }
}
