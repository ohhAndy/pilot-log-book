import Foundation
import SwiftData

/// Stores pilot credentials and medical dates for CARs compliance.
@Model
final class PilotProfile {
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var fullName: String = ""
    var licenseNumber: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    
    // Transport Canada Medical (Category 1 for CPL/ATPL)
    var medicalCategory1Date: Date = Date()
    var isSinglePilotAirTransportWithPax: Bool = false // Under CAR 404.04: if 40+ and single pilot with pax -> 6 mo validity
    
    // Last Recurrent Training / PPC / Flight Review
    var lastPPCDate: Date?
    var lastFlightReviewDate: Date?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        fullName: String = "Captain",
        licenseNumber: String = "AA123456",
        dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
        medicalCategory1Date: Date = Date(),
        isSinglePilotAirTransportWithPax: Bool = false,
        lastPPCDate: Date? = nil,
        lastFlightReviewDate: Date? = nil
    ) {
        self.id = UUID()
        self.fullName = fullName
        self.licenseNumber = licenseNumber
        self.dateOfBirth = dateOfBirth
        self.medicalCategory1Date = medicalCategory1Date
        self.isSinglePilotAirTransportWithPax = isSinglePilotAirTransportWithPax
        self.lastPPCDate = lastPPCDate
        self.lastFlightReviewDate = lastFlightReviewDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
