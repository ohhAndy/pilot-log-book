import Foundation
import SwiftData

/// Represents an aircraft in the pilot's fleet.
/// Supports convertible seasonal gear (floats, wheels/tailwheel, skis).
@Model
final class Aircraft {
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var registration: String       // e.g. "C-GJEN", "C-FABC"
    var typeDesignator: String     // e.g. "DH8D", "DHC-2", "C180", "A320", "B738"
    var makeAndModel: String       // e.g. "De Havilland DHC-2 Beaver"
    var category: String           // "Aeroplane", "Helicopter"
    var classType: String          // "Multi-Engine Land", "Single-Engine Land", "Single-Engine Sea", "Multi-Engine Sea"
    var engineType: String         // "Turboprop", "Jet", "Piston"
    
    // Seasonal / Convertible Gear Settings (Standard for Canadian bush & general aviation)
    var defaultGearType: String    // "Floats", "Tailwheel", "Skis", "Tricycle", "Amphibian"
    var isConvertibleGear: Bool = false
    
    // Operational Classifications
    var isTwoCrew: Bool = false    // Multi-crew type certification
    var isHighPerformance: Bool = false
    var isDefault: Bool = false    // Pre-selected for rapid logging
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()   // For Last-Write-Wins (LWW) sync
    
    @Relationship(deleteRule: .nullify, inverse: \FlightLogEntry.aircraft)
    var flights: [FlightLogEntry] = []
    
    init(
        registration: String,
        typeDesignator: String,
        makeAndModel: String,
        category: String = "Aeroplane",
        classType: String = "Multi-Engine Land",
        engineType: String = "Turboprop",
        defaultGearType: String = "Tricycle",
        isConvertibleGear: Bool = false,
        isTwoCrew: Bool = false,
        isHighPerformance: Bool = false,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.registration = registration.uppercased()
        self.typeDesignator = typeDesignator.uppercased()
        self.makeAndModel = makeAndModel
        self.category = category
        self.classType = classType
        self.engineType = engineType
        self.defaultGearType = defaultGearType
        self.isConvertibleGear = isConvertibleGear
        self.isTwoCrew = isTwoCrew
        self.isHighPerformance = isHighPerformance
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
