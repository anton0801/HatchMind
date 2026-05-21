//
//  DataStore.swift
//  Hatch Mind
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

final class DataStore: ObservableObject {
    @Published var incubations: [Incubation] = [] { didSet { save(incubations, key: "hm_incubations") } }
    @Published var readings: [ConditionReading] = [] { didSet { save(readings, key: "hm_readings") } }
    @Published var logs: [DailyLogEntry] = [] { didSet { save(logs, key: "hm_logs") } }
    @Published var candlings: [CandlingRecord] = [] { didSet { save(candlings, key: "hm_candlings") } }
    @Published var reminders: [ReminderItem] = [] { didSet { save(reminders, key: "hm_reminders") } }
    @Published var alerts: [ConditionAlert] = [] { didSet { save(alerts, key: "hm_alerts") } }
    @Published var activity: [ActivityEntry] = [] { didSet { save(activity, key: "hm_activity") } }
    @Published var tasks: [InspectionTask] = [] { didSet { save(tasks, key: "hm_tasks") } }

    init() {
        self.incubations = load("hm_incubations") ?? []
        self.readings = load("hm_readings") ?? []
        self.logs = load("hm_logs") ?? []
        self.candlings = load("hm_candlings") ?? []
        self.reminders = load("hm_reminders") ?? []
        self.alerts = load("hm_alerts") ?? []
        self.activity = load("hm_activity") ?? []
        self.tasks = load("hm_tasks") ?? []

        if incubations.isEmpty {
            seedSampleData()
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Seed
    private func seedSampleData() {
        let demo = Incubation(name: "Coop A — Spring Batch",
                              birdType: .chicken,
                              startDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date(),
                              eggCount: 24,
                              notes: "First batch of the season.")
        incubations.append(demo)

        // Seed readings for the past 8 days
        for i in 0..<8 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let temp = 37.5 + Double.random(in: -0.4...0.4)
            let hum = 52.0 + Double.random(in: -4.0...4.0)
            readings.append(ConditionReading(date: date, temperatureC: temp, humidity: hum,
                                             note: "", incubationId: demo.id))
        }

        // Daily logs
        for i in 0..<8 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            logs.append(DailyLogEntry(date: date, day: 8 - i,
                                      note: "All eggs turned. Conditions stable.",
                                      turned: true, candled: i == 5,
                                      incubationId: demo.id))
        }

        // Reminder
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 8; comps.minute = 0
        reminders.append(ReminderItem(title: "Morning Turning",
                                      type: .turning,
                                      time: Calendar.current.date(from: comps) ?? Date(),
                                      isEnabled: true,
                                      repeatDaily: true,
                                      incubationId: demo.id))
        comps.hour = 20; comps.minute = 0
        reminders.append(ReminderItem(title: "Evening Check",
                                      type: .checkConditions,
                                      time: Calendar.current.date(from: comps) ?? Date(),
                                      isEnabled: true,
                                      repeatDaily: true,
                                      incubationId: demo.id))

        // Tasks
        tasks.append(InspectionTask(title: "Check incubator water",
                                    detail: "Refill humidity tray if below 50%.",
                                    dueDate: Date(),
                                    isDone: false,
                                    incubationId: demo.id))
        tasks.append(InspectionTask(title: "Verify thermometer calibration",
                                    detail: "Compare with reference thermometer.",
                                    dueDate: Date().addingTimeInterval(86400),
                                    isDone: false,
                                    incubationId: demo.id))

        // Activity
        activity.append(ActivityEntry(date: Date().addingTimeInterval(-3600),
                                      title: "Incubation started",
                                      detail: "Coop A — Spring Batch",
                                      symbol: "play.circle.fill"))
    }

    // MARK: - Incubations
    func addIncubation(_ inc: Incubation) {
        incubations.append(inc)
        log(activity: ActivityEntry(date: Date(),
                                    title: "Started \(inc.name)",
                                    detail: "\(inc.eggCount) \(inc.birdType.rawValue.lowercased()) eggs",
                                    symbol: "plus.circle.fill"))
    }

    func updateIncubation(_ inc: Incubation) {
        if let idx = incubations.firstIndex(where: { $0.id == inc.id }) {
            incubations[idx] = inc
        }
    }

    func deleteIncubation(_ inc: Incubation) {
        incubations.removeAll { $0.id == inc.id }
        readings.removeAll { $0.incubationId == inc.id }
        logs.removeAll { $0.incubationId == inc.id }
        candlings.removeAll { $0.incubationId == inc.id }
        reminders.removeAll { $0.incubationId == inc.id }
        alerts.removeAll { $0.incubationId == inc.id }
        log(activity: ActivityEntry(date: Date(),
                                    title: "Removed \(inc.name)",
                                    detail: "Incubation deleted",
                                    symbol: "trash.fill"))
    }

    // MARK: - Readings
    func addReading(_ r: ConditionReading, for inc: Incubation) {
        readings.append(r)
        // alert generation
        if !inc.birdType.idealTempC.contains(r.temperatureC) {
            let severity: AlertSeverity = abs(r.temperatureC - 37.6) > 1.0 ? .critical : .warning
            let title = r.temperatureC > 37.8 ? "Temperature too high" : "Temperature too low"
            alerts.insert(ConditionAlert(date: Date(), severity: severity,
                                         title: title,
                                         message: "Reading \(String(format: "%.1f°C", r.temperatureC)) outside ideal range.",
                                         incubationId: inc.id), at: 0)
        }
        if !inc.birdType.idealHumidity.contains(r.humidity) {
            let severity: AlertSeverity = abs(r.humidity - 53) > 10 ? .critical : .warning
            let title = r.humidity > 60 ? "Humidity too high" : "Humidity too low"
            alerts.insert(ConditionAlert(date: Date(), severity: severity,
                                         title: title,
                                         message: "Humidity at \(Int(r.humidity))% outside ideal range.",
                                         incubationId: inc.id), at: 0)
        }
        log(activity: ActivityEntry(date: Date(),
                                    title: "Logged conditions",
                                    detail: String(format: "%.1f°C, %.0f%% RH", r.temperatureC, r.humidity),
                                    symbol: "thermometer"))
    }

    // MARK: - Logs
    func addLog(_ entry: DailyLogEntry) {
        logs.insert(entry, at: 0)
        log(activity: ActivityEntry(date: Date(),
                                    title: "Daily log saved",
                                    detail: "Day \(entry.day)",
                                    symbol: "square.and.pencil"))
    }

    // MARK: - Candling
    func addCandling(_ c: CandlingRecord) {
        candlings.insert(c, at: 0)
        log(activity: ActivityEntry(date: Date(),
                                    title: "Candling complete",
                                    detail: "Day \(c.day) — \(c.fertileCount) fertile",
                                    symbol: "flashlight.on.fill"))
    }

    // MARK: - Reminders
    func addReminder(_ r: ReminderItem) {
        reminders.append(r)
        if r.isEnabled { schedule(r) }
    }

    func updateReminder(_ r: ReminderItem) {
        if let idx = reminders.firstIndex(where: { $0.id == r.id }) {
            reminders[idx] = r
        }
        cancel(r)
        if r.isEnabled { schedule(r) }
    }

    func toggleReminder(_ r: ReminderItem) {
        var copy = r
        copy.isEnabled.toggle()
        updateReminder(copy)
    }

    func deleteReminder(_ r: ReminderItem) {
        cancel(r)
        reminders.removeAll { $0.id == r.id }
    }

    // MARK: - Alerts
    func markAlertRead(_ a: ConditionAlert) {
        if let idx = alerts.firstIndex(where: { $0.id == a.id }) {
            alerts[idx].isRead = true
        }
    }
    func clearAllAlerts() { alerts.removeAll() }

    // MARK: - Tasks
    func addTask(_ t: InspectionTask) {
        tasks.append(t)
        log(activity: ActivityEntry(date: Date(),
                                    title: "Task added",
                                    detail: t.title,
                                    symbol: "checklist"))
    }
    func toggleTask(_ t: InspectionTask) {
        if let idx = tasks.firstIndex(where: { $0.id == t.id }) {
            tasks[idx].isDone.toggle()
            if tasks[idx].isDone {
                log(activity: ActivityEntry(date: Date(),
                                            title: "Task completed",
                                            detail: t.title,
                                            symbol: "checkmark.circle.fill"))
            }
        }
    }
    func deleteTask(_ t: InspectionTask) {
        tasks.removeAll { $0.id == t.id }
    }

    // MARK: - Activity
    func log(activity entry: ActivityEntry) {
        activity.insert(entry, at: 0)
        if activity.count > 200 { activity = Array(activity.prefix(200)) }
    }

    func log(activity title: String, detail: String = "", symbol: String = "circle.fill") {
        log(activity: ActivityEntry(date: Date(), title: title, detail: detail, symbol: symbol))
    }

    func clearActivity() { activity.removeAll() }

    // MARK: - Reset
    func resetAll() {
        cancelAllNotifications()
        incubations.removeAll()
        readings.removeAll()
        logs.removeAll()
        candlings.removeAll()
        reminders.removeAll()
        alerts.removeAll()
        activity.removeAll()
        tasks.removeAll()
        seedSampleData()
    }

    // MARK: - Notifications
    func schedule(_ r: ReminderItem) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = r.title
        content.body = "Time for: \(r.type.rawValue)"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.hour, .minute], from: r.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: r.repeatDaily)
        let req = UNNotificationRequest(identifier: r.notificationId, content: content, trigger: trigger)
        center.add(req)
    }

    func cancel(_ r: ReminderItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [r.notificationId])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func rescheduleAll() {
        cancelAllNotifications()
        reminders.filter { $0.isEnabled }.forEach { schedule($0) }
    }

    // MARK: - Lookups
    func readings(for inc: Incubation) -> [ConditionReading] {
        readings.filter { $0.incubationId == inc.id }.sorted { $0.date > $1.date }
    }
    func logs(for inc: Incubation) -> [DailyLogEntry] {
        logs.filter { $0.incubationId == inc.id }.sorted { $0.day > $1.day }
    }
    func candlings(for inc: Incubation) -> [CandlingRecord] {
        candlings.filter { $0.incubationId == inc.id }.sorted { $0.day > $1.day }
    }
    func alerts(for inc: Incubation) -> [ConditionAlert] {
        alerts.filter { $0.incubationId == inc.id }.sorted { $0.date > $1.date }
    }
    func reminders(for inc: Incubation?) -> [ReminderItem] {
        guard let inc = inc else { return reminders }
        return reminders.filter { $0.incubationId == inc.id }
    }

    // Latest reading for dashboard
    func latestReading(for inc: Incubation) -> ConditionReading? {
        readings(for: inc).first
    }

    var primaryIncubation: Incubation? {
        incubations.first(where: { !$0.isCompleted }) ?? incubations.first
    }
}
