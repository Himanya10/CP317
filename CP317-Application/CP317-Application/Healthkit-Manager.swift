import Foundation
import HealthKit

// Enhanced Health Data structure
struct HealthData {
    var stepCount: Int = 0
    var heartRate: Int = 0
    var activeEnergy: Double = 0
    var sleepHours: Double = 0
    var walkingDistance: Double = 0
    var lastUpdated: Date = Date()
}

// Manages all HealthKit interactions
class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    @Published var latestData = HealthData()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let store = HKHealthStore()
    
    // All available health types
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Quantity types
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let walkingDistance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(walkingDistance)
        }
        
        // Sleep analysis
        if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        
        return types
    }

    init() {
        requestAuthorization { success, _ in
            if success {
                self.startObservingHealthData()
                self.refreshAllData()
            }
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.errorMessage = "Health data is not available on this device."
                completion(false, nil)
            }
            return
        }

        store.requestAuthorization(toShare: Set(), read: readTypes) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                }
                completion(success, error)
            }
        }
    }
    
    // MARK: - Data Refresh
    
    func refreshAllData() {
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        
        // Fetch all data types
        group.enter()
        fetchStepsToday { steps in
            DispatchQueue.main.async {
                self.latestData.stepCount = steps
            }
            group.leave()
        }
        
        group.enter()
        fetchMostRecentHeartRate { heartRate in
            DispatchQueue.main.async {
                self.latestData.heartRate = heartRate
            }
            group.leave()
        }
        
        group.enter()
        fetchActiveEnergy { energy in
            DispatchQueue.main.async {
                self.latestData.activeEnergy = energy
            }
            group.leave()
        }
        
        group.enter()
        fetchWalkingDistance { distance in
            DispatchQueue.main.async {
                self.latestData.walkingDistance = distance
            }
            group.leave()
        }
        
        group.enter()
        fetchSleepHours { sleepHours in
            DispatchQueue.main.async {
                self.latestData.sleepHours = sleepHours
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.latestData.lastUpdated = Date()
            self.isLoading = false
        }
    }
    
    // MARK: - Live Data Observer
    
    private func startObservingHealthData() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        setupObserverQuery(for: heartRateType) { [weak self] in
            self?.fetchMostRecentHeartRate { heartRate in
                DispatchQueue.main.async {
                    self?.latestData.heartRate = heartRate
                    self?.latestData.lastUpdated = Date()
                }
            }
        }
        
        setupObserverQuery(for: stepCountType) { [weak self] in
            self?.fetchStepsToday { steps in
                DispatchQueue.main.async {
                    self?.latestData.stepCount = steps
                    self?.latestData.lastUpdated = Date()
                }
            }
        }
    }
    
    private func setupObserverQuery(for type: HKSampleType, updateHandler: @escaping () -> Void) {
        let observerQuery = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
            } else {
                updateHandler()
            }
            completionHandler()
        }
        store.execute(observerQuery)
        
        // Enable background delivery
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if success {
                print("Background delivery enabled for \(type)")
            }
        }
    }

    // MARK: - Data Fetchers
    
    private func fetchStepsToday(completion: @escaping (Int) -> Void) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            completion(steps)
        }
        store.execute(query)
    }
    
    private func fetchMostRecentHeartRate(completion: @escaping (Int) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            let heartRate = samples?.first.flatMap {
                ($0 as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }.map { Int($0) } ?? 0
            completion(heartRate)
        }
        store.execute(query)
    }
    
    private func fetchActiveEnergy(completion: @escaping (Double) -> Void) {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let energy = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            completion(energy)
        }
        store.execute(query)
    }
    
    private func fetchWalkingDistance(completion: @escaping (Double) -> Void) {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let distance = result?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
            completion(distance)
        }
        store.execute(query)
    }
    
    private func fetchSleepHours(completion: @escaping (Double) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let sleepSamples = samples as? [HKCategorySample] ?? []
            let totalSleep = sleepSamples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            completion(totalSleep / 3600.0) // Convert to hours
        }
        store.execute(query)
    }
}
