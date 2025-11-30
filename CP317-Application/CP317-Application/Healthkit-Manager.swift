//
//  Healthkit-Manager.swift
//  CP317-Application
//

import Foundation
import HealthKit

struct HealthData {
    // Core Metrics
    var stepCount: Int = 0
    var sleepHours: Double = 0
    var hrvSDNN: Double = 0.0
    
    // Heart Rate
    var averageHeartRate: Int = 0
    var latestHeartRate: Int = 0
    
    // New Metrics
    var bloodPressureSystolic: Int? = nil
    var bloodPressureDiastolic: Int? = nil
    var oxygenSaturation: Double? = nil
    var bodyTemperature: Double? = nil
    var activeCalories: Int = 0
    var totalCalories: Int = 0
    var distanceWalked: Double = 0.0  // in kilometers
    var workoutMinutes: Int = 0
    
    var lastUpdated: Date = Date()
    
    // Helper computed properties for UI
    var hasBloodPressure: Bool {
        bloodPressureSystolic != nil && bloodPressureDiastolic != nil
    }
    
    var hasOxygenSaturation: Bool {
        oxygenSaturation != nil
    }
    
    var hasBodyTemperature: Bool {
        bodyTemperature != nil
    }
    
    var bloodPressureString: String {
        guard let systolic = bloodPressureSystolic,
              let diastolic = bloodPressureDiastolic else {
            return "Not enough info"
        }
        return "\(systolic)/\(diastolic)"
    }
    
    var oxygenSaturationString: String {
        guard let oxygen = oxygenSaturation else {
            return "Not enough info"
        }
        return String(format: "%.1f%%", oxygen * 100)
    }
    
    var bodyTemperatureString: String {
        guard let temp = bodyTemperature else {
            return "Not enough info"
        }
        return String(format: "%.1f°F", temp)
    }
}

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    @Published var latestData = HealthData()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let store = HKHealthStore()
    
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Original metrics
        types.insert(HKObjectType.quantityType(forIdentifier: .stepCount)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .heartRate)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!)
        types.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        
        // New metrics
        types.insert(HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .bodyTemperature)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!)
        types.insert(HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!)
        types.insert(HKObjectType.workoutType())
        
        return types
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        store.requestAuthorization(toShare: nil, read: readTypes) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
    
    // MARK: - Original Fetch Functions
    
    private func fetchStepCount(completion: @escaping (Int) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let type = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        store.execute(query)
    }
    
    private func fetchSleepHours(completion: @escaping (Double) -> Void) {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: []) { _, samples, _ in
            let sleepSamples = samples as? [HKCategorySample] ?? []
            let totalSleep = sleepSamples.filter {
                $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            DispatchQueue.main.async {
                completion(totalSleep / 3600.0)
            }
        }
        store.execute(query)
    }
    
    private func fetchAverageHeartRate(completion: @escaping (Int) -> Void) {
        let type = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let avg = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
            DispatchQueue.main.async {
                completion(Int(avg))
            }
        }
        store.execute(query)
    }
    
    private func fetchLatestHeartRate(completion: @escaping (Int) -> Void) {
        let type = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                completion(Int(bpm))
            }
        }
        store.execute(query)
    }
    
    private func fetchHRV(completion: @escaping (Double) -> Void) {
        let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            let hrv = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .secondUnit(with: .milli)) ?? 0.0
            DispatchQueue.main.async {
                completion(hrv)
            }
        }
        store.execute(query)
    }
    
    // MARK: - New Fetch Functions
    
    private func fetchBloodPressure(completion: @escaping (Int?, Int?) -> Void) {
        let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        var systolic: Int? = nil
        var diastolic: Int? = nil
        let group = DispatchGroup()
        
        // Fetch Systolic
        group.enter()
        let systolicQuery = HKSampleQuery(sampleType: systolicType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                systolic = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
            }
            group.leave()
        }
        store.execute(systolicQuery)
        
        // Fetch Diastolic
        group.enter()
        let diastolicQuery = HKSampleQuery(sampleType: diastolicType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                diastolic = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
            }
            group.leave()
        }
        store.execute(diastolicQuery)
        
        group.notify(queue: .main) {
            completion(systolic, diastolic)
        }
    }
    
    private func fetchOxygenSaturation(completion: @escaping (Double?) -> Void) {
        let type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let oxygen = sample.quantity.doubleValue(for: HKUnit.percent())
            DispatchQueue.main.async {
                completion(oxygen)
            }
        }
        store.execute(query)
    }
    
    private func fetchBodyTemperature(completion: @escaping (Double?) -> Void) {
        let type = HKObjectType.quantityType(forIdentifier: .bodyTemperature)!
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let temp = sample.quantity.doubleValue(for: HKUnit.degreeFahrenheit())
            DispatchQueue.main.async {
                completion(temp)
            }
        }
        store.execute(query)
    }
    
    private func fetchCalories(completion: @escaping (Int, Int) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        var activeCalories = 0
        var basalCalories = 0
        let group = DispatchGroup()
        
        // Fetch Active Calories
        group.enter()
        let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let activeQuery = HKStatisticsQuery(quantityType: activeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            activeCalories = Int(result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
            group.leave()
        }
        store.execute(activeQuery)
        
        // Fetch Basal Calories
        group.enter()
        let basalType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
        let basalQuery = HKStatisticsQuery(quantityType: basalType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            basalCalories = Int(result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
            group.leave()
        }
        store.execute(basalQuery)
        
        group.notify(queue: .main) {
            completion(activeCalories, activeCalories + basalCalories)
        }
    }
    
    private func fetchDistance(completion: @escaping (Double) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let distance = result?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
            DispatchQueue.main.async {
                completion(distance)
            }
        }
        store.execute(query)
    }
    
    private func fetchWorkoutMinutes(completion: @escaping (Int) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: []) { _, samples, _ in
            let workouts = samples as? [HKWorkout] ?? []
            let totalMinutes = workouts.reduce(0) { $0 + Int($1.duration / 60.0) }
            DispatchQueue.main.async {
                completion(totalMinutes)
            }
        }
        store.execute(query)
    }
    
    // MARK: - Main Fetch Method
    
    func fetchLatestMetrics(completion: @escaping (HealthData) -> Void) {
        self.isLoading = true
        self.errorMessage = nil
        
        var data = HealthData()
        let group = DispatchGroup()
        
        // Original metrics
        group.enter()
        fetchStepCount { val in
            data.stepCount = val
            group.leave()
        }
        
        group.enter()
        fetchSleepHours { val in
            data.sleepHours = val
            group.leave()
        }
        
        group.enter()
        fetchAverageHeartRate { val in
            data.averageHeartRate = val
            group.leave()
        }
        
        group.enter()
        fetchLatestHeartRate { val in
            data.latestHeartRate = val
            group.leave()
        }
        
        group.enter()
        fetchHRV { val in
            data.hrvSDNN = val
            group.leave()
        }
        
        // New metrics
        group.enter()
        fetchBloodPressure { systolic, diastolic in
            data.bloodPressureSystolic = systolic
            data.bloodPressureDiastolic = diastolic
            group.leave()
        }
        
        group.enter()
        fetchOxygenSaturation { val in
            data.oxygenSaturation = val
            group.leave()
        }
        
        group.enter()
        fetchBodyTemperature { val in
            data.bodyTemperature = val
            group.leave()
        }
        
        group.enter()
        fetchCalories { active, total in
            data.activeCalories = active
            data.totalCalories = total
            group.leave()
        }
        
        group.enter()
        fetchDistance { val in
            data.distanceWalked = val
            group.leave()
        }
        
        group.enter()
        fetchWorkoutMinutes { val in
            data.workoutMinutes = val
            group.leave()
        }
        
        group.notify(queue: .main) {
            data.lastUpdated = Date()
            self.latestData = data
            self.isLoading = false
            completion(data)
        }
    }
}
