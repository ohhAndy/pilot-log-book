import SwiftUI
import SwiftData

@main
struct PilotLogbookApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Aircraft.self,
            FlightLogEntry.self,
            SimulatorSession.self,
            PilotProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedInitialDataIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    @MainActor
    private func seedInitialDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Aircraft>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count == 0 {
            let dh8d = Aircraft(
                registration: "C-GJEN",
                typeDesignator: "DH8D",
                makeAndModel: "De Havilland Dash 8-400",
                classType: "Multi-Engine Land",
                engineType: "Turboprop",
                defaultGearType: "Tricycle",
                isTwoCrew: true,
                isDefault: true
            )
            let beaver = Aircraft(
                registration: "C-FABC",
                typeDesignator: "DHC-2",
                makeAndModel: "de Havilland DHC-2 Beaver",
                classType: "Single-Engine Land",
                engineType: "Piston",
                defaultGearType: "Floats",
                isConvertibleGear: true,
                isTwoCrew: false
            )
            context.insert(dh8d)
            context.insert(beaver)
            try? context.save()
        }
    }
}
