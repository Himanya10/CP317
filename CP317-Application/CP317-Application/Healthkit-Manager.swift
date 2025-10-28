import Foundation
import HealthKit

// The ViewModel will use this object to store the data
struct HealthData {
    var stepCount: Int = 0
    var heartRate: Int = 0 // In BPM
}

// Manages all HealthKit interactions
class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    // Published property to allow SwiftUI views to react to changes
    @Published var latestData = HealthData()

    private let store = HKHealthStore()
    
    // Define the types we want to read - use HKSampleType instead of HKObjectType
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        return types
    }

    init() {
        // Automatically request authorization on manager creation
        requestAuthorization { success, _ in
            if success {
                self.startObservingHealthData()
            }
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.health.error", code: 101, userInfo: [NSLocalizedDescriptionKey: "Health data is not available on this device."]));
            return
        }

        store.requestAuthorization(toShare: Set(), read: readTypes) { ok, error in
            // Must run completion on the main thread since UI might rely on it
            DispatchQueue.main.async {
                completion(ok, error)
            }
        }
    }
    
    // MARK: - Live Data Observer
    
    // Starts the long-running query to watch for changes to Heart Rate and Steps
    private func startObservingHealthData() {
        // Observe Heart Rate changes
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        // 1. Set up Observer for Heart Rate
        setupObserverQuery(for: heartRateType) { [weak self] in
            self?.fetchMostRecentSample(for: heartRateType) { sample in
                if let sample = sample {
                    let heartRate = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                    // Update the published property on the main thread
                    DispatchQueue.main.async {
                        self?.latestData.heartRate = heartRate
                    }
                }
            }
        }
        
        // 2. Set up Observer for Step Count
        setupObserverQuery(for: stepCountType) { [weak self] in
            self?.fetchStepsToday { stepCount in
                // Update the published property on the main thread
                DispatchQueue.main.async {
                    self?.latestData.stepCount = stepCount
                }
            }
        }
    }
    
    // FIXED: Changed parameter type from HKObjectType to HKSampleType
    private func setupObserverQuery(for type: HKSampleType, updateHandler: @escaping () -> Void) {
        let observerQuery = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("Observer query error for \(type): \(error.localizedDescription)")
                completionHandler()
                return
            }
            // A change occurred, run the update handler to fetch the new data
            updateHandler()
            completionHandler()
        }
        store.execute(observerQuery)
    }

    // MARK: - Fetchers
    
    // Fetches the single most recent heart rate sample
    private func fetchMostRecentSample(for type: HKQuantityType, completion: @escaping (HKQuantitySample?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                completion(nil); return
            }
            completion(sample)
        }
        store.execute(query)
    }
    
    // Fetches the total step count for today
    private func fetchStepsToday(completion: @escaping (Int) -> Void) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0); return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity(), error == nil else {
                completion(0); return
            }
            
            let totalSteps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(totalSteps)
        }
        store.execute(query)
    }
}
