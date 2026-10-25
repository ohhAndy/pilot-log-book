import SwiftUI

/// Fast offline aerodrome search sheet.
struct AirportPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let onSelect: (String) -> Void
    
    @State private var searchQuery: String = ""
    
    var searchResults: [AirportDirectoryService.AerodromeInfo] {
        if searchQuery.isEmpty {
            return AirportDirectoryService.aerodromes.values.sorted { $0.code < $1.code }
        } else {
            return AirportDirectoryService.search(query: searchQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                List(searchResults) { aero in
                    Button(action: {
                        onSelect(aero.code)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(aero.code)
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                    
                                    Text(aero.provinceOrTerritory)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.cyan.opacity(0.2))
                                        .foregroundColor(.cyan)
                                        .cornerRadius(4)
                                    
                                    if aero.isWaterdrome {
                                        Text("🛟 WATER")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text(aero.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("\(aero.city), \(aero.country) • Elev: \(aero.elevationFeet) ft")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .listRowBackground(Color(red: 0.09, green: 0.12, blue: 0.16))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchQuery, prompt: "Search CYYZ, Vancouver, Montreal...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
