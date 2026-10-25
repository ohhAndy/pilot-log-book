import Foundation

/// Strict validation engine for flight entries ensuring 100% mathematical and data integrity.
struct FlightValidationEngine {
    enum ValidationError: LocalizedError, Equatable {
        case missingAircraft
        case missingDepartureAirport
        case missingArrivalAirport
        case invalidFlightHours(String)
        case dayNightExceedsTotal(day: Double, night: Double, total: Double)
        case capacitiesExceedTotal(sum: Double, total: Double)
        case negativeLandings
        case negativePFLegs
        
        var errorDescription: String? {
            switch self {
            case .missingAircraft:
                return "Please select an aircraft registration."
            case .missingDepartureAirport:
                return "Departure aerodrome (4-letter ICAO/TC) is required."
            case .missingArrivalAirport:
                return "Arrival aerodrome (4-letter ICAO/TC) is required."
            case .invalidFlightHours(let msg):
                return msg
            case .dayNightExceedsTotal(let day, let night, let total):
                return String(format: "Day (%.1f) + Night (%.1f) = %.1f hrs exceeds Total Flight Time (%.1f hrs).", day, night, day + night, total)
            case .capacitiesExceedTotal(let sum, let total):
                return String(format: "Crew capacity hours (%.1f hrs) exceed Total Flight Time (%.1f hrs).", sum, total)
            case .negativeLandings:
                return "Takeoffs and landings cannot be negative."
            case .negativePFLegs:
                return "Number of legs as Pilot Flying cannot be negative."
            }
        }
    }
    
    /// Validates a flight log entry. Returns `.success` or `.failure(ValidationError)`.
    static func validate(
        aircraft: Aircraft?,
        departure: String,
        arrival: String,
        totalHours: Double,
        dayHours: Double,
        nightHours: Double,
        picHours: Double,
        picUSHoures: Double,
        sicHours: Double,
        dualHours: Double,
        instructorHours: Double,
        dayTakeoffs: Int,
        dayLandings: Int,
        nightTakeoffs: Int,
        nightLandings: Int,
        legsAsPilotFlying: Int
    ) -> Result<Void, ValidationError> {
        guard aircraft != nil else {
            return .failure(.missingAircraft)
        }
        
        let dep = departure.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dep.isEmpty else {
            return .failure(.missingDepartureAirport)
        }
        
        let arr = arrival.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !arr.isEmpty else {
            return .failure(.missingArrivalAirport)
        }
        
        guard totalHours > 0.0 else {
            return .failure(.invalidFlightHours("Total flight time must be greater than 0.0 hours."))
        }
        
        if totalHours > 24.0 {
            return .failure(.invalidFlightHours("Single flight time cannot exceed 24.0 hours."))
        }
        
        let epsilon = 0.001
        
        // Check Day + Night
        if (dayHours + nightHours) > (totalHours + epsilon) {
            return .failure(.dayNightExceedsTotal(day: dayHours, night: nightHours, total: totalHours))
        }
        
        // Check Capacities sum
        let capacitySum = picHours + picUSHoures + sicHours + dualHours + instructorHours
        if capacitySum > (totalHours + epsilon) {
            return .failure(.capacitiesExceedTotal(sum: capacitySum, total: totalHours))
        }
        
        // Check Landings/Takeoffs
        if dayTakeoffs < 0 || dayLandings < 0 || nightTakeoffs < 0 || nightLandings < 0 {
            return .failure(.negativeLandings)
        }
        
        if legsAsPilotFlying < 0 {
            return .failure(.negativePFLegs)
        }
        
        return .success(())
    }
}
