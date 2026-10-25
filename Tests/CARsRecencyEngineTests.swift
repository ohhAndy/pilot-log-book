import XCTest
@testable import PilotLogbook

final class CARsRecencyEngineTests: XCTestCase {
    
    // MARK: - CAR 700.27 Tests
    func testCAR70027RollingLimits() {
        let calendar = Calendar.current
        let today = Date()
        
        let ac = Aircraft(registration: "C-GJEN", typeDesignator: "DH8D", makeAndModel: "Dash 8-400")
        
        // Flight 10 days ago: 50 hrs
        let date10DaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!
        let f1 = FlightLogEntry(date: date10DaysAgo, aircraft: ac, isCrossCountry: true, flightTimeHours: 50.0)
        
        // Flight 40 days ago: 40 hrs (within 90 and 365, but outside 28)
        let date40DaysAgo = calendar.date(byAdding: .day, value: -40, to: today)!
        let f2 = FlightLogEntry(date: date40DaysAgo, aircraft: ac, isCrossCountry: true, flightTimeHours: 40.0)
        
        // Flight 200 days ago: 250 hrs (within 365, outside 90)
        let date200DaysAgo = calendar.date(byAdding: .day, value: -200, to: today)!
        let f3 = FlightLogEntry(date: date200DaysAgo, aircraft: ac, isCrossCountry: true, flightTimeHours: 250.0)
        
        let limits = CARsRecencyEngine.calculateFlightTimeLimits(flights: [f1, f2, f3], referenceDate: today)
        
        XCTAssertEqual(limits.hours28Days, 50.0)
        XCTAssertEqual(limits.buffer28Days, 62.0)
        XCTAssertFalse(limits.is28DaysExceeded)
        
        XCTAssertEqual(limits.hours90Days, 90.0)
        XCTAssertEqual(limits.buffer90Days, 210.0)
        
        XCTAssertEqual(limits.hours365Days, 340.0)
        XCTAssertEqual(limits.buffer365Days, 660.0)
    }
    
    // MARK: - CAR 421.34(4) ATPL Audit Tests
    func testCAR42134AuditPICUSCredit() {
        let ac = Aircraft(registration: "C-GJEN", typeDesignator: "DH8D", makeAndModel: "Dash 8-400")
        
        // Pilot has 180 hrs raw PIC, and 120 hrs PIC U/S
        // Under CAR 421.34(4), PIC U/S is capped at 100 hrs credit
        // Total credited PIC should be 180 + 100 = 280 hrs (exceeding 250 hrs requirement)
        let f1 = FlightLogEntry(
            aircraft: ac,
            isCrossCountry: true,
            flightTimeHours: 180.0,
            picHours: 180.0,
            picUSHoures: 0.0
        )
        let f2 = FlightLogEntry(
            aircraft: ac,
            isCrossCountry: true,
            flightTimeHours: 120.0,
            picHours: 0.0,
            picUSHoures: 120.0
        )
        
        let audit = CARsRecencyEngine.calculateATPLAudit(flights: [f1, f2], simulators: [])
        
        XCTAssertEqual(audit.picHoursRaw, 180.0)
        XCTAssertEqual(audit.picUSHouresRaw, 120.0)
        XCTAssertEqual(audit.picCredited, 280.0)
    }
    
    // MARK: - Convertible Gear & Tailwheel/Float Derivation Tests
    func testDynamicGearDerivations() {
        let bushPlane = Aircraft(
            registration: "C-FABC",
            typeDesignator: "DHC-2",
            makeAndModel: "Beaver",
            category: "Aeroplane",
            classType: "Single-Engine Land",
            engineType: "Piston",
            defaultGearType: "Floats",
            isConvertibleGear: true
        )
        
        // Flight 1: Summer float flying
        let fFloat = FlightLogEntry(
            aircraft: bushPlane,
            gearConfiguration: "Floats",
            flightTimeHours: 2.5
        )
        XCTAssertEqual(fFloat.floatHours, 2.5)
        XCTAssertEqual(fFloat.tailwheelHours, 0.0)
        
        // Flight 2: Autumn tundra tire tailwheel flying
        let fTail = FlightLogEntry(
            aircraft: bushPlane,
            gearConfiguration: "Tailwheel",
            flightTimeHours: 1.8
        )
        XCTAssertEqual(fTail.floatHours, 0.0)
        XCTAssertEqual(fTail.tailwheelHours, 1.8)
        
        // Flight 3: Winter ski flying
        let fSki = FlightLogEntry(
            aircraft: bushPlane,
            gearConfiguration: "Skis",
            flightTimeHours: 3.0
        )
        XCTAssertEqual(fSki.skiHours, 3.0)
        XCTAssertEqual(fSki.tailwheelHours, 3.0) // Skis count as tailwheel gear in taildragger
    }
}
