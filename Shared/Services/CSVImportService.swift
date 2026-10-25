import Foundation
import SwiftData

/// Robust, flexible CSV importer supporting ForeFlight, LogTen Pro, and custom pilot spreadsheets.
struct CSVImportService {
    struct ImportSummary {
        let totalRowsParsed: Int
        let successfulImports: Int
        let skippedRows: Int
        let newAircraftCreated: Int
        let errors: [String]
    }
    
    /// Parses and imports CSV text into SwiftData.
    static func importCSV(
        content: String,
        context: ModelContext,
        existingAircraft: [Aircraft]
    ) -> ImportSummary {
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else {
            return ImportSummary(totalRowsParsed: 0, successfulImports: 0, skippedRows: 0, newAircraftCreated: 0, errors: ["CSV file is empty or missing headers."])
        }
        
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        // Map column indexes
        let dateIdx = findIndex(in: headers, keywords: ["date", "flight_date", "flight date"])
        let regIdx = findIndex(in: headers, keywords: ["registration", "aircraft", "tail", "aircraftid", "ident"])
        let typeIdx = findIndex(in: headers, keywords: ["type", "model", "aircraft_type", "type_designator"])
        let depIdx = findIndex(in: headers, keywords: ["departure", "from", "dep", "origin", "orig"])
        let arrIdx = findIndex(in: headers, keywords: ["arrival", "to", "arr", "dest", "destination"])
        let totalIdx = findIndex(in: headers, keywords: ["total", "total_time", "flight_time", "duration", "hours", "totaltime"])
        let picIdx = findIndex(in: headers, keywords: ["pic", "pilot_in_command", "pilot in command"])
        let picUSIdx = findIndex(in: headers, keywords: ["picus", "pic_us", "pic u/s"])
        let sicIdx = findIndex(in: headers, keywords: ["sic", "copilot", "co_pilot", "second_in_command"])
        let dualIdx = findIndex(in: headers, keywords: ["dual", "dual_received", "instruction_received"])
        let dayIdx = findIndex(in: headers, keywords: ["day", "day_time", "dayhours"])
        let nightIdx = findIndex(in: headers, keywords: ["night", "night_time", "nighthours"])
        let ifrIdx = findIndex(in: headers, keywords: ["actual_ifr", "ifr", "instrument", "actual"])
        let dayLdgIdx = findIndex(in: headers, keywords: ["day_landings", "day_ldg", "landings_day"])
        let nightLdgIdx = findIndex(in: headers, keywords: ["night_landings", "night_ldg", "landings_night"])
        let totalLdgIdx = findIndex(in: headers, keywords: ["landings", "ldg", "total_landings"])
        let appIdx = findIndex(in: headers, keywords: ["approaches", "app", "ifr_approaches"])
        let pfIdx = findIndex(in: headers, keywords: ["pf", "pilot_flying", "legs_pf"])
        let remarksIdx = findIndex(in: headers, keywords: ["remarks", "comments", "notes"])
        
        var aircraftMap: [String: Aircraft] = [:]
        for ac in existingAircraft {
            aircraftMap[ac.registration.uppercased()] = ac
        }
        
        var importedCount = 0
        var skippedCount = 0
        var newAcCount = 0
        var errors: [String] = []
        
        // Date formatters
        let formatters: [DateFormatter] = [
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "dd/MM/yyyy"),
            createDateFormatter(format: "yyyy/MM/dd"),
            createDateFormatter(format: "dd-MM-yyyy")
        ]
        
        for (lineNum, line) in lines.dropFirst().enumerated() {
            let row = parseCSVLine(line)
            guard row.count > 1 else {
                skippedCount += 1
                continue
            }
            
            // 1. Parse Date
            let dateStr = getValue(from: row, at: dateIdx)
            var flightDate = Date()
            var dateMatched = false
            for fmt in formatters {
                if let d = fmt.date(from: dateStr) {
                    flightDate = d
                    dateMatched = true
                    break
                }
            }
            if !dateMatched && !dateStr.isEmpty {
                // If date cannot be parsed, use today but note warning
                flightDate = Date()
            }
            
            // 2. Parse Route
            let dep = getValue(from: row, at: depIdx).uppercased()
            let arr = getValue(from: row, at: arrIdx).uppercased()
            
            // 3. Parse Total Hours
            let totalStr = getValue(from: row, at: totalIdx)
            guard let total = TimeMathService.parseToDecimalTenths(totalStr), total > 0.0 else {
                skippedCount += 1
                continue
            }
            
            // 4. Resolve Aircraft
            let reg = getValue(from: row, at: regIdx).uppercased()
            let type = getValue(from: row, at: typeIdx).uppercased()
            
            var matchedAircraft: Aircraft? = nil
            if !reg.isEmpty {
                if let existing = aircraftMap[reg] {
                    matchedAircraft = existing
                } else {
                    let newAc = Aircraft(
                        registration: reg,
                        typeDesignator: type.isEmpty ? "UNKNOWN" : type,
                        makeAndModel: type.isEmpty ? reg : type,
                        classType: "Multi-Engine Land",
                        engineType: "Turboprop",
                        defaultGearType: "Tricycle"
                    )
                    context.insert(newAc)
                    aircraftMap[reg] = newAc
                    matchedAircraft = newAc
                    newAcCount += 1
                }
            }
            
            // 5. Parse Hours & Capacities
            let pic = TimeMathService.parseToDecimalTenths(getValue(from: row, at: picIdx)) ?? 0.0
            let picUS = TimeMathService.parseToDecimalTenths(getValue(from: row, at: picUSIdx)) ?? 0.0
            let sic = TimeMathService.parseToDecimalTenths(getValue(from: row, at: sicIdx)) ?? 0.0
            let dual = TimeMathService.parseToDecimalTenths(getValue(from: row, at: dualIdx)) ?? 0.0
            
            let night = TimeMathService.parseToDecimalTenths(getValue(from: row, at: nightIdx)) ?? 0.0
            let day = total >= night ? (total - night) : total
            let ifr = TimeMathService.parseToDecimalTenths(getValue(from: row, at: ifrIdx)) ?? 0.0
            
            // 6. Parse Landings & Approaches
            let dayLdg = Int(getValue(from: row, at: dayLdgIdx)) ?? 0
            let nightLdg = Int(getValue(from: row, at: nightLdgIdx)) ?? 0
            let totalLdg = Int(getValue(from: row, at: totalLdgIdx)) ?? (dayLdg + nightLdg)
            let apps = Int(getValue(from: row, at: appIdx)) ?? 0
            
            let pf = Int(getValue(from: row, at: pfIdx)) ?? 1
            let remarks = getValue(from: row, at: remarksIdx)
            
            let entry = FlightLogEntry(
                date: flightDate,
                aircraft: matchedAircraft,
                gearConfiguration: matchedAircraft?.defaultGearType ?? "Tricycle",
                departureAirport: dep.isEmpty ? "CYYZ" : dep,
                arrivalAirport: arr.isEmpty ? "CYUL" : arr,
                isCrossCountry: (dep != arr && !dep.isEmpty && !arr.isEmpty),
                flightTimeHours: total,
                picHours: pic > 0 ? pic : (picUS == 0 && sic == 0 && dual == 0 ? total : 0.0),
                picUSHoures: picUS,
                sicHours: sic,
                dualHours: dual,
                instructorHours: 0.0,
                isPilotFlying: pf > 0,
                legsAsPilotFlying: max(0, pf),
                dayHours: (day * 10).rounded() / 10,
                nightHours: (night * 10).rounded() / 10,
                actualIFRHours: ifr,
                dayLandings: dayLdg > 0 ? dayLdg : (totalLdg - nightLdg),
                nightLandings: nightLdg,
                dayTakeoffs: max(1, dayLdg),
                nightTakeoffs: nightLdg,
                approachesCount: apps,
                remarks: remarks.isEmpty ? nil : remarks
            )
            
            context.insert(entry)
            importedCount += 1
        }
        
        try? context.save()
        
        return ImportSummary(
            totalRowsParsed: lines.count - 1,
            successfulImports: importedCount,
            skippedRows: skippedCount,
            newAircraftCreated: newAcCount,
            errors: errors
        )
    }
    
    // MARK: - Helpers
    
    private static func findIndex(in headers: [String], keywords: [String]) -> Int? {
        for (index, header) in headers.enumerated() {
            let clean = header.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
            for kw in keywords {
                if clean == kw || clean.contains(kw) {
                    return index
                }
            }
        }
        return nil
    }
    
    private static func getValue(from row: [String], at index: Int?) -> String {
        guard let idx = index, idx < row.count else { return "" }
        return row[idx].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
    }
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var results: [String] = []
        var insideQuotes = false
        var currentToken = ""
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                results.append(currentToken)
                currentToken = ""
            } else {
                currentToken.append(char)
            }
        }
        results.append(currentToken)
        return results
    }
    
    private static func createDateFormatter(format: String) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        return fmt
    }
}
