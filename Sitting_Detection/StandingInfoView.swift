import SwiftUI
import HealthKit

class StandingViewModel: ObservableObject {
    private let healthStore = HKHealthStore()
    private var timer: Timer?
    
    @Published var isCurrentHourComplete = false
    @Published var continuousSittingHours = 0
    
    init() {
        setupHealthKit()
    }
    
    func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let standingType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!
        
        healthStore.requestAuthorization(toShare: nil, read: [standingType]) { success, error in
            if success {
                print("HealthKit authorization granted")
            } else {
                print("HealthKit authorization denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func startPeriodicChecks() {
        timer?.invalidate()
        fetchStandingData()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchStandingData()
        }
    }
    
    func stopPeriodicChecks() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchStandingData() {
        let standingType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!
        
        let now = Date()
        let calendar = Calendar.current
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now)!
        let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: twoHoursAgo, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: standingType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: twoHoursAgo,
                                                intervalComponents: DateComponents(hour: 1))
        
        query.initialResultsHandler = { [weak self] query, results, error in
            guard let results = results else {
                print("No results: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var previousHourComplete = false
            var currentHourComplete = false
            
            results.enumerateStatistics(from: twoHoursAgo, to: now) { statistics, stop in
                let standingTime = statistics.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                
                if statistics.startDate < oneHourAgo {
                    previousHourComplete = standingTime >= 1
                } else {
                    currentHourComplete = standingTime >= 1
                }
            }
            
            if !previousHourComplete && !currentHourComplete {
                self?.sendStandingReminder()
            }
            
            // Calculate continuous sitting hours
            let startOfDay = calendar.startOfDay(for: now)
            var sittingHours = 0
            results.enumerateStatistics(from: startOfDay, to: now) { statistics, stop in
                let standingTime = statistics.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                if standingTime < 1 {
                    sittingHours += 1
                } else {
                    sittingHours = 0
                }
            }
            
            DispatchQueue.main.async {
                self?.isCurrentHourComplete = currentHourComplete
                self?.continuousSittingHours = sittingHours
            }
        }
        
        healthStore.execute(query)
    }
    
    func sendStandingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Stand!"
        content.body = "You haven't stood in the last hour. Take a quick break!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
}
