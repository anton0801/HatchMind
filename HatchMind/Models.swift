//
//  Models.swift
//  Hatch Mind
//

import Foundation
import SwiftUI

// MARK: - Bird Type
enum BirdType: String, Codable, CaseIterable, Identifiable {
    case chicken = "Chicken"
    case duck = "Duck"
    case goose = "Goose"
    case quail = "Quail"
    case turkey = "Turkey"
    case pheasant = "Pheasant"

    var id: String { rawValue }

    var incubationDays: Int {
        switch self {
        case .chicken: return 21
        case .duck: return 28
        case .goose: return 30
        case .quail: return 17
        case .turkey: return 28
        case .pheasant: return 24
        }
    }

    var idealTempC: ClosedRange<Double> {
        switch self {
        case .chicken: return 37.5...37.8
        case .duck: return 37.4...37.6
        case .goose: return 37.4...37.6
        case .quail: return 37.5...37.8
        case .turkey: return 37.5...37.8
        case .pheasant: return 37.5...37.8
        }
    }

    var idealHumidity: ClosedRange<Double> {
        switch self {
        case .chicken: return 50...55
        case .duck: return 55...60
        case .goose: return 55...65
        case .quail: return 45...55
        case .turkey: return 50...55
        case .pheasant: return 50...55
        }
    }

    var emoji: String {
        switch self {
        case .chicken: return "🐔"
        case .duck: return "🦆"
        case .goose: return "🪿"
        case .quail: return "🐦"
        case .turkey: return "🦃"
        case .pheasant: return "🐦"
        }
    }
}

// MARK: - Incubation
struct Incubation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var birdType: BirdType
    var startDate: Date
    var eggCount: Int
    var notes: String = ""
    var hatchedCount: Int = 0
    var isCompleted: Bool = false

    var totalDays: Int { birdType.incubationDays }

    var currentDay: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(max(days + 1, 1), totalDays)
    }

    var progress: Double {
        Double(min(currentDay, totalDays)) / Double(totalDays)
    }

    var expectedHatchDate: Date {
        Calendar.current.date(byAdding: .day, value: totalDays, to: startDate) ?? Date()
    }

    var stage: DevelopmentStage {
        DevelopmentStage.stage(forDay: currentDay, totalDays: totalDays)
    }

    var isHatchDay: Bool {
        currentDay >= totalDays
    }
}

// MARK: - Development Stage
struct DevelopmentStage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let dayRange: ClosedRange<Int>
    let description: String
    let symbol: String

    static func stage(forDay day: Int, totalDays: Int) -> DevelopmentStage {
        let stages = standard(totalDays: totalDays)
        return stages.first(where: { $0.dayRange.contains(day) }) ?? stages.first!
    }

    static func standard(totalDays: Int) -> [DevelopmentStage] {
        let q = max(totalDays / 4, 1)
        return [
            DevelopmentStage(title: "Cell Formation",
                             dayRange: 1...q,
                             description: "First cells form. Heart begins to develop. Critical temperature stability needed.",
                             symbol: "circle.dashed"),
            DevelopmentStage(title: "Organ Development",
                             dayRange: (q+1)...(q*2),
                             description: "Organs and limbs form. Embryo doubles in size. Regular turning is essential.",
                             symbol: "heart.circle"),
            DevelopmentStage(title: "Growth & Movement",
                             dayRange: (q*2+1)...(q*3),
                             description: "Feathers begin to grow. Embryo moves and responds to light.",
                             symbol: "sparkles"),
            DevelopmentStage(title: "Pre-Hatch",
                             dayRange: (q*3+1)...totalDays,
                             description: "Stop turning. Increase humidity. Chick positions for hatching.",
                             symbol: "egg.fill")
        ]
    }
}

// MARK: - Condition Reading
struct ConditionReading: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var temperatureC: Double
    var humidity: Double
    var note: String = ""
    var incubationId: UUID
}

// MARK: - Daily Log
struct DailyLogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var day: Int
    var note: String
    var turned: Bool
    var candled: Bool
    var incubationId: UUID
}

// MARK: - Candling Record
struct CandlingRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var day: Int
    var fertileCount: Int
    var infertileCount: Int
    var deadCount: Int
    var notes: String
    var incubationId: UUID
}

// MARK: - Reminder / Task
enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case turning = "Turning"
    case checkConditions = "Check Conditions"
    case candling = "Candling"
    case prepareHatcher = "Prepare Hatcher"
    case custom = "Custom"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .turning: return "arrow.triangle.2.circlepath"
        case .checkConditions: return "thermometer"
        case .candling: return "flashlight.on.fill"
        case .prepareHatcher: return "tray.fill"
        case .custom: return "bell.fill"
        }
    }

    var icon: String { symbol }

    var color: Color {
        switch self {
        case .turning: return .hmOrange
        case .checkConditions: return .hmTempNorm
        case .candling: return .hmYellow
        case .prepareHatcher: return .hmGreen
        case .custom: return .hmYellowActive
        }
    }

    var tint: Color { color }

    var defaultTitle: String {
        switch self {
        case .turning: return "Turn the eggs"
        case .checkConditions: return "Check temperature & humidity"
        case .candling: return "Candle eggs"
        case .prepareHatcher: return "Prepare hatcher"
        case .custom: return "Custom reminder"
        }
    }

    var helperText: String {
        switch self {
        case .turning: return "3–5 times daily during incubation"
        case .checkConditions: return "Quick environmental sweep"
        case .candling: return "Inspect on day 7, 14, 18"
        case .prepareHatcher: return "Stop turning, raise humidity"
        case .custom: return "Anything you choose"
        }
    }
}

struct ReminderItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var type: ReminderType
    var time: Date
    var isEnabled: Bool
    var repeatDaily: Bool
    var incubationId: UUID?
    var notificationId: String { id.uuidString }
}

// MARK: - Alert
enum AlertSeverity: String, Codable {
    case info, warning, critical
    var color: Color {
        switch self {
        case .info: return .hmGreen
        case .warning: return .hmYellow
        case .critical: return .hmStatusError
        }
    }
    var symbol: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct ConditionAlert: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var severity: AlertSeverity
    var title: String
    var message: String
    var incubationId: UUID
    var isRead: Bool = false
}

// MARK: - Activity Entry
struct ActivityEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var title: String
    var detail: String
    var symbol: String
}

// MARK: - Task
struct InspectionTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var detail: String
    var dueDate: Date
    var isDone: Bool
    var incubationId: UUID?
}

// MARK: - User Profile
struct UserProfile: Codable, Equatable {
    var name: String
    var farmName: String
    var email: String
    var bio: String = ""

    static let demo = UserProfile(name: "Demo Farmer",
                                  farmName: "Sunny Coop",
                                  email: "demo@hatchmind.app",
                                  bio: "Raising healthy poultry one batch at a time.")
}
