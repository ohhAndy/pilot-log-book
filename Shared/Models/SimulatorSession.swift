import Foundation
import SwiftData

/// Represents a training session in a certified Flight Simulation Training Device (FSTD).
/// Tracks Level C/D Full Flight Simulators (FFS) and Flight Training Devices (FTD) per CARs.
@Model
final class SimulatorSession {
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var date: Date = Date()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()   // For Last-Write-Wins (LWW) sync
    
    // Device Information
    var deviceLevel: String        // "Level D FFS", "Level C FFS", "FTD Level 5", "FTD Level 2"
    var aircraftType: String       // e.g. "B738", "A320", "DH8D"
    var approvalNumber: String?    // TC Device Identifier (e.g. "TC-412")
    var trainingFacility: String?  // e.g. "CAE Montreal", "FlightSafety Toronto"
    
    // Check / Training Type
    var isPPC: Bool = false        // Pilot Proficiency Check (CAR 705/704/703)
    var isIPC: Bool = false        // Instrument Proficiency Check (CAR 401.05)
    var isRecurrent: Bool = true
    
    // Hours & Practice Counts
    var totalHours: Double = 0.0
    var dualHours: Double = 0.0
    var ifrSimulatedHours: Double = 0.0
    var approachesCount: Int = 0
    var holdsCount: Int = 0
    
    var instructorOrExaminer: String?
    var remarks: String?
    
    init(
        date: Date = Date(),
        deviceLevel: String = "Level D FFS",
        aircraftType: String = "DH8D",
        approvalNumber: String? = nil,
        trainingFacility: String? = nil,
        isPPC: Bool = false,
        isIPC: Bool = false,
        isRecurrent: Bool = true,
        totalHours: Double = 0.0,
        dualHours: Double = 0.0,
        ifrSimulatedHours: Double = 0.0,
        approachesCount: Int = 0,
        holdsCount: Int = 0,
        instructorOrExaminer: String? = nil,
        remarks: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deviceLevel = deviceLevel
        self.aircraftType = aircraftType.uppercased()
        self.approvalNumber = approvalNumber
        self.trainingFacility = trainingFacility
        self.isPPC = isPPC
        self.isIPC = isIPC
        self.isRecurrent = isRecurrent
        self.totalHours = totalHours
        self.dualHours = dualHours
        self.ifrSimulatedHours = ifrSimulatedHours
        self.approachesCount = approachesCount
        self.holdsCount = holdsCount
        self.instructorOrExaminer = instructorOrExaminer
        self.remarks = remarks
    }
}
