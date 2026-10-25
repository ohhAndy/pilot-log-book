import SwiftUI
import SwiftData

/// Transport Canada CARs Compliance & Currency Dashboard.
/// Visualizes CAR 700.27 rolling duty meters, CAR 421.34(4) ATPL audit, and CAR 401.05 recency.
struct CARsDashboardView: View {
    @Query(sort: \FlightLogEntry.date, order: .reverse) private var flights: [FlightLogEntry]
    @Query private var simulators: [SimulatorSession]
    @Query private var profiles: [PilotProfile]
    
    @State private var selectedAuditTab: Int = 0 // 0: CAR 700.27 Duty, 1: ATPL Audit, 2: Recency
    
    var profile: PilotProfile {
        profiles.first ?? PilotProfile()
    }
    
    var limits: CARsRecencyEngine.FlightTimeLimits {
        CARsRecencyEngine.calculateFlightTimeLimits(flights: flights)
    }
    
    var atplAudit: CARsRecencyEngine.ATPLAudit {
        CARsRecencyEngine.calculateATPLAudit(flights: flights, simulators: simulators)
    }
    
    var recency: CARsRecencyEngine.RecencyStatus {
        CARsRecencyEngine.calculateRecencyStatus(flights: flights, simulators: simulators)
    }
    
    var medical: CARsRecencyEngine.MedicalStatus {
        CARsRecencyEngine.calculateMedicalStatus(profile: profile)
    }
    
    var pfMetrics: CARsRecencyEngine.PFMetrics {
        CARsRecencyEngine.calculatePFMetrics(flights: flights)
    }
    
    var gearTotals: CARsRecencyEngine.GearTotals {
        CARsRecencyEngine.calculateGearTotals(flights: flights)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        medicalBannerCard
                        car70027Section
                        atplAuditSection
                        recencyCardsSection
                        operationalSummarySection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("CARs Compliance")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    // MARK: - Medical Banner
    
    private var medicalBannerCard: some View {
        HStack {
            Image(systemName: medical.isValid ? "cross.case.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(medical.isValid ? (medical.isExpiringSoon ? .orange : .cyan) : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Category 1 Medical (CAR 404.04)")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                Text(medical.statusText)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(medical.expiryDate, style: .date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(medical.isExpiringSoon ? Color.orange : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - CAR 700.27 Commercial Flight Time Limits
    
    private var car70027Section: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CAR 700.27 FLIGHT TIME LIMITS")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                Spacer()
                Text("Commercial Part VII")
                    .font(.caption2)
                    .foregroundColor(.cyan)
            }
            
            VStack(spacing: 12) {
                limitMeterRow(
                    title: "28 Consecutive Days",
                    current: limits.hours28Days,
                    limit: limits.limit28Days,
                    percent: limits.percent28Days,
                    buffer: limits.buffer28Days,
                    isExceeded: limits.is28DaysExceeded
                )
                
                limitMeterRow(
                    title: "90 Consecutive Days",
                    current: limits.hours90Days,
                    limit: limits.limit90Days,
                    percent: limits.percent90Days,
                    buffer: limits.buffer90Days,
                    isExceeded: limits.is90DaysExceeded
                )
                
                limitMeterRow(
                    title: "365 Consecutive Days",
                    current: limits.hours365Days,
                    limit: limits.limit365Days,
                    percent: limits.percent365Days,
                    buffer: limits.buffer365Days,
                    isExceeded: limits.is365DaysExceeded
                )
            }
            .padding(14)
            .background(Color(red: 0.12, green: 0.15, blue: 0.20))
            .cornerRadius(12)
        }
    }
    
    private func limitMeterRow(
        title: String,
        current: Double,
        limit: Double,
        percent: Double,
        buffer: Double,
        isExceeded: Bool
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.1f / %.0f hrs", current, limit))
                    .font(.subheadline.bold())
                    .foregroundColor(isExceeded ? .red : (percent > 0.8 ? .orange : .white))
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isExceeded ? Color.red : (percent > 0.8 ? Color.orange : Color.cyan))
                        .frame(width: geo.size.width * CGFloat(min(1.0, percent)), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(String(format: "%.1f hrs buffer remaining", buffer))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.0f%%", percent * 100))
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - CAR 421.34(4) ATPL Audit Section
    
    private var atplAuditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CAR 421.34(4) ATPL(A) AUDIT")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                Spacer()
                if atplAudit.isFullyQualified {
                    Text("✓ QUALIFIED")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                } else {
                    Text("IN PROGRESS")
                        .font(.caption2.bold())
                        .foregroundColor(.cyan)
                }
            }
            
            VStack(spacing: 10) {
                auditRow(
                    title: "Total Flight Time (Aeroplanes)",
                    current: atplAudit.totalFlightTime,
                    required: atplAudit.reqTotal,
                    isMet: atplAudit.isTotalMet,
                    subtitle: "\(String(format: "%.1f", atplAudit.aeroplaneFlightTime)) / 900.0 in aeroplanes"
                )
                
                auditRow(
                    title: "PIC Credited (CAR 421.11 / 421.34)",
                    current: atplAudit.picCredited,
                    required: atplAudit.reqPIC,
                    isMet: atplAudit.isPICMet,
                    subtitle: "Raw PIC: \(String(format: "%.1f", atplAudit.picHoursRaw))h + PIC U/S: \(String(format: "%.1f", atplAudit.picUSHouresRaw))h (max 100h credit)"
                )
                
                auditRow(
                    title: "PIC Cross-Country",
                    current: atplAudit.picXCHours,
                    required: atplAudit.reqPICXC,
                    isMet: atplAudit.picXCHours >= atplAudit.reqPICXC,
                    subtitle: "Min 100.0 hrs PIC XC"
                )
                
                auditRow(
                    title: "Night Flight Time",
                    current: atplAudit.totalNightHours,
                    required: atplAudit.reqTotalNight,
                    isMet: atplAudit.isNightMet,
                    subtitle: "PIC Night: \(String(format: "%.1f", atplAudit.picNightHours)) / 25.0 req"
                )
                
                auditRow(
                    title: "Instrument Time (Actual + Sim)",
                    current: atplAudit.instrumentHoursCredited,
                    required: atplAudit.reqInstrument,
                    isMet: atplAudit.isInstrumentMet,
                    subtitle: "Max 25.0 hrs approved simulator credit"
                )
            }
            .padding(14)
            .background(Color(red: 0.12, green: 0.15, blue: 0.20))
            .cornerRadius(12)
        }
    }
    
    private func auditRow(
        title: String,
        current: Double,
        required: Double,
        isMet: Bool,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isMet ? .green : .gray)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.1f / %.0f hrs", current, required))
                    .font(.subheadline.bold())
                    .foregroundColor(isMet ? .green : .cyan)
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.leading, 24)
        }
    }
    
    // MARK: - CAR 401.05 Recency Cards
    
    private var recencyCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CAR 401.05 RECENCY STATUS (6 MONTHS)")
                .font(.caption.bold())
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                // Passenger Currency Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(recency.isDayPassengerCurrent ? .cyan : .orange)
                        Text("Passenger")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    Text(recency.isDayPassengerCurrent ? "CURRENT" : "LAPSING")
                        .font(.headline.bold())
                        .foregroundColor(recency.isDayPassengerCurrent ? .green : .orange)
                    Text("\(recency.dayLandings6Mo) Day / \(recency.nightLandings6Mo) Night Ldgs")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                .cornerRadius(10)
                
                // IFR Currency Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "gauge.with.needle")
                            .foregroundColor(recency.isIFRCurrent6Mo ? .cyan : .orange)
                        Text("IFR 6-6-6")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    Text(recency.isIFRCurrent6Mo ? "CURRENT" : "PPC / REQ")
                        .font(.headline.bold())
                        .foregroundColor(recency.isIFRCurrent6Mo ? .green : .orange)
                    Text(String(format: "%.1fh IFR / %d Apps", recency.ifrHours6Mo, recency.approaches6Mo))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Operational Summary (PF & Specialized Gear)
    
    private var operationalSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPERATIONAL & GEAR TOTALS")
                .font(.caption.bold())
                .foregroundColor(.gray)
            
            HStack(spacing: 10) {
                summaryTile(title: "Pilot Flying", value: "\(pfMetrics.legsPF) legs", subtitle: String(format: "%.0f%% PF", pfMetrics.percentPF))
                summaryTile(title: "Tailwheel", value: String(format: "%.1fh", gearTotals.tailwheelHours), subtitle: "Bush gear")
                summaryTile(title: "Floatplane", value: String(format: "%.1fh", gearTotals.floatHours), subtitle: "Seaplane")
                summaryTile(title: "Skis", value: String(format: "%.1fh", gearTotals.skiHours), subtitle: "Winter")
            }
        }
    }
    
    private func summaryTile(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.cyan)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(8)
    }
}
