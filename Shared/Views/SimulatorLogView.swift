import SwiftUI
import SwiftData

/// Dedicated simulator entry view for Level C/D Full Flight Simulators (FFS) and FTDs.
/// Tracks recurrent checks (PPC / IPC) without requiring real aircraft or route constraints.
struct SimulatorLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SimulatorSession.date, order: .reverse) private var simSessions: [SimulatorSession]
    
    @State private var showAddSimSheet: Bool = false
    
    // Form state
    @State private var sessionDate: Date = Date()
    @State private var deviceLevel: String = "Level D FFS"
    @State private var aircraftType: String = "DH8D"
    @State private var approvalNumber: String = ""
    @State private var trainingFacility: String = "CAE Montreal"
    
    @State private var totalHoursStr: String = "4.0"
    @State private var dualHoursStr: String = "4.0"
    @State private var ifrHoursStr: String = "2.0"
    @State private var approachesCount: Int = 4
    @State private var holdsCount: Int = 1
    
    @State private var isPPC: Bool = true
    @State private var isIPC: Bool = true
    @State private var isRecurrent: Bool = true
    @State private var examinerName: String = ""
    @State private var remarks: String = "Annual Recurrent PPC / Group 1 Renewal"
    
    let deviceLevels = ["Level D FFS", "Level C FFS", "FTD Level 5", "FTD Level 2"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                if simSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Simulator Sessions Logged")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Log recurrent PPC, IPC, or type rating training in certified Level C/D Full Flight Simulators.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button(action: { showAddSimSheet = true }) {
                            Text("Log Simulator Session")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    List {
                        ForEach(simSessions) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(session.date, style: .date)
                                        .font(.caption.bold())
                                        .foregroundColor(.gray)
                                    Text("• \(session.aircraftType) \(session.deviceLevel)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Text(String(format: "%.1f hrs", session.totalHours))
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                }
                                
                                HStack(spacing: 8) {
                                    if session.isPPC {
                                        simBadge("PPC Passed", color: .green)
                                    }
                                    if session.isIPC {
                                        simBadge("IPC Recency", color: .blue)
                                    }
                                    simBadge("\(session.approachesCount) Apps", color: .teal)
                                }
                                
                                if let facility = session.trainingFacility {
                                    Text(facility)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                if let rem = session.remarks {
                                    Text(rem)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .italic()
                                }
                            }
                            .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.16))
                        }
                        .onDelete(perform: deleteSessions)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Simulator Training")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSimSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showAddSimSheet) {
                addSimSessionModal
            }
        }
    }
    
    private func simBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private var addSimSessionModal: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    DatePicker("Date", selection: $sessionDate, displayedComponents: .date)
                    Picker("Device Level", selection: $deviceLevel) {
                        ForEach(deviceLevels, id: \.self) { Text($0) }
                    }
                    TextField("Aircraft Type (e.g. DH8D, B738)", text: $aircraftType)
                        .textInputAutocapitalization(.characters)
                    TextField("TC Device Approval ID (e.g. TC-412)", text: $approvalNumber)
                    TextField("Facility (e.g. CAE Montreal)", text: $trainingFacility)
                }
                
                Section("Recurrent Checks & Ratings") {
                    Toggle("Pilot Proficiency Check (PPC)", isOn: $isPPC)
                    Toggle("Instrument Proficiency Check (IPC)", isOn: $isIPC)
                    Toggle("Recurrent Training", isOn: $isRecurrent)
                    TextField("Examiner / Instructor Name", text: $examinerName)
                }
                
                Section("Hours & Instrument Practice") {
                    TextField("Total Session Hours (e.g. 4.0)", text: $totalHoursStr)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Simulated IFR Hours (e.g. 2.5)", text: $ifrHoursStr)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Stepper("Approaches: \(approachesCount)", value: $approachesCount, in: 0...20)
                    Stepper("Holds: \(holdsCount)", value: $holdsCount, in: 0...10)
                }
                
                Section("Remarks") {
                    TextField("Remarks / Exercises Completed", text: $remarks)
                }
            }
            .navigationTitle("Log Simulator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSimSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSimSession()
                    }
                }
            }
        }
    }
    
    private func saveSimSession() {
        let total = Double(totalHoursStr) ?? 0.0
        let ifr = Double(ifrHoursStr) ?? 0.0
        let dual = Double(dualHoursStr) ?? total
        
        let session = SimulatorSession(
            date: sessionDate,
            deviceLevel: deviceLevel,
            aircraftType: aircraftType,
            approvalNumber: approvalNumber.isEmpty ? nil : approvalNumber,
            trainingFacility: trainingFacility.isEmpty ? nil : trainingFacility,
            isPPC: isPPC,
            isIPC: isIPC,
            isRecurrent: isRecurrent,
            totalHours: total,
            dualHours: dual,
            ifrSimulatedHours: ifr,
            approachesCount: approachesCount,
            holdsCount: holdsCount,
            instructorOrExaminer: examinerName.isEmpty ? nil : examinerName,
            remarks: remarks.isEmpty ? nil : remarks
        )
        
        modelContext.insert(session)
        try? modelContext.save()
        showAddSimSheet = false
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = simSessions[index]
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}
