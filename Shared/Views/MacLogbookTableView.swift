import SwiftUI
import SwiftData

/// Mac-optimized wide multi-column spreadsheet table for log audits and desktop review.
struct MacLogbookTableView: View {
    @Query(sort: \FlightLogEntry.date, order: .reverse) private var flights: [FlightLogEntry]
    
    @State private var searchText: String = ""
    @State private var selectedFlightId: UUID?
    
    var filteredFlights: [FlightLogEntry] {
        if searchText.isEmpty {
            return flights
        }
        let q = searchText.lowercased()
        return flights.filter {
            $0.departureAirport.lowercased().contains(q)
                || $0.arrivalAirport.lowercased().contains(q)
                || ($0.aircraft?.registration.lowercased().contains(q) ?? false)
                || ($0.flightNumber?.lowercased().contains(q) ?? false)
                || ($0.remarks?.lowercased().contains(q) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mac Search & Audit Toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search flights (CYYZ, DH8D, AC123...)", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(filteredFlights.count) flights")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                let total = filteredFlights.reduce(0.0) { $0 + $1.flightTimeHours }
                Text(String(format: "Total: %.1f hrs", total))
                    .font(.headline.bold())
                    .foregroundColor(.cyan)
                    .padding(.leading, 12)
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.10, blue: 0.14))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Spreadsheet Table (10 consolidated columns for SwiftUI TableColumnBuilder compliance)
            Table(filteredFlights, selection: $selectedFlightId) {
                TableColumn("Date") { flight in
                    Text(flight.date, style: .date)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 85, ideal: 95)
                
                TableColumn("Aircraft") { flight in
                    HStack(spacing: 4) {
                        Text(flight.aircraft?.registration ?? "-")
                            .fontWeight(.bold)
                        if let type = flight.aircraft?.typeDesignator {
                            Text("(\(type))")
                                .foregroundColor(.cyan)
                        }
                    }
                }
                .width(min: 110, ideal: 130)
                
                TableColumn("Gear") { flight in
                    Text(flight.gearConfiguration)
                }
                .width(min: 75, ideal: 85)
                
                TableColumn("Route") { flight in
                    Text("\(flight.departureAirport) → \(flight.arrivalAirport)")
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 100, ideal: 120)
                
                TableColumn("Total") { flight in
                    Text(String(format: "%.1f", flight.flightTimeHours))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .width(min: 50, ideal: 60)
                
                TableColumn("Capacity") { flight in
                    if flight.picHours > 0 {
                        Text(String(format: "PIC: %.1f", flight.picHours))
                            .foregroundColor(.cyan)
                    } else if flight.picUSHoures > 0 {
                        Text(String(format: "PIC U/S: %.1f", flight.picUSHoures))
                            .foregroundColor(.purple)
                    } else if flight.sicHours > 0 {
                        Text(String(format: "SIC: %.1f", flight.sicHours))
                            .foregroundColor(.blue)
                    } else if flight.dualHours > 0 {
                        Text(String(format: "Dual: %.1f", flight.dualHours))
                            .foregroundColor(.orange)
                    } else {
                        Text("-")
                    }
                }
                .width(min: 80, ideal: 95)
                
                TableColumn("PF Legs") { flight in
                    Text(flight.isPilotFlying ? "\(flight.legsAsPilotFlying) PF" : "PM")
                        .foregroundColor(flight.isPilotFlying ? .green : .gray)
                }
                .width(min: 60, ideal: 70)
                
                TableColumn("Day / Night") { flight in
                    Text(String(format: "%.1fD / %.1fN", flight.dayHours, flight.nightHours))
                        .foregroundColor(flight.nightHours > 0 ? .indigo : .gray)
                }
                .width(min: 85, ideal: 100)
                
                TableColumn("IFR / Ldg") { flight in
                    Text("\(flight.approachesCount) App / \(flight.dayLandings + flight.nightLandings) Ldg")
                }
                .width(min: 85, ideal: 100)
                
                TableColumn("Remarks") { flight in
                    Text(flight.remarks ?? "")
                        .foregroundColor(.gray)
                }
                .width(min: 120, ideal: 200)
            }
        }
        .background(Color(red: 0.05, green: 0.07, blue: 0.10))
    }
}
