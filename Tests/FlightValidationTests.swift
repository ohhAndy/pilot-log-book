import XCTest
@testable import PilotLogbook

final class FlightValidationTests: XCTestCase {
    
    func testValidationPassesValidFlight() {
        let ac = Aircraft(registration: "C-GJEN", typeDesignator: "DH8D", makeAndModel: "Dash 8-400")
        
        let result = FlightValidationEngine.validate(
            aircraft: ac,
            departure: "CYYZ",
            arrival: "CYUL",
            totalHours: 1.8,
            dayHours: 1.2,
            nightHours: 0.6,
            picHours: 1.8,
            picUSHoures: 0.0,
            sicHours: 0.0,
            dualHours: 0.0,
            instructorHours: 0.0,
            dayTakeoffs: 1,
            dayLandings: 1,
            nightTakeoffs: 0,
            nightLandings: 0,
            legsAsPilotFlying: 1
        )
        
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure(let err):
            XCTFail("Validation should succeed, but failed with: \(err)")
        }
    }
    
    func testValidationFailsMissingAircraft() {
        let result = FlightValidationEngine.validate(
            aircraft: nil,
            departure: "CYYZ",
            arrival: "CYUL",
            totalHours: 1.8,
            dayHours: 1.8,
            nightHours: 0.0,
            picHours: 1.8,
            picUSHoures: 0.0,
            sicHours: 0.0,
            dualHours: 0.0,
            instructorHours: 0.0,
            dayTakeoffs: 1,
            dayLandings: 1,
            nightTakeoffs: 0,
            nightLandings: 0,
            legsAsPilotFlying: 1
        )
        
        switch result {
        case .success:
            XCTFail("Should fail missing aircraft")
        case .failure(let err):
            XCTAssertEqual(err, .missingAircraft)
        }
    }
    
    func testValidationFailsDayNightExceedsTotal() {
        let ac = Aircraft(registration: "C-GJEN", typeDesignator: "DH8D", makeAndModel: "Dash 8-400")
        
        let result = FlightValidationEngine.validate(
            aircraft: ac,
            departure: "CYYZ",
            arrival: "CYUL",
            totalHours: 1.8,
            dayHours: 1.5,
            nightHours: 1.0, // 1.5 + 1.0 = 2.5 > 1.8
            picHours: 1.8,
            picUSHoures: 0.0,
            sicHours: 0.0,
            dualHours: 0.0,
            instructorHours: 0.0,
            dayTakeoffs: 1,
            dayLandings: 1,
            nightTakeoffs: 0,
            nightLandings: 0,
            legsAsPilotFlying: 1
        )
        
        switch result {
        case .success:
            XCTFail("Should fail day+night exceeds total")
        case .failure(let err):
            XCTAssertEqual(err, .dayNightExceedsTotal(day: 1.5, night: 1.0, total: 1.8))
        }
    }
    
    func testValidationFailsNegativePFLegs() {
        let ac = Aircraft(registration: "C-GJEN", typeDesignator: "DH8D", makeAndModel: "Dash 8-400")
        
        let result = FlightValidationEngine.validate(
            aircraft: ac,
            departure: "CYYZ",
            arrival: "CYUL",
            totalHours: 1.8,
            dayHours: 1.8,
            nightHours: 0.0,
            picHours: 1.8,
            picUSHoures: 0.0,
            sicHours: 0.0,
            dualHours: 0.0,
            instructorHours: 0.0,
            dayTakeoffs: 1,
            dayLandings: 1,
            nightTakeoffs: 0,
            nightLandings: 0,
            legsAsPilotFlying: -1 // Negative
        )
        
        switch result {
        case .success:
            XCTFail("Should fail negative PF legs")
        case .failure(let err):
            XCTAssertEqual(err, .negativePFLegs)
        }
    }
}
