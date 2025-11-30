//
//  MainTabView.swift
//  CP317-Application
//
//  Created by Himanya Verma on 2025-11-25.
//

import SwiftUI

struct MainTabView: View {
    // The AppViewModel is the single source of truth for app state and data flow
    @StateObject var vm = AppViewModel.shared
    
    var body: some View {
        TabView {
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationView {
                StressForecastView()
            }
            .tabItem {
                Label("Stress", systemImage: "waveform.path.ecg")
            }
            
            NavigationView {
                CalorieTrackingView()
            }
            .tabItem {
                Label("Calories", systemImage: "flame.fill")
            }
            
            NavigationView {
                AdaptiveGoalsView()
            }
            .tabItem {
                Label("Goals", systemImage: "flag.fill")
            }
            
            NavigationView {
                MedicationReconciliationView()
            }
            .tabItem {
                Label("MediVision", systemImage: "cross.case.fill")
            }
        }
        .accentColor(Color.pgPrimary)
        .environmentObject(vm)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppViewModel.shared)
    }
}
