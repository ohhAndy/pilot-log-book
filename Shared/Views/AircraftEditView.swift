import SwiftUI
import SwiftData

/// Modal sheet for editing an existing aircraft's profile or deleting it.
/// Automatically recomputes derived multi-engine/turbine/gear hours on historical flights upon save.
struct AircraftEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allAircraft: [Aircraft]
    
    let aircraft: Aircraft
    
    // Form State
    @State private var registration: String
    @State private var typeDesignator: String
    @State private var makeAndModel: String
    @State private var category: String
    @State private var classType: String
    @State private var engineType: String
    @State private var defaultGearType: String
    @State private var isConvertibleGear: Bool
    @State private var isTwoCrew: Bool
    @State private var isHighPerformance: Bool
    @State private var isDefault: Bool
    
    @State private var showDeleteConfirmation: Bool = false
    
    let categoryOptions = ["Aeroplane", "Helicopter"]
    let classOptions = ["Single-Engine Land", "Multi-Engine Land", "Single-Engine Sea", "Multi-Engine Sea"]
    let engineOptions = ["Turboprop", "Jet", "Piston"]
    let gearOptions = ["Tricycle", "Tailwheel", "Floats", "Skis", "Amphibian"]
    
    init(aircraft: Aircraft) {
        self.aircraft = aircraft
        _registration = State(initialValue: aircraft.registration)
        _typeDesignator = State(initialValue: aircraft.typeDesignator)
        _makeAndModel = State(initialValue: aircraft.makeAndModel)
        _category = State(initialValue: aircraft.category)
        _classType = State(initialValue: aircraft.classType)
        _engineType = State(initialValue: aircraft.engineType)
        _defaultGearType = State(initialValue: aircraft.defaultGearType)
        _isConvertibleGear = State(initialValue: aircraft.isConvertibleGear)
        _isTwoCrew = State(initialValue: aircraft.isTwoCrew)
        _isHighPerformance = State(initialValue: aircraft.isHighPerformance)
        _isDefault = State(initialValue: aircraft.isDefault)
    }
    
    var totalLoggedHours: Double {
        aircraft.flights.reduce(0.0) { $0 + $1.flightTimeHours }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Registration & Identification") {
                    TextField("Registration (e.g. C-GJEN)", text: $registration)
                        .textInputAutocapitalization(.characters)
                        .font(.headline)
                    TextField("Type Designator (e.g. DH8D, DHC-2)", text: $typeDesignator)
                        .textInputAutocapitalization(.characters)
                    TextField("Make & Model (e.g. Dash 8-400)", text: $makeAndModel)
                }
                
                Section("Classification & Certification") {
                    Picker("Category", selection: $category) {
                        ForEach(categoryOptions, id: \.self) { Text($0) }
                    }
                    Picker("Class", selection: $classType) {
                        ForEach(classOptions, id: \.self) { Text($0) }
                    }
                    Picker("Engine Type", selection: $engineType) {
                        ForEach(engineOptions, id: \.self) { Text($0) }
                    }
                    Toggle("Two-Crew Type Rating (CAR 705/704)", isOn: $isTwoCrew)
                    Toggle("High Performance (CAR 421.40)", isOn: $isHighPerformance)
                }
                
                Section("Landing Gear & Bush Config") {
                    Picker("Default Gear", selection: $defaultGearType) {
                        ForEach(gearOptions, id: \.self) { Text($0) }
                    }
                    Toggle("Convertible Gear (Swaps Floats/Wheels/Skis)", isOn: $isConvertibleGear)
                }
                
                Section("Fleet Preferences") {
                    Toggle("Default Aircraft for Quick Log", isOn: $isDefault)
                }
                
                Section("Logbook History") {
                    HStack {
                        Text("Logged Sectors")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(aircraft.flights.count) flights")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Logged Hours")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f hrs", totalLoggedHours))
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Delete Aircraft")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Aircraft")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .disabled(registration.trimmingCharacters(in: .whitespaces).isEmpty ||
                              typeDesignator.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete \(aircraft.registration)?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Aircraft", role: .destructive) {
                    deleteAircraft()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if aircraft.flights.isEmpty {
                    Text("Are you sure you want to delete this aircraft from your fleet?")
                } else {
                    Text("This aircraft has \(aircraft.flights.count) logged flight(s). Deleting it will remove it from your fleet, but your flight log entries will remain safe.")
                }
            }
        }
    }
    
    private func saveChanges() {
        let cleanReg = registration.trimmingCharacters(in: .whitespaces).uppercased()
        let cleanType = typeDesignator.trimmingCharacters(in: .whitespaces).uppercased()
        let cleanMakeModel = makeAndModel.trimmingCharacters(in: .whitespaces)
        
        aircraft.registration = cleanReg
        aircraft.typeDesignator = cleanType
        aircraft.makeAndModel = cleanMakeModel.isEmpty ? cleanType : cleanMakeModel
        aircraft.category = category
        aircraft.classType = classType
        aircraft.engineType = engineType
        aircraft.defaultGearType = defaultGearType
        aircraft.isConvertibleGear = isConvertibleGear
        aircraft.isTwoCrew = isTwoCrew
        aircraft.isHighPerformance = isHighPerformance
        aircraft.updatedAt = Date()
        
        // Handle default switch
        if isDefault {
            for ac in allAircraft where ac.id != aircraft.id {
                ac.isDefault = false
            }
            aircraft.isDefault = true
        } else {
            aircraft.isDefault = false
        }
        
        // Recompute derived hours for all associated historical flights
        for flight in aircraft.flights {
            flight.recomputeDerivedHours()
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteAircraft() {
        if aircraft.isDefault {
            // Find another aircraft to be default
            if let nextDefault = allAircraft.first(where: { $0.id != aircraft.id }) {
                nextDefault.isDefault = true
            }
        }
        modelContext.delete(aircraft)
        try? modelContext.save()
        dismiss()
    }
}
