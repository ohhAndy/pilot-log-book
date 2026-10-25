import Foundation

/// Fast time math utilities for decimal hours and HH:MM formatting.
struct TimeMathService {
    
    /// Converts decimal tenths hours (e.g. 1.8) to hours and minutes (e.g. 1h 48m).
    static func decimalToHoursAndMinutes(_ decimalHours: Double) -> (hours: Int, minutes: Int) {
        let totalMinutes = Int((decimalHours * 60.0).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return (hours, minutes)
    }
    
    /// Formats decimal hours into a friendly string like "1h 48m".
    static func formatHoursAndMinutes(_ decimalHours: Double) -> String {
        let (h, m) = decimalToHoursAndMinutes(decimalHours)
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
    
    /// Converts hours and minutes string (e.g. "1:48" or "1.8") into standard decimal tenths.
    static func parseToDecimalTenths(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // If user typed "1:48"
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            if parts.count == 2, let h = Double(parts[0]), let m = Double(parts[1]) {
                let dec = h + (m / 60.0)
                return (dec * 10).rounded() / 10
            }
        }
        
        // If user typed "1.8"
        if let direct = Double(trimmed) {
            return (direct * 10).rounded() / 10
        }
        
        return nil
    }
    
    /// Safely nudges a decimal hours value by a given delta, rounded to 1 decimal place, minimum 0.0.
    static func nudge(current: Double, delta: Double) -> Double {
        return max(0.0, ((current + delta) * 10.0).rounded() / 10.0)
    }
}
