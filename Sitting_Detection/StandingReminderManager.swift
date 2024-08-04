import HealthKit
import UIKit
import UserNotifications

class StandingReminderManager {
    let healthStore = HKHealthStore()
    
    func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let standingType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!
        
        healthStore.requestAuthorization(toShare: nil, read: [standingType]) { (success, error) in
            if success {
                print("HealthKit authorization granted")
                self.setupBackgroundFetch()
            } else {
                print("HealthKit authorization denied")
            }
        }
    }
    
    func setupBackgroundFetch() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }
    
    func checkStandingStatus() {
        let standingType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!
        let now = Date()
        let hourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: hourAgo, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: standingType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch standing data: \(error?.localizedDescription ?? "")")
                return
            }
            
            let standingTime = sum.doubleValue(for: HKUnit.minute())
            if standingTime < 1 {  // If less than 1 minute of standing time
                self.sendNotification()
            }
        }
        
        healthStore.execute(query)
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Stand!"
        content.body = "You haven't stood up in the last hour. Take a quick break!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
}
