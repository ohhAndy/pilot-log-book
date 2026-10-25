import Foundation
import SwiftData

/// Core personal logbook entry conforming to Transport Canada CAR 401.08.
/// Pure hours-based logging (zero timestamps required).
@Model
final class FlightLogEntry {
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var date: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()   // For Last-Write-Wins (LWW) sync
    
    // Flight & Crew Identification (Optional)
    var flightNumber: String?
    var crewNames: String?
    
    // Aircraft & Flown Gear Configuration
    var aircraft: Aircraft?
    var gearConfiguration: String = "Tricycle" // "Floats", "Tailwheel", "Skis", "Tricycle", "Amphibian"
    
    // Route (4-letter ICAO / TC)
    var departureAirport: String = ""
    var arrivalAirport: String = ""
    var route: String?
    var isCrossCountry: Bool = true
    
    // Total Flight Duration (Standard Decimal Tenths, e.g. 1.8)
    var flightTimeHours: Double = 0.0
    
    // CAR 401.08 Capacities (Hours)
    var picHours: Double = 0.0
    var picUSHoures: Double = 0.0     // PIC Under Supervision (CAR 421.11 / 421.34(4))
    var sicHours: Double = 0.0        // Co-pilot
    var dualHours: Double = 0.0
    var instructorHours: Double = 0.0
    
    // Pilot Flying (PF) vs Pilot Monitoring (PM)
    var isPilotFlying: Bool = true
    var legsAsPilotFlying: Int = 1    // Direct numeric field for number of legs as PF!
    
    // Flight Conditions (Hours)
    var dayHours: Double = 0.0
    var nightHours: Double = 0.0
    var actualIFRHours: Double = 0.0
    var simulatedIFRHours: Double = 0.0
    
    // Specialized Aircraft Hours (Derived based on aircraft & gearConfiguration)
    var tailwheelHours: Double = 0.0
    var floatHours: Double = 0.0
    var skiHours: Double = 0.0
    var multiEngineHours: Double = 0.0
    var turbineHours: Double = 0.0
    
    // Landings & Approaches
    var dayLandings: Int = 0
    var nightLandings: Int = 0
    var dayTakeoffs: Int = 0
    var nightTakeoffs: Int = 0
    var approachesCount: Int = 0     // Simple count for CAR 401.05 IFR recency
    
    var remarks: String?
    
    init(
        date: Date = Date(),
        aircraft: Aircraft? = nil,
        gearConfiguration: String = "Tricycle",
        departureAirport: String = "",
        arrivalAirport: String = "",
        route: String? = nil,
        isCrossCountry: Bool = true,
        flightTimeHours: Double = 0.0,
        picHours: Double = 0.0,
        picUSHoures: Double = 0.0,
        sicHours: Double = 0.0,
        dualHours: Double = 0.0,
        instructorHours: Double = 0.0,
        isPilotFlying: Bool = true,
        legsAsPilotFlying: Int = 1,
        dayHours: Double = 0.0,
        nightHours: Double = 0.0,
        actualIFRHours: Double = 0.0,
        simulatedIFRHours: Double = 0.0,
        dayLandings: Int = 0,
        nightLandings: Int = 0,
        dayTakeoffs: Int = 0,
        nightTakeoffs: Int = 0,
        approachesCount: Int = 0,
        flightNumber: String? = nil,
        crewNames: String? = nil,
        remarks: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.createdAt = Date()
        self.updatedAt = Date()
        self.aircraft = aircraft
        self.gearConfiguration = gearConfiguration
        self.departureAirport = departureAirport.uppercased()
        self.arrivalAirport = arrivalAirport.uppercased()
        self.route = route?.uppercased()
        self.isCrossCountry = isCrossCountry
        self.flightTimeHours = flightTimeHours
        self.picHours = picHours
        self.picUSHoures = picUSHoures
        self.sicHours = sicHours
        self.dualHours = dualHours
        self.instructorHours = instructorHours
        self.isPilotFlying = isPilotFlying
        self.legsAsPilotFlying = legsAsPilotFlying
        self.dayHours = dayHours
        self.nightHours = nightHours
        self.actualIFRHours = actualIFRHours
        self.simulatedIFRHours = simulatedIFRHours
        self.dayLandings = dayLandings
        self.nightLandings = nightLandings
        self.dayTakeoffs = dayTakeoffs
        self.nightTakeoffs = nightTakeoffs
        self.approachesCount = approachesCount
        self.flightNumber = flightNumber
        self.crewNames = crewNames
        self.remarks = remarks
        
        self.recomputeDerivedHours()
    }
    
    /// Recomputes Multi-Engine, Turbine, Tailwheel, Float, and Ski hours based on aircraft profile and gearConfiguration.
    func recomputeDerivedHours() {
        guard let ac = aircraft else { return }
        
        // Multi-Engine derivation
        if ac.classType.contains("Multi-Engine") {
            self.multiEngineHours = flightTimeHours
        } else {
            self.multiEngineHours = 0.0
        }
        
        // Turbine derivation (Turboprop or Jet)
        if ac.engineType == "Turboprop" || ac.engineType == "Jet" {
            self.turbineHours = flightTimeHours
        } else {
            self.turbineHours = 0.0
        }
        
        // Dynamic Gear attribution for this specific flight
        let gear = gearConfiguration.lowercased()
        if gear.contains("float") || gear.contains("amphib") {
            self.floatHours = flightTimeHours
        } else {
            self.floatHours = 0.0
        }
        
        if gear.contains("tail") || gear.contains("ski") {
            self.tailwheelHours = flightTimeHours
        } else {
            self.tailwheelHours = 0.0
        }
        
        if gear.contains("ski") {
            self.skiHours = flightTimeHours
        } else {
            self.skiHours = 0.0
        }
    }
}
