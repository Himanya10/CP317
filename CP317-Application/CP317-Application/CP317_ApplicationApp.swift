//
//  CP317_ApplicationApp.swift
//  CP317-Application
//

import SwiftUI

@main
struct CP317_Application_App: App {
    // Initialize both shared instances as StateObjects
    @StateObject private var vm = AppViewModel.shared
    @StateObject private var aiModel = PredictionEngine.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Inject both view models into the environment
                .environmentObject(vm)
                .environmentObject(aiModel)
        }
    }
}
