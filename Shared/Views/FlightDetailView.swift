import SwiftUI
import SwiftData

/// Detailed inspection and editor for an individual flight log record.
struct FlightDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var flight: FlightLogEntry
    
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        routeHeaderCard
                        hoursSummaryCard
                        capacityCard
                        pilotFlyingCard
                        conditionsAndGearCard
                        landingsAndApproachesCard
                        if let remarks = flight.remarks, !remarks.isEmpty {
                            remarksCard(remarks)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Flight Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cyan)
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog(
                "Delete Flight?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(flight)
                    try? modelContext.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This flight will be permanently removed from your personal log.")
            }
        }
    }
    
    // MARK: - Cards
    
    private var routeHeaderCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(flight.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                if let flightNo = flight.flightNumber {
                    Text(flightNo)
                        .font(.headline.bold())
                        .foregroundColor(.cyan)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.departureAirport)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if let info = AirportDirectoryService.lookup(code: flight.departureAirport) {
                        Text(info.city)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.arrivalAirport)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if let info = AirportDirectoryService.lookup(code: flight.arrivalAirport) {
                        Text(info.city)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                if let ac = flight.aircraft {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .foregroundColor(.cyan)
                        Text(ac.registration)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("• \(ac.typeDesignator)")
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(flight.gearConfiguration)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .foregroundColor(.cyan)
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
    
    private var hoursSummaryCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL TIME")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                Text(String(format: "%.1f HRS", flight.flightTimeHours))
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text(TimeMathService.formatHoursAndMinutes(flight.flightTimeHours))
                    .font(.caption2)
                    .foregroundColor(.cyan)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("Day:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.1fh", flight.dayHours))
                        .foregroundColor(.white)
                        .bold()
                }
                HStack {
                    Text("Night:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.1fh", flight.nightHours))
                        .foregroundColor(.indigo)
                        .bold()
                }
                if flight.isCrossCountry {
                    Text("Cross Country (XC)")
                        .font(.caption2.bold())
                        .foregroundColor(.cyan)
                }
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
    
    private var capacityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CAR 401.08 CREW CAPACITY")
                .font(.caption.bold())
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                capacityPill(title: "PIC", hours: flight.picHours, activeColor: .cyan)
                capacityPill(title: "PIC U/S", hours: flight.picUSHoures, activeColor: .purple)
                capacityPill(title: "SIC", hours: flight.sicHours, activeColor: .blue)
                capacityPill(title: "Dual", hours: flight.dualHours, activeColor: .orange)
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
    
    private func capacityPill(title: String, hours: Double, activeColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(hours > 0 ? activeColor : .gray)
            Text(String(format: "%.1f", hours))
                .font(.headline.bold())
                .foregroundColor(hours > 0 ? .white : .gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(hours > 0 ? activeColor.opacity(0.15) : Color(red: 0.08, green: 0.10, blue: 0.14))
        .cornerRadius(8)
    }
    
    private var pilotFlyingCard: some View {
        HStack {
            Image(systemName: flight.isPilotFlying ? "airplane.departure" : "headphones")
                .font(.title2)
                .foregroundColor(flight.isPilotFlying ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.isPilotFlying ? "Pilot Flying (PF)" : "Pilot Monitoring (PM)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text("\(flight.legsAsPilotFlying) leg\(flight.legsAsPilotFlying > 1 ? "s" : "") credited")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if flight.isPilotFlying {
                Text("PF: \(flight.legsAsPilotFlying)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
    
    private var conditionsAndGearCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AUTOMATIC ATTRIBUTIONS")
                .font(.caption.bold())
                .foregroundColor(.gray)
            
            HStack(spacing: 10) {
                attributionTile(title: "Multi-Engine", hours: flight.multiEngineHours)
                attributionTile(title: "Turbine", hours: flight.turbineHours)
                attributionTile(title: "Tailwheel", hours: flight.tailwheelHours)
                attributionTile(title: "Floatplane", hours: flight.floatHours)
            }
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
    
    private func attributionTile(title: String, hours: Double) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(String(format: "%.1fh", hours))
                .font(.subheadline.bold())
                .foregroundColor(hours > 0 ? .cyan : .gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .cornerRadius(6)
    }
    
    private var landingsAndApproachesCard: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
                Text("Day Ldg: \(flight.dayLandings)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                Text("Night Ldg: \(flight.nightLandings)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            
            HStack {
                Image(systemName: "gauge.with.needle")
                    .foregroundColor(.teal)
                Text("Apps: \(flight.approachesCount)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(10)
    }
    
    private func remarksCard(_ remarks: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("REMARKS")
                .font(.caption.bold())
                .foregroundColor(.gray)
            Text(remarks)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
}
