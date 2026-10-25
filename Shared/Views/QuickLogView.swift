import SwiftUI
import SwiftData

/// Fast cockpit quick-entry form for pilots.
/// Pure hours-based logging with instant role allocation, complementary day/night math,
/// and convertible gear configuration overrides.
struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Aircraft.registration) private var aircraftList: [Aircraft]
    
    // Form State
    @State private var selectedDate: Date = Date()
    @State private var selectedAircraft: Aircraft?
    @State private var selectedGear: String = "Tricycle"
    
    @State private var departureCode: String = ""
    @State private var arrivalCode: String = ""
    @State private var isCrossCountry: Bool = true
    
    @State private var totalHoursString: String = ""
    @State private var selectedCapacity: String = "PIC" // PIC, PIC U/S, SIC, Dual, Instructor
    
    @State private var isPilotFlying: Bool = true
    @State private var legsAsPF: Int = 1
    
    // Day/Night Split
    @State private var dayNightMode: String = "All Day" // "All Day", "All Night", "Split"
    @State private var dayHoursString: String = ""
    @State private var nightHoursString: String = ""
    
    @State private var showingDepPicker: Bool = false
    @State private var showingArrPicker: Bool = false
    
    // Landings & Approaches
    @State private var dayLandings: Int = 1
    @State private var nightLandings: Int = 0
    @State private var approachesCount: Int = 0
    
    // Optional Details
    @State private var flightNumber: String = ""
    @State private var crewNames: String = ""
    @State private var remarks: String = ""
    
    // Validation Alert State
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var showSuccessBanner: Bool = false
    
    let gearOptions = ["Tricycle", "Tailwheel", "Floats", "Skis", "Amphibian"]
    let capacityOptions = ["PIC", "PIC U/S", "SIC", "Dual"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        aircraftAndGearSection
                        routeSection
                        hoursAndCapacitySection
                        pilotFlyingSection
                        dayNightSplitSection
                        landingsAndApproachesSection
                        optionalDetailsSection
                        saveActionsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Quick Log")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFlight(continueToNextLeg: false)
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                }
            }
            .sheet(isPresented: $showingDepPicker) {
                AirportPickerSheet(title: "Select Departure") { code in
                    departureCode = code
                    updateXCStatus()
                }
            }
            .sheet(isPresented: $showingArrPicker) {
                AirportPickerSheet(title: "Select Arrival") { code in
                    arrivalCode = code
                    updateXCStatus()
                }
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Please check required fields.")
            }
            .onAppear {
                setupDefaults()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            DatePicker(
                "Flight Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .colorScheme(.dark)
            
            Spacer()
            
            Text("Transport Canada CAR 401.08")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private var aircraftAndGearSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AIRCRAFT & CONFIGURATION")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                // Aircraft Picker
                Menu {
                    ForEach(aircraftList) { ac in
                        Button(action: {
                            selectedAircraft = ac
                            selectedGear = ac.defaultGearType
                        }) {
                            Text("\(ac.registration) • \(ac.typeDesignator)")
                        }
                    }
                    if aircraftList.isEmpty {
                        Text("No aircraft registered")
                    }
                } label: {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.cyan)
                        Text(selectedAircraft?.registration ?? "Select Aircraft")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        if let ac = selectedAircraft {
                            Text("• \(ac.typeDesignator)")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(10)
                }
                
                // Gear Configuration Picker
                Menu {
                    ForEach(gearOptions, id: \.self) { gear in
                        Button(action: { selectedGear = gear }) {
                            Text(gearTitle(gear))
                        }
                    }
                } label: {
                    HStack {
                        Text(gearIcon(selectedGear))
                        Text(selectedGear)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ROUTE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        ZStack(alignment: .leading) {
                            if departureCode.isEmpty {
                                Text("CYYZ")
                                    .font(.title3.bold())
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            TextField("", text: $departureCode)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.characters)
                                .onChange(of: departureCode) { _, _ in updateXCStatus() }
                        }
                        
                        Button(action: { showingDepPicker = true }) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption.bold())
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(8)
                    
                    if let depInfo = AirportDirectoryService.lookup(code: departureCode) {
                        Text(depInfo.name)
                            .font(.caption2)
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                    }
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                    .padding(.top, -10)
                
                // Arrival
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        ZStack(alignment: .leading) {
                            if arrivalCode.isEmpty {
                                Text("CYUL")
                                    .font(.title3.bold())
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            TextField("", text: $arrivalCode)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.characters)
                                .onChange(of: arrivalCode) { _, _ in updateXCStatus() }
                        }
                        
                        Button(action: { showingArrPicker = true }) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption.bold())
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(8)
                    
                    if let arrInfo = AirportDirectoryService.lookup(code: arrivalCode) {
                        Text(arrInfo.name)
                            .font(.caption2)
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                    }
                }
            }
            
            // Cross Country Toggle
            Toggle(isOn: $isCrossCountry) {
                HStack(spacing: 6) {
                    Image(systemName: "map")
                        .foregroundColor(isCrossCountry ? .cyan : .gray)
                    Text("Cross Country (XC)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .tint(.cyan)
            .padding(.top, 4)
        }
    }
    
    private var hoursAndCapacitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
                // Total Hours
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL HOURS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack {
                        ZStack(alignment: .leading) {
                            if totalHoursString.isEmpty {
                                Text("0.0")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            TextField("", text: $totalHoursString)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .onChange(of: totalHoursString) { _, _ in
                                    handleTotalHoursChanged()
                                }
                        }
                        
                        Text("HRS")
                            .font(.caption.bold())
                            .foregroundColor(.cyan)
                            .padding(.top, 14)
                    }
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(10)
                    
                    // Quick Nudge Buttons for Cockpit Speed
                    HStack(spacing: 6) {
                        nudgeButton("-0.1", delta: -0.1)
                        nudgeButton("+0.1", delta: 0.1)
                        nudgeButton("+0.5", delta: 0.5)
                        nudgeButton("+1.0", delta: 1.0)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Capacity Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("CAPACITY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(capacityOptions, id: \.self) { cap in
                            Button(action: { selectedCapacity = cap }) {
                                Text(cap)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedCapacity == cap ? Color.cyan : Color(red: 0.12, green: 0.15, blue: 0.20))
                                    .foregroundColor(selectedCapacity == cap ? .black : .white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var pilotFlyingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CREW DUTY ROLE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Spacer()
                if isPilotFlying {
                    Text("\(legsAsPF) leg\(legsAsPF > 1 ? "s" : "") as PF")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 12) {
                // PF Toggle
                Button(action: {
                    isPilotFlying = true
                    if legsAsPF == 0 { legsAsPF = 1 }
                    triggerHaptic()
                }) {
                    HStack {
                        Image(systemName: "airplane.departure")
                        Text("Pilot Flying (PF)")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPilotFlying ? Color.cyan : Color(red: 0.12, green: 0.15, blue: 0.20))
                    .foregroundColor(isPilotFlying ? .black : .white)
                    .cornerRadius(10)
                }
                
                // PM Toggle
                Button(action: {
                    isPilotFlying = false
                    legsAsPF = 0
                    triggerHaptic()
                }) {
                    HStack {
                        Image(systemName: "headphones")
                        Text("Pilot Monitoring")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(!isPilotFlying ? Color.cyan.opacity(0.8) : Color(red: 0.12, green: 0.15, blue: 0.20))
                    .foregroundColor(!isPilotFlying ? .black : .white)
                    .cornerRadius(10)
                }
            }
            
            // Dedicated unsquished stepper row for PF legs
            if isPilotFlying {
                HStack {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(.green)
                    Text("Number of Legs as PF:")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if legsAsPF > 1 {
                                legsAsPF -= 1
                                triggerHaptic()
                            }
                        }) {
                            Image(systemName: "minus")
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 0.18, green: 0.22, blue: 0.28))
                                .cornerRadius(6)
                        }
                        
                        Text("\(legsAsPF)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(minWidth: 28)
                        
                        Button(action: {
                            legsAsPF += 1
                            triggerHaptic()
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 0.18, green: 0.22, blue: 0.28))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(10)
                .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                .cornerRadius(8)
            }
        }
    }
    
    private var dayNightSplitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DAY / NIGHT SPLIT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Mode presets
                HStack(spacing: 6) {
                    presetButton(title: "☀️ All Day", mode: "All Day")
                    presetButton(title: "🌙 All Night", mode: "All Night")
                    presetButton(title: "🌓 Split", mode: "Split")
                }
            }
            
            if dayNightMode == "Split" {
                HStack(spacing: 16) {
                    HStack {
                        Text("Day:")
                            .foregroundColor(.gray)
                        ZStack(alignment: .leading) {
                            if dayHoursString.isEmpty {
                                Text("0.0")
                                    .foregroundColor(.white.opacity(0.35))
                                    .bold()
                            }
                            TextField("", text: $dayHoursString)
                                .foregroundColor(.white)
                                .bold()
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .onChange(of: dayHoursString) { _, newDay in
                                    recomputeFromDay(newDay)
                                }
                        }
                    }
                    .padding(8)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Night:")
                            .foregroundColor(.gray)
                        ZStack(alignment: .leading) {
                            if nightHoursString.isEmpty {
                                Text("0.0")
                                    .foregroundColor(.white.opacity(0.35))
                                    .bold()
                            }
                            TextField("", text: $nightHoursString)
                                .foregroundColor(.white)
                                .bold()
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                                .onChange(of: nightHoursString) { _, newNight in
                                    recomputeFromNight(newNight)
                                }
                        }
                    }
                    .padding(8)
                    .background(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func nudgeButton(_ title: String, delta: Double) -> some View {
        Button(action: {
            let current = Double(totalHoursString) ?? 0.0
            let newTotal = TimeMathService.nudge(current: current, delta: delta)
            totalHoursString = String(format: "%.1f", newTotal)
            handleTotalHoursChanged()
            triggerHaptic()
        }) {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(red: 0.15, green: 0.18, blue: 0.24))
                .foregroundColor(.cyan)
                .cornerRadius(6)
        }
    }
    
    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
    
    private func presetButton(title: String, mode: String) -> some View {
        Button(action: {
            dayNightMode = mode
            if let _ = Double(totalHoursString) {
                if mode == "All Day" {
                    dayHoursString = totalHoursString
                    nightHoursString = "0.0"
                } else if mode == "All Night" {
                    dayHoursString = "0.0"
                    nightHoursString = totalHoursString
                }
            } else {
                dayHoursString = ""
                nightHoursString = ""
            }
        }) {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(dayNightMode == mode ? Color.cyan : Color(red: 0.12, green: 0.15, blue: 0.20))
                .foregroundColor(dayNightMode == mode ? .black : .gray)
                .cornerRadius(6)
        }
    }
    
    private var landingsAndApproachesSection: some View {
        VStack(spacing: 8) {
            stepperRow(title: "Day Landings", icon: "sun.max.fill", value: $dayLandings)
            stepperRow(title: "Night Landings", icon: "moon.fill", value: $nightLandings)
            stepperRow(title: "IFR Approaches (CAR 401.05)", icon: "gauge.with.needle", value: $approachesCount)
        }
    }
    
    private func stepperRow(title: String, icon: String, value: Binding<Int>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { if value.wrappedValue > 0 { value.wrappedValue -= 1 } }) {
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(red: 0.15, green: 0.18, blue: 0.24))
                        .cornerRadius(6)
                }
                
                Text("\(value.wrappedValue)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(minWidth: 20)
                
                Button(action: { value.wrappedValue += 1 }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(red: 0.15, green: 0.18, blue: 0.24))
                        .cornerRadius(6)
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .cornerRadius(8)
    }
    
    private var optionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .leading) {
                if flightNumber.isEmpty {
                    Text("Flight # (e.g. AC8924)")
                        .foregroundColor(.white.opacity(0.65))
                        .font(.subheadline)
                        .padding(.leading, 12)
                }
                TextField("", text: $flightNumber)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(12)
            }
            .background(Color(red: 0.12, green: 0.15, blue: 0.20))
            .cornerRadius(8)
            
            ZStack(alignment: .leading) {
                if remarks.isEmpty {
                    Text("Remarks (e.g. Visual RWY 06L, smooth leg)")
                        .foregroundColor(.white.opacity(0.65))
                        .font(.subheadline)
                        .padding(.leading, 12)
                }
                TextField("", text: $remarks)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(12)
            }
            .background(Color(red: 0.12, green: 0.15, blue: 0.20))
            .cornerRadius(8)
        }
    }
    
    private var saveActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                saveFlight(continueToNextLeg: true)
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Save & Next Leg")
                }
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cyan)
                .foregroundColor(.black)
                .cornerRadius(12)
                .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaults() {
        if selectedAircraft == nil, let defaultAc = aircraftList.first(where: { $0.isDefault }) ?? aircraftList.first {
            selectedAircraft = defaultAc
            selectedGear = defaultAc.defaultGearType
        }
        updateXCStatus()
    }
    
    private func updateXCStatus() {
        let dep = departureCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let arr = arrivalCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !dep.isEmpty && !arr.isEmpty {
            isCrossCountry = (dep != arr)
        }
    }
    
    private func handleTotalHoursChanged() {
        guard let total = Double(totalHoursString) else {
            if totalHoursString.isEmpty {
                dayHoursString = ""
                nightHoursString = ""
            }
            return
        }
        if dayNightMode == "All Day" {
            dayHoursString = totalHoursString
            nightHoursString = "0.0"
        } else if dayNightMode == "All Night" {
            dayHoursString = "0.0"
            nightHoursString = totalHoursString
        } else {
            // Keep night proportion or clamp
            let night = Double(nightHoursString) ?? 0.0
            if night > total {
                nightHoursString = String(format: "%.1f", total)
                dayHoursString = "0.0"
            } else {
                dayHoursString = String(format: "%.1f", total - night)
            }
        }
    }
    
    private func recomputeFromDay(_ dayStr: String) {
        guard let total = Double(totalHoursString), let day = Double(dayStr) else { return }
        if day <= total {
            nightHoursString = String(format: "%.1f", total - day)
        }
    }
    
    private func recomputeFromNight(_ nightStr: String) {
        guard let total = Double(totalHoursString), let night = Double(nightStr) else { return }
        if night <= total {
            dayHoursString = String(format: "%.1f", total - night)
        }
    }
    
    private func gearIcon(_ gear: String) -> String {
        switch gear.lowercased() {
        case "floats": return "🛟"
        case "tailwheel": return "🛞"
        case "skis": return "🎿"
        case "amphibian": return "⚓"
        default: return "✈️"
        }
    }
    
    private func gearTitle(_ gear: String) -> String {
        switch gear.lowercased() {
        case "floats": return "🛟 Floats (Seaplane)"
        case "tailwheel": return "🛞 Tailwheel (Bush)"
        case "skis": return "🎿 Skis (Winter)"
        case "amphibian": return "⚓ Amphibian"
        default: return "✈️ Tricycle Gear"
        }
    }
    
    private func saveFlight(continueToNextLeg: Bool) {
        guard let totalHours = Double(totalHoursString), totalHours > 0 else {
            errorMessage = "Please enter total flight hours (must be greater than 0)."
            showErrorAlert = true
            return
        }
        
        let dayHours = Double(dayHoursString) ?? (dayNightMode == "All Night" ? 0.0 : totalHours)
        let nightHours = Double(nightHoursString) ?? (dayNightMode == "All Day" ? 0.0 : max(0.0, totalHours - dayHours))
        
        var pic = 0.0
        var picUS = 0.0
        var sic = 0.0
        var dual = 0.0
        
        switch selectedCapacity {
        case "PIC": pic = totalHours
        case "PIC U/S": picUS = totalHours
        case "SIC": sic = totalHours
        case "Dual": dual = totalHours
        default: pic = totalHours
        }
        
        // Run strict validation
        let validation = FlightValidationEngine.validate(
            aircraft: selectedAircraft,
            departure: departureCode,
            arrival: arrivalCode,
            totalHours: totalHours,
            dayHours: dayHours,
            nightHours: nightHours,
            picHours: pic,
            picUSHoures: picUS,
            sicHours: sic,
            dualHours: dual,
            instructorHours: 0.0,
            dayTakeoffs: (dayLandings > 0 || nightLandings > 0) ? 1 : 0,
            dayLandings: dayLandings,
            nightTakeoffs: 0,
            nightLandings: nightLandings,
            legsAsPilotFlying: legsAsPF
        )
        
        switch validation {
        case .failure(let err):
            errorMessage = err.localizedDescription
            showErrorAlert = true
            return
            
        case .success:
            let newEntry = FlightLogEntry(
                date: selectedDate,
                aircraft: selectedAircraft,
                gearConfiguration: selectedGear,
                departureAirport: departureCode,
                arrivalAirport: arrivalCode,
                route: nil,
                isCrossCountry: isCrossCountry,
                flightTimeHours: totalHours,
                picHours: pic,
                picUSHoures: picUS,
                sicHours: sic,
                dualHours: dual,
                instructorHours: 0.0,
                isPilotFlying: isPilotFlying,
                legsAsPilotFlying: legsAsPF,
                dayHours: dayHours,
                nightHours: nightHours,
                actualIFRHours: approachesCount > 0 ? min(totalHours, 0.5) : 0.0,
                simulatedIFRHours: 0.0,
                dayLandings: dayLandings,
                nightLandings: nightLandings,
                dayTakeoffs: dayLandings,
                nightTakeoffs: nightLandings,
                approachesCount: approachesCount,
                flightNumber: flightNumber.isEmpty ? nil : flightNumber,
                crewNames: crewNames.isEmpty ? nil : crewNames,
                remarks: remarks.isEmpty ? nil : remarks
            )
            
            modelContext.insert(newEntry)
            try? modelContext.save()
            
            if continueToNextLeg {
                // Setup next leg: Previous arrival becomes new departure!
                departureCode = arrivalCode
                arrivalCode = ""
                totalHoursString = ""
                dayHoursString = ""
                nightHoursString = ""
                remarks = ""
                flightNumber = ""
                dayLandings = 1
                nightLandings = 0
                approachesCount = 0
            } else {
                dismiss()
            }
        }
    }
}
