import SwiftUI
import SwiftData

/// Fleet manager for registering aircraft with convertible gear configurations.
struct AircraftManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Aircraft.registration) private var aircraftList: [Aircraft]
    
    @State private var showAddAircraftSheet: Bool = false
    @State private var selectedAircraftForEdit: Aircraft?
    @State private var aircraftPendingDelete: Aircraft?
    @State private var showDeleteAlert: Bool = false
    
    // Form fields for new aircraft
    @State private var registration: String = ""
    @State private var typeDesignator: String = ""
    @State private var makeAndModel: String = ""
    @State private var classType: String = "Multi-Engine Land"
    @State private var engineType: String = "Turboprop"
    @State private var defaultGearType: String = "Tricycle"
    @State private var isConvertibleGear: Bool = false
    @State private var isTwoCrew: Bool = true
    @State private var makeDefaultNewAircraft: Bool = false
    
    let classOptions = ["Single-Engine Land", "Multi-Engine Land", "Single-Engine Sea", "Multi-Engine Sea"]
    let engineOptions = ["Turboprop", "Jet", "Piston"]
    let gearOptions = ["Tricycle", "Tailwheel", "Floats", "Skis", "Amphibian"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                if aircraftList.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Aircraft Added")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Add your company or personal aircraft once. Hours will auto-derive based on its profile.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button(action: addSampleFleet) {
                            Text("Add Sample Fleet (DH8D, DHC-2, C172)")
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
                        ForEach(aircraftList) { ac in
                            Button(action: {
                                selectedAircraftForEdit = ac
                            }) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Text(ac.registration)
                                                .font(.headline.bold())
                                                .foregroundColor(.white)
                                            Text("• \(ac.typeDesignator)")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.cyan)
                                            
                                            if ac.isDefault {
                                                Text("DEFAULT")
                                                    .font(.caption2.bold())
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.cyan.opacity(0.2))
                                                    .foregroundColor(.cyan)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Text(ac.makeAndModel)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        HStack(spacing: 8) {
                                            Text(gearIcon(ac.defaultGearType) + " " + ac.defaultGearType)
                                            Text("•")
                                            Text(ac.classType)
                                            Text("•")
                                            Text(ac.engineType)
                                            
                                            if ac.isConvertibleGear {
                                                Text("(Convertible)")
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        
                                        if !ac.flights.isEmpty {
                                            HStack(spacing: 8) {
                                                Text("\(ac.flights.count) logged flight\(ac.flights.count > 1 ? "s" : "")")
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.6))
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                                let totalHours = ac.flights.reduce(0.0) { $0 + $1.flightTimeHours }
                                                Text(String(format: "%.1f hrs", totalHours))
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.cyan)
                                            }
                                            .padding(.top, 2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    promptDelete(aircraft: ac)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    selectedAircraftForEdit = ac
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.cyan)
                            }
                            .swipeActions(edge: .leading) {
                                if !ac.isDefault {
                                    Button {
                                        setAsDefault(ac)
                                    } label: {
                                        Label("Make Default", systemImage: "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                            }
                            .contextMenu {
                                Button {
                                    selectedAircraftForEdit = ac
                                } label: {
                                    Label("Edit Aircraft", systemImage: "pencil")
                                }
                                
                                if !ac.isDefault {
                                    Button {
                                        setAsDefault(ac)
                                    } label: {
                                        Label("Set as Default Fleet Aircraft", systemImage: "star")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    promptDelete(aircraft: ac)
                                } label: {
                                    Label("Delete Aircraft", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Fleet Manager")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddAircraftSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showAddAircraftSheet) {
                addAircraftModal
            }
            .sheet(item: $selectedAircraftForEdit) { ac in
                AircraftEditView(aircraft: ac)
            }
            .confirmationDialog(
                "Delete Aircraft",
                isPresented: $showDeleteAlert,
                titleVisibility: .visible,
                presenting: aircraftPendingDelete
            ) { ac in
                Button("Delete \(ac.registration)", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) {
                    aircraftPendingDelete = nil
                }
            } message: { ac in
                if ac.flights.isEmpty {
                    Text("Are you sure you want to delete '\(ac.registration)' from your fleet?")
                } else {
                    Text("Are you sure you want to delete '\(ac.registration)'? This aircraft has \(ac.flights.count) logged flight(s). Deleting it will remove it from your fleet, but your flight log entries will remain safe.")
                }
            }
        }
    }
    
    private var addAircraftModal: some View {
        NavigationStack {
            Form {
                Section("Registration & Model") {
                    TextField("Registration (e.g. C-GJEN)", text: $registration)
                        .textInputAutocapitalization(.characters)
                    TextField("Type Designator (e.g. DH8D, DHC-2, A320)", text: $typeDesignator)
                        .textInputAutocapitalization(.characters)
                    TextField("Make & Model (e.g. Dash 8-400)", text: $makeAndModel)
                }
                
                Section("Classification") {
                    Picker("Class", selection: $classType) {
                        ForEach(classOptions, id: \.self) { Text($0) }
                    }
                    Picker("Engine Type", selection: $engineType) {
                        ForEach(engineOptions, id: \.self) { Text($0) }
                    }
                    Toggle("Two-Crew Aircraft", isOn: $isTwoCrew)
                }
                
                Section("Landing Gear & Seasonal Setup") {
                    Picker("Default Gear", selection: $defaultGearType) {
                        ForEach(gearOptions, id: \.self) { Text($0) }
                    }
                    Toggle("Convertible Gear (Swaps Floats/Wheels/Skis)", isOn: $isConvertibleGear)
                }
                
                Section("Preferences") {
                    Toggle("Set as Default Fleet Aircraft", isOn: $makeDefaultNewAircraft)
                }
            }
            .navigationTitle("Add Aircraft")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddAircraftSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNewAircraft()
                    }
                    .fontWeight(.bold)
                    .disabled(registration.trimmingCharacters(in: .whitespaces).isEmpty ||
                              typeDesignator.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveNewAircraft() {
        let isDef = makeDefaultNewAircraft || aircraftList.isEmpty
        if isDef {
            for ac in aircraftList {
                ac.isDefault = false
            }
        }
        
        let newAc = Aircraft(
            registration: registration.trimmingCharacters(in: .whitespaces).uppercased(),
            typeDesignator: typeDesignator.trimmingCharacters(in: .whitespaces).uppercased(),
            makeAndModel: makeAndModel.isEmpty ? typeDesignator.uppercased() : makeAndModel,
            classType: classType,
            engineType: engineType,
            defaultGearType: defaultGearType,
            isConvertibleGear: isConvertibleGear,
            isTwoCrew: isTwoCrew,
            isDefault: isDef
        )
        modelContext.insert(newAc)
        try? modelContext.save()
        
        showAddAircraftSheet = false
        registration = ""
        typeDesignator = ""
        makeAndModel = ""
        makeDefaultNewAircraft = false
    }
    
    private func setAsDefault(_ aircraft: Aircraft) {
        for ac in aircraftList {
            ac.isDefault = (ac.id == aircraft.id)
        }
        try? modelContext.save()
    }
    
    private func promptDelete(aircraft: Aircraft) {
        aircraftPendingDelete = aircraft
        showDeleteAlert = true
    }
    
    private func confirmDelete() {
        guard let ac = aircraftPendingDelete else { return }
        if ac.isDefault {
            if let next = aircraftList.first(where: { $0.id != ac.id }) {
                next.isDefault = true
            }
        }
        modelContext.delete(ac)
        try? modelContext.save()
        aircraftPendingDelete = nil
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
    
    private func addSampleFleet() {
        let dh8d = Aircraft(
            registration: "C-GJEN",
            typeDesignator: "DH8D",
            makeAndModel: "De Havilland Dash 8-400",
            classType: "Multi-Engine Land",
            engineType: "Turboprop",
            defaultGearType: "Tricycle",
            isTwoCrew: true,
            isDefault: true
        )
        let beaver = Aircraft(
            registration: "C-FABC",
            typeDesignator: "DHC-2",
            makeAndModel: "de Havilland DHC-2 Beaver",
            classType: "Single-Engine Land",
            engineType: "Piston",
            defaultGearType: "Floats",
            isConvertibleGear: true,
            isTwoCrew: false
        )
        let c172 = Aircraft(
            registration: "C-GXYZ",
            typeDesignator: "C172",
            makeAndModel: "Cessna 172 Skyhawk",
            classType: "Single-Engine Land",
            engineType: "Piston",
            defaultGearType: "Tricycle",
            isTwoCrew: false
        )
        modelContext.insert(dh8d)
        modelContext.insert(beaver)
        modelContext.insert(c172)
        try? modelContext.save()
    }
    
    private func deleteAircraft(at offsets: IndexSet) {
        for index in offsets {
            let ac = aircraftList[index]
            if ac.isDefault {
                if let next = aircraftList.first(where: { $0.id != ac.id }) {
                    next.isDefault = true
                }
            }
            modelContext.delete(ac)
        }
        try? modelContext.save()
    }
}
