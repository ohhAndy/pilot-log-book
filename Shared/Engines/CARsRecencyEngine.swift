import Foundation

/// Comprehensive calculation engine for Transport Canada regulations:
/// - CAR 700.27 (Flight Time Limitations)
/// - CAR 421.34(4) (ATPL Aeroplane Experience Audit)
/// - CAR 401.05 (Recency Requirements)
/// - CAR 404.04 (Category 1 Medical Expiry)
struct CARsRecencyEngine {
    
    // MARK: - CAR 700.27 Commercial Flight Time Limitations
    
    struct FlightTimeLimits {
        let hours28Days: Double
        let limit28Days: Double = 112.0
        
        let hours90Days: Double
        let limit90Days: Double = 300.0
        
        let hours365Days: Double
        let limit365Days: Double = 1000.0
        
        var percent28Days: Double { min(1.0, hours28Days / limit28Days) }
        var percent90Days: Double { min(1.0, hours90Days / limit90Days) }
        var percent365Days: Double { min(1.0, hours365Days / limit365Days) }
        
        var buffer28Days: Double { max(0.0, limit28Days - hours28Days) }
        var buffer90Days: Double { max(0.0, limit90Days - hours90Days) }
        var buffer365Days: Double { max(0.0, limit365Days - hours365Days) }
        
        var is28DaysExceeded: Bool { hours28Days >= limit28Days }
        var is90DaysExceeded: Bool { hours90Days >= limit90Days }
        var is365DaysExceeded: Bool { hours365Days >= limit365Days }
    }
    
    /// Computes rolling flight time limitations per CAR 700.27 as of a given reference date (defaults to today).
    static func calculateFlightTimeLimits(
        flights: [FlightLogEntry],
        referenceDate: Date = Date()
    ) -> FlightTimeLimits {
        let calendar = Calendar.current
        
        let date28DaysAgo = calendar.date(byAdding: .day, value: -28, to: referenceDate) ?? referenceDate
        let date90DaysAgo = calendar.date(byAdding: .day, value: -90, to: referenceDate) ?? referenceDate
        let date365DaysAgo = calendar.date(byAdding: .day, value: -365, to: referenceDate) ?? referenceDate
        
        var h28 = 0.0
        var h90 = 0.0
        var h365 = 0.0
        
        for flight in flights {
            if flight.date >= date28DaysAgo && flight.date <= referenceDate {
                h28 += flight.flightTimeHours
            }
            if flight.date >= date90DaysAgo && flight.date <= referenceDate {
                h90 += flight.flightTimeHours
            }
            if flight.date >= date365DaysAgo && flight.date <= referenceDate {
                h365 += flight.flightTimeHours
            }
        }
        
        return FlightTimeLimits(
            hours28Days: (h28 * 10).rounded() / 10,
            hours90Days: (h90 * 10).rounded() / 10,
            hours365Days: (h365 * 10).rounded() / 10
        )
    }
    
    // MARK: - CAR 421.34(4) ATPL Aeroplane Experience Audit
    
    struct ATPLAudit {
        let totalFlightTime: Double             // Req: 1,500.0 (min 900 aeroplanes)
        let aeroplaneFlightTime: Double         // Min 900.0
        let reqTotal: Double = 1500.0
        let reqAeroplane: Double = 900.0
        
        let picHoursRaw: Double
        let picUSHouresRaw: Double
        let picCredited: Double                 // Req: 250.0 (PIC + up to 100h PIC U/S)
        let reqPIC: Double = 250.0
        
        let picXCHours: Double                  // Req: 100.0
        let reqPICXC: Double = 100.0
        
        let picNightHours: Double               // Req: 25.0
        let reqPICNight: Double = 25.0
        
        let totalNightHours: Double             // Req: 100.0 (min 30 in aeroplanes)
        let reqTotalNight: Double = 100.0
        
        let additionalXCCredited: Double        // Req: 100.0 (PIC XC or 50% Co-pilot XC)
        let reqAdditionalXC: Double = 100.0
        
        let instrumentHoursCredited: Double     // Req: 75.0 (Actual/sim IFR + max 25h sim)
        let reqInstrument: Double = 75.0
        
        var isTotalMet: Bool { totalFlightTime >= reqTotal && aeroplaneFlightTime >= reqAeroplane }
        var isPICMet: Bool { picCredited >= reqPIC && picXCHours >= reqPICXC && picNightHours >= reqPICNight }
        var isNightMet: Bool { totalNightHours >= reqTotalNight }
        var isXCMet: Bool { additionalXCCredited >= reqAdditionalXC }
        var isInstrumentMet: Bool { instrumentHoursCredited >= reqInstrument }
        
        var isFullyQualified: Bool {
            isTotalMet && isPICMet && isNightMet && isXCMet && isInstrumentMet
        }
    }
    
    /// Evaluates the pilot's experience against CAR 421.34(4) for ATPL(A).
    static func calculateATPLAudit(
        flights: [FlightLogEntry],
        simulators: [SimulatorSession]
    ) -> ATPLAudit {
        var totalHours = 0.0
        var aeroplaneHours = 0.0
        var picRaw = 0.0
        var picUSRaw = 0.0
        var picXC = 0.0
        var picNight = 0.0
        var totalNight = 0.0
        var additionalPICXC = 0.0
        var additionalSICXC = 0.0
        var actualIFR = 0.0
        var simulatedIFR = 0.0
        
        for flight in flights {
            totalHours += flight.flightTimeHours
            if flight.aircraft?.category == "Aeroplane" || flight.aircraft == nil {
                aeroplaneHours += flight.flightTimeHours
            }
            
            picRaw += flight.picHours
            picUSRaw += flight.picUSHoures
            
            // PIC Cross-country & night
            if flight.isCrossCountry {
                picXC += flight.picHours
                // Additional XC accumulation
                additionalPICXC += flight.picHours
                additionalSICXC += flight.sicHours
            }
            
            if flight.nightHours > 0 {
                // If flying as PIC during night
                if flight.picHours > 0 {
                    picNight += min(flight.picHours, flight.nightHours)
                }
                totalNight += flight.nightHours
            }
            
            actualIFR += flight.actualIFRHours
            simulatedIFR += flight.simulatedIFRHours
        }
        
        // Sim credits
        var simHoursTotal = 0.0
        var simIFRHours = 0.0
        for sim in simulators {
            simHoursTotal += sim.totalHours
            simIFRHours += sim.ifrSimulatedHours
        }
        
        // Under CAR 421.34(4), PIC U/S can be credited at 100% up to 100 hours towards the 250h PIC requirement
        let picUSCredited = min(100.0, picUSRaw)
        let totalPICCredited = picRaw + picUSCredited
        
        // Additional XC: PIC XC hours + (SIC XC hours * 0.5)
        let additionalXCCredit = additionalPICXC + (additionalSICXC * 0.5)
        
        // Instrument: actual + simulated + approved sim capped at 25.0 hrs
        let cappedSimIFR = min(25.0, simIFRHours)
        let totalIFRCredited = actualIFR + simulatedIFR + cappedSimIFR
        
        return ATPLAudit(
            totalFlightTime: (totalHours * 10).rounded() / 10,
            aeroplaneFlightTime: (aeroplaneHours * 10).rounded() / 10,
            picHoursRaw: (picRaw * 10).rounded() / 10,
            picUSHouresRaw: (picUSRaw * 10).rounded() / 10,
            picCredited: (totalPICCredited * 10).rounded() / 10,
            picXCHours: (picXC * 10).rounded() / 10,
            picNightHours: (picNight * 10).rounded() / 10,
            totalNightHours: (totalNight * 10).rounded() / 10,
            additionalXCCredited: (additionalXCCredit * 10).rounded() / 10,
            instrumentHoursCredited: (totalIFRCredited * 10).rounded() / 10
        )
    }
    
    // MARK: - CAR 401.05 Recency Tracking
    
    struct RecencyStatus {
        // CAR 401.05(2) Passenger Recency (preceding 6 months)
        let dayLandings6Mo: Int
        let nightLandings6Mo: Int
        var isDayPassengerCurrent: Bool { (dayLandings6Mo + nightLandings6Mo) >= 5 }
        var isNightPassengerCurrent: Bool { nightLandings6Mo >= 5 }
        
        // CAR 401.05(3) Instrument Recency (preceding 6 months)
        let ifrHours6Mo: Double
        let approaches6Mo: Int
        var isIFRCurrent6Mo: Bool { ifrHours6Mo >= 6.0 && approaches6Mo >= 6 }
    }
    
    /// Computes 6-month passenger and IFR recency per CAR 401.05.
    static func calculateRecencyStatus(
        flights: [FlightLogEntry],
        simulators: [SimulatorSession],
        referenceDate: Date = Date()
    ) -> RecencyStatus {
        let calendar = Calendar.current
        let date6MonthsAgo = calendar.date(byAdding: .month, value: -6, to: referenceDate) ?? referenceDate
        
        var dayLdg = 0
        var nightLdg = 0
        var ifrHrs = 0.0
        var apps = 0
        
        for flight in flights where flight.date >= date6MonthsAgo && flight.date <= referenceDate {
            dayLdg += flight.dayLandings
            nightLdg += flight.nightLandings
            ifrHrs += (flight.actualIFRHours + flight.simulatedIFRHours)
            apps += flight.approachesCount
        }
        
        for sim in simulators where sim.date >= date6MonthsAgo && sim.date <= referenceDate {
            ifrHrs += sim.ifrSimulatedHours
            apps += sim.approachesCount
        }
        
        return RecencyStatus(
            dayLandings6Mo: dayLdg,
            nightLandings6Mo: nightLdg,
            ifrHours6Mo: (ifrHrs * 10).rounded() / 10,
            approaches6Mo: apps
        )
    }
    
    // MARK: - CAR 404.04 Category 1 Medical Validity
    
    struct MedicalStatus {
        let expiryDate: Date
        let daysRemaining: Int
        let isValid: Bool
        let isExpiringSoon: Bool // Within 30 days
        let statusText: String
    }
    
    /// Evaluates Category 1 Aviation Medical Certificate validity under CAR 404.04.
    static func calculateMedicalStatus(
        profile: PilotProfile,
        referenceDate: Date = Date()
    ) -> MedicalStatus {
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: profile.dateOfBirth, to: referenceDate).year ?? 30
        
        // In Canada, medical is valid to the 1st day of the (N+1)th month
        // Under 40: 12 months
        // 40+ and single-pilot with pax: 6 months
        // 40-59 (two pilot or no pax): 12 months
        // 60+ (airline transport): 6 months
        var validityMonths = 12
        if age >= 60 {
            validityMonths = 6
        } else if age >= 40 && profile.isSinglePilotAirTransportWithPax {
            validityMonths = 6
        }
        
        // Transport Canada rule: expires on the first day of the month following validity period
        guard let targetMonthDate = calendar.date(byAdding: .month, value: validityMonths, to: profile.medicalCategory1Date),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: targetMonthDate) else {
            return MedicalStatus(expiryDate: Date(), daysRemaining: 0, isValid: false, isExpiringSoon: false, statusText: "Unknown")
        }
        
        let components = calendar.dateComponents([.year, .month], from: nextMonth)
        guard let expiryDate = calendar.date(from: components) else {
            return MedicalStatus(expiryDate: Date(), daysRemaining: 0, isValid: false, isExpiringSoon: false, statusText: "Unknown")
        }
        
        let days = calendar.dateComponents([.day], from: referenceDate, to: expiryDate).day ?? 0
        let isValid = days > 0
        let isExpiringSoon = (0...30).contains(days)
        
        let text: String
        if !isValid {
            text = "Expired (\(abs(days)) days ago)"
        } else if isExpiringSoon {
            text = "Expires in \(days) days"
        } else {
            text = "Valid (\(days) days remaining)"
        }
        
        return MedicalStatus(
            expiryDate: expiryDate,
            daysRemaining: days,
            isValid: isValid,
            isExpiringSoon: isExpiringSoon,
            statusText: text
        )
    }
    
    // MARK: - Pilot Flying (PF) Metrics
    
    struct PFMetrics {
        let totalLegs: Int
        let legsPF: Int
        let legsPM: Int
        var percentPF: Double { totalLegs > 0 ? (Double(legsPF) / Double(totalLegs)) * 100.0 : 0.0 }
    }
    
    static func calculatePFMetrics(flights: [FlightLogEntry]) -> PFMetrics {
        var pf = 0
        var total = 0
        for f in flights {
            pf += f.legsAsPilotFlying
            total += max(1, f.legsAsPilotFlying) // Count at least 1 leg per entry
        }
        return PFMetrics(
            totalLegs: total,
            legsPF: pf,
            legsPM: max(0, total - pf)
        )
    }
    
    // MARK: - Specialized Gear Totals
    
    struct GearTotals {
        let tailwheelHours: Double
        let floatHours: Double
        let skiHours: Double
        let multiEngineHours: Double
        let turbineHours: Double
    }
    
    static func calculateGearTotals(flights: [FlightLogEntry]) -> GearTotals {
        var tail = 0.0
        var float = 0.0
        var ski = 0.0
        var me = 0.0
        var turb = 0.0
        
        for f in flights {
            tail += f.tailwheelHours
            float += f.floatHours
            ski += f.skiHours
            me += f.multiEngineHours
            turb += f.turbineHours
        }
        
        return GearTotals(
            tailwheelHours: (tail * 10).rounded() / 10,
            floatHours: (float * 10).rounded() / 10,
            skiHours: (ski * 10).rounded() / 10,
            multiEngineHours: (me * 10).rounded() / 10,
            turbineHours: (turb * 10).rounded() / 10
        )
    }
}
