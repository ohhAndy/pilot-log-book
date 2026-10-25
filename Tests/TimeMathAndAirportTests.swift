import XCTest
@testable import PilotLogbook

final class TimeMathAndAirportTests: XCTestCase {
    
    // MARK: - TimeMathService Tests
    func testDecimalToHoursAndMinutes() {
        let res1 = TimeMathService.decimalToHoursAndMinutes(1.8)
        XCTAssertEqual(res1.hours, 1)
        XCTAssertEqual(res1.minutes, 48)
        
        let res2 = TimeMathService.decimalToHoursAndMinutes(0.5)
        XCTAssertEqual(res2.hours, 0)
        XCTAssertEqual(res2.minutes, 30)
        
        let formatted = TimeMathService.formatHoursAndMinutes(2.4)
        XCTAssertEqual(formatted, "2h 24m")
    }
    
    func testParseHoursAndMinutesStringToDecimal() {
        let dec1 = TimeMathService.parseToDecimalTenths("1:48")
        XCTAssertEqual(dec1, 1.8)
        
        let dec2 = TimeMathService.parseToDecimalTenths("2:30")
        XCTAssertEqual(dec2, 2.5)
        
        let dec3 = TimeMathService.parseToDecimalTenths("3.2")
        XCTAssertEqual(dec3, 3.2)
    }
    
    func testNudgeDecimalHours() {
        // Start from 0.0
        XCTAssertEqual(TimeMathService.nudge(current: 0.0, delta: 0.1), 0.1)
        XCTAssertEqual(TimeMathService.nudge(current: 0.0, delta: 0.5), 0.5)
        XCTAssertEqual(TimeMathService.nudge(current: 0.0, delta: 1.0), 1.0)
        XCTAssertEqual(TimeMathService.nudge(current: 0.0, delta: -0.1), 0.0) // Clamp at 0
        
        // Start from 1.8
        XCTAssertEqual(TimeMathService.nudge(current: 1.8, delta: 0.1), 1.9)
        XCTAssertEqual(TimeMathService.nudge(current: 1.8, delta: -0.1), 1.7)
        XCTAssertEqual(TimeMathService.nudge(current: 1.8, delta: 0.5), 2.3)
        XCTAssertEqual(TimeMathService.nudge(current: 1.8, delta: 1.0), 2.8)
        
        // Floating point precision checks (avoid 0.1 + 0.2 = 0.30000000000000004)
        XCTAssertEqual(TimeMathService.nudge(current: 0.2, delta: 0.1), 0.3)
        XCTAssertEqual(TimeMathService.nudge(current: 0.7, delta: 0.1), 0.8)
        XCTAssertEqual(TimeMathService.nudge(current: 0.9, delta: 0.1), 1.0)
    }
    
    // MARK: - AirportDirectoryService Tests
    func testAirportLookup() {
        let yvr = AirportDirectoryService.lookup(code: "CYVR")
        XCTAssertNotNil(yvr)
        XCTAssertEqual(yvr?.city, "Vancouver")
        XCTAssertEqual(yvr?.provinceOrTerritory, "BC")
        XCTAssertFalse(yvr?.isWaterdrome ?? true)
        
        let water = AirportDirectoryService.lookup(code: "CYWH")
        XCTAssertNotNil(water)
        XCTAssertTrue(water?.isWaterdrome ?? false)
    }
    
    func testAirportSearch() {
        let results = AirportDirectoryService.search(query: "Yellowknife")
        XCTAssertEqual(results.first?.code, "CYZF")
        
        let montrealResults = AirportDirectoryService.search(query: "Montréal")
        XCTAssertTrue(montrealResults.contains(where: { $0.code == "CYUL" }))
    }
}
