import SwiftUI
import SwiftData

/// Main root view for the Pilot Logbook.
/// Provides a bottom TabView on iOS and a NavigationSplitView on macOS.
struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        #if os(macOS)
        macSidebarView
        #else
        iosTabView
        #endif
    }
    
    // MARK: - iOS Tab View
    private var iosTabView: some View {
        TabView(selection: $selectedTab) {
            LogbookListView()
                .tabItem {
                    Label("Logbook", systemImage: "book.pages.fill")
                }
                .tag(0)
            
            CARsDashboardView()
                .tabItem {
                    Label("CARs Recency", systemImage: "shield.checkerboard")
                }
                .tag(1)
            
            SimulatorLogView()
                .tabItem {
                    Label("Simulator", systemImage: "desktopcomputer")
                }
                .tag(2)
            
            AircraftManagerView()
                .tabItem {
                    Label("Fleet", systemImage: "airplane")
                }
                .tag(3)
        }
        .tint(.cyan)
    }
    
    // MARK: - macOS Sidebar & Table View
    #if os(macOS)
    private var macSidebarView: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Logbook Table", systemImage: "tablecells")
                    .tag(0)
                Label("CARs Compliance", systemImage: "shield.checkerboard")
                    .tag(1)
                Label("Simulator Training", systemImage: "desktopcomputer")
                    .tag(2)
                Label("Fleet Manager", systemImage: "airplane")
                    .tag(3)
            }
            .navigationTitle("Pilot Logbook")
        } detail: {
            switch selectedTab {
            case 0:
                MacLogbookTableView()
            case 1:
                CARsDashboardView()
            case 2:
                SimulatorLogView()
            case 3:
                AircraftManagerView()
            default:
                MacLogbookTableView()
            }
        }
    }
    #endif
}
