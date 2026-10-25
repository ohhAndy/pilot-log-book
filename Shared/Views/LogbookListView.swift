import SwiftUI
import SwiftData

/// Chronological logbook view with quick filters, search, and flight detail inspection.
struct LogbookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlightLogEntry.date, order: .reverse) private var flights: [FlightLogEntry]
    
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var showQuickLogSheet: Bool = false
    @State private var selectedFlightForDetail: FlightLogEntry?
    
    let filterOptions = ["All", "PIC", "PIC U/S", "SIC", "PF Only", "Float", "Tailwheel", "Night"]
    
    var filteredFlights: [FlightLogEntry] {
        flights.filter { flight in
            // Search text filter
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = flight.departureAirport.lowercased().contains(query)
                    || flight.arrivalAirport.lowercased().contains(query)
                    || (flight.aircraft?.registration.lowercased().contains(query) ?? false)
                    || (flight.flightNumber?.lowercased().contains(query) ?? false)
                    || (flight.remarks?.lowercased().contains(query) ?? false)
            }
            
            // Category filter
            let matchesCategory: Bool
            switch selectedFilter {
            case "PIC": matchesCategory = flight.picHours > 0
            case "PIC U/S": matchesCategory = flight.picUSHoures > 0
            case "SIC": matchesCategory = flight.sicHours > 0
            case "PF Only": matchesCategory = flight.isPilotFlying
            case "Float": matchesCategory = flight.floatHours > 0
            case "Tailwheel": matchesCategory = flight.tailwheelHours > 0
            case "Night": matchesCategory = flight.nightHours > 0
            default: matchesCategory = true
            }
            
            return matchesSearch && matchesCategory
        }
    }
    
    var totalHours: Double {
        flights.reduce(0.0) { $0 + $1.flightTimeHours }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerTotalsBar
                    filterBar
                    
                    if filteredFlights.isEmpty {
                        emptyStateView
                    } else {
                        flightList
                    }
                }
            }
            .navigationTitle("Personal Log")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showQuickLogSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Log")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.cyan)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search airport, aircraft, flight #...")
            .sheet(isPresented: $showQuickLogSheet) {
                QuickLogView()
            }
            .sheet(item: $selectedFlightForDetail) { flight in
                FlightDetailView(flight: flight)
            }
        }
    }
    
    private var headerTotalsBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL LOGGED HOURS")
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
                Text(String(format: "%.1f HRS", totalHours))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("TOTAL SECTORS")
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
                Text("\(flights.count) LEGS")
                    .font(.title3.bold())
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Text(filter)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.cyan : Color(red: 0.12, green: 0.15, blue: 0.20))
                            .foregroundColor(selectedFilter == filter ? .black : .gray)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var flightList: some View {
        List {
            ForEach(filteredFlights) { flight in
                flightRow(flight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFlightForDetail = flight
                    }
                    .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.16))
                    .listRowSeparatorTint(Color.white.opacity(0.1))
            }
            .onDelete(perform: deleteFlights)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func flightRow(_ flight: FlightLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flight.date, style: .date)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                
                if let flightNo = flight.flightNumber {
                    Text("• \(flightNo)")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Gear Icon if specialized
                if flight.gearConfiguration == "Floats" {
                    Text("🛟 Floats")
                        .font(.caption2.bold())
                        .foregroundColor(.cyan)
                } else if flight.gearConfiguration == "Tailwheel" {
                    Text("🛞 Tailwheel")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                } else if flight.gearConfiguration == "Skis" {
                    Text("🎿 Skis")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                }
                
                Text(String(format: "%.1f hrs", flight.flightTimeHours))
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            HStack {
                // Route
                HStack(spacing: 6) {
                    Text(flight.departureAirport)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Text(flight.arrivalAirport)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Aircraft Registration & Type
                if let ac = flight.aircraft {
                    Text("\(ac.registration) (\(ac.typeDesignator))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // Badges row: Role, PF, Night, Approaches
            HStack(spacing: 6) {
                if flight.picHours > 0 {
                    badge(text: "PIC", color: .cyan)
                } else if flight.picUSHoures > 0 {
                    badge(text: "PIC U/S", color: .purple)
                } else if flight.sicHours > 0 {
                    badge(text: "SIC", color: .blue)
                } else if flight.dualHours > 0 {
                    badge(text: "Dual", color: .orange)
                }
                
                if flight.isPilotFlying {
                    badge(text: "PF", color: .green)
                }
                
                if flight.nightHours > 0 {
                    badge(text: String(format: "Night %.1fh", flight.nightHours), color: .indigo)
                }
                
                if flight.approachesCount > 0 {
                    badge(text: "\(flight.approachesCount) App", color: .teal)
                }
                
                if (flight.dayLandings + flight.nightLandings) > 0 {
                    badge(text: "\(flight.dayLandings + flight.nightLandings) Ldg", color: .gray)
                }
                
                Spacer()
            }
            
            if let rem = flight.remarks, !rem.isEmpty {
                Text(rem)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "airplane.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Flights Found")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("Tap '+ Log Flight' to log your first sector in 10 seconds.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func deleteFlights(at offsets: IndexSet) {
        for index in offsets {
            let flight = filteredFlights[index]
            modelContext.delete(flight)
        }
        try? modelContext.save()
    }
}
