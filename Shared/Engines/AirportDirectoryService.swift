import Foundation

/// Fast, 100% offline aerodrome lookup service with comprehensive Canadian aerodromes, bush strips, and waterdromes.
struct AirportDirectoryService {
    struct AerodromeInfo: Identifiable, Hashable {
        var id: String { code }
        let code: String            // 4-letter ICAO / TC (e.g. "CYYZ", "CNC3")
        let name: String            // "Toronto Pearson International"
        let city: String            // "Toronto"
        let provinceOrTerritory: String // "ON", "QC", "BC", etc.
        let country: String         // "Canada", "USA"
        let elevationFeet: Int
        let isWaterdrome: Bool
        let longestRunwayFeet: Int?
    }
    
    /// Pre-indexed dataset of Canadian aerodromes across all provinces, territories, bush strips, and waterdromes.
    static let aerodromes: [String: AerodromeInfo] = [
        // MARK: - Ontario (ON)
        "CYYZ": AerodromeInfo(code: "CYYZ", name: "Toronto Pearson Int'l", city: "Toronto", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 569, isWaterdrome: false, longestRunwayFeet: 11120),
        "CYTZ": AerodromeInfo(code: "CYTZ", name: "Billy Bishop Toronto City Airport", city: "Toronto", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 251, isWaterdrome: false, longestRunwayFeet: 3988),
        "CYOW": AerodromeInfo(code: "CYOW", name: "Ottawa Macdonald-Cartier Int'l", city: "Ottawa", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 374, isWaterdrome: false, longestRunwayFeet: 10005),
        "CYHM": AerodromeInfo(code: "CYHM", name: "John C. Munro Hamilton Int'l", city: "Hamilton", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 780, isWaterdrome: false, longestRunwayFeet: 10006),
        "CYKF": AerodromeInfo(code: "CYKF", name: "Region of Waterloo Int'l", city: "Kitchener/Waterloo", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 1054, isWaterdrome: false, longestRunwayFeet: 7000),
        "CYXU": AerodromeInfo(code: "CYXU", name: "London International Airport", city: "London", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 912, isWaterdrome: false, longestRunwayFeet: 8800),
        "CYQT": AerodromeInfo(code: "CYQT", name: "Thunder Bay Airport", city: "Thunder Bay", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 654, isWaterdrome: false, longestRunwayFeet: 7300),
        "CYSB": AerodromeInfo(code: "CYSB", name: "Greater Sudbury Airport", city: "Sudbury", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 1048, isWaterdrome: false, longestRunwayFeet: 6600),
        "CYAM": AerodromeInfo(code: "CYAM", name: "Sault Ste. Marie Airport", city: "Sault Ste. Marie", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 632, isWaterdrome: false, longestRunwayFeet: 6000),
        "CYTS": AerodromeInfo(code: "CYTS", name: "Timmins Victor M. Power", city: "Timmins", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 967, isWaterdrome: false, longestRunwayFeet: 6000),
        "CYKZ": AerodromeInfo(code: "CYKZ", name: "Buttonville Municipal Airport", city: "Toronto/Markham", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 650, isWaterdrome: false, longestRunwayFeet: 3897),
        "CNC3": AerodromeInfo(code: "CNC3", name: "Brampton-Caledon Airport", city: "Brampton", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 950, isWaterdrome: false, longestRunwayFeet: 3500),
        "CAM3": AerodromeInfo(code: "CAM3", name: "Cookstown/Kirby Field", city: "Cookstown", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 820, isWaterdrome: false, longestRunwayFeet: 2200),
        "CNV9": AerodromeInfo(code: "CNV9", name: "Muskoka Waterdrome", city: "Gravenhurst", provinceOrTerritory: "ON", country: "Canada", elevationFeet: 740, isWaterdrome: true, longestRunwayFeet: nil),
        
        // MARK: - Quebec (QC)
        "CYUL": AerodromeInfo(code: "CYUL", name: "Montréal-Trudeau Int'l", city: "Montréal", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 118, isWaterdrome: false, longestRunwayFeet: 11000),
        "CYHU": AerodromeInfo(code: "CYHU", name: "Montréal/Saint-Hubert Airport", city: "Longueuil", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 90, isWaterdrome: false, longestRunwayFeet: 7800),
        "CYMX": AerodromeInfo(code: "CYMX", name: "Montréal-Mirabel Int'l", city: "Mirabel", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 270, isWaterdrome: false, longestRunwayFeet: 12000),
        "CYQB": AerodromeInfo(code: "CYQB", name: "Québec City Jean Lesage Int'l", city: "Québec City", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 244, isWaterdrome: false, longestRunwayFeet: 9000),
        "CYVO": AerodromeInfo(code: "CYVO", name: "Val-d'Or Airport", city: "Val-d'Or", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 1106, isWaterdrome: false, longestRunwayFeet: 10000),
        "CYBG": AerodromeInfo(code: "CYBG", name: "CFB Bagotville / Saguenay", city: "Saguenay", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 522, isWaterdrome: false, longestRunwayFeet: 10000),
        "CYRJ": AerodromeInfo(code: "CYRJ", name: "Roberval Airport", city: "Roberval", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 586, isWaterdrome: false, longestRunwayFeet: 5000),
        "CST3": AerodromeInfo(code: "CST3", name: "Lac-à-la-Tortue Water Airport", city: "Shawinigan", provinceOrTerritory: "QC", country: "Canada", elevationFeet: 428, isWaterdrome: true, longestRunwayFeet: nil),
        
        // MARK: - British Columbia (BC)
        "CYVR": AerodromeInfo(code: "CYVR", name: "Vancouver International", city: "Vancouver", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 14, isWaterdrome: false, longestRunwayFeet: 11500),
        "CYYJ": AerodromeInfo(code: "CYYJ", name: "Victoria International", city: "Victoria", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 63, isWaterdrome: false, longestRunwayFeet: 7000),
        "CYXX": AerodromeInfo(code: "CYXX", name: "Abbotsford International", city: "Abbotsford", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 195, isWaterdrome: false, longestRunwayFeet: 9600),
        "CYLW": AerodromeInfo(code: "CYLW", name: "Kelowna International", city: "Kelowna", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 1421, isWaterdrome: false, longestRunwayFeet: 8900),
        "CYXS": AerodromeInfo(code: "CYXS", name: "Prince George Airport", city: "Prince George", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 2267, isWaterdrome: false, longestRunwayFeet: 11450),
        "CYPR": AerodromeInfo(code: "CYPR", name: "Prince Rupert Airport", city: "Prince Rupert", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 116, isWaterdrome: false, longestRunwayFeet: 6000),
        "CYQQ": AerodromeInfo(code: "CYQQ", name: "CFB Comox", city: "Comox", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 84, isWaterdrome: false, longestRunwayFeet: 10000),
        "CYCD": AerodromeInfo(code: "CYCD", name: "Nanaimo Airport", city: "Nanaimo", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 92, isWaterdrome: false, longestRunwayFeet: 6600),
        "CYKA": AerodromeInfo(code: "CYKA", name: "Kamloops Airport", city: "Kamloops", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 1133, isWaterdrome: false, longestRunwayFeet: 8000),
        "CYWH": AerodromeInfo(code: "CYWH", name: "Victoria Inner Harbour Seaplane Base", city: "Victoria", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 0, isWaterdrome: true, longestRunwayFeet: nil),
        "CXH": AerodromeInfo(code: "CXH", name: "Vancouver Harbour Water Airport", city: "Vancouver", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 0, isWaterdrome: true, longestRunwayFeet: nil),
        "CBA8": AerodromeInfo(code: "CBA8", name: "Barkley Valley Bush Strip", city: "Barkley", provinceOrTerritory: "BC", country: "Canada", elevationFeet: 1200, isWaterdrome: false, longestRunwayFeet: 2000),
        
        // MARK: - Alberta (AB)
        "CYYC": AerodromeInfo(code: "CYYC", name: "Calgary International", city: "Calgary", provinceOrTerritory: "AB", country: "Canada", elevationFeet: 3557, isWaterdrome: false, longestRunwayFeet: 14000),
        "CYEG": AerodromeInfo(code: "CYEG", name: "Edmonton International", city: "Edmonton", provinceOrTerritory: "AB", country: "Canada", elevationFeet: 2373, isWaterdrome: false, longestRunwayFeet: 11000),
        "CYMM": AerodromeInfo(code: "CYMM", name: "Fort McMurray International", city: "Fort McMurray", provinceOrTerritory: "AB", country: "Canada", elevationFeet: 1211, isWaterdrome: false, longestRunwayFeet: 7500),
        "CYQL": AerodromeInfo(code: "CYQL", name: "Lethbridge Airport", city: "Lethbridge", provinceOrTerritory: "AB", country: "Canada", elevationFeet: 3048, isWaterdrome: false, longestRunwayFeet: 6500),
        "CYQU": AerodromeInfo(code: "CYQU", name: "Grande Prairie Airport", city: "Grande Prairie", provinceOrTerritory: "AB", country: "Canada", elevationFeet: 2195, isWaterdrome: false, longestRunwayFeet: 8500),
        "CYBW": AerodromeInfo(code: "CYBW", name: "Calgary/Springbank Airport", city: "Calgary", provinceOrTerritory: "AB", country: "Canada", elevationFeet: 3940, isWaterdrome: false, longestRunwayFeet: 5000),
        
        // MARK: - Manitoba (MB)
        "CYWG": AerodromeInfo(code: "CYWG", name: "Winnipeg Richardson Int'l", city: "Winnipeg", provinceOrTerritory: "MB", country: "Canada", elevationFeet: 783, isWaterdrome: false, longestRunwayFeet: 11000),
        "CYBR": AerodromeInfo(code: "CYBR", name: "Brandon Municipal Airport", city: "Brandon", provinceOrTerritory: "MB", country: "Canada", elevationFeet: 1343, isWaterdrome: false, longestRunwayFeet: 6500),
        "CYTH": AerodromeInfo(code: "CYTH", name: "Thompson Airport", city: "Thompson", provinceOrTerritory: "MB", country: "Canada", elevationFeet: 729, isWaterdrome: false, longestRunwayFeet: 5800),
        "CYYQ": AerodromeInfo(code: "CYYQ", name: "Churchill Airport", city: "Churchill", provinceOrTerritory: "MB", country: "Canada", elevationFeet: 96, isWaterdrome: false, longestRunwayFeet: 9200),
        
        // MARK: - Saskatchewan (SK)
        "CYXE": AerodromeInfo(code: "CYXE", name: "Saskatoon John G. Diefenbaker", city: "Saskatoon", provinceOrTerritory: "SK", country: "Canada", elevationFeet: 1654, isWaterdrome: false, longestRunwayFeet: 8300),
        "CYQR": AerodromeInfo(code: "CYQR", name: "Regina International", city: "Regina", provinceOrTerritory: "SK", country: "Canada", elevationFeet: 1895, isWaterdrome: false, longestRunwayFeet: 7900),
        "CYPA": AerodromeInfo(code: "CYPA", name: "Prince Albert Glass Field", city: "Prince Albert", provinceOrTerritory: "SK", country: "Canada", elevationFeet: 1405, isWaterdrome: false, longestRunwayFeet: 5000),
        
        // MARK: - Atlantic Provinces (NS, NB, NL, PE)
        "CYHZ": AerodromeInfo(code: "CYHZ", name: "Halifax Stanfield Int'l", city: "Halifax", provinceOrTerritory: "NS", country: "Canada", elevationFeet: 477, isWaterdrome: false, longestRunwayFeet: 10500),
        "CYQM": AerodromeInfo(code: "CYQM", name: "Greater Moncton Roméo LeBlanc", city: "Moncton", provinceOrTerritory: "NB", country: "Canada", elevationFeet: 232, isWaterdrome: false, longestRunwayFeet: 10000),
        "CYFC": AerodromeInfo(code: "CYFC", name: "Fredericton International", city: "Fredericton", provinceOrTerritory: "NB", country: "Canada", elevationFeet: 68, isWaterdrome: false, longestRunwayFeet: 8000),
        "CYYT": AerodromeInfo(code: "CYYT", name: "St. John's International", city: "St. John's", provinceOrTerritory: "NL", country: "Canada", elevationFeet: 461, isWaterdrome: false, longestRunwayFeet: 8500),
        "CYQX": AerodromeInfo(code: "CYQX", name: "Gander International", city: "Gander", provinceOrTerritory: "NL", country: "Canada", elevationFeet: 496, isWaterdrome: false, longestRunwayFeet: 10200),
        "CYGZ": AerodromeInfo(code: "CYGZ", name: "Happy Valley-Goose Bay", city: "Goose Bay", provinceOrTerritory: "NL", country: "Canada", elevationFeet: 160, isWaterdrome: false, longestRunwayFeet: 11050),
        "CYYG": AerodromeInfo(code: "CYYG", name: "Charlottetown Airport", city: "Charlottetown", provinceOrTerritory: "PE", country: "Canada", elevationFeet: 161, isWaterdrome: false, longestRunwayFeet: 7000),
        
        // MARK: - Northern Territories (NT, YT, NU)
        "CYZF": AerodromeInfo(code: "CYZF", name: "Yellowknife Airport", city: "Yellowknife", provinceOrTerritory: "NT", country: "Canada", elevationFeet: 675, isWaterdrome: false, longestRunwayFeet: 7500),
        "CYEV": AerodromeInfo(code: "CYEV", name: "Inuvik Mike Zubko Airport", city: "Inuvik", provinceOrTerritory: "NT", country: "Canada", elevationFeet: 224, isWaterdrome: false, longestRunwayFeet: 6000),
        "CYXY": AerodromeInfo(code: "CYXY", name: "Whitehorse Erik Nielsen Int'l", city: "Whitehorse", provinceOrTerritory: "YT", country: "Canada", elevationFeet: 2317, isWaterdrome: false, longestRunwayFeet: 9500),
        "CYFB": AerodromeInfo(code: "CYFB", name: "Iqaluit Airport", city: "Iqaluit", provinceOrTerritory: "NU", country: "Canada", elevationFeet: 110, isWaterdrome: false, longestRunwayFeet: 8600),
        "CYRB": AerodromeInfo(code: "CYRB", name: "Resolute Bay Airport", city: "Resolute", provinceOrTerritory: "NU", country: "Canada", elevationFeet: 222, isWaterdrome: false, longestRunwayFeet: 6500),
        
        // MARK: - Key International US Hubs
        "KJFK": AerodromeInfo(code: "KJFK", name: "John F. Kennedy Int'l", city: "New York", provinceOrTerritory: "NY", country: "USA", elevationFeet: 13, isWaterdrome: false, longestRunwayFeet: 14511),
        "KORD": AerodromeInfo(code: "KORD", name: "Chicago O'Hare Int'l", city: "Chicago", provinceOrTerritory: "IL", country: "USA", elevationFeet: 672, isWaterdrome: false, longestRunwayFeet: 13000),
        "KLAX": AerodromeInfo(code: "KLAX", name: "Los Angeles Int'l", city: "Los Angeles", provinceOrTerritory: "CA", country: "USA", elevationFeet: 128, isWaterdrome: false, longestRunwayFeet: 12091),
        "KMCO": AerodromeInfo(code: "KMCO", name: "Orlando Int'l", city: "Orlando", provinceOrTerritory: "FL", country: "USA", elevationFeet: 96, isWaterdrome: false, longestRunwayFeet: 12005),
        "KBOS": AerodromeInfo(code: "KBOS", name: "Boston Logan Int'l", city: "Boston", provinceOrTerritory: "MA", country: "USA", elevationFeet: 20, isWaterdrome: false, longestRunwayFeet: 10083),
        "KSEA": AerodromeInfo(code: "KSEA", name: "Seattle-Tacoma Int'l", city: "Seattle", provinceOrTerritory: "WA", country: "USA", elevationFeet: 433, isWaterdrome: false, longestRunwayFeet: 11901)
    ]
    
    /// Resolves an ICAO or TC code to friendly display name.
    static func lookup(code: String) -> AerodromeInfo? {
        let key = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return aerodromes[key]
    }
    
    /// Searches aerodromes matching a query against code, name, or city.
    static func search(query: String) -> [AerodromeInfo] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        
        return aerodromes.values.filter {
            $0.code.lowercased().contains(q)
                || $0.name.lowercased().contains(q)
                || $0.city.lowercased().contains(q)
                || $0.provinceOrTerritory.lowercased().contains(q)
        }.sorted { $0.code < $1.code }
    }
}
