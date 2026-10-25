import XCTest
import SwiftData
@testable import PilotLogbook

@MainActor
final class AircraftManagementTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([Aircraft.self, FlightLogEntry.self, SimulatorSession.self, PilotProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
    }
    
    func testAircraftEditingUpdatesDerivedHoursOnFlights() throws {
        // Create initial Single-Engine Piston aircraft
        let ac = Aircraft(
            registration: "C-FABC",
            typeDesignator: "C172",
            makeAndModel: "Cessna 172",
            classType: "Single-Engine Land",
            engineType: "Piston",
            defaultGearType: "Tricycle"
        )
        context.insert(ac)
        
        let flight = FlightLogEntry(
            date: Date(),
            aircraft: ac,
            gearConfiguration: "Tricycle",
            departureAirport: "CYVR",
            arrivalAirport: "CYYJ",
            flightTimeHours: 2.0,
            picHours: 2.0
        )
        context.insert(flight)
        try context.save()
        
        XCTAssertEqual(flight.multiEngineHours, 0.0)
        XCTAssertEqual(flight.turbineHours, 0.0)
        
        // Now edit aircraft to be Multi-Engine Turboprop (e.g. type upgrade)
        ac.classType = "Multi-Engine Land"
        ac.engineType = "Turboprop"
        ac.typeDesignator = "DH8D"
        ac.makeAndModel = "Dash 8-400"
        
        // Recompute on associated flights
        for f in ac.flights {
            f.recomputeDerivedHours()
        }
        try context.save()
        
        XCTAssertEqual(flight.multiEngineHours, 2.0)
        XCTAssertEqual(flight.turbineHours, 2.0)
    }
    
    func testAircraftDeletionPreservesHistoricalFlightLogEntries() throws {
        let ac = Aircraft(
            registration: "C-GJEN",
            typeDesignator: "DH8D",
            makeAndModel: "Dash 8-400",
            classType: "Multi-Engine Land",
            engineType: "Turboprop",
            defaultGearType: "Tricycle",
            isDefault: true
        )
        context.insert(ac)
        
        let flight = FlightLogEntry(
            date: Date(),
            aircraft: ac,
            gearConfiguration: "Tricycle",
            departureAirport: "CYYZ",
            arrivalAirport: "CYUL",
            flightTimeHours: 1.5,
            picHours: 1.5
        )
        context.insert(flight)
        try context.save()
        
        XCTAssertEqual(ac.flights.count, 1)
        XCTAssertEqual(flight.aircraft?.registration, "C-GJEN")
        
        // Delete aircraft from fleet
        context.delete(ac)
        try context.save()
        
        // Flight must still exist with logged hours intact (nullified relationship, not cascaded)
        let fetchDescriptor = FetchDescriptor<FlightLogEntry>()
        let remainingFlights = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(remainingFlights.count, 1)
        XCTAssertEqual(remainingFlights.first?.flightTimeHours, 1.5)
        XCTAssertEqual(remainingFlights.first?.picHours, 1.5)
        XCTAssertNil(remainingFlights.first?.aircraft)
    }
    
    func testDefaultAircraftManagement() throws {
        let ac1 = Aircraft(registration: "C-AAA", typeDesignator: "C172", makeAndModel: "C172", isDefault: true)
        let ac2 = Aircraft(registration: "C-BBB", typeDesignator: "DH8D", makeAndModel: "DH8D", isDefault: false)
        context.insert(ac1)
        context.insert(ac2)
        try context.save()
        
        XCTAssertTrue(ac1.isDefault)
        XCTAssertFalse(ac2.isDefault)
        
        // Switch default to ac2
        ac1.isDefault = false
        ac2.isDefault = true
        try context.save()
        
        XCTAssertFalse(ac1.isDefault)
        XCTAssertTrue(ac2.isDefault)
    }
}
